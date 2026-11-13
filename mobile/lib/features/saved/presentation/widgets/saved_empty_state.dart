import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Item 6B: Empty State UI (1:1 dari `wisgo_interactive_3d_prototype (1).html`).
///
/// Menampilkan:
/// - Pill "DAFTAR TERSIMPAN KOSONG"
/// - Judul "Belum Ada Destinasi Disimpan"
/// - Penjelasan wilayah Padang, Payakumbuh, Bukittinggi, atau Daerah Terpencil
/// - Kotak pratinjau vertikal "Data yang Tersimpan Luring di Perangkat"
/// - 2 Tombol Aksi: "Muat 4 Destinasi Unggulan Sumbar" & "Cari dari Navigator Daerah"
class SavedEmptyState extends StatelessWidget {
  final VoidCallback onRestoreDefaultPressed;
  final VoidCallback? onOpenExplorePressed;

  const SavedEmptyState({
    super.key,
    required this.onRestoreDefaultPressed,
    this.onOpenExplorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.creamSubtle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: const Text(
              'DAFTAR TERSIMPAN KOSONG',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Destinasi Disimpan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Simpan destinasi wisata dari wilayah Padang, Payakumbuh, Bukittinggi, atau Daerah Terpencil agar foto lokasi, panduan akses jalan, dan rincian biaya resmi tetap bisa dibuka tanpa sinyal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          // Vertical Preview of What Gets Saved
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATA YANG TERSIMPAN LURING DI PERANGKAT:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Foto & Panduan Medan Jalan',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'Tersedia Luring',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.warmBorder),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tarif Tiket & Parkir Resmi Perda',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'Vertikal Lengkap',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRestoreDefaultPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: AppColors.cream,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Muat 4 Destinasi Unggulan Sumbar',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (onOpenExplorePressed != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onOpenExplorePressed,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  foregroundColor: AppColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cari dari Navigator Daerah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
