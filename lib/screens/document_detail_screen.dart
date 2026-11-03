import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final isPub = document.isPublication;
    final badgeBg = isPub ? AppTheme.primary100 : AppTheme.green100;
    final badgeText = isPub ? AppTheme.primary800 : AppTheme.green800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Dokumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tautan dokumen "${document.title}" disalin.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image (Centered with subtle shadow)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 200,
                  height: 266, // 3:4 ratio
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: document.coverUrl != null && document.coverUrl!.isNotEmpty
                      ? Image.network(
                          document.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => _buildFallbackCover(),
                        )
                      : _buildFallbackCover(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Badges Row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPub ? Icons.menu_book_rounded : Icons.newspaper_rounded,
                        size: 14,
                        color: badgeText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPub ? 'Publikasi' : 'BRS',
                        style: TextStyle(
                          color: badgeText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Year Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.gray700),
                      const SizedBox(width: 4),
                      Text(
                        '${document.year}',
                        style: const TextStyle(
                          color: AppTheme.gray800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Audio Status Badge
                if (document.hasAudio)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.green100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headphones_rounded, size: 14, color: AppTheme.green800),
                        SizedBox(width: 4),
                        Text(
                          'Audio Tersedia',
                          style: TextStyle(
                            color: AppTheme.green800,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Document Title
            Text(
              document.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Meta Info List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                children: [
                  if (document.indicator != null)
                    _buildMetaRow(
                      Icons.local_offer_outlined,
                      'Indikator',
                      document.indicator!.name,
                    ),
                  if (document.createdAt != null)
                    _buildMetaRow(
                      Icons.access_time_rounded,
                      'Tanggal Terbit',
                      document.createdAt!,
                    ),
                  _buildMetaRow(
                    Icons.volume_up_outlined,
                    'Durasi Audio',
                    document.audioDurationFormatted,
                  ),
                  _buildMetaRow(
                    Icons.file_download_outlined,
                    'Jumlah Unduhan',
                    '${document.downloadCount} kali',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons (Putar Audio, Unduh MP3, Unduh FLAC)
            if (document.hasAudio) ...[
              ElevatedButton.icon(
                onPressed: () {
                  AudioService().playDocument(document);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Memutar audio: ${document.title}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Putar Audio Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mengunduh audio format MP3...')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Unduh MP3'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary600,
                        side: const BorderSide(color: AppTheme.primary600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mengunduh audio kualitas tinggi FLAC...')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Unduh FLAC'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.green700,
                        side: const BorderSide(color: AppTheme.green600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: AppTheme.gray500),
                    SizedBox(width: 10),
                    Text(
                      'Audio dokumen sedang diproses...',
                      style: TextStyle(color: AppTheme.gray600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Deskripsi Section
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              document.description ?? 'Tidak ada deskripsi tersedia untuk dokumen ini.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.gray700,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Informasi Audio Section (matches right-sidebar in web app)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Audio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAudioInfoRow('Durasi:', document.audioDurationFormatted),
                  _buildAudioInfoRow('Format:', 'MP3 / FLAC'),
                  _buildAudioInfoRow('Ukuran:', document.fileSizeFormatted ?? '2.4 MB'),
                ],
              ),
            ),

            // Ringkasan Ekstraksi Teks jika ada
            if (document.extractedText != null && document.extractedText!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Ringkasan Teks Dokumen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: Text(
                  document.extractedText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray700,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppTheme.gray200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              document.isPublication ? Icons.menu_book_rounded : Icons.newspaper_rounded,
              size: 54,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: 8),
            const Text(
              'BPS SULAWESI UTARA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.gray400),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray600)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
        ],
      ),
    );
  }
}
