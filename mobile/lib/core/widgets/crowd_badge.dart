import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// CrowdBadge - Penanda Keramaian (Sepi, Sedang, Ramai) (desain.md 07.2)
enum CrowdLevel { sepi, sedang, ramai }

class CrowdBadge extends StatelessWidget {
  final CrowdLevel level;

  const CrowdBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (level) {
      case CrowdLevel.sepi:
        bg = AppColors.successBg;
        fg = AppColors.success;
        text = 'Sepi';
        break;
      case CrowdLevel.sedang:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        text = 'Sedang';
        break;
      case CrowdLevel.ramai:
        bg = AppColors.coralTint;
        fg = AppColors.terracotta;
        text = 'Ramai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
