import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import '../models/document_model.dart';
import '../models/indicator_model.dart';
import 'api_service.dart';
import 'audio_service.dart';

enum VoiceState {
  idle,
  speaking,
  listening,
  processing,
  error,
}

class VoiceAssistantService extends ChangeNotifier {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  bool get isSpeaking => _state == VoiceState.speaking;
  bool get isListening => _state == VoiceState.listening;

  String _statusMessage = 'Menyiapkan asisten suara...';
  String get statusMessage => _statusMessage;

  String _lastSpokenWords = '';
  String get lastSpokenWords => _lastSpokenWords;

  IndicatorModel? _selectedIndicator;
  IndicatorModel? get selectedIndicator => _selectedIndicator;

  List<DocumentModel> _matchedDocuments = [];
  List<DocumentModel> get matchedDocuments => _matchedDocuments;

  DocumentModel? _activeDocument;
  DocumentModel? get activeDocument => _activeDocument;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String _localeId = 'id_ID';
  bool _speechEnabled = false;
  Timer? _speechDebounceTimer;
  Timer? _relistenTimer;
  Timer? _ttsFallbackTimer;
  bool _isProcessingCommand = false;
  bool _isStartingSpeech = false;
  bool _shouldListenAfterTts = true;
  bool _isWaitingForUserSpeech = false;

  // Callbacks for screen updates
  void Function(IndicatorModel indicator, List<DocumentModel> docs)? onIndicatorSelected;
  void Function(DocumentModel doc)? onPlayDocument;
  void Function(int tabIndex)? onNavigateTab;

