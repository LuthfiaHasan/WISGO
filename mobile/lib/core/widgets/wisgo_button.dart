import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum WisgoButtonVariant {
  primary,
  secondary,
  danger,
  outline,
}

enum WisgoButtonSize {
  large,  // 52 px - CTA Utama
  medium, // 42 px - Aksi Modal / Kartu
}

/// WisgoButton - Komponen Tombol Standar Baku WISGO (desain.md 05.1)
class WisgoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final WisgoButtonVariant variant;
  final WisgoButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  const WisgoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = WisgoButtonVariant.primary,
    this.size = WisgoButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final double height = size == WisgoButtonSize.large ? 52.0 : 42.0;
    final double radius = size == WisgoButtonSize.large ? 14.0 : 12.0;
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case WisgoButtonVariant.primary:
        bg = isEnabled ? AppColors.forest : AppColors.disabledBg;
        fg = isEnabled ? AppColors.cream : AppColors.disabledText;
        break;
      case WisgoButtonVariant.secondary:
        bg = isEnabled ? AppColors.sage : AppColors.disabledBg;
        fg = isEnabled ? AppColors.forest : AppColors.disabledText;
        break;
      case WisgoButtonVariant.danger:
        bg = isEnabled ? AppColors.danger : AppColors.disabledBg;
        fg = isEnabled ? Colors.white : AppColors.disabledText;
        break;
      case WisgoButtonVariant.outline:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.forest : AppColors.disabledText;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.sageBorder : AppColors.disabledBg,
          width: 1.5,
        );
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: size == WisgoButtonSize.large ? 14 : 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: borderSide,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
