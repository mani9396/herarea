import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Identity (Luxury Ruby & Crimson)
  static const Color primaryRuby = Color(0xFFB03052);
  static const Color primaryRubyLight = Color(0xFFC75170);
  static const Color primaryRubyDark = Color(0xFF801F37);

  // Accent & Attainment (Verified Gold & Amber)
  static const Color accentGold = Color(0xFFEAA636);
  static const Color accentGoldLight = Color(0xFFF0BD68);
  static const Color accentGoldDark = Color(0xFFB87B19);

  // Surfaces — Light Mode (Luxury Blush Pink & Pearl)
  static const Color backgroundLight = Color(0xFFFFF7F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFFBECEF);
  static const Color borderLight = Color(0xFFE5D0D5);

  // Surfaces — Dark Mode (Midnight Ruby & Deep Obsidian)
  static const Color backgroundDark = Color(0xFF140D10);
  static const Color surfaceDark = Color(0xFF1E1418);
  static const Color surfaceVariantDark = Color(0xFF2E1C23);
  static const Color borderDark = Color(0xFF452B35);

  // Typography Neutrals
  static const Color textHighLight = Color(0xFF21171A);
  static const Color textMediumLight = Color(0xFF6A575D);
  static const Color textDisabledLight = Color(0xFFAD9C9F);

  static const Color textHighDark = Color(0xFFFAF2F4);
  static const Color textMediumDark = Color(0xFFC4B3B8);
  static const Color textDisabledDark = Color(0xFF635257);

  // Functional Status Feedback
  static const Color success = Color(0xFF2A9D8F);
  static const Color warning = Color(0xFFE76F51);
  static const Color error = Color(0xFFD62828);
  static const Color info = Color(0xFF457B9D);

  // Cross-Theme Compat Tokens
  static const Color blushPink = Color(0xFFFBECEF);
  static const Color neutralCharcoal = Color(0xFF21171A);
  static const Color errorRed = Color(0xFFD62828);

  // Gradients for Luxury Aesthetics
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB03052), Color(0xFF801F37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF0BD68), Color(0xFFEAA636)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