  /// Inisialisasi TTS dan STT
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setup TTS
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.5); // Kecepatan jelas dan ramah
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      _tts.setStartHandler(() {
        _state = VoiceState.speaking;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _onTtsCompleted();
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _onTtsCompleted();
      });

      // Setup STT
      _speechEnabled = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (_speechEnabled) {
        final locales = await _speech.locales();
        final indLocale = locales.where((l) => l.localeId.toLowerCase().startsWith('id'));
        if (indLocale.isNotEmpty) {
          _localeId = indLocale.first.localeId;
        } else {
          final system = await _speech.systemLocale();
          if (system != null) {
            _localeId = system.localeId;
          }
        }
      }

      _isInitialized = true;
      _statusMessage = 'Asisten suara siap';
      notifyListeners();
    } catch (e) {
      debugPrint('VoiceAssistant init error: $e');
      _isInitialized = true;
    }
  }

  /// Alur Sambutan & Tutorial Otomatis saat aplikasi dibuka
  Future<void> startWelcomeFlow() async {
    await initialize();

    // Hentikan pemutaran audio lain jika ada
    await AudioService().stop();
    await _speech.stop();
    _isWaitingForUserSpeech = false;
    _selectedIndicator = null;
    _matchedDocuments = [];
    _activeDocument = null;

    const welcomeScript = 
        'Selamat datang di Audio Statistik Badan Pusat Statistik Provinsi Sulawesi Utara. '
        'Aplikasi ini dirancang khusus dengan kendali suara penuh. '
        'Setelah penjelasan ini selesai, mikrofon akan aktif terus mendengarkan suara Anda tanpa perlu menekan tombol apapun. '
        'Jika audio sedang berbicara, Anda dapat langsung berbicara atau mengetuk layar untuk memotong audio. '
        'Berikut adalah dua belas jenis indikator statistik: '
        'Satu, Pertumbuhan Ekonomi. '
        'Dua, Inflasi. '
        'Tiga, Nilai Tukar Petani atau NTP. '
        'Empat, Ekspor dan Impor. '
        'Lima, Transportasi. '
        'Enam, Pariwisata. '
        'Tujuh, Pembangunan Manusia. '
        'Delapan, Pertanian. '
        'Sembilan, Ketenagakerjaan. '
        'Sepuluh, Kemiskinan. '
        'Sebelas, Industri. '
        'Dua belas, Kependudukan. '
        'Anda dapat memilih dengan menyebutkan nomornya atau langsung menyebutkan nama indikatornya.';

    _statusMessage = 'Menyampaikan sambutan dan tutorial...';
    notifyListeners();

    await speak(welcomeScript, listenAfter: true);
  }

  /// Membacakan teks melalui TTS
  Future<void> speak(String text, {bool listenAfter = true}) async {
    _ttsFallbackTimer?.cancel();
    _speechDebounceTimer?.cancel();
    _relistenTimer?.cancel();

    // Hentikan STT saat TTS berbicara agar mic tidak menangkap suara TTS sendiri
    if (_speech.isListening) {
      await _speech.stop();
    }

    _state = VoiceState.speaking;
    _statusMessage = 'Berbicara...';
    _shouldListenAfterTts = listenAfter;
    notifyListeners();

    // Safety fallback timer: jika native completion event di Android macet/hilang,
    // timer ini otomatis menyelesaikan status berbicara dan membuka mic
    final words = text.split(RegExp(r'\s+')).length;
    final estimatedDurationSeconds = (words / 2.3).ceil() + 2;
    _ttsFallbackTimer = Timer(Duration(seconds: estimatedDurationSeconds), () {
      if (_state == VoiceState.speaking) {
        debugPrint('TTS Safety fallback timer triggered ($estimatedDurationSeconds s)');
        _onTtsCompleted();
      }
    });

    try {
      await _tts.stop();
      await _tts.speak(text);
      // Ketika awaitSpeakCompletion(true) aktif, baris ini selesai setelah audio native selesai
      if (_state == VoiceState.speaking) {
        _onTtsCompleted();
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _onTtsCompleted();
    }
  }

  void _onTtsCompleted() {
    _ttsFallbackTimer?.cancel();
    if (_state != VoiceState.speaking && _state != VoiceState.idle) return;

    _state = VoiceState.idle;
    _statusMessage = 'Mendengarkan... Silakan berbicara';
    notifyListeners();

    if (_shouldListenAfterTts && !AudioService().isPlaying) {
      _isWaitingForUserSpeech = true; // Tandai bahwa mic harus terus menyala menunggu user bicara
      // Jeda 250ms agar audio speaker hening sebelum mic menyala
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!AudioService().isPlaying && !_isProcessingCommand && _state != VoiceState.speaking) {
          startListening();
        }
      });
    }
  }

  /// Menjadwalkan pengaktifan mikrofon kembali secara aman (mencegah error_busy & error_client)
  void _scheduleRelisten({Duration delay = const Duration(milliseconds: 700)}) {
    _relistenTimer?.cancel();
    if (!_isWaitingForUserSpeech ||
        _state == VoiceState.speaking ||
        AudioService().isPlaying ||
        _isProcessingCommand) {
      return;
    }

    _relistenTimer = Timer(delay, () async {
      if (_isWaitingForUserSpeech &&
          _state != VoiceState.speaking &&
          !AudioService().isPlaying &&
          !_isProcessingCommand) {
        await startListening();
      }
    });
  }

  /// Membuka Mikrofon secara otomatis dan persisten sampai user berbicara
  Future<void> startListening() async {
    _speechDebounceTimer?.cancel();
    _relistenTimer?.cancel();

    // Cegah tabrakan reentrancy pemanggilan listen ganda
    if (_isStartingSpeech) return;
    _isStartingSpeech = true;

    // Jangan menyalakan mic jika audio berita sedang aktif diputar atau TTS sedang berbicara
    if (AudioService().isPlaying || _state == VoiceState.speaking) {
      _isStartingSpeech = false;
      return;
    }

    if (!_speechEnabled) {
      _speechEnabled = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
    }

    if (!_speechEnabled) {
      _state = VoiceState.error;
      _statusMessage = 'Izin mikrofon belum aktif';
      _isStartingSpeech = false;
      notifyListeners();
      return;
    }

    // Pastikan TTS berhenti
    await _tts.stop();

    // Jika mic saat ini sedang aktif atau status transisi, cancel secara bersih terlebih dahulu
    if (_speech.isListening) {
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isProcessingCommand = false;
    _isWaitingForUserSpeech = true;
    _state = VoiceState.listening;
    _statusMessage = 'Mendengarkan... Silakan berbicara';
    notifyListeners();

    try {
      final listenOptions = stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(seconds: 30),
      );

      // ignore: deprecated_member_use
      await _speech.listen(
        onResult: _onSpeechResult,
        // ignore: deprecated_member_use
        localeId: _localeId,
        listenOptions: listenOptions,
      );
    } catch (e) {
      _state = VoiceState.idle;
      _statusMessage = 'Mikrofon siap. Silakan bicara.';
      notifyListeners();
      // Re-schedule jika terjadi kegagalan sesaat
      _scheduleRelisten(delay: const Duration(milliseconds: 1200));
    } finally {
      _isStartingSpeech = false;
    }
  }

  /// Hentikan mendengarkan
  Future<void> stopListening() async {
    _isWaitingForUserSpeech = false;
    _speechDebounceTimer?.cancel();
    _relistenTimer?.cancel();
    await _speech.stop();
    _state = VoiceState.idle;
    _statusMessage = 'Mikrofon nonaktif';
    notifyListeners();
  }

  /// Cut Audio Langsung & Mulai Mendengarkan (Fitur Interupsi / Barge-in)
  /// Ketika audio sementara dijalankan dan user ingin berbicara, audio langsung di-cut!
  Future<void> cutAudioAndListen() async {
    _ttsFallbackTimer?.cancel();
    _speechDebounceTimer?.cancel();
    _relistenTimer?.cancel();
    _isProcessingCommand = false;
    _lastSpokenWords = '';

    // 1. Cut seketika suara TTS
    await _tts.stop();

    // 2. Cut seketika suara Audio Player berita
    if (AudioService().isPlaying) {
      await AudioService().pause();
    }

    _state = VoiceState.idle;
    _statusMessage = 'Audio dihentikan. Silakan berbicara...';
    notifyListeners();

    // 3. Beri jeda kecil agar audio stream Android bersih sebelum membuka mic
    _isWaitingForUserSpeech = true;
    await Future.delayed(const Duration(milliseconds: 200));
    await startListening();
  }

  /// Alias interupsi pengguna
  Future<void> userInterruptedToSpeak() => cutAudioAndListen();

  void _onSpeechStatus(String status) {
    if (status == 'listening') {
      _state = VoiceState.listening;
      _statusMessage = 'Mendengarkan... Silakan berbicara';
      notifyListeners();
    } else if (status == 'notListening' || status == 'done') {
      if (_state == VoiceState.listening) {
        _state = VoiceState.idle;
        notifyListeners();
      }
      // Jadwalkan pengaktifan ulang secara aman tanpa spamming native engine
      _scheduleRelisten(delay: const Duration(milliseconds: 800));
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('STT Error: ${error.errorMsg}');
    final msg = error.errorMsg.toLowerCase();

    // Jika terjadi error_busy atau error_client, JANGAN panggil listen secara langsung!
    // Berikan jeda waktu pendinginan agar native SpeechRecognizer Android stabil kembali
    if (msg.contains('busy') || msg.contains('client')) {
      _relistenTimer?.cancel();
      _isStartingSpeech = false;
      _state = VoiceState.idle;
      _statusMessage = 'Menyiapkan mikrofon...';
      notifyListeners();

      _scheduleRelisten(delay: const Duration(milliseconds: 1500));
      return;
    }

    // Untuk error jeda/no-match biasa, jadwalkan relisten dengan jeda aman
    _scheduleRelisten(delay: const Duration(milliseconds: 1000));
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // --- BUG FIX: CEGAH SISA REKAMAN MEMOTONG ASISTEN ---
    // Jika sistem sedang sibuk mengambil data atau menyusun kalimat, 
    // abaikan sisa suara dari mikrofon yang terlambat masuk.
    if (_isProcessingCommand) return;

    // JIKA USER MULAI BERBICARA KETIKA AUDIO SEDANG BERJALAN -> LANGSUNG CUT AUDIO!
    if (_state == VoiceState.speaking || AudioService().isPlaying) {
      _tts.stop();
      if (AudioService().isPlaying) {
        AudioService().stop();
      }
    }

    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;

    _lastSpokenWords = words;
    _statusMessage = 'Mendengar: "$words"';
    notifyListeners();

    _speechDebounceTimer?.cancel();

    if (result.finalResult) {
      _isWaitingForUserSpeech = false; // User sudah selesai bicara
      _processSpokenCommand(words);
    } else {
      // Debounce untuk kata parsial yang sudah lengkap
      _speechDebounceTimer = Timer(const Duration(milliseconds: 950), () {
        if (!_isProcessingCommand && _state == VoiceState.listening) {
          _isWaitingForUserSpeech = false;
          _processSpokenCommand(words);
        }
      });
    }
  }

  /// Memproses perintah suara pengguna
  Future<void> _processSpokenCommand(String spokenText) async {
    if (_isProcessingCommand) return;
    _isProcessingCommand = true;
    _speechDebounceTimer?.cancel();

    final rawText = spokenText.trim();
    if (rawText.isEmpty) {
      _isProcessingCommand = false;
      return;
    }

    await _speech.stop();
    _state = VoiceState.processing;
    _statusMessage = 'Memproses: "$rawText"...';
    notifyListeners();

    final lower = rawText.toLowerCase();

    // 1. Cek Perintah Putar Audio Dokumen Aktif
    if (lower == 'putar' || lower == 'play' || lower == 'dengarkan') {
      await _handlePlayCommand();
      _isProcessingCommand = false;
      return;
    }

    // 2. Cek Perintah Jeda Audio
    if (lower.contains('jeda') || lower.contains('pause') || lower.contains('tahan')) {
      await AudioService().pause();
      _isProcessingCommand = false;
      await speak('Audio dijeda. Katakan Lanjut untuk melanjutkan, atau sebutkan indikator lain.');
      return;
    }

    // 3. Cek Perintah Lanjut Audio
    if (lower.contains('lanjut') || lower.contains('resume')) {
      await AudioService().resume();
      _state = VoiceState.idle;
      _statusMessage = 'Memutar audio...';
      _isProcessingCommand = false;
      notifyListeners();
      return;
    }

    // 4. Cek Perintah Stop Audio
    if (lower.contains('stop') || lower.contains('matikan') || lower.contains('hentikan')) {
      await AudioService().stop();
      _isProcessingCommand = false;
      await speak('Audio dihentikan. Silakan sebutkan pilihan berikutnya.');
      return;
    }

    // 5. Cek Perintah Ulangi / Panduan
    if (lower.contains('ulang') || lower.contains('bantuan') || lower.contains('daftar indikator') || lower.contains('menu')) {
      _isProcessingCommand = false;
      await startWelcomeFlow();
      return;
    }

    // 6. Cek Perintah Kembali / Beranda
    if (lower.contains('kembali') || lower.contains('beranda') || lower.contains('awal')) {
      _selectedIndicator = null;
      _matchedDocuments = [];
      _activeDocument = null;
      if (onNavigateTab != null) onNavigateTab!(0);
      _isProcessingCommand = false;
      await speak('Kembali ke beranda. Silakan sebutkan nomor atau nama indikator statistik.');
      return;
    }

    // 7. JIKA SEDANG DI DALAM INDIKATOR: CEK APAKAH USER MEMILIH FILE (BERDASARKAN NOMOR ATAU JUDUL)
    if (_matchedDocuments.isNotEmpty) {
      final selectedDoc = _matchDocumentInList(lower, _matchedDocuments);
      if (selectedDoc != null) {
        await _playSelectedDocument(selectedDoc);
        _isProcessingCommand = false;
        return;
      }
    }

    // 8. CEK PEMILIHAN INDIKATOR: BISA DENGAN NAMA LANGSUNG ATAU DENGAN NOMOR (1 - 12)
    final matchedIndicator = _matchIndicator(lower);
    if (matchedIndicator != null) {
      await selectIndicator(matchedIndicator, spokenWord: rawText);
      _isProcessingCommand = false;
      return;
    }

    // 9. Jika belum cocok, cari secara umum berdasarkan kata kunci
    await _handleGeneralSearch(rawText);
    _isProcessingCommand = false;
  }

  /// Pencocokan cerdas 12 indikator statistik:
  /// BISA DENGAN NAMA LANGSUNG ATAU DENGAN NOMOR (1 s.d 12)
  IndicatorModel? _matchIndicator(String query) {
    final indicators = ApiService.defaultIndicators;
    final lower = query.toLowerCase();

    // A. Cek Berdasarkan Nama Indikator Langsung
    if (lower.contains('pertumbuhan ekonomi') || lower.contains('ekonomi') || lower.contains('pdrb')) {
      return indicators.firstWhere((i) => i.id == 1);
    }
    if (lower.contains('inflasi') || lower.contains('ihk') || lower.contains('indeks harga')) {
      return indicators.firstWhere((i) => i.id == 2);
    }
    if (lower.contains('nilai tukar petani') || lower.contains('ntp') || lower.contains('tukar petani')) {
      return indicators.firstWhere((i) => i.id == 3);
    }
    if (lower.contains('ekspor') || lower.contains('impor') || lower.contains('perdagangan luar negeri')) {
      return indicators.firstWhere((i) => i.id == 4);
    }
    if (lower.contains('transportasi') || lower.contains('angkutan') || lower.contains('penerbangan') || lower.contains('pelabuhan')) {
      return indicators.firstWhere((i) => i.id == 5);
    }
    if (lower.contains('pariwisata') || lower.contains('wisata') || lower.contains('hotel') || lower.contains('turis')) {
      return indicators.firstWhere((i) => i.id == 6);
    }
    if (lower.contains('pembangunan manusia') || lower.contains('ipm') || lower.contains('indeks pembangunan')) {
      return indicators.firstWhere((i) => i.id == 7);
    }
    if (lower.contains('pertanian') || lower.contains('petani') || lower.contains('kelapa') || lower.contains('cengkeh') || lower.contains('perkebunan')) {
      return indicators.firstWhere((i) => i.id == 8);
    }
    if (lower.contains('ketenagakerjaan') || lower.contains('tenaga kerja') || lower.contains('pengangguran') || lower.contains('tpt') || lower.contains('angkatan kerja')) {
      return indicators.firstWhere((i) => i.id == 9);
    }
    if (lower.contains('kemiskinan') || lower.contains('miskin') || lower.contains('garis kemiskinan')) {
      return indicators.firstWhere((i) => i.id == 10);
    }
    if (lower.contains('industri') || lower.contains('manufaktur') || lower.contains('pabrik')) {
      return indicators.firstWhere((i) => i.id == 11);
    }
    if (lower.contains('kependudukan') || lower.contains('penduduk') || lower.contains('demografi') || lower.contains('sensus')) {
      return indicators.firstWhere((i) => i.id == 12);
    }

    // B. Cek Berdasarkan Nomor Indikator (1 s.d 12)
    // Jika user mengatakan "1", "satu", "nomor 1", "indikator 1", dll.
    // Jika sedang di dalam indikator dan dokumen ada, nomor file diprioritaskan di atas.
    // Jika tidak cocok dengan file, atau sedang di beranda, maka nomor diinterpretasikan sebagai indikator.
    final num = _parseNumber(lower);
    if (num != null && num >= 1 && num <= indicators.length) {
      return indicators[num - 1];
    }

    return null;
  }

  /// Mencocokkan file/dokumen di dalam indikator berdasarkan NOMOR FILE atau JUDUL FILE
  DocumentModel? _matchDocumentInList(String query, List<DocumentModel> docs) {
    if (docs.isEmpty) return null;
    final lower = query.toLowerCase();

    // 1. Cek Berdasarkan Nomor File (misal: "file 1", "file satu", "nomor 1", "nomor satu", "1", "satu")
    final num = _parseNumber(lower);
    if (num != null && num >= 1 && num <= docs.length) {
      // Jika user eksplisit menyebut "file" atau "nomor" atau angka tunggal
      if (lower.contains('file') || lower.contains('nomor') || lower.trim() == '$num' || _isPureNumberWord(lower)) {
        return docs[num - 1];
      }
      // Jika di dalam halaman indikator, nomor langsung merujuk ke file
      return docs[num - 1];
    }

    // 2. Cek Berdasarkan Judul File (pencocokan kata dalam judul)
    final clean = lower
        .replaceAll(RegExp(r'\b(file|nomor|putar|play|baca|dengarkan|buka|ke)\b'), '')
        .trim();

    if (clean.length >= 3) {
      for (final doc in docs) {
        if (doc.title.toLowerCase().contains(clean)) {
          return doc;
        }
      }

      // Pencocokan per kata (token match)
      final tokens = clean.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
      if (tokens.isNotEmpty) {
        DocumentModel? bestDoc;
        int maxHits = 0;
        for (final doc in docs) {
          final titleLower = doc.title.toLowerCase();
          int hits = 0;
          for (final token in tokens) {
            if (titleLower.contains(token)) hits++;
          }
          if (hits > maxHits) {
            maxHits = hits;
            bestDoc = doc;
          }
        }
        if (maxHits >= 1 && bestDoc != null) {
          return bestDoc;
        }
      }
    }

    return null;
  }

  bool _isPureNumberWord(String text) {
    final t = text.trim();
    const numbers = [
      'satu', 'dua', 'tiga', 'empat', 'lima', 'enam',
      'tujuh', 'delapan', 'sembilan', 'sepuluh', 'sebelas', 'dua belas'
    ];
    return numbers.contains(t);
  }

  /// Parser angka / bilangan bahasa Indonesia
  int? _parseNumber(String text) {
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ').trim();

    // Cek angka numerik (1, 2, 3...)
    final words = clean.split(RegExp(r'\s+'));
    for (final w in words) {
      final n = int.tryParse(w);
      if (n != null) return n;
    }

    // Cek kata bilangan gabungan
    if (clean.contains('dua belas') || clean.contains('keduabelas') || clean.contains('12')) return 12;
    if (clean.contains('sebelas') || clean.contains('kesebelas') || clean.contains('11')) return 11;
    if (clean.contains('sepuluh') || clean.contains('kesepuluh') || clean.contains('10')) return 10;
    if (clean.contains('sembilan') || clean.contains('kesembilan') || clean.contains('9')) return 9;
    if (clean.contains('delapan') || clean.contains('kedelapan') || clean.contains('8')) return 8;
    if (clean.contains('tujuh') || clean.contains('ketujuh') || clean.contains('7')) return 7;
    if (clean.contains('enam') || clean.contains('keenam') || clean.contains('6')) return 6;
    if (clean.contains('lima') || clean.contains('kelima') || clean.contains('5')) return 5;
    if (clean.contains('empat') || clean.contains('keempat') || clean.contains('4')) return 4;
    if (clean.contains('tiga') || clean.contains('ketiga') || clean.contains('3')) return 3;
    if (clean.contains('dua') || clean.contains('kedua') || clean.contains('2')) return 2;
    if (clean.contains('satu') || clean.contains('pertama') || clean.contains('kesatu') || clean.contains('1')) return 1;

    return null;
  }

  /// Menangani aksi saat indikator statistik terpilih
  /// MEMBACAKAN DAFTAR FILE SECARA RINGKAS
  Future<void> selectIndicator(IndicatorModel indicator, {String? spokenWord}) async {
    _lastSpokenWords = spokenWord ?? indicator.name;
    _selectedIndicator = indicator;
    _statusMessage = 'Mencari dokumen ${indicator.name}...';
    notifyListeners();

    // 1. TUNGGU PENCARIAN SELESAI
    final docs = await ApiService().searchDocuments(indicatorId: indicator.id);

    // 2. MATIKAN MIC & TTS SEMENTARA AGAR BERSIH
    _isWaitingForUserSpeech = false;
    _shouldListenAfterTts = false;
    _relistenTimer?.cancel();
    await _speech.stop();
    await _tts.stop();

    _matchedDocuments = docs;
    _activeDocument = docs.isNotEmpty ? docs.first : null;

    _statusMessage = 'Menampilkan indikator: ${indicator.name}';
    notifyListeners();

    if (onIndicatorSelected != null) {
      onIndicatorSelected!(indicator, docs);
    }

    final docCount = docs.length;
    final buffer = StringBuffer();
    
    // MENGGUNAKAN KOMA (,) BUKAN TITIK (.) AGAR ANDROID TTS TIDAK BERHENTI DINI
    buffer.write('Indikator ${indicator.name}, ');

    if (docCount == 0) {
      buffer.write('Belum ada file dokumen, silakan sebutkan indikator lain.');
    } else {
      buffer.write('Terdapat $docCount file, ');
      
      // Bacakan maksimal 5 file teratas agar pengguna tidak bosan menunggu
      final maxToRead = docCount > 5 ? 5 : docCount;
      for (int i = 0; i < maxToRead; i++) {
        buffer.write('File ${i + 1}, ${docs[i].title}, ');
      }
      buffer.write('Silakan sebutkan nomor file atau judul file untuk memutar.');
    }

    // 3. MULAI BACA
    await speak(buffer.toString(), listenAfter: true);
  }

  /// Memutar file dokumen yang dipilih user (berdasarkan nomor atau judul)
  Future<void> _playSelectedDocument(DocumentModel doc) async {
    _activeDocument = doc;

    if (!doc.hasAudio) {
      await speak('File audio untuk "${doc.title}" belum tersedia. Silakan sebutkan nomor file yang lain.', listenAfter: true);
      return;
    }

    // Matikan TTS & mic seketika agar tidak bertabrakan dengan audio berita
    _isWaitingForUserSpeech = false;
    _shouldListenAfterTts = false;
    await _tts.stop();
    await _speech.stop();

    _state = VoiceState.idle;
    _statusMessage = 'Memutar audio: ${doc.title}';
    notifyListeners();

    await AudioService().playDocument(doc);
    if (onPlayDocument != null) {
      onPlayDocument!(doc);
    }
  }

  /// Menangani perintah putar audio dokumen aktif
  Future<void> _handlePlayCommand() async {
    final doc = _activeDocument;
    if (doc == null) {
      await speak('Belum ada file yang dipilih. Silakan sebutkan nomor file atau nama indikator.', listenAfter: true);
      return;
    }
    await _playSelectedDocument(doc);
  }

  /// Menangani pencarian umum jika kata yang diucapkan bukan indikator atau file
  Future<void> _handleGeneralSearch(String query) async {
    final docs = await ApiService().searchDocuments(query: query);

    if (docs.isNotEmpty) {
      _matchedDocuments = docs;
      _activeDocument = docs.first;
      _statusMessage = 'Ditemukan: "${docs.first.title}"';
      notifyListeners();

      final buffer = StringBuffer();
      buffer.write('Ditemukan ${docs.length} file. ');
      final maxToRead = docs.length > 5 ? 5 : docs.length;
      for (int i = 0; i < maxToRead; i++) {
        buffer.write('File ${i + 1}, ${docs[i].title}. ');
      }
      buffer.write('Sebutkan nomor atau judul file untuk memutar.');

      await speak(buffer.toString(), listenAfter: true);
    } else {
      const notFoundSpeech = 'Data belum ditemukan. Silakan sebutkan nomor atau nama indikator statistik.';
      await speak(notFoundSpeech, listenAfter: true);
    }
  }

  @override
  void dispose() {
    _isWaitingForUserSpeech = false;
    _ttsFallbackTimer?.cancel();
    _speechDebounceTimer?.cancel();
    _relistenTimer?.cancel();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
