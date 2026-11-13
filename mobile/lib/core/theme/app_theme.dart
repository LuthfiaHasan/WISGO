import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream100,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green800,
        primary: AppColors.green800,
        secondary: AppColors.coral500,
        surface: AppColors.cream100,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.ink900),
        bodyMedium: TextStyle(color: AppColors.ink900),
        titleLarge: TextStyle(color: AppColors.ink900, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream100,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink900),
        titleTextStyle: TextStyle(
          color: AppColors.ink900,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

