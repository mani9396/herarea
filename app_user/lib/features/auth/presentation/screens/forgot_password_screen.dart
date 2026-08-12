import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/shared.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _submitted = false;

  void _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      await ref.read(authApiRepositoryProvider).requestOtp(_inputController.text.trim(), role: 'CUSTOMER');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _submitted = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 650;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Recovery', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Navigate back to login',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
              child: Container(
                padding: EdgeInsets.all(isWide ? 40 : 0),
                decoration: isWide
                    ? BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      )
                    : null,
                child: _submitted ? _buildSuccessView(isDark) : _buildRecoveryForm(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Security lock emblem',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.25), width: 1.5),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryRuby, size: 36),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Restore Account Access',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontFamily: AppTypography.displayFont,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter your registered mobile number or email address. Our secure authentication server will dispatch a temporary recovery token.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          CustomTextField(
            label: 'Registered Mobile or Email',
            hintText: 'e.g. 9876543210 or name@example.com',
            helperText: 'You will receive an SMS or email containing a 4-digit code.',
            controller: _inputController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide your registered mobile number or email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          CustomButton(
            label: 'Dispatch Recovery OTP Token',
            icon: Icons.send_rounded,
            isLoading: _isLoading,
            onPressed: _onSubmit,
          ),
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: TextButton.icon(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryRuby),
              label: const Text(
                'Return to Sign In',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  color: AppColors.primaryRuby,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Verification email sent successfully',
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.success, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.success, size: 64),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Recovery OTP Dispatched',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontFamily: AppTypography.displayFont,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'We have transmitted a confidential security code to ${_inputController.text}. Please input this token on the upcoming screen to verify ownership.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                height: 1.6,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Enter OTP Verification',
          icon: Icons.verified_user_outlined,
          onPressed: () => context.push(RoutePaths.otpVerification),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => setState(() => _submitted = false),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            'Try a different contact method',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
