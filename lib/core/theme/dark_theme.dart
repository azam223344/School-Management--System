import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class DarkTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.brandBlue,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF070B14),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF123C93),
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
      iconTheme: const IconThemeData(color: Color(0xFFE2E8F0)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2E5BFF),
          foregroundColor: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF121A2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E162A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
