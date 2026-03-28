// lib/config/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ══════════════════════════════════════
  // CORES PRINCIPAIS
  // ══════════════════════════════════════
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9B94FF);
  static const primaryDark = Color(0xFF4A42D4);

  static const secondary = Color(0xFF00BFA6);
  static const secondaryLight = Color(0xFF5DF2D6);
  static const secondaryDark = Color(0xFF008E76);

  // ══════════════════════════════════════
  // BACKGROUNDS
  // ══════════════════════════════════════
  static const background = Color(0xFFF8F9FE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F8);

  // ══════════════════════════════════════
  // TEXTOS
  // ══════════════════════════════════════
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ══════════════════════════════════════
  // SEMÂNTICAS
  // ══════════════════════════════════════
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);

  // ══════════════════════════════════════
  // CORES DE HUMOR (1-5)
  // ══════════════════════════════════════
  static const mood1 = Color(0xFFEF4444);
  static const mood2 = Color(0xFFF97316);
  static const mood3 = Color(0xFFF59E0B);
  static const mood4 = Color(0xFF84CC16);
  static const mood5 = Color(0xFF10B981);

  static Color moodColor(int score) {
    switch (score) {
      case 1: return mood1;
      case 2: return mood2;
      case 3: return mood3;
      case 4: return mood4;
      case 5: return mood5;
      default: return mood3;
    }
  }

  static Color moodBackgroundColor(int score) {
    return moodColor(score).withOpacity(0.1);
  }

  // ══════════════════════════════════════
  // CORES DE EMOÇÕES
  // ══════════════════════════════════════
  static const Map<String, Color> emotions = {
    'ansiedade': Color(0xFFF97316),
    'tristeza': Color(0xFF3B82F6),
    'raiva': Color(0xFFEF4444),
    'medo': Color(0xFF8B5CF6),
    'alegria': Color(0xFF10B981),
    'calma': Color(0xFF06B6D4),
    'frustração': Color(0xFFEC4899),
    'confusão': Color(0xFF6B7280),
  };
}