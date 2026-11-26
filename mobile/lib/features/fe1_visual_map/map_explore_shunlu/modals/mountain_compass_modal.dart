import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/destination_model.dart';

/// Modal Bottom Sheet Kompas Visual Landmark Gunung Sumatera Barat (Pilar 2)
Future<void> showMountainCompassModal({
  required BuildContext context,
  required List<MountainLandmarkModel> mountains,
  required double initialHeadingDeg,
  required ValueChanged<double> onHeadingChanged,
}) {
  double currentHeading = initialHeadingDeg;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => SafeArea(
            top: false,
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Kompas Gunung
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.forest.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.explore,
                        color: AppColors.forest,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kompas Visual Landmark Gunung',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Pilar 2: Navigasi visual ke puncak gunung ikonik Sumbar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.muted,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Azimuth Compass Dial Widget
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgCard,
                          border: Border.all(color: AppColors.forest, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.forest.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned(
                              top: 8,
                              child: Text(
                                'N (0°)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 8,
                              child: Text(
                                'E (90°)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 8,
                              child: Text(
                                'S (180°)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 8,
                              child: Text(
                                'W (270°)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              '${currentHeading.toStringAsFixed(0)}°',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.rotate(
                        angle: currentHeading * 3.1415926535 / 180,
                        child: Container(
                          width: 180,
                          height: 180,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.navigation,
                            color: AppColors.danger,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Heading Slider
                Row(
                  children: [
                    const Text(
                      'Arah HP: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: currentHeading,
                        min: 0,
                        max: 360,
                        activeColor: AppColors.forest,
                        onChanged: (val) {
                          setSheetState(() => currentHeading = val);
                          onHeadingChanged(val);
                        },
                      ),
                    ),
                    Text(
                      '${currentHeading.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Landmark Gunung Terdeteksi:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),

                ...mountains.map((mtn) {
                  final diff = (currentHeading - mtn.defaultBearingDeg).abs();
                  final isAligned = diff < 20 || diff > 340;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAligned ? AppColors.sage : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAligned
                            ? AppColors.forest
                            : AppColors.warmBorder,
                        width: isAligned ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isAligned
                              ? AppColors.forest
                              : AppColors.warning.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.landscape_rounded,
                            color: isAligned ? Colors.white : AppColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      mtn.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.creamSubtle,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${mtn.elevationMdpl} mdpl',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mtn.regency,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mtn.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bearing: ${mtn.defaultBearingDeg.toStringAsFixed(0)}°',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAligned
                                    ? AppColors.forest
                                    : AppColors.muted,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (isAligned)
                              const Text(
                                '🎯 SEJAJAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    ),
  );
}
