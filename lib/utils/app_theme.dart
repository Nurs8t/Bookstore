import 'package:flutter/material.dart';

/// Қолданбаның түстері мен тақырыбы бір жерде.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFF9F5F0);
  static const Color primary = Color(0xFF4E342E); // қою қоңыр
  static const Color textDark = Color(0xFF3E2723);
  static const Color gold = Color(0xFFC8963E); // бестселлер, рейтинг

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6D4C41),
      primary: primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textDark,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade100),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
