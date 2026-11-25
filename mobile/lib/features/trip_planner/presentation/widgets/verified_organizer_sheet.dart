import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';

/// Modal Mekanisme Verifikasi Penyelenggara (Item 6 Open Trip)
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Verifikasi
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forest.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'TERVERIFIKASI RESMI WISGO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        organizer.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                      Text(
                        organizer.organizationName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detail Kredibilitas Penyelenggara (7 Poin Resmi Trip Go)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.creamSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  // 1. Nama Penyelenggara & Organisasi
                  _buildCredentialRow(
                    icon: Icons.person_rounded,
                    label: '1. Nama Lengkap Penyelenggara',
                    value: '${organizer.name} (${organizer.organizationName})',
                    isHighlight: true,
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // 2. Upload KTP
                  _buildCredentialRow(
                    icon: Icons.badge_outlined,
                    label: '2. Status Upload e-KTP',
                    value: '${organizer.ktpUploadStatus} • ${organizer.ktpStatus}',
                    isHighlight: true,
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // 3. Nomor HP Terverifikasi
                  _buildCredentialRow(
                    icon: Icons.phone_android_rounded,
                    label: '3. Nomor Handphone Terverifikasi',
                    value: '${organizer.phone} (OTP Terhubung Akun WISGO)',
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // 4. Akun / Media Sosial
                  _buildCredentialRow(
                    icon: Icons.share_rounded,
                    label: '4. Akun / Media Sosial Terhubung',
                    value: organizer.socialMedia,
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // 5. Verifikasi Wajah / Liveness Biometrik
                  _buildCredentialRow(
                    icon: Icons.face_retouching_natural_rounded,
                    label: '5. Verifikasi Wajah (Liveness Biometrik)',
                    value: organizer.faceVerificationStatus,
                    isHighlight: true,
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // 6. Pengalaman Sebagai Penyelenggara
                  _buildCredentialRow(
                    icon: Icons.work_history_rounded,
                    label: '6. Pengalaman Penyelenggara',
                    value: '${organizer.experienceYears} (${organizer.completedTrips} Trip Berhasil • ★ ${organizer.rating})',
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // 7. Lisensi & Sertifikasi Kompetensi Khusus
                  _buildCredentialRow(
                    icon: Icons.card_membership_rounded,
                    label: '7. Lisensi & Sertifikasi Khusus',
                    value: '${organizer.licenseNumber}\n${organizer.specialCompetency}',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Escrow Guarantee Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jaminan Keamanan Escrow WISGO',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          organizer.escrowProtectionNote,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF1E3A8A),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Saya Mengerti & Terjamin Aman',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isHighlight ? AppColors.success : AppColors.forest),
        const SizedBox(width: 10),
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
                  color: isHighlight ? const Color(0xFF065F46) : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
