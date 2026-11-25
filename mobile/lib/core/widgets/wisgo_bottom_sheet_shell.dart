import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// WisgoBottomSheetShell - Shell Pembungkus Baku Modal Bottom Sheet (desain.md 05.2)
/// Radius atas seragam 28 px, drag handle 40x4 px warmBorder, anti-overflow header, dan SafeArea.
class WisgoBottomSheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double? maxHeightFactor;
  final EdgeInsetsGeometry padding;

  const WisgoBottomSheetShell({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.maxHeightFactor = 0.92,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    Widget content = Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle Baku 40x4 px
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.warmBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. Header Seragam (Judul anti-overflow + Tombol Tutup 44x44 px)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h2,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: AppSpacing.xs),
                ],
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.ink, size: 22),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Body Konten
          Flexible(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: content,
      ),
    );
  }
}
