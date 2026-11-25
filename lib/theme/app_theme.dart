import 'package:flutter/material.dart';

/// Konfigurasi Material Design 3 Theme dan Typography modern untuk CuacaKu.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF2563EB);
  static const Color canvasBackground = Color(0xFFF2F5FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color inkPrimary = Color(0xFF0F172A);
  static const Color inkSecondary = Color(0xFF64748B);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      surface: canvasBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvasBackground,
      textTheme: _buildTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: inkPrimary,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: inkPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        hintStyle: const TextStyle(
          color: inkSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
        side: BorderSide.none,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    const tabular = [FontFeature.tabularFigures()];
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 68,
        fontWeight: FontWeight.w300,
        height: 1.0,
        letterSpacing: -3.0,
        color: inkPrimary,
        fontFeatures: tabular,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: inkPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: inkPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: inkPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: inkPrimary,
        fontFeatures: tabular,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: inkSecondary,
        fontFeatures: tabular,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: inkSecondary,
      ),
    );
  }
}
