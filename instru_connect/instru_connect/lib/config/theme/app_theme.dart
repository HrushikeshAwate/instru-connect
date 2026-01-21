// config/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'color_scheme.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: academicColorScheme,
    scaffoldBackgroundColor: academicColorScheme.surface,

    // TEXT
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF64748B),
      ),
    ),

    // 🔹 YOUR SNIPPET STARTS HERE
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: academicColorScheme.surface,
      foregroundColor: academicColorScheme.onSurface,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      color: academicColorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: academicColorScheme.outline,
      thickness: 1,
    ),
  );
}
