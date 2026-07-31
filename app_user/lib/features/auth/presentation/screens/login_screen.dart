import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';
import 'package:her_area/data/mock/mock_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '9876543210');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _onLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 650)); // Simulate authentication dispatch
      if (mounted) {
        setState(() => _isLoading = false);
        context.push(RoutePaths.otpVerification);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            // Production Two-Column Desktop/Web Split Layout
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildBrandShowcasePanel(isDark),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                        child: _buildLoginForm(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Single Column Mobile/Tablet Layout
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                  child: _buildLoginForm(isDark),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Luxury Hero Medallion
          Semantics(
            label: 'HER AREA Diamond Emblem',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRuby.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: AppColors.primaryRuby,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Welcome to HER AREA',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontFamily: AppTypography.displayFont,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Discover curated saree boutiques, master maggam artisans, and private bridal studios across your neighborhood.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Mobile Number Input with Country Code Prefix Badge
          CustomTextField(
            label: 'Registered Mobile Number',
            hintText: 'Enter 10-digit number',
            helperText: 'We will send an SMS authentication token to verify this number.',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            prefixWidget: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                borderRadius: const BorderRadius.horizontal(left: AppSpacing.radiusMd),
                border: Border(
                  right: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              alignment: Alignment.center,
              width: 76,
              child: Text(
                '+91',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(RoutePaths.forgotPassword),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: const Text(
                'Forgot Password / Recovery?',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  color: AppColors.primaryRuby,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          CustomButton(
            label: 'Get Verification OTP',
            icon: Icons.security_rounded,
            isLoading: _isLoading,
            onPressed: _onLogin,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Divider Section
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'NEW TO HER AREA?',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          CustomButton(
            label: 'Create New Member Account',
            variant: ButtonVariant.outline,
            icon: Icons.person_add_outlined,
            onPressed: () => context.push(RoutePaths.signup),
          ),
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Text(
              'By signing in, you agree to our Terms of Service & Local Vendor Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11,
                color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandShowcasePanel(bool isDark) {
    final featuredStore = MockData.allStores[0];
    final featureReview = featuredStore.reviews[0];

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.all(48),
      child: Stack(
        children: [
          // Background ambient rings
          Positioned(
            right: -100,
            bottom: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.15), width: 2),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.accentGold, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.accentGoldLight, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFIED LOCAL O2O PLATFORM',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGoldLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Curated Elegance,\nTailored Locally.',
                style: TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Connect directly with trusted maggam specialists, bespoke wedding couturiers, and heirloom jewelers in your exact locality.",
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 16,
                  color: AppColors.surfaceVariantLight.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),

              // Glassmorphic Featured Review Card from Mock Data
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35), width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                        const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                        const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                        const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                        const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '5.0 VERIFIED REVIEW',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentGoldLight,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${featureReview.comment}"',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryRubyLight,
                          child: Text(
                            featureReview.userName[0],
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              featureReview.userName,
                              style: const TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Client at ${featuredStore.name}',
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  _buildFeatureBadge(Icons.radar_rounded, 'Exact Radius Search'),
                  const SizedBox(width: 24),
                  _buildFeatureBadge(Icons.event_seat_rounded, 'Private Trial Suites'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accentGoldLight, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
