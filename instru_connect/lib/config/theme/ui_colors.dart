// config/theme/ui_colors.dart
import 'package:flutter/material.dart';

class UIColors {
  // =========================
  // CORE BRAND (Vibrant Mix)
  // =========================
  static const primary = Color(0xFF2563EB); // Electric Blue
  static const secondary = Color(0xFF7C3AED); // Violet
  static const tertiary = Color(0xFF06B6D4); // Teal

  // Used by existing screens — DO NOT REMOVE
  static const Color deepTeal = tertiary;

  // =========================
  // STATUS COLORS
  // =========================
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF38BDF8);

  // =========================
  // BASE COLORS
  // =========================
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // =========================
  // GRADIENTS (ADVANCED UI)
  // =========================

  // Hero / Main highlight cards
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // Brighter blue
      Color(0xFF2563EB), // Strong primary blue
      Color(0xFF22D3EE), // Bright cyan accent
    ],
  );
  // Primary action cards
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary / feature cards
  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success cards
  static const successGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF4ADE80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warning / attention cards
  static const warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFACC15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Error / critical cards
  static const errorGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft background sections
  static const softBackgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Curated palette for colorful, professional action tiles.
  static const tilePalette = <LinearGradient>[
    LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF0EA5A4), Color(0xFF22C55E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFDB2777), Color(0xFFEF4444)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static LinearGradient tileGradient(int index) {
    return tilePalette[index % tilePalette.length];
  }
}
