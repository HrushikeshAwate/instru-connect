// config/theme/color_scheme.dart
import 'package:flutter/material.dart';

final ColorScheme academicColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.light,

  // 🔒 LOCKED SEED (Authority color)
  seedColor: const Color(0xFF050C9C),

  // ── Explicit overrides (intentional) ──
  primary: const Color(0xFF3572EF),      // Primary actions
  secondary: const Color(0xFF3ABEF9),    // Accents / info
  surface: Colors.white,                 // Cards, sheets
  background: const Color(0xFFF8FAFC),   // App background
  error: const Color(0xFFB91C1C),         // Error state (standard red)
);
