import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Authentic Editorial Skeleton Shimmer Loader (1:1 dari `wisgo_interactive_3d_prototype (1).html`).
///
/// Menyesuaikan struktur kartu destinasi bergambar + rincian biaya resmi vertikal.
class SavedSkeletonShimmer extends StatefulWidget {
  final int itemCount;

  const SavedSkeletonShimmer({
    super.key,
    this.itemCount = 2,
  });

  @override
  State<SavedSkeletonShimmer> createState() => _SavedSkeletonShimmerState();
}

class _SavedSkeletonShimmerState extends State<SavedSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;
        return Column(
          children: List.generate(
            widget.itemCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildShimmerCard(v, isFirst: index == 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard(double v, {required bool isFirst}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area Foto Header (h-36 = 144px)
          _shimmerBox(
            width: double.infinity,
            height: 144,
            radius: 0,
            value: v,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirst) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _shimmerBox(width: 112, height: 16, radius: 4, value: v),
                      _shimmerBox(width: 80, height: 16, radius: 4, value: v),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _shimmerBox(width: 240, height: 20, radius: 5, value: v),
                if (isFirst) ...[
                  const SizedBox(height: 8),
                  _shimmerBox(width: 180, height: 14, radius: 4, value: v),
                ],
                const SizedBox(height: 12),

                // Vertical Fee Skeleton Rows
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerBox(
                            width: 112,
                            height: 14,
                            radius: 4,
                            value: v,
                          ),
                          _shimmerBox(
                            width: 80,
                            height: 14,
                            radius: 4,
                            value: v,
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.warmBorder),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerBox(
                            width: 128,
                            height: 14,
                            radius: 4,
                            value: v,
                          ),
                          _shimmerBox(
                            width: 64,
                            height: 14,
                            radius: 4,
                            value: v,
                          ),
                        ],
                      ),
                      if (isFirst) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            color: AppColors.warmBorder,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _shimmerBox(
                              width: 112,
                              height: 14,
                              radius: 4,
                              value: v,
                            ),
                            _shimmerBox(
                              width: 64,
                              height: 14,
                              radius: 4,
                              value: v,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (isFirst) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _shimmerBox(
                          width: double.infinity,
                          height: 40,
                          radius: 12,
                          value: v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _shimmerBox(
                        width: 80,
                        height: 40,
                        radius: 12,
                        value: v,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
    required double value,
  }) {
    final start = (value * 2) - 1.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(start - 1.0, 0),
          end: Alignment(start + 1.0, 0),
          colors: const [
            AppColors.shimmerBase,
            AppColors.shimmerHighlight,
            AppColors.shimmerBase,
          ],
          stops: const [0.25, 0.5, 0.75],
        ),
      ),
    );
  }
}
