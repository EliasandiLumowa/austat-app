import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/indicator_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/document_card_widget.dart';
import 'document_detail_screen.dart';

class PublicationsScreen extends StatefulWidget {
  final int? initialIndicatorId;
  final int? initialYear;
  final String? initialQuery;

  const PublicationsScreen({
    super.key,
    this.initialIndicatorId,
    this.initialYear,
    this.initialQuery,
  });

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<IndicatorModel> _indicators = [];
  List<DocumentModel> _documents = [];
  List<int> _years = [];

  int? _selectedYear;
  int? _selectedIndicatorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndicatorId = widget.initialIndicatorId;
    _selectedYear = widget.initialYear;
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final indicators = await ApiService().getIndicators();
    final years = await ApiService().getAvailableYearsFromApi();
    _indicators = indicators;
    _years = years;

    await _filterData();
  }

  Future<void> _filterData() async {
    setState(() => _isLoading = true);
    final results = await ApiService().getPublications(
      query: _searchController.text.trim(),
      year: _selectedYear,
      indicatorId: _selectedIndicatorId,
    );
    if (!mounted) return;
    setState(() {
      _documents = results;
      _isLoading = false;
    });
  }

  void _resetFilter() {
    _searchController.clear();
    setState(() {
      _selectedYear = null;
      _selectedIndicatorId = null;
    });
    _filterData();
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
        onRefresh: _filterData,
        color: AppTheme.primary600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Publikasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Publikasi terkini dari BPS Sulawesi Utara dalam format audio yang mudah diakses',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.gray600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Filter Card
              _buildFilterCard(),
              const SizedBox(height: 16),

              // Results Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${_documents.length} Publikasi',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray700,
                    ),
                  ),
                  if (_selectedYear != null ||
                      _selectedIndicatorId != null ||
                      _searchController.text.isNotEmpty)
                    InkWell(
                      onTap: _resetFilter,
                      child: const Text(
                        'Reset Filter',
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

              // Grid or Empty State
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
                            childAspectRatio: 0.52,
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

  Widget _buildFilterCard() {
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
          // Search Input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari judul Publikasi...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.gray400),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterData();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _filterData(),
          ),
          const SizedBox(height: 12),

          // Dropdowns Row
          Row(
            children: [
              // Year Dropdown
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
                    _filterData();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Indicator Dropdown
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
                    _filterData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter Button
          ElevatedButton.icon(
            onPressed: _filterData,
            icon: const Icon(Icons.filter_list_rounded, size: 18),
            label: const Text('Terapkan Filter'),
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
            child: const Icon(Icons.menu_book_rounded, size: 36, color: AppTheme.gray400),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada Publikasi ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba ubah kata kunci atau hapus beberapa filter yang aktif.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.gray500),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _resetFilter,
            child: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }
}
