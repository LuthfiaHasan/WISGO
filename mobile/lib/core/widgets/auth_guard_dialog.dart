import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'wisgo_button.dart';

/// AuthGuard - Pelindung Aksi Interaktif Pengguna (desain.md Section 07.1)
/// Digunakan untuk Check-in Paspor, Usul Wisata, Bookmark, Buat/Gabung Open Trip, Simpan Jejak WISGO
class AuthGuard {
  AuthGuard._();

  /// Periksa sesi. Jika user adalah tamu, tampilkan dialog ajakan login.
  /// Mengembalikan true jika terautentikasi atau setelah user berhasil login.
  static Future<bool> check({
    required BuildContext context,
    required String actionTitle,
    required String actionDescription,
    bool isAuthenticated = false,
    VoidCallback? onLoginSuccess,
  }) async {
    if (isAuthenticated) return true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AuthGuardModal(
        actionTitle: actionTitle,
        actionDescription: actionDescription,
      ),
    );

    if (result == true && onLoginSuccess != null) {
      onLoginSuccess();
    }

    return result ?? false;
  }
}

class _AuthGuardModal extends StatelessWidget {
  final String actionTitle;
  final String actionDescription;

  const _AuthGuardModal({
    required this.actionTitle,
    required this.actionDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: AppRadius.brSheet,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warmBorder,
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),

            // Icon Shield
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: AppColors.forest,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Judul & Deskripsi
            Text(
              actionTitle,
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              actionDescription,
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Tombol Masuk dengan Google
            WisgoButton(
              label: 'Masuk dengan Akun Google',
              icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
              variant: WisgoButtonVariant.primary,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Tombol Nanti Saja / Mode Tamu
            WisgoButton(
              label: 'Lanjutkan Jelajah sebagai Tamu',
              variant: WisgoButtonVariant.outline,
              size: WisgoButtonSize.medium,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
