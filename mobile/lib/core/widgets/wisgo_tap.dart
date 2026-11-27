import 'package:flutter/material.dart';

/// WisgoTap - Pembungkus Interaksi Sentuh & Kursor Baku (desain.md 05.5)
/// Memastikan kursor desktop/web berbentuk pointer (click) dan area sentuh minimal 44x44 px.
class WisgoTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final double minTouchTarget;
  final BorderRadius? borderRadius;

  const WisgoTap({
    super.key,
    required this.child,
    required this.onTap,
    this.tooltip,
    this.minTouchTarget = 44.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTouchTarget,
            minHeight: minTouchTarget,
          ),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: child,
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      content = Tooltip(
        message: tooltip!,
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: tooltip,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: content,
      ),
    );
  }
}
