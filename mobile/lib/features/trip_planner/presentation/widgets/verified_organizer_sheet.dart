import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../models/open_trip_model.dart';

/// Modal Profil Penyelenggara / Pemandu Trip Go (Poin 12 Revisi Trip Go)
/// Menampilkan 5 informasi publik penyelenggara:
/// 1. Nama
/// 2. Nomor HP
/// 3. Akun Media Sosial
/// 4. Lisensi / Sertifikasi (Wajib untuk jalur berat / hard)
/// 5. Pengalaman Penyelenggara
/// (Upload KTP & Verifikasi Wajah dipindahkan khusus ke form pembuatan trip penyelenggara)
class VerifiedOrganizerSheet extends StatelessWidget {
  final VerifiedOrganizer organizer;

  const VerifiedOrganizerSheet({
    super.key,
    required this.organizer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar baku 40x4 px
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Penyelenggara
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.cream,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            border: Border.all(color: AppColors.successBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Penyelenggara Terverifikasi WISGO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          organizer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          organizer.organizationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                      tooltip: 'Tutup',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 5 Informasi Utama Penyelenggara / Pemandu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  children: [
                    // 1. Nama
                    _buildInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Nama Penyelenggara / Pemandu',
                      value: organizer.name,
                    ),
                    const Divider(height: 18, color: AppColors.divider),

                    // 2. Nomor HP
                    _buildInfoRow(
                      icon: Icons.phone_android_rounded,
                      label: 'Nomor HP',
                      value: organizer.phone,
                    ),
                    const Divider(height: 18, color: AppColors.divider),

                    // 3. Akun Media Sosial
                    _buildInfoRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Akun Media Sosial',
                      value: organizer.socialMedia,
                    ),
                    const Divider(height: 18, color: AppColors.divider),

                    // 4. Lisensi (Wajib untuk jalur Hard / Berat)
                    _buildInfoRow(
                      icon: Icons.card_membership_rounded,
                      label: 'Lisensi / Sertifikasi (Wajib Jalur Hard)',
                      value:
                          '${organizer.licenseNumber}\n${organizer.specialCompetency}',
                      isHighlight: true,
                    ),
                    const Divider(height: 18, color: AppColors.divider),

                    // 5. Pengalaman Penyelenggara
                    _buildInfoRow(
                      icon: Icons.work_history_outlined,
                      label: 'Pengalaman Penyelenggara',
                      value:
                          '${organizer.experienceYears} • ${organizer.completedTrips} Trip Berhasil • ★ ${organizer.rating}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text(
                    'Tutup Profil Penyelenggara',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isHighlight ? AppColors.sage : AppColors.creamSubtle,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isHighlight ? AppColors.forest : AppColors.ink,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
