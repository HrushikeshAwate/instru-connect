// config/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'color_scheme.dart';
import 'ui_colors.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: academicColorScheme,

    // 🌈 Soft neutral base (lets gradients shine)
    scaffoldBackgroundColor: UIColors.background,

    // =========================
    // TYPOGRAPHY (modern, premium)
    // =========================
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: UIColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: UIColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: UIColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: UIColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: UIColors.textSecondary,
      ),
    ),

    // =========================
    // APP BAR (glass-style base)
    // =========================
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: UIColors.textPrimary,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: UIColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: UIColors.textPrimary),
    ),

    // =========================
    // CARD THEME (base card only)
    // =========================
    cardTheme: CardThemeData(
      elevation: 0,
      color: UIColors.surface,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    ),

    // =========================
    // BUTTONS
    // =========================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: UIColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: UIColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: UIColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
    ),

    // =========================
    // LIST TILES
    // =========================
    listTileTheme: ListTileThemeData(
      iconColor: UIColors.primary,
      textColor: UIColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    // =========================
    // DIVIDERS
    // =========================
    dividerTheme: const DividerThemeData(
      thickness: 1,
      color: Color(0xFFE5E7EB),
    ),

    // =========================
    // INPUTS (clean, modern)
    // =========================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: UIColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: UIColors.textSecondary, fontSize: 13),
    ),
  );
}

ThemeData buildDarkAppTheme() {
  const darkBg = Color(0xFF0B1220);
  const darkSurface = Color(0xFF111827);
  const darkSurfaceAlt = Color(0xFF1F2937);
  const darkTextPrimary = Color(0xFFF8FAFC);
  const darkTextSecondary = Color(0xFFCBD5E1);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: UIColors.primary,
      secondary: UIColors.tertiary,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
    ),
    scaffoldBackgroundColor: darkBg,
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: darkTextPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: darkTextSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: darkTextPrimary,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
      ),
      iconTheme: IconThemeData(color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurface,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkSurfaceAlt, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: UIColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF93C5FD),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: UIColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: const Color(0xFF93C5FD),
      textColor: darkTextPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    dividerTheme: const DividerThemeData(thickness: 1, color: darkSurfaceAlt),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 13),
    ),
  );
}
