import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// WisgoTap - Pengganti GestureDetector Baku (desain.md Section 05.5)
/// Standar: MouseRegion Click Cursor, Touch Target Minimum >= 44x44, Semantics Aksesibilitas
class WisgoTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double minTouchTarget;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;

  const WisgoTap({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.minTouchTarget = 44.0,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.rSm;
    final bool isEnabled = onTap != null;

    Widget tapBody = Material(
      color: Colors.transparent,
      borderRadius: effectiveRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        splashColor: splashColor ?? AppColors.sage.withValues(alpha: 0.3),
        highlightColor: highlightColor ?? AppColors.creamSubtle.withValues(alpha: 0.2),
        child: child,
      ),
    );

    if (minTouchTarget > 0) {
      tapBody = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minTouchTarget,
          minHeight: minTouchTarget,
        ),
        child: Center(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: tapBody,
        ),
      );
    }

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: semanticLabel,
        child: tapBody,
      ),
    );
  }
}
