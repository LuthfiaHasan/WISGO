import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// PillButton - Tombol Utama CTA 52px sesuai standar desain.md (Section 05.1)
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool isFullWidth;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.forest,
    this.textColor = AppColors.cream,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTypography.title.copyWith(
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox(
          height: 52, // Standar tinggi 52px wajib sesuai desain.md
          width: isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.rPill, // Bentuk Pill sempurna
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            ),
            onPressed: onPressed,
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
