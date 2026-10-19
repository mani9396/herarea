import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

enum ForgotPasswordStep {
  requestEmail,
  verifyOtp,
  resetPassword,
  success,
}

class VendorForgotPasswordScreen extends ConsumerStatefulWidget {
  const VendorForgotPasswordScreen({super.key});

  @override
  ConsumerState<VendorForgotPasswordScreen> createState() => _VendorForgotPasswordScreenState();
}

class _VendorForgotPasswordScreenState extends ConsumerState<VendorForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ForgotPasswordStep _currentStep = ForgotPasswordStep.requestEmail;
  String? _resetToken;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Step 1: Dispatch Recovery OTP ---
  void _onRequestOtp() async {
    final email = _emailController.text.trim();
    final emailErr = ValidationHelpers.validateEmail(email);
    if (emailErr != null) {
      setState(() => _errorMessage = emailErr);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authApiRepositoryProvider).requestOtp(
      email,
      role: 'VENDOR',
      purpose: 'PASSWORD_RESET',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _currentStep = ForgotPasswordStep.verifyOtp;
        _errorMessage = null;
      });
    } else {
      final err = AuthApiRepository.lastErrorMessage;
      setState(() {
        _errorMessage = (err.isNotEmpty && !err.toLowerCase().contains('unexpected network'))
            ? err
            : 'No vendor account found with this email. Please verify your email address.';
      });
    }
  }

  // --- Step 2: Verify Recovery OTP ---
  void _onVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final token = await ref.read(authApiRepositoryProvider).verifyOtpForPurpose(
      email,
      otp,
      'PASSWORD_RESET',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (token != null && token.isNotEmpty) {
      setState(() {
        _resetToken = token;
        _currentStep = ForgotPasswordStep.resetPassword;
        _errorMessage = null;
      });
    } else {
      final err = AuthApiRepository.lastErrorMessage;
      setState(() {
        _errorMessage = (err.isNotEmpty && !err.toLowerCase().contains('unexpected network'))
            ? err
            : 'Invalid or expired verification code. Please check and try again.';
      });
    }
  }

  // --- Step 3: Set New Password ---
  void _onResetPassword() async {
    final passErr = ValidationHelpers.validatePassword(_passwordController.text);
    if (passErr != null) {
      setState(() => _errorMessage = passErr);
      return;
    }

    if (_passwordController.text.length < 8 ||
        !_passwordController.text.contains(RegExp(r'[A-Z]')) ||
        !_passwordController.text.contains(RegExp(r'[0-9]'))) {
      setState(() => _errorMessage = 'Password must be at least 8 chars with 1 uppercase letter and 1 number.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final success = await ref.read(authApiRepositoryProvider).resetPassword(
      email: email,
      resetToken: _resetToken ?? '',
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _currentStep = ForgotPasswordStep.success;
        _errorMessage = null;
      });
    } else {
      final err = AuthApiRepository.lastErrorMessage;
      setState(() {
        _errorMessage = (err.isNotEmpty && !err.toLowerCase().contains('unexpected network'))
            ? err
            : 'Failed to reset password. The reset link may have expired.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Partner Password Recovery'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep == ForgotPasswordStep.verifyOtp) {
              setState(() => _currentStep = ForgotPasswordStep.requestEmail);
            } else if (_currentStep == ForgotPasswordStep.resetPassword) {
              setState(() => _currentStep = ForgotPasswordStep.verifyOtp);
            } else {
              context.go(VendorRoutePaths.login);
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildCurrentStep(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case ForgotPasswordStep.requestEmail:
        return _buildEmailStep(context);
      case ForgotPasswordStep.verifyOtp:
        return _buildOtpStep(context);
      case ForgotPasswordStep.resetPassword:
        return _buildResetPasswordStep(context);
      case ForgotPasswordStep.success:
        return _buildSuccessStep(context);
    }
  }

  // Step 1: Email Input
  Widget _buildEmailStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryRuby,
            child: Icon(Icons.lock_reset_rounded, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Recover Partner Account',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Enter your registered official business email address. We will send a secure 6-digit OTP code to verify your identity.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.neutralCharcoal.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_errorMessage != null) ...[
          ErrorView(title: 'Recovery Error', message: _errorMessage!, onRetry: null),
          const SizedBox(height: AppSpacing.md),
        ],
        CustomTextField(
          label: 'Registered Business Email',
          hintText: 'partner@example.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomButton(
          label: 'Send Recovery Code 🔒',
          isLoading: _isLoading,
          onPressed: _onRequestOtp,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryRuby),
            label: const Text('Return to Login', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // Step 2: OTP Input
  Widget _buildOtpStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRuby.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.primaryRuby),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Enter 6-Digit Code',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'We have sent a verification code to ${_emailController.text.trim()}. This code is valid for 5 minutes.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.neutralCharcoal.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_errorMessage != null) ...[
          ErrorView(title: 'Verification Error', message: _errorMessage!, onRetry: null),
          const SizedBox(height: AppSpacing.md),
        ],
        CustomTextField(
          label: '6-Digit Verification Code',
          hintText: 'e.g. 123456',
          controller: _otpController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.security_rounded,
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomButton(
          label: 'Verify Code 🛡️',
          isLoading: _isLoading,
          onPressed: _onVerifyOtp,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _onRequestOtp,
              child: const Text('Resend Code', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => setState(() => _currentStep = ForgotPasswordStep.requestEmail),
              child: const Text('Change Email', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: New Password Input
  Widget _buildResetPasswordStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.accentGold,
            child: Icon(Icons.lock_open_rounded, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Create New Password',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Please choose a new, secure password for your partner account.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.neutralCharcoal.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_errorMessage != null) ...[
          ErrorView(title: 'Password Error', message: _errorMessage!, onRetry: null),
          const SizedBox(height: AppSpacing.md),
        ],
        CustomTextField(
          label: 'New Password',
          hintText: 'Min 8 chars, 1 uppercase, 1 number',
          controller: _passwordController,
          isPassword: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Confirm New Password',
          hintText: 'Re-enter your new password',
          controller: _confirmPasswordController,
          isPassword: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomButton(
          label: 'Update Password 🚀',
          isLoading: _isLoading,
          onPressed: _onResetPassword,
        ),
      ],
    );
  }

  // Step 4: Success View
  Widget _buildSuccessStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.success),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Password Reset Complete! 🎉',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your partner studio password has been updated successfully. You can now sign in using your registered email or mobile number.',
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600], height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Proceed to Login ➡️',
          onPressed: () => context.go(VendorRoutePaths.login),
        ),
      ],
    );
  }
}
