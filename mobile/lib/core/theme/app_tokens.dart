import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Arsitektur Tipografi Resmi WISGO (desain.md 03)
/// Menggunakan font tunggal Plus Jakarta Sans dan batas lantai minimum >= 11 px.
class AppTypography {
  AppTypography._();

  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.4,
        color: AppColors.ink,
      );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.3,
        color: AppColors.ink,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: -0.2,
        color: AppColors.ink,
      );

  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.1,
        color: AppColors.ink,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0,
        color: AppColors.ink,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0,
        color: AppColors.muted,
      );

  /// Ukuran terkecil yang diizinkan (Lantai Minimum >= 11 px)
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.2,
        color: AppColors.muted,
      );

  /// Tabular figures untuk harga, sisa kursi, dan angka kuantitatif
  static TextStyle withTabularFigures(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Skala Spacing Grid Kelipatan 4 px Resmi (desain.md 04.A)
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

/// Skala Radius Sudut Baku (desain.md 04.B)
class AppRadius {
  AppRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double sheet = 28.0;
  static const double pill = 999.0;

  static const Radius rXs = Radius.circular(xs);
  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rSheet = Radius.circular(sheet);
  static const Radius rPill = Radius.circular(pill);

  static final BorderRadius brXs = BorderRadius.circular(xs);
  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
  static final BorderRadius brLg = BorderRadius.circular(lg);
  static final BorderRadius brSheet = BorderRadius.vertical(top: rSheet);
  static final BorderRadius brPill = BorderRadius.circular(pill);
}
