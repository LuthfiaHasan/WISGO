import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum WisgoBadgeVariant {
  success,
  warning,
  info,
  danger,
  goldMinang,
  neutral,
  terracotta,
}

/// WisgoBadge - Komponen Badge & Tag Semantik Baku (desain.md Section 05.4)
/// Teks: AppTypography.caption (11 px, w700)
/// Radius: AppRadius.xs (8 px), Padding: 8 px horizontal, 4 px vertical
class WisgoBadge extends StatelessWidget {
  final String label;
  final WisgoBadgeVariant variant;
  final IconData? icon;
  final bool hasDot;

  const WisgoBadge({
    super.key,
    required this.label,
    this.variant = WisgoBadgeVariant.neutral,
    this.icon,
    this.hasDot = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case WisgoBadgeVariant.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        borderSide = const BorderSide(color: AppColors.successBorder, width: 1);
        break;
      case WisgoBadgeVariant.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warningDark;
        borderSide = BorderSide(color: AppColors.warning.withValues(alpha: 0.3), width: 1);
        break;
      case WisgoBadgeVariant.info:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        borderSide = const BorderSide(color: AppColors.infoBorder, width: 1);
        break;
      case WisgoBadgeVariant.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        borderSide = BorderSide(color: AppColors.danger.withValues(alpha: 0.3), width: 1);
        break;
      case WisgoBadgeVariant.goldMinang:
        bg = AppColors.goldSoft.withValues(alpha: 0.2);
        fg = AppColors.goldMinang;
        borderSide = BorderSide(color: AppColors.goldMinang.withValues(alpha: 0.4), width: 1);
        break;
      case WisgoBadgeVariant.terracotta:
        bg = AppColors.coralTint;
        fg = AppColors.terracotta;
        borderSide = BorderSide(color: AppColors.terracotta.withValues(alpha: 0.25), width: 1);
        break;
      case WisgoBadgeVariant.neutral:
        bg = AppColors.creamSubtle;
        fg = AppColors.muted;
        borderSide = const BorderSide(color: AppColors.warmBorder, width: 1);
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
        border: Border.fromBorderSide(borderSide),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 1),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
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
