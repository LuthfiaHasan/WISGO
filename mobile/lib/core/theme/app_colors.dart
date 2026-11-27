import 'package:flutter/material.dart';

/// Single Source of Truth Resmi Palet Warna WISGO (desain.md)
/// Karakter Visual: Warm Organic Minangkabau
/// - cream:       #FAF3E6 (Latar utama Scaffold & Modal)
/// - creamSubtle: #F3EBDC (Permukaan sekunder, chip non-aktif)
/// - bgCard:      #FFFFFF (Permukaan kartu utama di atas cream)
/// - forest:      #193D22 (Merek utama & CTA primer)
/// - brush:       #2F663E (Aksen hijau sekunder & eyebrow)
/// - sage:        #DFECE2 (Latar badge aktif & chip terpilih)
/// - sageBorder:  #D5E2D7 (Garis tepi kartu & button outline)
/// - warmBorder:  #E5DEC9 (Border di atas cream, divider, drag handle)
/// - terracotta:  #E65F2B (Aksen tunggal maks 10%: FAB, Ramai, kritis)
/// - coralTint:   #F9E4DC (Latar lembut untuk banner terakota)
/// - ink:         #142618 (Teks utama, judul, angka penting)
/// - muted:       #5A6B5D (Teks sekunder, metadata, ikon non-aktif)
class AppColors {
  AppColors._();

  // ================= 1. CORE BRAND PALETTE (desain.md 02.A) =================
  static const Color cream = Color(0xFFFAF3E6);
  static const Color creamSubtle = Color(0xFFF3EBDC);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color forest = Color(0xFF193D22);
  static const Color brush = Color(0xFF2F663E);
  static const Color sage = Color(0xFFDFECE2);
  static const Color sageBorder = Color(0xFFD5E2D7);
  static const Color warmBorder = Color(0xFFE5DEC9);
  static const Color terracotta = Color(0xFFE65F2B);
  static const Color coralTint = Color(0xFFF9E4DC);
  static const Color ink = Color(0xFF142618);
  static const Color muted = Color(0xFF5A6B5D);

  // Shimmer Skeleton Colors
  static const Color shimmerBase = Color(0xFFEDE4D3);
  static const Color shimmerHighlight = Color(0xFFF7F1E5);

  // ================= 2. TOKEN SEMANTIK RESMI (desain.md 02.B) =================
  // Sukses, Terverifikasi, Escrow, Status Sepi
  static const Color success = Color(0xFF15803D);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFDCFCE7);

  // Peringatan, Rating Bintang, Status Sedang, Cuaca
  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);

  // Warisan Budaya, Paspor Digital Minang, Aksen Level
  static const Color goldMinang = Color(0xFFC89242);
  static const Color goldSoft = Color(0xFFE5C07B);

  // Informasi Rute, Open Trip Badge, Catatan Sistem
  static const Color info = Color(0xFF1E5B82);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  // Bahaya, Radar Darurat SOS, Error Validasi, Hapus Permanen
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Divider tipis di dalam kartu putih
  static const Color divider = Color(0xFFE5E7EB);

  // ================= 3. TOKEN 4 PIN KANVAS 360° TERSTANDARISASI (desain.md 02.C) =================
  static const Color pinNavigasiBiru = Color(0xFF2563EB); // Berpindah scene udara <-> darat
  static const Color pinAudioEmas = Color(0xFFD97706);     // Narasi audio sejarah & budaya Minang
  static const Color pinFasilitasHijau = Color(0xFF15803D); // Toilet, mushola, loket, parkir
  static const Color pinMitraOranye = Color(0xFFE65F2B);   // Homestay, kuliner, sewa baju adat, perahu

  // ================= 4. SEMANTIC & LEGACY COMPATIBILITY ALIASES =================
  static const Color background = cream;
  static const Color primaryDark = forest;
  static const Color primaryMain = brush;
  static const Color secondaryLight = sage;
  static const Color secondaryBorder = sageBorder;
  static const Color accent = terracotta;
  static const Color accentLight = coralTint;

  // Aliases dari theme/app_colors.dart (Memastikan 100% kompatibilitas FE-1)
  static const Color cream100 = cream;
  static const Color green800 = forest;
  static const Color green500 = success;
  static const Color ink900 = ink;
  static const Color coral500 = terracotta;
  static const Color orange500 = warning;
  static const Color indigo500 = info;
  static const Color sage100 = sage;

  // Legacy aliases proyek lainnya
  static const Color bg = cream;
  static const Color creamBg = cream;
  static const Color green = forest;
  static const Color greenDark = forest;
  static const Color greenMedium = brush;
  static const Color forestDeep = forest;
  static const Color sageCard = sage;
  static const Color mintBadge = sage;
  static const Color coral = terracotta;
  static const Color peach = coralTint;
  static const Color emeraldAccent = brush;
  static const Color limeAccent = sage;
  static const Color limeSoft = sage;
  static const Color limeMid = sageBorder;

  static const Color textMuted = muted;
  static const Color borderLight = sageBorder;
  static const Color borderInput = sageBorder;
  static const Color inputFill = cream;
  static const Color disabledBg = sageBorder;
  static const Color disabledText = muted;
}
