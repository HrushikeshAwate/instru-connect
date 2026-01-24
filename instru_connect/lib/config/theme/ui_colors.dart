// config/theme/ui_colors.dart
import 'package:flutter/material.dart';

class UIColors {
  // =========================
  // CORE BRAND (Vibrant Mix)
  // =========================
  static const primary = Color(0xFF2563EB);   // Electric Blue
  static const secondary = Color(0xFF7C3AED); // Violet
  static const tertiary = Color(0xFF06B6D4);  // Teal

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
    Color(0xFF1E3C72), // Bright steel blue
    Color(0xFF2A5298), // Clean academic blue
    Color(0xFF3A7BD5), // Steel cyan
  ],
);
  // Primary action cards
  static const primaryGradient = LinearGradient(
    colors: [
      Color(0xFF2563EB),
      Color(0xFF06B6D4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary / feature cards
  static const secondaryGradient = LinearGradient(
    colors: [
      Color(0xFF4F46E5),
      Color(0xFF7C3AED),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success cards
  static const successGradient = LinearGradient(
    colors: [
      Color(0xFF16A34A),
      Color(0xFF4ADE80),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warning / attention cards
  static const warningGradient = LinearGradient(
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFFACC15),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Error / critical cards
  static const errorGradient = LinearGradient(
    colors: [
      Color(0xFFDC2626),
      Color(0xFFF87171),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft background sections
  static const softBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFEFF6FF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
