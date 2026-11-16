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
      // Universal Button Hover Effects, Transitions & Cursor Feedback
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 200),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 1.0;
            if (states.contains(WidgetState.hovered)) return 6.0;
            return 2.0;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 200),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF193D22).withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 200),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF193D22).withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 200),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF193D22).withValues(alpha: 0.10);
            }
            return null;
          }),
        ),
      ),
    );
  }
}
