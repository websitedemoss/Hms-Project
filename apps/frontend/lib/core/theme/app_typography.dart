import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Clinical Typography System for Medicare Hospital & I.C.U
/// - Headings & Brand: Plus Jakarta Sans (Executive clinical SaaS authority)
/// - Body & Labels: Inter (Dense clinical readability & accessibility)
/// - Identifiers & Metrics: JetBrains Mono (Tabular numerals for MRNs, vitals, slots)
class AppTypography {
  // Headings & Display (Plus Jakarta Sans)
  static TextStyle displayLarge({Color color = AppColors.textPrimaryLight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: color,
        height: 1.2,
      );

  static TextStyle displayMedium({Color color = AppColors.textPrimaryLight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: color,
        height: 1.25,
      );

  static TextStyle headingLarge({Color color = AppColors.textPrimaryLight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color,
        height: 1.3,
      );

  static TextStyle headingMedium({Color color = AppColors.textPrimaryLight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
        height: 1.35,
      );

  static TextStyle headingSmall({Color color = AppColors.textPrimaryLight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
        height: 1.4,
      );

  // Body & Paragraphs (Inter)
  static TextStyle bodyLarge({Color color = AppColors.textPrimaryLight}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color color = AppColors.textSecondaryLight}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.45,
      );

  static TextStyle bodySmall({Color color = AppColors.textSecondaryLight}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // Labels & Actions (Plus Jakarta Sans / Inter)
  static TextStyle labelLarge({Color color = AppColors.textPrimaryLight, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: weight,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium({Color color = AppColors.textSecondaryLight, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: weight,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle labelSmall({Color color = AppColors.textSecondaryLight}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color,
      );

  // Monospaced Tabular Figures (JetBrains Mono)
  static TextStyle monoMrn({Color color = AppColors.primary, double fontSize = 12}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color,
      );

  static TextStyle monoKpi({Color color = AppColors.textPrimaryLight, double fontSize = 28}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle monoCode({Color color = AppColors.textSecondaryLight, double fontSize = 11}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
