import 'package:flutter/material.dart';

class AppColors {
  // Brand & Clinical Identity
  static const Color primary = Color(0xFF1E3A8A); // Deep Clinical Navy
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF0D9488); // Medical Teal
  static const Color secondaryLight = Color(0xFF14B8A6);

  // Surface & Neutrals
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate-50
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B); // Slate-800
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200
  static const Color borderDark = Color(0xFF334155); // Slate-700

  // Text Hierarchy
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate-900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate-500
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Clinical Status Badges
  static const Color success = Color(0xFF10B981); // Emerald (Available/Normal)
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber (Triage/Waiting)
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444); // Crimson (Critical/ICU/Occupied)
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7); // Sky Blue (Scheduled/OPD)
  static const Color infoLight = Color(0xFFE0F2FE);

  // Wards & Bed Categories
  static const Color icuBadge = Color(0xFFDC2626); // Crimson
  static const Color generalWardBadge = Color(0xFF2563EB); // Royal Blue
  static const Color privateWardBadge = Color(0xFF7C3AED); // Purple
}
