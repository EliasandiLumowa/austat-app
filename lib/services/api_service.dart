import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/document_model.dart';
import '../models/indicator_model.dart';
import '../config/app_config.dart'; // Import file konfigurasi

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _baseUrl = _getDefaultBaseUrl();
  }

  // Active base URL for backend connection
  late String _baseUrl;
  String get baseUrl => _baseUrl;

  static String _getDefaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      // GANTI BARIS INI: Gunakan AppConfig agar dinamis
      if (Platform.isAndroid) return AppConfig.baseUrl; 
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Normalizes media URLs (covers, audio streams) from Laravel backend
  /// so they resolve properly across Android Emulator (10.0.2.2),
  /// Physical devices on Wi-Fi (LAN IP), Web, and Desktop.
  static String? normalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    final currentBase = ApiService().baseUrl;

    if (trimmed.startsWith('/')) {
      return '$currentBase$trimmed';
    }

    try {
      final parsed = Uri.parse(trimmed);
      final base = Uri.parse(currentBase);

      // If backend returned localhost / 127.0.0.1 but the device needs 10.0.2.2 or LAN IP
      if ((parsed.host == '127.0.0.1' || parsed.host == 'localhost') && (base.host != parsed.host)) {
        return parsed.replace(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
        ).toString();
      }
    } catch (_) {}

    return trimmed;
  }

  // Common JSON headers
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // --- API METHODS ---

  /// Fetch home page bundle (indicators, recents, statistics, years) in one shot
  Future<Map<String, dynamic>> getHomeBundle() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/home');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];

          final indicators = (data['indicators'] as List? ?? [])
              .map((i) => IndicatorModel.fromJson(i))
              .toList();

          final recents = (data['recent_documents'] as List? ?? [])
              .map((d) => DocumentModel.fromJson(d))
              .toList();

          final statistics = data['statistics'] as Map<String, dynamic>? ?? {};
          final availableYears = (data['available_years'] as List? ?? [])
              .map((y) => int.tryParse(y.toString()) ?? 2025)
              .toList();

          return {
            'indicators': indicators.isNotEmpty ? indicators : defaultIndicators,
            'recentDocuments': recents.isNotEmpty ? recents : defaultDocuments,
            'statistics': statistics,
            'availableYears': availableYears.isNotEmpty ? availableYears : getAvailableYears(),
          };
        }
      }
    } catch (_) {}

    // Fallback if offline
    return {
      'indicators': defaultIndicators,
      'recentDocuments': defaultDocuments,
      'statistics': {
        'total_documents': defaultDocuments.length,
        'total_publications': defaultDocuments.where((d) => d.isPublication).length,
        'total_brs': defaultDocuments.where((d) => d.isBrs).length,
        'total_audio_files': defaultDocuments.where((d) => d.hasAudio).length,
      },
      'availableYears': getAvailableYears(),
    };
  }

  /// Get list of indicators with active documents count
  Future<List<IndicatorModel>> getIndicators() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/indicators');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          final list = (body['data'] as List)
              .map((item) => IndicatorModel.fromJson(item))
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    return defaultIndicators;
  }

  /// Get recent documents for home screen
  Future<List<DocumentModel>> getRecentDocuments() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/documents?per_page=6&sort_by=created_at&sort_order=desc');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final docsJson = body['data']?['documents'] ?? body['data']?['data'] ?? body['data'];
        if (docsJson is List) {
          final list = docsJson.map((item) => DocumentModel.fromJson(item)).toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    return defaultDocuments;
  }

  /// Get publication documents with filtering
  Future<List<DocumentModel>> getPublications({
    String? query,
    int? year,
    int? indicatorId,
    int page = 1,
    int perPage = 12,
  }) async {
    return _fetchDocuments(
      type: 'publication',
      query: query,
      year: year,
      indicatorId: indicatorId,
      page: page,
      perPage: perPage,
    );
  }

  /// Get BRS documents with filtering
  Future<List<DocumentModel>> getBrs({
    String? query,
    int? year,
    int? indicatorId,
    int page = 1,
    int perPage = 12,
  }) async {
    return _fetchDocuments(
      type: 'brs',
      query: query,
      year: year,
      indicatorId: indicatorId,
      page: page,
      perPage: perPage,
    );
  }

  /// Search across documents with flexible filters
  Future<List<DocumentModel>> searchDocuments({
    String? query,
    String? type,
    int? year,
    int? indicatorId,
    int page = 1,
    int perPage = 12,
  }) async {
    return _fetchDocuments(
      type: type,
      query: query,
      year: year,
      indicatorId: indicatorId,
      page: page,
      perPage: perPage,
    );
  }

  /// Internal document fetcher with API call and offline fallback
  Future<List<DocumentModel>> _fetchDocuments({
    String? type,
    String? query,
    int? year,
    int? indicatorId,
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != null && type.isNotEmpty && type != 'all') {
        queryParams['type'] = type;
      }
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      if (indicatorId != null) {
        queryParams['indicator_id'] = indicatorId.toString();
      }
      if (query != null && query.trim().isNotEmpty) {
        queryParams['search'] = query.trim();
      }

      final uri = Uri.parse('$_baseUrl/api/v1/documents').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final docsJson = body['data']?['documents'] ?? body['data']?['data'] ?? body['data'];
        if (docsJson is List) {
          final list = docsJson.map((item) => DocumentModel.fromJson(item)).toList();
          // If the backend has documents, return them
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    // Graceful fallback to local documents if offline or empty
    return _filterDocuments(
      type: type,
      query: query,
      year: year,
      indicatorId: indicatorId,
    );
  }

  /// Get single document detail and its related documents
  Future<Map<String, dynamic>?> getDocumentDetail(dynamic idOrSlug) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/documents/$idOrSlug');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final doc = DocumentModel.fromJson(data['document']);
          final related = (data['related'] as List? ?? [])
              .map((item) => DocumentModel.fromJson(item))
              .toList();

          return {
            'document': doc,
            'related': related,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// NLP Voice Search - sends spoken transcript to backend parser
  Future<Map<String, dynamic>> parseVoiceSearch(String transcript) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/voice-search');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'transcript': transcript}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['parsed'] != null) {
          final parsed = body['parsed'];
          return {
            'query': parsed['query'] ?? '',
            'year': parsed['year'],
            'type': parsed['type'],
            'indicatorId': parsed['indicator_id'],
          };
        }
      }
    } catch (_) {}

    // Fallback to local NLP parsing matching Laravel HomeController@parseSearchInput
    final lower = transcript.toLowerCase();
    int? detectedYear;
    String? detectedType;
    int? detectedIndicatorId;
    String remainder = transcript;

    // Detect 4-digit year
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(lower);
    if (yearMatch != null) {
      detectedYear = int.tryParse(yearMatch.group(1)!);
      remainder = remainder.replaceAll(yearMatch.group(1)!, '');
    }

    // Detect document type
    if (lower.contains('publikasi')) {
      detectedType = 'publication';
      remainder = remainder.replaceAll(RegExp(r'publikasi', caseSensitive: false), '');
    } else if (lower.contains('brs') || lower.contains('berita resmi')) {
      detectedType = 'brs';
      remainder = remainder.replaceAll(RegExp(r'brs|berita resmi', caseSensitive: false), '');
    }

    // Detect indicator
    for (final ind in defaultIndicators) {
      if (lower.contains(ind.name.toLowerCase()) || lower.contains(ind.slug)) {
        detectedIndicatorId = ind.id;
        remainder = remainder.replaceAll(RegExp(ind.name, caseSensitive: false), '');
        break;
      }
    }

    // Clean common stopwords
    final stopwords = [
      'dokumen', 'carikan', 'carilah', 'cariin', 'tahun', 'indikator',
      'tolong', 'jenis', 'halo', 'hai', 'bps', 'sulawesi utara', 'sulut',
      'saya', 'ingin', 'mau', 'lihat', 'tampilkan', 'cari', 'data'
    ];
    for (final stop in stopwords) {
      remainder = remainder.replaceAll(RegExp('\\b$stop\\b', caseSensitive: false), '');
    }
    remainder = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();

    return {
      'query': remainder,
      'year': detectedYear,
      'type': detectedType,
      'indicatorId': detectedIndicatorId,
    };
  }

  /// Search keyword suggestions for auto-complete
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/search-suggestions?q=${Uri.encodeComponent(query)}');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          return body.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Available years for filtering
  Future<List<int>> getAvailableYearsFromApi() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/documents/years');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          final list = (body['data'] as List)
              .map((y) => int.tryParse(y.toString()) ?? 2025)
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}
    return getAvailableYears();
  }

  List<int> getAvailableYears() {
    return [2026, 2025, 2024, 2023, 2022, 2021];
  }

  /// Record audio playback event in backend
  Future<void> recordPlay(int documentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/documents/$documentId/play');
      await http.post(uri, headers: _headers).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Record document download event in backend
  Future<void> recordDownload(int documentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/documents/$documentId/track-download');
      await http.post(uri, headers: _headers).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  // --- LOCAL FALLBACK FILTERING ---

  List<DocumentModel> _filterDocuments({
    String? type,
    String? query,
    int? year,
    int? indicatorId,
  }) {
    return defaultDocuments.where((doc) {
      if (type != null && type.isNotEmpty && type != 'all') {
        if (doc.type.toLowerCase() != type.toLowerCase()) return false;
      }
      if (year != null && doc.year != year) {
        return false;
      }
      if (indicatorId != null && doc.indicatorId != indicatorId) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchTitle = doc.title.toLowerCase().contains(q);
        final matchDesc = (doc.description ?? '').toLowerCase().contains(q);
        final matchInd = (doc.indicator?.name ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchInd) return false;
      }
      return true;
    }).toList();
  }

  // --- DEFAULT DATA FOR OFFLINE / INITIAL PREVIEW ---

  static final List<IndicatorModel> defaultIndicators = [
    const IndicatorModel(
      id: 1,
      name: 'Pertumbuhan Ekonomi',
      slug: 'pertumbuhan-ekonomi',
      description: 'Data dan analisis pertumbuhan ekonomi regional PDRB Sulawesi Utara',
      icon: 'fas fa-chart-line',
      activeDocumentsCount: 24,
    ),
    const IndicatorModel(
      id: 2,
      name: 'Inflasi',
      slug: 'inflasi',
      description: 'Tingkat inflasi dan indeks harga konsumen di Sulawesi Utara',
      icon: 'fas fa-percentage',
      activeDocumentsCount: 18,
    ),
    const IndicatorModel(
      id: 3,
      name: 'Nilai Tukar Petani (NTP)',
      slug: 'ntp',
      description: 'Nilai tukar petani dan indeks harga yang dibayar petani',
      icon: 'fas fa-seedling',
      activeDocumentsCount: 15,
    ),
    const IndicatorModel(
      id: 4,
      name: 'Ekspor dan Impor',
      slug: 'ekspor-impor',
      description: 'Data perdagangan luar negeri ekspor dan impor Sulawesi Utara',
      icon: 'fas fa-ship',
      activeDocumentsCount: 14,
    ),
    const IndicatorModel(
      id: 5,
      name: 'Transportasi',
      slug: 'transportasi',
      description: 'Statistik transportasi laut, udara, dan darat Sulawesi Utara',
      icon: 'fas fa-truck',
      activeDocumentsCount: 10,
    ),
    const IndicatorModel(
      id: 6,
      name: 'Pariwisata',
      slug: 'pariwisata',
      description: 'Data tingkat hunian hotel dan wisatawan mancanegara',
      icon: 'fas fa-camera',
      activeDocumentsCount: 12,
    ),
    const IndicatorModel(
      id: 7,
      name: 'Pembangunan Manusia',
      slug: 'pembangunan-manusia',
      description: 'Indeks Pembangunan Manusia (IPM) dan kualitas hidup masyarakat',
      icon: 'fas fa-users',
      activeDocumentsCount: 8,
    ),
    const IndicatorModel(
      id: 8,
      name: 'Pertanian',
      slug: 'pertanian',
      description: 'Statistik pertanian, perkebunan kelapa, cengkeh, dan perikanan',
      icon: 'fas fa-leaf',
      activeDocumentsCount: 16,
    ),
    const IndicatorModel(
      id: 9,
      name: 'Ketenagakerjaan',
      slug: 'ketenagakerjaan',
      description: 'Data ketenagakerjaan, tingkat pengangguran terbuka (TPT), dan angkatan kerja',
      icon: 'fas fa-briefcase',
      activeDocumentsCount: 11,
    ),
    const IndicatorModel(
      id: 10,
      name: 'Kemiskinan',
      slug: 'kemiskinan',
      description: 'Tingkat kemiskinan, garis kemiskinan, dan kesenjangan sosial',
      icon: 'fas fa-hand-holding-heart',
      activeDocumentsCount: 9,
    ),
    const IndicatorModel(
      id: 11,
      name: 'Industri',
      slug: 'industri',
      description: 'Statistik industri pengolahan mikro, kecil, dan manufaktur',
      icon: 'fas fa-industry',
      activeDocumentsCount: 7,
    ),
    const IndicatorModel(
      id: 12,
      name: 'Kependudukan',
      slug: 'kependudukan',
      description: 'Data demografi, piramida penduduk, dan proyeksi kependudukan',
      icon: 'fas fa-user-friends',
      activeDocumentsCount: 13,
    ),
  ];

  static final List<DocumentModel> defaultDocuments = [
    DocumentModel(
      id: 1,
      uuid: 'sulut-doc-001',
      title: 'Provinsi Sulawesi Utara Dalam Angka 2025',
      slug: 'provinsi-sulawesi-utara-dalam-angka-2025',
      type: 'publication',
      year: 2025,
      indicatorId: 1,
      indicator: defaultIndicators[0],
      description: 'Publikasi komprehensif yang memuat gambaran umum tentang keadaan geografi dan iklim, pemerintahan, serta perkembangan kondisi sosial-demografi dan perekonomian di Sulawesi Utara tahun 2025.',
      fileSizeFormatted: '18.4 MB',
      coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=600&q=80',
      mp3Url: 'https://actions.google.com/sounds/v1/speech/greeting.mp3',
      audioDuration: 745,
      audioDurationFormatted: '12:25',
      downloadCount: 1240,
      playCount: 432,
      createdAt: '25 Januari 2025',
      extractedText: 'Ringkasan Eksekutif: Perekonomian Sulawesi Utara pada tahun 2024 tumbuh solid di atas rata-rata nasional sebesar 5,48 persen didukung oleh sektor pertanian, perdagangan besar dan eceran, serta konstruksi.',
    ),
    DocumentModel(
      id: 2,
      uuid: 'sulut-doc-002',
      title: 'Perkembangan Indeks Harga Konsumen dan Inflasi Sulawesi Utara Januari 2025',
      slug: 'perkembangan-inflasi-sulut-januari-2025',
      type: 'brs',
      year: 2025,
      indicatorId: 2,
      indicator: defaultIndicators[1],
      description: 'Berita Resmi Statistik mengenai perkembangan inflasi gabungan kota-kota di Sulawesi Utara (Kota Manado dan Kota Kotamobagu) pada Januari 2025.',
      fileSizeFormatted: '1.8 MB',
      coverUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=600&q=80',
      mp3Url: 'https://actions.google.com/sounds/v1/speech/announcement.mp3',
      audioDuration: 320,
      audioDurationFormatted: '05:20',
      downloadCount: 890,
      playCount: 512,
      createdAt: '01 Februari 2025',
      extractedText: 'Pada bulan Januari 2025, Sulawesi Utara mengalami inflasi year-on-year sebesar 2,41 persen dengan Indeks Harga Konsumen (IHK) sebesar 106,32. Komoditas penyumbang inflasi utama adalah beras, cabai rawit, dan tomat.',
    ),
    DocumentModel(
      id: 3,
      uuid: 'sulut-doc-003',
      title: 'Pertumbuhan Ekonomi Sulawesi Utara Triwulan IV-2024',
      slug: 'pertumbuhan-ekonomi-sulut-tw-iv-2024',
      type: 'brs',
      year: 2024,
      indicatorId: 1,
      indicator: defaultIndicators[0],
      description: 'Laporan BRS mengenai Produk Domestik Regional Bruto (PDRB) Sulawesi Utara Triwulan IV-2024 berdasarkan harga berlaku dan harga konstan 2010.',
      fileSizeFormatted: '2.1 MB',
      coverUrl: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=600&q=80',
      mp3Url: 'https://actions.google.com/sounds/v1/speech/greeting.mp3',
      audioDuration: 410,
      audioDurationFormatted: '06:50',
      downloadCount: 1530,
      playCount: 780,
      createdAt: '05 Februari 2025',
      extractedText: 'Ekonomi Sulawesi Utara Triwulan IV-2024 tumbuh sebesar 5,62 persen (y-on-y). Dari sisi produksi, Lapangan Usaha Jasa Keuangan dan Asuransi mengalami pertumbuhan tertinggi sebesar 11,20 persen.',
    ),
    DocumentModel(
      id: 4,
      uuid: 'sulut-doc-004',
      title: 'Indikator Kesejahteraan Rakyat Sulawesi Utara 2024',
      slug: 'indikator-kesejahteraan-rakyat-sulut-2024',
      type: 'publication',
      year: 2024,
      indicatorId: 7,
      indicator: defaultIndicators[6],
      description: 'Publikasi tahunan yang menyajikan aspek kesejahteraan yang datanya tersedia dan terukur, meliputi kependudukan, kesehatan, pendidikan, ketenagakerjaan, taraf dan pola konsumsi.',
      fileSizeFormatted: '12.6 MB',
      coverUrl: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=600&q=80',
      mp3Url: 'https://actions.google.com/sounds/v1/speech/announcement.mp3',
      audioDuration: 615,
      audioDurationFormatted: '10:15',
      downloadCount: 940,
      playCount: 310,
      createdAt: '18 Desember 2024',
      extractedText: 'Indeks Pembangunan Manusia (IPM) Provinsi Sulawesi Utara tahun 2024 mencapai 75,28, meningkat 0,55 poin dibandingkan capaian tahun sebelumnya, menempatkan Sulut dalam kategori IPM tinggi.',
    ),
    DocumentModel(
      id: 5,
      uuid: 'sulut-doc-005',
      title: 'Statistik Ekspor dan Impor Provinsi Sulawesi Utara 2024',
      slug: 'statistik-ekspor-impor-sulut-2024',
      type: 'publication',
      year: 2024,
      indicatorId: 4,
      indicator: defaultIndicators[3],
      description: 'Memuat data ekspor menurut komoditi unggulan (minyak nabati, kopra, ikan) dan negara tujuan utama serta perkembangan impor barang modal dan konsumsi.',
      fileSizeFormatted: '9.3 MB',
      coverUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80',
      mp3Url: 'https://actions.google.com/sounds/v1/speech/greeting.mp3',
      audioDuration: 480,
      audioDurationFormatted: '08:00',
      downloadCount: 720,
      playCount: 245,
      createdAt: '12 November 2024',
      extractedText: 'Nilai ekspor nonmigas Sulawesi Utara tahun 2024 mencapai USD 1,12 miliar dengan komoditas lemak dan minyak hewan/nabati tetap menjadi andalan utama ke pasar Tiongkok dan Amerika Serikat.',
    ),
    DocumentModel(
      id: 6,
      uuid: 'sulut-doc-006',
      title: 'Perkembangan Nilai Tukar Petani (NTP) Sulawesi Utara Januari 2025',
      slug: 'perkembangan-ntp-sulut-januari-2025',
      type: 'brs',
      year: 2025,
      indicatorId: 3,
      indicator: defaultIndicators[2],
      description: 'Data bulanan BRS tentang Nilai Tukar Petani dan indeks harga produsen pertanian subsektor tanaman pangan, hortikultura, perkebunan rakyat, dan peternakan.',
      fileSizeFormatted: '1.5 MB',
      coverUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=600&q=80',
      mp3Url: 'https://actions.google.com/sounds/v1/speech/announcement.mp3',
      audioDuration: 285,
      audioDurationFormatted: '04:45',
      downloadCount: 610,
      playCount: 220,
      createdAt: '01 Februari 2025',
      extractedText: 'Nilai Tukar Petani (NTP) Sulawesi Utara pada Januari 2025 sebesar 113,84 atau naik 0,68 persen dibanding NTP bulan sebelumnya yang dipicu kenaikan subsektor perkebunan cengkeh dan kelapa.',
    ),
  ];
}
