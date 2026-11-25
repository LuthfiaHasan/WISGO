import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// WisgoCard - Komponen Kartu Baku WISGO (desain.md Section 05.3)
/// Latar: AppColors.bgCard, Radius: 20 px, Border: 1 px warmBorder, Bayangan: Forest Ink Soft
class WisgoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? borderSide;
  final BorderRadius? borderRadius;
  final bool hasShadow;

  const WisgoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.backgroundColor,
    this.borderSide,
    this.borderRadius,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.rLg;
    final effectiveBorder = borderSide ?? const BorderSide(color: AppColors.warmBorder, width: 1);

    Widget cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bgCard,
        borderRadius: effectiveRadius,
        border: Border.fromBorderSide(effectiveBorder),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: effectiveRadius,
            child: InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius,
              splashColor: AppColors.sage.withValues(alpha: 0.3),
              highlightColor: AppColors.creamSubtle.withValues(alpha: 0.2),
              child: cardBody,
            ),
          ),
        ),
      );
    }

    return cardBody;
  }
}
