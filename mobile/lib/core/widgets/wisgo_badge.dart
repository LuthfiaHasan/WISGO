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

/// WisgoBadge - Badge Semantik Baku WISGO (desain.md 05.4)
/// Tinggi pas, padding 8x4 px, radius 8 px, teks caption 11 px w700.
class WisgoBadge extends StatelessWidget {
  final String label;
  final WisgoBadgeVariant variant;
  final Widget? icon;

  const WisgoBadge({
    super.key,
    required this.label,
    this.variant = WisgoBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case WisgoBadgeVariant.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = AppColors.successBorder;
        break;
      case WisgoBadgeVariant.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        border = AppColors.warning.withValues(alpha: 0.25);
        break;
      case WisgoBadgeVariant.info:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        border = AppColors.infoBorder;
        break;
      case WisgoBadgeVariant.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        border = AppColors.danger.withValues(alpha: 0.25);
        break;
      case WisgoBadgeVariant.goldMinang:
        bg = AppColors.goldSoft.withValues(alpha: 0.20);
        fg = AppColors.goldMinang;
        border = AppColors.goldMinang.withValues(alpha: 0.35);
        break;
      case WisgoBadgeVariant.terracotta:
        bg = AppColors.coralTint;
        fg = AppColors.terracotta;
        border = AppColors.terracotta.withValues(alpha: 0.25);
        break;
      case WisgoBadgeVariant.neutral:
        bg = AppColors.sage;
        fg = AppColors.forest;
        border = AppColors.sageBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
