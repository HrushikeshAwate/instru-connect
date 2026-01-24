// config/theme/color_scheme.dart
import 'package:flutter/material.dart';

final ColorScheme academicColorScheme = const ColorScheme(
  brightness: Brightness.light,

  // ===== CORE BRAND (Advanced, Vibrant) =====
  primary: Color(0xFF2563EB),          // Electric Blue
  onPrimary: Colors.white,

  secondary: Color(0xFF7C3AED),        // Violet Accent
  onSecondary: Colors.white,

  tertiary: Color(0xFF06B6D4),          // Teal Highlight
  onTertiary: Colors.white,

  // ===== STATUS COLORS =====
  error: Color(0xFFEF4444),             // Soft Red
  onError: Colors.white,

  // ===== SURFACES =====
  background: Color(0xFFF8FAFC),        // Soft neutral (lets colors pop)
  onBackground: Color(0xFF0F172A),

  surface: Colors.white,
  onSurface: Color(0xFF0F172A),

  surfaceVariant: Color(0xFFF1F5F9),
  onSurfaceVariant: Color(0xFF475569),

  // ===== OUTLINES & UTILITY =====
  outline: Color(0xFFE2E8F0),
  shadow: Colors.black,
  scrim: Colors.black,

  // ===== REQUIRED CONTAINERS =====
  primaryContainer: Color(0xFFDBEAFE),
  onPrimaryContainer: Color(0xFF1E3A8A),

  secondaryContainer: Color(0xFFEDE9FE),
  onSecondaryContainer: Color(0xFF4C1D95),

  tertiaryContainer: Color(0xFFCFFAFE),
  onTertiaryContainer: Color(0xFF155E75),

  errorContainer: Color(0xFFFEE2E2),
  onErrorContainer: Color(0xFF7F1D1D),

  inverseSurface: Color(0xFF1E293B),
  onInverseSurface: Colors.white,

  inversePrimary: Color(0xFF93C5FD),
);
