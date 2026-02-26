import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class LightTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.brandBlue,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF3F7FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.brandBlue,
        foregroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 2,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.brandBlue,
          foregroundColor: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.86),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppConstants.brandBlue,
            width: 1.4,
          ),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
