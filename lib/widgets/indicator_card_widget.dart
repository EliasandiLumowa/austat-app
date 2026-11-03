import 'package:flutter/material.dart';
import '../models/indicator_model.dart';
import '../theme/app_theme.dart';

class IndicatorCardWidget extends StatelessWidget {
  final IndicatorModel indicator;
  final VoidCallback? onTap;
  final int? indexNumber;
  final bool isSelected;

  const IndicatorCardWidget({
    super.key,
    required this.indicator,
    this.onTap,
    this.indexNumber,
    this.isSelected = false,
  });

  IconData _getIconData(String? iconStr, String slug) {
    if (slug.contains('ekonomi')) return Icons.trending_up_rounded;
    if (slug.contains('inflasi')) return Icons.percent_rounded;
    if (slug.contains('ntp') || slug.contains('petani')) return Icons.grass_rounded;
    if (slug.contains('ekspor') || slug.contains('impor')) return Icons.directions_boat_rounded;
    if (slug.contains('transportasi')) return Icons.local_shipping_rounded;
    if (slug.contains('pariwisata')) return Icons.photo_camera_rounded;
    if (slug.contains('manusia') || slug.contains('ipm')) return Icons.groups_rounded;
    if (slug.contains('pertanian')) return Icons.eco_rounded;
    if (slug.contains('ketenagakerjaan')) return Icons.work_outline_rounded;
    if (slug.contains('kemiskinan')) return Icons.volunteer_activism_rounded;
    if (slug.contains('industri')) return Icons.factory_outlined;
    if (slug.contains('kependudukan')) return Icons.people_outline_rounded;
    return Icons.bar_chart_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppTheme.primary600 : AppTheme.gray200,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.primary600.withAlpha(35)
                : Colors.black.withAlpha(8),
            blurRadius: isSelected ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Badge Nomor Urut (1 - 12)
              if (indexNumber != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary600 : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$indexNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.gray600,
                      ),
                    ),
                  ),
                ),

              // Status Audio Aktif
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Aktif',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular icon
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary100 : AppTheme.primary50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconData(indicator.icon, indicator.slug),
                        color: AppTheme.primary600,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Indicator Name
                    Text(
                      indicator.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppTheme.primary800 : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Document Count
                    Text(
                      '${indicator.activeDocumentsCount} dokumen',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
