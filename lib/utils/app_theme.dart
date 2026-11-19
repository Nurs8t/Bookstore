import 'package:flutter/material.dart';

/// Қолданбаның түстері мен тақырыптары (жарық және қараңғы) бір жерде.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFF9F5F0);
  static const Color primary = Color(0xFF4E342E); // қою қоңыр
  static const Color textDark = Color(0xFF3E2723);
  static const Color gold = Color(0xFFC8963E); // бестселлер, рейтинг

  // Қараңғы тақырып түстері
  static const Color darkBackground = Color(0xFF1B1715);
  static const Color darkSurface = Color(0xFF26201D);
  static const Color darkText = Color(0xFFF1EBE6);
  static const Color darkAccent = Color(0xFFD7A98C); // ашық қоңыр — қараңғы фонда оқылады

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6D4C41),
      primary: primary,
      onSurface: textDark, // мәтіннің әдепкі түсі
      surfaceContainerLowest: Colors.white, // карточкалар
    );
    return _build(scheme, background);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6D4C41),
      brightness: Brightness.dark,
      primary: darkAccent,
      onPrimary: textDark,
      surface: darkBackground,
      onSurface: darkText,
      surfaceContainerLowest: darkSurface, // карточкалар
    );
    return _build(scheme, darkBackground);
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// Тақырыпқа тәуелді түстер: жарық тақырыпта — қоңыр/ақ, қараңғыда — ашық қоңыр/күңгірт.
extension AppColors on BuildContext {
  /// Карточкалар мен панельдердің фоны.
  Color get surfaceCard => Theme.of(this).colorScheme.surfaceContainerLowest;

  /// Баға, белгішелер сияқты акцент түсі.
  Color get accent => Theme.of(this).colorScheme.primary;
}
