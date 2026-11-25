import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

/// Tema Kanonik Global WISGO (desain.md)
/// Mendukung Keterbacaan Luar Ruang, Tipografi Plus Jakarta Sans, dan Interaksi Mouse/Touch
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.forest,
        onPrimary: AppColors.cream,
        secondary: AppColors.brush,
        onSecondary: AppColors.cream,
        tertiary: AppColors.terracotta,
        onTertiary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.bgCard,
        onSurface: AppColors.ink,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        titleLarge: AppTypography.h2,
        titleMedium: AppTypography.title,
        titleSmall: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySmall,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.title,
        labelMedium: AppTypography.bodySmall,
        labelSmall: AppTypography.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: AppTypography.h1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: const BorderSide(color: AppColors.warmBorder),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rSheet,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.warmBorder,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.rPill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.sageBorder),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: const ButtonStyle(
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: const ButtonStyle(
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
    );
  }
}
