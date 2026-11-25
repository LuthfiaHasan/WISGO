import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// CrowdBadge - Penanda Keramaian Sesuai Token Semantik (desain.md Section 07.2)
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
        fg = AppColors.warningDark;
        text = 'Sedang';
        break;
      case CrowdLevel.ramai:
        bg = AppColors.coralTint;
        fg = AppColors.terracotta;
        text = 'Ramai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rXs,
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
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
