import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class DocumentCardWidget extends StatelessWidget {
  final DocumentModel document;
  final int index;
  final VoidCallback? onTap;

  const DocumentCardWidget({
    super.key,
    required this.document,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPub = document.isPublication;
    final badgeBg = isPub ? AppTheme.primary100 : AppTheme.green100;
    final badgeText = isPub ? AppTheme.primary800 : AppTheme.green800;
    final actionBtnColor = isPub ? AppTheme.primary600 : AppTheme.green600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3:4 Aspect Ratio Cover with Badges
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover Image
                document.coverUrl != null && document.coverUrl!.isNotEmpty
                    ? Image.network(
                        document.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => _buildFallbackCover(),
                      )
                    : _buildFallbackCover(),

                // Play Overlay Center Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (document.hasAudio) {
                        AudioService().playDocument(document);
                      }
                    },
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primary600.withAlpha(230),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          document.hasAudio ? Icons.play_arrow_rounded : Icons.access_time_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top-Left: Type Badge (Publikasi / BRS)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
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
                          size: 13,
                          color: badgeText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPub ? 'Publikasi' : 'BRS',
                          style: TextStyle(
                            color: badgeText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-Right: Number badge (like web voice navigation index)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                InkWell(
                  onTap: onTap,
                  child: Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Year
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.gray400),
                    const SizedBox(width: 5),
                    Text(
                      '${document.year}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Indicator
                if (document.indicator != null)
                  Row(
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 13, color: AppTheme.gray400),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          document.indicator!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
                        ),
                      ),
                    ],
                  ),

                // Description
                if (document.description != null && document.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    document.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.gray500,
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    // Play Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (document.hasAudio) {
                            AudioService().playDocument(document);
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Putar', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionBtnColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Detail Eye Button
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        side: const BorderSide(color: AppTheme.gray300),
                        foregroundColor: AppTheme.gray700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Icon(Icons.visibility_outlined, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
              size: 48,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: 8),
            Text(
              'BPS SULAWESI UTARA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
