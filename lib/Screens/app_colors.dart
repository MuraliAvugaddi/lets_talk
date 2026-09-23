import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // LET'S SPEAK BRAND
  // ============================================================

  static const Color navy = Color(0xFF155A88);
  static const Color deepNavy = Color(0xFF0E466D);
  static const Color blue = Color(0xFF2C6F9F);

  static const Color teal = Color(0xFF28C2C2);

  static const Color yellow = Color(0xFFF7DF55);

  static const Color periwinkle = Color(0xFF7CA4D8);

  // ============================================================
  // LIGHT MODE
  // ============================================================

  static const Color background = Color(0xFFE8F2F8);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceSoft = Color(0xFFF4F9FC);

  static const Color border = Color(0xFFD5E5EE);

  static const Color text = Color(0xFF173A52);

  static const Color textSecondary = Color(0xFF678196);

  // ============================================================
  // DARK MODE
  // ============================================================

  static const Color darkBackground = Color(0xFF08141D);

  static const Color darkSurface = Color(0xFF102330);

  static const Color darkSurface2 = Color(0xFF153247);

  static const Color darkBorder = Color(0xFF24465D);

  static const Color darkText = Color(0xFFF5FAFD);

  static const Color darkTextSecondary = Color(0xFFAEC1CE);

  // ============================================================
  // STATUS
  // ============================================================

  static const Color success = Color(0xFF16A66A);

  static const Color error = Color(0xFFE45757);

  static const Color warning = Color(0xFFF2B84B);

  // ============================================================
  // COMMON TRANSPARENT COLORS
  // ============================================================

  static Color navy10 = navy.withValues(alpha: 0.10);

  static Color navy15 = navy.withValues(alpha: 0.15);

  static Color teal10 = teal.withValues(alpha: 0.10);

  static Color teal15 = teal.withValues(alpha: 0.15);

  static Color yellow15 = yellow.withValues(alpha: 0.15);

  static Color success10 = success.withValues(alpha: 0.10);

  static Color error10 = error.withValues(alpha: 0.10);
}