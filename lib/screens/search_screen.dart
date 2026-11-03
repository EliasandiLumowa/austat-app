import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/indicator_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/document_card_widget.dart';
import '../widgets/voice_search_dialog.dart';
import 'document_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final Map<String, dynamic>? initialParams;

  const SearchScreen({super.key, this.initialParams});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<IndicatorModel> _indicators = [];
  List<DocumentModel> _documents = [];
  List<int> _years = [];

  String? _selectedType; // null / 'all', 'publication', 'brs'
  int? _selectedYear;
  int? _selectedIndicatorId;
  String? _voiceSearchBannerText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _applyParams(widget.initialParams);
    _loadInitialData();
  }

  void _applyParams(Map<String, dynamic>? params) {
    if (params == null) return;
    if (params['query'] != null) {
      _queryController.text = params['query'];
    }
    if (params['type'] != null) {
      _selectedType = params['type'];
    }
    if (params['year'] != null) {
      _selectedYear = params['year'];
    }
    if (params['indicatorId'] != null) {
      _selectedIndicatorId = params['indicatorId'];
    }
    if (params['voicePhrase'] != null || params['transcript'] != null) {
      _voiceSearchBannerText = params['voicePhrase'] ?? params['transcript'];
    }
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialParams != oldWidget.initialParams) {
      _applyParams(widget.initialParams);
      _executeSearch();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final indicators = await ApiService().getIndicators();
    final years = await ApiService().getAvailableYearsFromApi();
    _indicators = indicators;
    _years = years;
    await _executeSearch();
  }

  Future<void> _executeSearch() async {
    setState(() => _isLoading = true);
    final results = await ApiService().searchDocuments(
      query: _queryController.text.trim(),
      type: _selectedType,
      year: _selectedYear,
      indicatorId: _selectedIndicatorId,
    );
    if (!mounted) return;
    setState(() {
      _documents = results;
      _isLoading = false;
    });
  }

  void _openVoiceDialog() {
    VoiceSearchDialog.show(
      context,
      onSearchParsed: (parsed) {
        setState(() {
          _voiceSearchBannerText = parsed['query'] ?? 'Perintah suara';
          _applyParams(parsed);
        });
        _executeSearch();
      },
    );
  }

  void _resetSearch() {
    _queryController.clear();
    setState(() {
      _selectedType = null;
      _selectedYear = null;
      _selectedIndicatorId = null;
      _voiceSearchBannerText = null;
    });
    _executeSearch();
  }

  void _openDetail(DocumentModel doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(document: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _executeSearch,
        color: AppTheme.primary600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pencarian Dokumen',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  IconButton(
                    onPressed: _openVoiceDialog,
                    icon: const Icon(Icons.mic_rounded, color: AppTheme.primary600),
                    tooltip: 'Pencarian Suara',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Voice search active notification banner (matches web search.blade.php)
              if (_voiceSearchBannerText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mic_rounded, color: AppTheme.primary600, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pencarian Suara: "$_voiceSearchBannerText"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary800,
                              ),
                            ),
                            const Text(
                              'Hasil pencarian berdasarkan perintah suara Anda',
                              style: TextStyle(fontSize: 11, color: AppTheme.primary600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.primary600),
                        onPressed: () => setState(() => _voiceSearchBannerText = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Search Filter Form
              _buildSearchForm(),
              const SizedBox(height: 16),

              // Results Count Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${_documents.length} Dokumen',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray700,
                    ),
                  ),
                  if (_queryController.text.isNotEmpty ||
                      _selectedType != null ||
                      _selectedYear != null ||
                      _selectedIndicatorId != null)
                    InkWell(
                      onTap: _resetSearch,
                      child: const Text(
                        'Reset Pencarian',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Documents Grid / Empty State
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppTheme.primary600),
                      ),
                    )
                  : _documents.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.44,
                          ),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            return DocumentCardWidget(
                              document: doc,
                              index: index,
                              onTap: () => _openDetail(doc),
                            );
                          },
                        ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Keyword input
          TextField(
            controller: _queryController,
            decoration: InputDecoration(
              hintText: 'Cari judul, deskripsi, tahun, atau indikator...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.gray400),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_queryController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _queryController.clear();
                        _executeSearch();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppTheme.primary600, size: 20),
                    onPressed: _openVoiceDialog,
                  ),
                ],
              ),
            ),
            onSubmitted: (_) => _executeSearch(),
          ),
          const SizedBox(height: 12),

          // Document Type dropdown
          DropdownButtonFormField<String?>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              labelText: 'Jenis Dokumen',
              labelStyle: TextStyle(fontSize: 12),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Semua Jenis', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'publication', child: Text('Publikasi', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'brs', child: Text('BRS (Berita Resmi Statistik)', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              setState(() => _selectedType = val);
              _executeSearch();
            },
          ),
          const SizedBox(height: 10),

          // Year & Indicator row
          Row(
            children: [
              // Year
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    labelText: 'Tahun',
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua', style: TextStyle(fontSize: 13)),
                    ),
                    ..._years.map((y) => DropdownMenuItem<int?>(
                          value: y,
                          child: Text('$y', style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedYear = val);
                    _executeSearch();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Indicator
              Expanded(
                flex: 6,
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedIndicatorId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    labelText: 'Indikator',
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Indikator', style: TextStyle(fontSize: 13)),
                    ),
                    ..._indicators.map((ind) => DropdownMenuItem<int?>(
                          value: ind.id,
                          child: Text(
                            ind.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedIndicatorId = val);
                    _executeSearch();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search action button
          ElevatedButton.icon(
            onPressed: _executeSearch,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Cari Dokumen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary600,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppTheme.gray100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.gray400),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dokumen tidak ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pastikan ejaan kata kunci benar, atau coba ubah pilihan indikator dan tahun.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.gray500),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _resetSearch,
            child: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }
}
