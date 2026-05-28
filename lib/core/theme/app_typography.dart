import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme get textTheme => TextTheme(
        displayLarge: _inter(32, FontWeight.w700, -1.2),
        displayMedium: _inter(28, FontWeight.w700, -0.8),
        displaySmall: _inter(24, FontWeight.w700, -0.5),
        headlineLarge: _inter(20, FontWeight.w700, -0.3),
        headlineMedium: _inter(18, FontWeight.w600, -0.2),
        headlineSmall: _inter(16, FontWeight.w600, -0.1),
        titleLarge: _inter(15, FontWeight.w600, 0),
        titleMedium: _inter(14, FontWeight.w500, 0),
        titleSmall: _inter(13, FontWeight.w500, 0, color: AppColors.textSecondary),
        bodyLarge: _inter(15, FontWeight.w400, 0),
        bodyMedium: _inter(14, FontWeight.w400, 0, color: AppColors.textSecondary),
        bodySmall: _inter(12, FontWeight.w400, 0, color: AppColors.textTertiary),
        labelLarge: _inter(13, FontWeight.w600, 0.1),
        labelMedium: _inter(11, FontWeight.w600, 0.5, color: AppColors.textSecondary),
        labelSmall: _inter(10, FontWeight.w600, 0.8, color: AppColors.textTertiary),
      );

  static TextStyle _inter(
    double size,
    FontWeight weight,
    double tracking, {
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: tracking,
      );

  // Utility styles
  static TextStyle get moneyLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get moneyMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get moneySmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: AppColors.textTertiary,
      );

  static TextStyle get tag => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      );
}
