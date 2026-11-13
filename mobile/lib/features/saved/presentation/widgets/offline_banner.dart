import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Global Static Offline Notification Banner (Item 6 dari `wisgo_interactive_3d_prototype (1).html`).
///
/// Menampilkan:
/// - Indikator titik terracotta + teks "MODE TANPA KONEKSI INTERNET"
/// - Deskripsi: "Menampilkan katalog daerah, bookmark tersimpan, dan rincian biaya resmi vertikal dari memori perangkat."
/// - Tombol "Aktifkan" di sisi kanan
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.coralTint,
        border: Border(
          bottom: BorderSide(
            color: AppColors.terracotta.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.terracotta,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'MODE TANPA KONEKSI INTERNET',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Menampilkan katalog daerah, bookmark tersimpan, dan rincian biaya resmi vertikal dari memori perangkat.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.terracotta.withValues(alpha: 0.30),
                  ),
                ),
                child: const Text(
                  'Aktifkan',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
