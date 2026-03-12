// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand
  static const Color primary = Color(0xFF4F46E5);       // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);

  // Secondary
  static const Color secondary = Color(0xFF06B6D4);     // Cyan
  static const Color secondaryLight = Color(0xFF67E8F9);

  // Semantic
  static const Color success = Color(0xFF10B981);       // Green - High
  static const Color warning = Color(0xFFF59E0B);       // Amber - Medium
  static const Color danger = Color(0xFFEF4444);        // Red - Risk
  static const Color info = Color(0xFF3B82F6);          // Blue

  // Performance Colors
  static const Color highPerf = Color(0xFF10B981);
  static const Color mediumPerf = Color(0xFFF59E0B);
  static const Color lowPerf = Color(0xFFEF4444);

  // Light Theme
  static const Color lightBg = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8EAFF);
  static const Color lightText = Color(0xFF0F0F23);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Dark Theme
  static const Color darkBg = Color(0xFF0A0A1A);
  static const Color darkSurface = Color(0xFF12122A);
  static const Color darkCard = Color(0xFF1A1A35);
  static const Color darkBorder = Color(0xFF2D2D5E);
  static const Color darkText = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
