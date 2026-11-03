import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class WebFooterWidget extends StatelessWidget {
  final Function(int index)? onNavigateTab;

  const WebFooterWidget({super.key, this.onNavigateTab});

  Future<void> _openBpsSulut() async {
    final uri = Uri.parse('https://sulut.bps.go.id');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.gray800,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Title
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Audio Statistik',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Layanan audio untuk publikasi dan berita resmi statistik BPS Sulawesi Utara yang mendukung aksesibilitas untuk pengguna dengan gangguan penglihatan.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.gray300,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Tautan Section
          const Text(
            'Tautan Cepat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildFooterLink('Beranda', () => onNavigateTab?.call(0)),
              _buildFooterLink('Publikasi', () => onNavigateTab?.call(1)),
              _buildFooterLink('BRS', () => onNavigateTab?.call(2)),
              _buildFooterLink('Pencarian', () => onNavigateTab?.call(3)),
              _buildFooterLink('BPS Sulut ↗', _openBpsSulut),
            ],
          ),
          const SizedBox(height: 24),

          // Aksesibilitas Checklist
          const Text(
            'Fitur Aksesibilitas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildCheckItem('Text-to-Speech Otomatis'),
          _buildCheckItem('Pencarian Suara Alami'),
          _buildCheckItem('Navigasi Ramah Aksesibilitas'),
          _buildCheckItem('Screen Reader Friendly'),
          _buildCheckItem('Pemutar Audio Interaktif'),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFF374151), height: 1),
          const SizedBox(height: 16),

          // Copyright
          Center(
            child: Text(
              '© ${DateTime.now().year} BPS Provinsi Sulawesi Utara.\nSemua hak dilindungi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.gray400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF93C5FD),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray300,
            ),
          ),
        ],
      ),
    );
  }
}
