import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/gamification_model.dart';

/// Modal Bottom Sheet Rincian Aktivitas Check-in & Gamifikasi (desain.md)
Future<void> showActivityDetailModal({
  required BuildContext context,
  required CheckInActivity activity,
  required String formattedTimestamp,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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
              const SizedBox(height: 14),

              // Title Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: activity.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: activity.iconColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(activity.icon, color: activity.iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.destinationTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activity.region,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(modalCtx),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: AppColors.muted,
                    ),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: EdgeInsets.zero,
                    tooltip: 'Tutup',
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(color: AppColors.warmBorder, height: 1),
              const SizedBox(height: 16),

              // Rincian Detail Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  children: [
                    _ActivityModalRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Waktu Aktivitas',
                      value: formattedTimestamp,
                    ),
                    const Divider(height: 16, color: AppColors.warmBorder),
                    const _ActivityModalRow(
                      icon: Icons.verified_rounded,
                      label: 'Status Verifikasi',
                      value: 'GPS Terverifikasi (<500m)',
                      valueColor: AppColors.success,
                    ),
                    const Divider(height: 16, color: AppColors.warmBorder),
                    _ActivityModalRow(
                      icon: Icons.military_tech_rounded,
                      label: 'Hadiah Diperoleh',
                      value: '+${activity.xpEarned} XP & +${activity.pointsEarned} GP',
                      valueColor: AppColors.warningDark,
                    ),
                    const Divider(height: 16, color: AppColors.warmBorder),
                    _ActivityModalRow(
                      icon: Icons.flag_rounded,
                      label: 'Catatan Misi',
                      value: activity.note,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(modalCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tutup Rincian',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActivityModalRow extends StatelessWidget {
  const _ActivityModalRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.forest),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
