import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About HER AREA', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              // Brand Emblem
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryRuby.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.diamond_rounded, size: 54, color: AppColors.accentGoldLight),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'HER AREA',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: AppTypography.displayFont,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isDark ? Colors.white : AppColors.primaryRuby,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'THE PREMIER O2O FASHION & CRAFTSMANSHIP PLATFORM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.accentGold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('v2.4.0 Production Edition', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Mission Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Our Vision & Story',
                      style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HER AREA was founded with a singular purpose: empowering women with verified, hyper-local discovery of neighborhood weaving houses, authentic Zardosi artisans, and luxury bridal couture studios.\n\nWe eliminate uncertainty by pairing curated digital showcases with authentic offline O2O experiences—bringing master consultants directly to your home for personalized measurements and consultations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Community Impact Metrics
              Row(
                children: [
                  _buildMetricCard('5,000+', 'Verified Artisans', isDark),
                  const SizedBox(width: 12),
                  _buildMetricCard('50,000+', 'Happy Brides', isDark),
                  const SizedBox(width: 12),
                  _buildMetricCard('4.9 ★', 'Platform Rating', isDark),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Social Links
              Text(
                'Connect With Our Styling Curators',
                style: theme.textTheme.titleMedium?.copyWith(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(context, Icons.camera_alt_outlined, 'Instagram'),
                  const SizedBox(width: 16),
                  _buildSocialButton(context, Icons.share_rounded, 'Pinterest'),
                  const SizedBox(width: 16),
                  _buildSocialButton(context, Icons.public_rounded, 'Website'),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryRuby),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon, String platform) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primaryRuby),
      label: Text(platform, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      backgroundColor: AppColors.blushPink.withValues(alpha: 0.4),
      side: const BorderSide(color: AppColors.primaryRuby, width: 0.8),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening HER AREA on $platform...'), behavior: SnackBarBehavior.floating));
      },
    );
  }
}
