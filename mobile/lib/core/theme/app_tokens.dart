import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Arsitektur Tipografi & Skala Geometri Baku WISGO (desain.md)
/// Karakter: Plus Jakarta Sans, Keterbacaan Luar Ruang, Lantai Ukuran Minimum >= 11 px
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';

  /// Judul layar utama / Onboarding / Hero (22 px, w800, h1.2, ls -0.4)
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );

  /// Judul halaman tab: Jelajah Sumbar, Open Trip Sumbar (19 px, w800, h1.25, ls -0.3)
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  /// Judul modal bottom sheet & heading seksi (16 px, w800, h1.3, ls -0.2)
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  /// Judul kartu destinasi, judul kartu Open Trip, label CTA utama (14 px, w700, h1.35, ls -0.1)
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );

  /// Paragraf deskripsi, catatan medan, isi ulasan, pesan dialog (13 px, w500, h1.45, ls 0)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Subjudul kartu, metadata lokasi/tanggal, tombol sekunder (12 px, w500, h1.4, ls 0)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.muted,
  );

  /// Ukuran terkecil yang diizinkan (>= 11 px): badge, chip, eyebrow (11 px, w700, h1.3, ls 0.2)
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.muted,
  );

  /// Helper untuk meratakan angka Rupiah, sisa kursi, jarak km, dan stempel paspor
  static TextStyle tabular(TextStyle base) {
    return base.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Skala Spacing Baku (Kelipatan 4 px)
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

/// Skala Radius Sudut Baku (Hanya 6 Nilai Resmi)
class AppRadius {
  AppRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double sheet = 28.0;
  static const double pill = 999.0;

  static final BorderRadius rXs = BorderRadius.circular(xs);
  static final BorderRadius rSm = BorderRadius.circular(sm);
  static final BorderRadius rMd = BorderRadius.circular(md);
  static final BorderRadius rLg = BorderRadius.circular(lg);
  static final BorderRadius rSheet = const BorderRadius.vertical(top: Radius.circular(sheet));
  static final BorderRadius rPill = BorderRadius.circular(pill);
}
