import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/indicator_model.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/voice_assistant_service.dart';
import '../theme/app_theme.dart';
import '../widgets/document_card_widget.dart';
import '../widgets/indicator_card_widget.dart';
import '../widgets/web_footer_widget.dart';
import 'document_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  final Function(Map<String, dynamic> searchParams)? onTriggerSearch;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
    this.onTriggerSearch,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceAssistantService _voice = VoiceAssistantService();
  List<IndicatorModel> _indicators = [];
  List<DocumentModel> _recentDocuments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _voice.addListener(_onVoiceStateChanged);
    _loadData();
  }

  void _onVoiceStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoiceStateChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bundle = await ApiService().getHomeBundle();
    if (!mounted) return;
    setState(() {
      _indicators = (bundle['indicators'] as List<IndicatorModel>?) ?? ApiService.defaultIndicators;
      _recentDocuments = (bundle['recentDocuments'] as List<DocumentModel>?) ?? [];
      _isLoading = false;
    });
  }

  void _openDetail(DocumentModel doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(document: doc),
      ),
    );
  }

  void _onIndicatorTap(IndicatorModel ind) {
    _voice.selectIndicator(ind);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary600),
      );
    }

    final activeIndicator = _voice.selectedIndicator;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary600,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  // --- HERO SECTION WITH VOICE-FIRST PROMPTS ---
                  _buildHeroSection(),
                  const SizedBox(height: 24),

                  // --- SECTION HASIL SUARA (JIKA PENGGUNA MENGUCAPKAN INDIKATOR) ---
                  if (activeIndicator != null) ...[
                    _buildVoiceResultSection(activeIndicator),
                    const SizedBox(height: 28),
                  ],

                  // --- INDIKATOR STATISTIK HEADING ---
                  _buildSectionHeader(
                    title: '12 Indikator Statistik BPS',
                    subtitle: 'Sebutkan salah satu nama atau nomor indikator di bawah ini lewat suara',
                  ),
                  const SizedBox(height: 16),

                  // Indikator Grid (12 Kategori bernomor)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: _indicators.length,
                    itemBuilder: (context, index) {
                      final ind = _indicators[index];
                      final isSelected = activeIndicator?.id == ind.id;
                      return IndicatorCardWidget(
                        indicator: ind,
                        indexNumber: index + 1,
                        isSelected: isSelected,
                        onTap: () => _onIndicatorTap(ind),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // --- DOKUMEN TERBARU ---
                  _buildSectionHeader(
                    title: 'Dokumen Statistik Terkini',
                    subtitle: 'Katakan "Putar" untuk mendengarkan audio dokumen aktif',
                  ),
                  const SizedBox(height: 16),

                  // Recent Documents Grid (2 columns)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.44,
                    ),
                    itemCount: _recentDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = _recentDocuments[index];
                      return DocumentCardWidget(
                        document: doc,
                        index: index,
                        onTap: () => _openDetail(doc),
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // --- FITUR AKSESIBILITAS SECTION ---
                  _buildAccessibilitySection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // --- WEB FOOTER ---
            WebFooterWidget(
              onNavigateTab: widget.onNavigateTab,
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan hasil ketika pengguna mengucapkan nama indikator lewat suara
  Widget _buildVoiceResultSection(IndicatorModel indicator) {
    final docs = _voice.matchedDocuments;
    final lastSpoken = _voice.lastSpokenWords;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Light emerald green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Hasil Suara
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HASIL PERINTAH SUARA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Kategori: ${indicator.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (lastSpoken.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_rounded, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ucapan Anda: "$lastSpoken"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (indicator.description != null && indicator.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              indicator.description!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFBBF7D0), height: 1),
          const SizedBox(height: 12),

          // Ringkasan Dokumen & Aksi Audio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${docs.length} Dokumen Statistik Ditemukan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                ),
              ),
              if (docs.isNotEmpty && docs.first.hasAudio)
                ElevatedButton.icon(
                  onPressed: () {
                    VoiceAssistantService().stopListening();
                    AudioService().playDocument(docs.first);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Putar Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          if (docs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docs.first.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (docs.first.extractedText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            docs.first.extractedText!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.gray600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Blue Volume Icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(60), width: 2),
            ),
            child: const Icon(
              Icons.hearing_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Audio Statistik Sulawesi Utara',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Aplikasi aksesibilitas berbasis interaksi suara penuh untuk penyandang disabilitas penglihatan. '
            'Cukup sebutkan indikator statistik yang Anda inginkan setelah audio berbicara.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFDBEAFE),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Interaksi Cepat (Bicara & Ulangi)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _voice.userInterruptedToSpeak(),
                icon: const Icon(Icons.mic_rounded, size: 20),
                label: const Text('Bicara Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _voice.startWelcomeFlow(),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Ulangi Panduan Suara'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Fitur Aksesibilitas Disabilitas Netra',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildAccessCard(
            icon: Icons.record_voice_over_rounded,
            title: 'Interaksi Suara Otomatis (Voice-Driven)',
            desc: 'Saat aplikasi dibuka, sistem otomatis menyambut dan memandu lewat audio, kemudian langsung mendengarkan suara Anda tanpa perlu menyentuh layar.',
          ),
          const SizedBox(height: 14),

          _buildAccessCard(
            icon: Icons.volume_up_rounded,
            title: 'Pembacaan 12 Indikator Statistik',
            desc: 'Dua belas indikator statistik disampaikan secara audio dan data masing-masing indikator dapat langsung didengarkan melalui suara.',
          ),
          const SizedBox(height: 14),

          _buildAccessCard(
            icon: Icons.mic_rounded,
            title: 'Pengenalan Perintah Bebas',
            desc: 'Katakan nama indikator (seperti "Pertumbuhan Ekonomi", "Inflasi"), atau kendali pemutaran ("Putar", "Jeda", "Ulangi").',
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primary600,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary600.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
