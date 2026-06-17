import 'package:flutter/material.dart';

/// Music Director — **Sabi-Sabi blue** brand alignment (see Sabi-Sabi `SabiColors`).
abstract final class AppColors {
  // --- Surfaces (Sabi OLED + glass stack) ---
  static const Color background = Color(0xFF000000); // OLED black
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2A4A5C); // blue-tinted divider

  // --- Sabi blue accents ---
  /// Primary brand blue — links, selected nav, focus (#0096D6)
  static const Color accentPrimary = Color(0xFF0096D6);
  /// Lighter blue for gradient end (#4DB8E8)
  static const Color accentSecondary = Color(0xFF4DB8E8);
  /// Border / highlight cyan (#00BBFF) — chips, glow accents
  static const Color accentTertiary = Color(0xFF00BBFF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);

  /// CTA / hero buttons — Sabi blue gradient (dark → mid → light)
  static const LinearGradient ctaGradient = LinearGradient(
    colors: [
      Color(0xFF0077AB), // sabiBlueDark
      Color(0xFF0096D6), // sabiBlue
      Color(0xFF4DB8E8), // sabiBlueLight
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient titleGradient = LinearGradient(
    colors: [
      Color(0xFF0077AB),
      Color(0xFF0096D6),
      Color(0xFF00BBFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
