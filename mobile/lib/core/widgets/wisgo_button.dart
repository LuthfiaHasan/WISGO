import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum WisgoButtonVariant {
  primary,
  secondary,
  danger,
  outline,
}

/// WisgoButton - Komponen Tombol Standar Baku (desain.md Section 05.1)
/// Tinggi Baku: 52 px (CTA Utama) & 42 px (Komposisi Modal/Kartu)
/// Fitur: Loading state built-in, disabled state, touch target >= 44x44, mouse click cursor
class WisgoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final WisgoButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final BorderRadius? borderRadius;

  const WisgoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = WisgoButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
    this.borderRadius,
  });

  /// Factory untuk Tombol Compact 42 px
  factory WisgoButton.compact({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    WisgoButtonVariant variant = WisgoButtonVariant.primary,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = true,
  }) {
    return WisgoButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: variant,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      height: 42.0,
      borderRadius: AppRadius.rSm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case WisgoButtonVariant.primary:
        bg = isDisabled ? AppColors.disabledBg : AppColors.forest;
        fg = isDisabled ? AppColors.disabledText : AppColors.cream;
        break;
      case WisgoButtonVariant.secondary:
        bg = isDisabled ? AppColors.disabledBg : AppColors.sage;
        fg = isDisabled ? AppColors.disabledText : AppColors.forest;
        break;
      case WisgoButtonVariant.danger:
        bg = isDisabled ? AppColors.disabledBg : AppColors.danger;
        fg = isDisabled ? AppColors.disabledText : Colors.white;
        break;
      case WisgoButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDisabled ? AppColors.disabledText : AppColors.forest;
        borderSide = BorderSide(
          color: isDisabled ? AppColors.disabledBg : AppColors.sageBorder,
          width: 1.5,
        );
        break;
    }

    final effectiveRadius = borderRadius ??
        (height >= 50.0 ? AppRadius.rPill : AppRadius.rSm);

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Semantics(
        button: true,
        enabled: !isDisabled,
        label: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 44.0,
            minWidth: 44.0,
          ),
          child: SizedBox(
            height: height,
            width: isFullWidth ? double.infinity : null,
            child: ElevatedButton(
              onPressed: isDisabled ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                elevation: 0,
                shadowColor: Colors.transparent,
                side: borderSide,
                shape: RoundedRectangleBorder(
                  borderRadius: effectiveRadius,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: height >= 50.0 ? 19 : 17, color: fg),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          label,
                          style: (height >= 50.0
                                  ? AppTypography.title
                                  : AppTypography.bodySmall)
                              .copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
