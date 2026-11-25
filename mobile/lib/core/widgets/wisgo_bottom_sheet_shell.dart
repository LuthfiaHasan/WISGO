import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// WisgoBottomSheetShell - Pembungkus Modal Bottom Sheet Baku (desain.md Section 05.2)
/// Radius Atas Baku: 28 px (AppRadius.sheet)
/// Latar: AppColors.cream, Drag Handle 40x4 px, Header Anti-Overflow, Hit Target 44x44
class WisgoBottomSheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onClose;
  final double? maxHeightFactor;
  final bool isDismissible;
  final EdgeInsetsGeometry padding;

  const WisgoBottomSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onClose,
    this.maxHeightFactor = 0.92,
    this.isDismissible = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final effectiveMaxHeight =
        maxHeightFactor != null ? screenHeight * maxHeightFactor! : screenHeight * 0.92;

    return Container(
      constraints: BoxConstraints(
        maxHeight: effectiveMaxHeight,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: AppRadius.rSheet,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle Bar (40 x 4 px)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: AppRadius.rPill,
                  ),
                ),
              ),

              // Header Bar Seragam (Anti Overflow)
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.warmBorder, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ...[
                      trailing!,
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Semantics(
                        button: true,
                        label: 'Tutup Modal',
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.ink,
                            ),
                            splashRadius: 22,
                            onPressed: () {
                              if (onClose != null) {
                                onClose!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Konten Modal Fleksibel
              Flexible(
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
