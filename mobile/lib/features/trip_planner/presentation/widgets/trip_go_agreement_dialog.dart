import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Daftar Ketentuan Resmi Panduan Trip Go (Bernomor 1-8)
const List<Map<String, String>> kTripGoGuidelines = [
  {
    'title': '1 Destinasi Tunggal & Penyelenggara Berlisensi',
    'desc':
        'Perjalanan wisata terstruktur dengan 1 destinasi tunggal per-trip bersama penyelenggara lokal yang telah terverifikasi identitas serta lisensinya.',
  },
  {
    'title': 'Sistem Pembayaran Rekening Penampung (Escrow)',
    'desc':
        'Seluruh pembayaran masuk terlebih dahulu ke Rekening Penampung (Escrow) resmi melalui Payment Gateway WISGO, dan baru diteruskan kepada penyelenggara setelah perjalanan terlaksana dengan baik.',
  },
  {
    'title': 'Transparansi Harga Include & Exclude',
    'desc':
        'Setiap jadwal Trip Go wajib mencantumkan rincian fasilitas yang sudah termasuk (Include) dan tidak termasuk (Exclude) secara jujur sebelum peserta mendaftar.',
  },
  {
    'title': 'Komunikasi Terpusat di Chat In-App WISGO',
    'desc':
        'Koordinasi rombongan antara penyelenggara dan peserta dilakukan langsung melalui fitur Chat di dalam aplikasi WISGO tanpa perlu berpindah ke WhatsApp.',
  },
  {
    'title': 'Kewajiban Persiapan & Barang Bawaan',
    'desc':
        'Peserta wajib memeriksa dan menyetujui konfirmasi daftar Persiapan Trip serta Barang Bawaan yang ditetapkan penyelenggara sebelum hari keberangkatan.',
  },
  {
    'title': 'Titik Kumpul Presisi & Notifikasi Pengingat',
    'desc':
        'Titik kumpul keberangkatan terhubung langsung ke Google Maps dan dilengkapi pengingat jadwal agar seluruh peserta tiba tepat waktu.',
  },
  {
    'title': 'Tanggung Jawab Platform & Pelaksanaan Lapangan',
    'desc':
        'WISGO berperan sebagai penyedia platform digital dan penjamin transaksi Escrow. Seluruh proses teknis serta keselamatan aktivitas lapangan merupakan tanggung jawab bersama penyelenggara dan peserta.',
  },
  {
    'title': 'Ketentuan Pembatalan & Pengembalian Dana',
    'desc':
        'Pengajuan pembatalan atau pengembalian dana (refund) diproses melalui sistem WISGO mengikuti batas waktu yang berlaku sebelum tanggal keberangkatan.',
  },
];

/// Modal Bottom Sheet Resmi: PANDUAN TRIP GO (Terpadu 1-8)
void showTripGoGuideSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle baku 40x4 px
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 20,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PANDUAN TRIP GO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Ketentuan resmi perjalanan bareng di WISGO',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                        tooltip: 'Tutup',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.warmBorder),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  shrinkWrap: true,
                  itemCount: kTripGoGuidelines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = kTripGoGuidelines[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Pop-up Persetujuan Perjanjian Awal Sebelum Bergabung ke Trip Go (Poin 4)
/// Mengembalikan `true` jika wisatawan mencentang persetujuan & menekan Lanjutkan.
Future<bool> showTripGoJoinAgreementDialog(
  BuildContext context, {
  required String tripTitle,
}) async {
  bool isAgreed = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    size: 18,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Persetujuan Trip Go',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sebelum bergabung pada "$tripTitle", pastikan Anda memahami ketentuan utama Trip Go:',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Pembayaran aman melalui Rekening Penampung (Escrow) WISGO.\n'
                          '2. Wajib mengikuti jadwal, titik kumpul, serta daftar persiapan & barang bawaan.\n'
                          '3. Komunikasi resmi rombongan melalui fitur Chat In-App WISGO.\n'
                          '4. WISGO adalah penyedia platform; keselamatan aktivitas lapangan menjadi tanggung jawab bersama penyelenggara dan peserta.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.ink,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showTripGoGuideSheet(context),
                      icon: const Icon(
                        Icons.menu_book_rounded,
                        size: 15,
                        color: AppColors.forest,
                      ),
                      label: const Text(
                        'Baca Panduan Trip Go Lengkap (1–8)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setDialogState(() => isAgreed = !isAgreed),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isAgreed ? AppColors.sage : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAgreed
                              ? AppColors.forest
                              : AppColors.sageBorder,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isAgreed,
                              activeColor: AppColors.forest,
                              onChanged: (v) =>
                                  setDialogState(() => isAgreed = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Saya telah membaca dan menyetujui seluruh persyaratan & ketentuan Trip Go WISGO.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    isAgreed ? () => Navigator.pop(dialogCtx, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: AppColors.cream,
                  disabledBackgroundColor: AppColors.disabledBg,
                  disabledForegroundColor: AppColors.disabledText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: const Text(
                  'Setuju & Lanjutkan',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  return result == true;
}
