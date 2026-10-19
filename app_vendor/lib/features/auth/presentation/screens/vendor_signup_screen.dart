import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

enum VendorSignupStep {
  fillDetails,
  verifyEmailOtp,
}

class VendorSignupScreen extends ConsumerStatefulWidget {
  const VendorSignupScreen({super.key});

  @override
  ConsumerState<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends ConsumerState<VendorSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  VendorSignupStep _currentStep = VendorSignupStep.fillDetails;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- Step 1: Request Email Verification Code ---
  void _onRequestOtp() async {
    final nameErr = ValidationHelpers.validateRequired(_nameController.text, 'Owner Name');
    final emailErr = ValidationHelpers.validateEmail(_emailController.text);
    final phoneErr = ValidationHelpers.validatePhoneNumber(_phoneController.text);
    final passErr = ValidationHelpers.validatePassword(_passwordController.text);

    if (nameErr != null || emailErr != null || phoneErr != null || passErr != null) {
      setState(() => _errorMessage = nameErr ?? emailErr ?? phoneErr ?? passErr);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'You must agree to Partner O2O Terms & Conditions.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    final success = await ref.read(authApiRepositoryProvider).requestOtp(
      email,
      role: 'VENDOR',
      purpose: 'REGISTRATION',
      fullName: name,
      phoneNumber: phone,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _currentStep = VendorSignupStep.verifyEmailOtp;
        _errorMessage = null;
      });
    } else {
      final err = AuthApiRepository.lastErrorMessage;
      setState(() {
        _errorMessage = (err.isNotEmpty && !err.toLowerCase().contains('unexpected network'))
            ? err
            : 'Failed to send verification code. Please check your email and mobile number.';
      });
    }
  }

  // --- Step 2: Complete Registration with Verified OTP ---
  void _onCompleteRegistration() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification code sent to your email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final errorMessage = await ref.read(authApiRepositoryProvider).vendorSelfRegister(
      ownerName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      context.go(VendorRoutePaths.login);
    } else {
      setState(() => _errorMessage = errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == VendorSignupStep.fillDetails
            ? 'New Partner Registration'
            : 'Verify Business Email'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep == VendorSignupStep.verifyEmailOtp) {
              setState(() {
                _currentStep = VendorSignupStep.fillDetails;
                _errorMessage = null;
              });
            } else {
              context.go(VendorRoutePaths.welcome);
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _currentStep == VendorSignupStep.fillDetails
                ? _buildFillDetailsStep(context)
                : _buildVerifyOtpStep(context),
          ),
        ),
      ),
    );
  }

  // --- Step 1 View: Account Credentials & Details ---
  Widget _buildFillDetailsStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentGold),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.accentGoldDark, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Join 300+ verified artisans & designer boutiques in Hyderabad with zero onboarding commission!',
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Owner Basic Details', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        Text('Set up your account credentials.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: AppSpacing.lg),
        if (_errorMessage != null) ...[
          ErrorView(title: 'Registration Error', message: _errorMessage!, onRetry: null),
          const SizedBox(height: AppSpacing.md),
        ],
        CustomTextField(
          label: 'Business Owner / Principal Designer Name',
          hintText: 'e.g. Tejasi Nambiar',
          controller: _nameController,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Official Business Email',
          hintText: 'partner@example.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Business Mobile Number',
          hintText: '10-digit number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Secure Password',
          hintText: 'Min 8 chars, 1 uppercase, 1 number',
          controller: _passwordController,
          isPassword: true,
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Confirm Password',
          hintText: 'Re-enter your password',
          controller: _confirmPasswordController,
          isPassword: true,
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              activeColor: AppColors.primaryRuby,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to HER AREA ',
                    style: textTheme.bodySmall,
                    children: [
                      TextSpan(text: 'Partner Terms', style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                      const TextSpan(text: ' & '),
                      TextSpan(text: 'Zero Commission Policy', style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomButton(
          label: 'Verify Email & Continue ➡️',
          isLoading: _isLoading,
          onPressed: _onRequestOtp,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text("Already registered? ", style: textTheme.bodyMedium),
            InkWell(
              onTap: () => context.go(VendorRoutePaths.login),
              child: Text("Login Here", style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 2 View: Email OTP Verification ---
  Widget _buildVerifyOtpStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
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
          'Verify Business Email',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'We have dispatched a 6-digit verification code to ${_emailController.text.trim()}. This code expires in 5 minutes.',
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
          label: 'Complete Registration 🚀',
          isLoading: _isLoading,
          onPressed: _onCompleteRegistration,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isLoading ? null : _onRequestOtp,
              child: const Text('Resend Code', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = VendorSignupStep.fillDetails;
                  _errorMessage = null;
                });
              },
              child: const Text('Edit Details', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}
