import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const Color scaffold = Color(0xFF080C14);
  static const Color surface = Color(0xFF0F1421);
  static const Color card = Color(0xFF141B2D);
  static const Color cardElevated = Color(0xFF1A2236);
  static const Color border = Color(0xFF1E2A40);
  static const Color divider = Color(0xFF0F1828);

  // Primary — Blue
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primarySurface = Color(0xFF172554);
  static const Color primaryMuted = Color(0xFF1E3A6E);

  // Success — Emerald
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successSurface = Color(0xFF022C22);

  // Warning — Amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningSurface = Color(0xFF1C1200);

  // Error — Red
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorSurface = Color(0xFF1C0505);

  // Accent — Violet
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleSurface = Color(0xFF1E1040);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF475569);
  static const Color textDisabled = Color(0xFF2D3748);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF080C14), Color(0xFF0A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGlowBlue = LinearGradient(
    colors: [Color(0xFF1A2845), Color(0xFF141B2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGreen = LinearGradient(
    colors: [Color(0xFF0D2E22), Color(0xFF141B2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowRed = LinearGradient(
    colors: [Color(0xFF2E0D0D), Color(0xFF141B2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowAmber = LinearGradient(
    colors: [Color(0xFF2E1E0D), Color(0xFF141B2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
