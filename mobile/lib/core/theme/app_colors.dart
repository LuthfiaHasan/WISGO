import 'package:flutter/material.dart';

/// Kalibrasi Palet Warna Resmi WISGO (desain.md)
/// Karakter Visual: Warm Organic Minangkabau
/// Single Source of Truth Resmi untuk Mobile & Web
class AppColors {
  AppColors._();

  // ==========================================
  // A. Palet Inti (Core Brand Palette)
  // ==========================================
  /// Latar halaman utama (Scaffold) & latar modal bottom sheet (#FAF3E6)
  static const Color cream = Color(0xFFFAF3E6);
  static const Color background = cream;

  /// Permukaan sekunder, chip non-aktif, kotak preview halus (#F3EBDC)
  static const Color creamSubtle = Color(0xFFF3EBDC);

  /// Permukaan kartu utama di atas latar cream agar elevasi bersih (#FFFFFF)
  static const Color bgCard = Color(0xFFFFFFFF);

  /// Warna merek utama, CTA primer, tab aktif, ikon penekanan (#193D22)
  static const Color forest = Color(0xFF193D22);
  static const Color primaryDark = forest;

  /// Aksen hijau sekunder, label eyebrow, tombol sekunder/hover (#2F663E)
  static const Color brush = Color(0xFF2F663E);
  static const Color primaryMain = brush;

  /// Latar badge aktif, chip terpilih, kotak ajakan & tips destinasi (#DFECE2)
  static const Color sage = Color(0xFFDFECE2);
  static const Color secondaryLight = sage;

  /// Garis tepi kartu hijau halus, input border, dan tombol outline (#D5E2D7)
  static const Color sageBorder = Color(0xFFD5E2D7);

  /// Garis tepi kartu di atas cream, divider lembut, drag handle modal (#E5DEC9)
  static const Color warmBorder = Color(0xFFE5DEC9);

  /// Aksen tunggal (maks 10% layar): FAB, aksi kritis, badge Ramai, tombol hapus Host (#E65F2B)
  static const Color terracotta = Color(0xFFE65F2B);
  static const Color accent = terracotta;

  /// Latar lembut untuk banner peringatan/ajakan beraksen terracotta (#F9E4DC)
  static const Color coralTint = Color(0xFFF9E4DC);
  static const Color accentLight = coralTint;

  /// Teks utama (judul, isi, angka penting). Pengganti #000000 (#142618)
  static const Color ink = Color(0xFF142618);

  /// Teks sekunder, subjudul, ikon non-aktif (#5A6B5D)
  static const Color muted = Color(0xFF5A6B5D);

  /// Gradien skeleton loader saat memuat data API
  static const Color shimmerBase = Color(0xFFEDE4D3);
  static const Color shimmerHighlight = Color(0xFFF7F1E5);

  /// State Disabled
  static const Color disabledBg = Color(0xFFE2DDD3);
  static const Color disabledText = Color(0xFF8C968E);

  // ==========================================
  // B. Token Semantik Resmi
  // ==========================================
  /// Terverifikasi, Escrow aktif, status Sepi, check-in berhasil
  static const Color success = Color(0xFF15803D);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFDCFCE7);

  /// Rating bintang, status Sedang / Menunggu, peringatan cuaca
  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);

  /// Paspor Digital Minang, lencana level, aksen budaya Minangkabau
  static const Color goldMinang = Color(0xFFC89242);
  static const Color goldSoft = Color(0xFFE5C07B);

  /// Informasi rute, cuaca, Open Trip badge, catatan sistem
  static const Color info = Color(0xFF1E5B82);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  /// Titik notifikasi merah, Radar SOS Darurat, error validasi, hapus permanen
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);

  /// Garis pemisah tipis di dalam kartu putih
  static const Color divider = Color(0xFFE5E7EB);

  // ==========================================
  // C. Token 4 Pin Kanvas 360° Terstandarisasi
  // ==========================================
  /// Berpindah antar-scene panorama udara ↔ darat
  static const Color pinNavigasiBiru = Color(0xFF2563EB);

  /// Narasi audio sejarah & budaya Minangkabau
  static const Color pinAudioEmas = Color(0xFFD97706);

  /// Toilet, musala, loket resmi, parkir Perda
  static const Color pinFasilitasHijau = Color(0xFF15803D);

  /// Homestay, kuliner, sewa baju adat, perahu lokal
  static const Color pinMitraOranye = Color(0xFFE65F2B);

  // ==========================================
  // D. Legacy Aliases (Kompatibilitas Kode Lama)
  // ==========================================
  static const Color cream100 = cream;
  static const Color green800 = forest;
  static const Color green500 = success;
  static const Color ink900 = ink;
  static const Color coral500 = terracotta;
  static const Color orange500 = pinMitraOranye;
  static const Color indigo500 = info;
  static const Color sage100 = sage;
}
