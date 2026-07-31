import 'package:flutter/material.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/theme/app_spacing.dart';

class AppTheme {
  AppTheme._();

  // Backward-compatible alias bindings for existing prototype presentation screens
  static const Color primaryRuby = AppColors.primaryRuby;
  static const Color accentGold = AppColors.accentGold;
  static const Color blushPink = AppColors.surfaceVariantLight;
  static const Color neutralCharcoal = AppColors.textHighLight;
  static const Color successGreen = AppColors.success;
  static const Color errorRed = AppColors.error;

  static ThemeData get lightTheme => _buildTheme(isDark: false);
  static ThemeData get darkTheme => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final colorScheme = isDark
        ? ColorScheme.fromSeed(
            seedColor: AppColors.primaryRuby,
            brightness: Brightness.dark,
            primary: AppColors.primaryRubyLight,
            secondary: AppColors.accentGold,
            surface: AppColors.surfaceDark,
            error: AppColors.error,
          )
        : ColorScheme.fromSeed(
            seedColor: AppColors.primaryRuby,
            brightness: Brightness.light,
            primary: AppColors.primaryRuby,
            secondary: AppColors.accentGold,
            surface: AppColors.surfaceLight,
            error: AppColors.error,
          );

    final textTheme = AppTypography.buildTextTheme(isDark: isDark);
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      textTheme: textTheme,

      // AppBar Customization
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: AppSpacing.elevationNone,
        centerTitle: false,
        scrolledUnderElevation: AppSpacing.elevationLow,
        iconTheme: IconThemeData(color: isDark ? AppColors.textHighDark : AppColors.textHighLight),
        titleTextStyle: textTheme.titleLarge,
      ),

      // Card Component Styling
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        elevation: AppSpacing.elevationLow,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
      ),

      // ElevatedButton Styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: AppSpacing.elevationNone,
          padding: AppSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),

      // OutlinedButton Styling
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: AppSpacing.buttonPadding,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
      ),

      // NavigationBar Styling for M3 bottom bars
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight,
        elevation: AppSpacing.elevationMedium,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(textTheme.labelSmall),
      ),

      // Bottom Sheet Styling
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: AppSpacing.elevationHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
