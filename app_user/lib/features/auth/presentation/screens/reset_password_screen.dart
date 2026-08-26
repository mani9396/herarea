import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/shared.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  // Validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  bool _isPasswordStrong() {
    return _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;
  }

  void _onSubmit() async {
    if (!_isPasswordStrong()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please ensure your new password meets all strength requirements.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (widget.resetToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid reset session. Please try again.'), backgroundColor: AppColors.error),
        );
        context.go(RoutePaths.forgotPassword);
        return;
      }

      setState(() => _isLoading = true);

      // Email was entered in the forgot password screen and should be in the pendingRegistrationProvider or lastAttemptedIdentifier
      final pendingReg = ref.read(pendingRegistrationProvider);
      final email = pendingReg?.email ?? AuthApiRepository.lastAttemptedIdentifier;

      final success = await ref.read(authApiRepositoryProvider).resetPassword(
        email: email,
        resetToken: widget.resetToken,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          // Clear any leftover data
          ref.read(pendingRegistrationProvider.notifier).state = null;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully. Please sign in.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(RoutePaths.login);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update password. Your link may have expired.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 650;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
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
                child: _buildForm(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
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
              child: const Icon(Icons.password_rounded, color: AppColors.primaryRuby, size: 36),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Create New Password',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontFamily: AppTypography.displayFont,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your identity has been verified. Please create a new password to restore access to your account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          CustomTextField(
            label: 'New Password',
            hintText: 'Enter a strong password',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please create a password';
              if (!_isPasswordStrong()) return 'Please meet all password requirements';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Strength indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark.withValues(alpha: 0.5) : AppColors.surfaceVariantLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements:',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRequirementRow('Minimum 8 characters', _hasMinLength),
                const SizedBox(height: 8),
                _buildRequirementRow('One uppercase letter', _hasUppercase),
                const SizedBox(height: 8),
                _buildRequirementRow('One lowercase letter', _hasLowercase),
                const SizedBox(height: 8),
                _buildRequirementRow('One number', _hasNumber),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          CustomTextField(
            label: 'Confirm New Password',
            hintText: 'Re-enter your password',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: Icons.lock_reset_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          CustomButton(
            label: 'Update Password',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isLoading,
            onPressed: _onSubmit,
          ),
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: TextButton(
              onPressed: () => context.go(RoutePaths.login),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                'Cancel and return to Sign In',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isMet ? AppColors.success : (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 13,
            color: isMet 
                ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textHighDark : AppColors.textHighLight)
                : (Theme.of(context).brightness == Brightness.dark ? AppColors.textMediumDark : AppColors.textMediumLight),
          ),
        ),
      ],
    );
  }
}
