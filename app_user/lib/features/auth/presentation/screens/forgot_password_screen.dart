import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/features/auth/presentation/widgets/auth_ui_components.dart';
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
      final email = _inputController.text.trim();
      final success = await ref.read(authApiRepositoryProvider).requestOtp(
            email,
            role: 'CUSTOMER',
            purpose: 'PASSWORD_RESET',
          );
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ref.read(pendingRegistrationProvider.notifier).state = PendingRegistration(
            fullName: '',
            email: email,
            dateOfBirth: '',
            gender: '',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification code sent to $email. Please enter it below.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          context.push(RoutePaths.otpVerification, extra: {
            'purpose': 'PASSWORD_RESET',
            'email': email,
          });
        } else {
          final err = AuthApiRepository.lastErrorMessage;
          final displayMessage = (err.isNotEmpty && !err.toLowerCase().contains('unexpected network'))
              ? err
              : 'No account found with this email address. Please check your email or sign up.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      displayMessage,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Account Recovery',
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          tooltip: 'Navigate back to login',
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AuthTokens.backgroundGradient,
        ),
        child: Stack(
          children: [
            const AuthBackgroundDecoration(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        // Prominent official logo
                        const AuthBrandHeader(
                          compact: true,
                          customHeadline: 'Secure password recovery for your HER AREA account',
                        ),
                        const SizedBox(height: 28),

                        // Form Card
                        AuthFormCard(
                          child: _submitted ? _buildSuccessView(isDark) : _buildRecoveryForm(isDark),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AuthTokens.brandPink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AuthTokens.brandPink.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AuthTokens.brandMagenta, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Restore your account access',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12.5,
                        color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Enter your registered email address below. We will send a secure 6-digit OTP code to verify your identity.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),

          // Email Input
          AuthTextField(
            label: 'Registered Email Address',
            hintText: 'e.g. name@example.com',
            helperText: 'You will receive a 6-digit code at this email address.',
            controller: _inputController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide your registered email address';
              }
              final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Dispatch OTP Button
          AuthPrimaryButton(
            label: 'Dispatch Recovery OTP Token',
            icon: Icons.send_rounded,
            isLoading: _isLoading,
            onPressed: _onSubmit,
          ),
          const SizedBox(height: 18),

          Center(
            child: TextButton.icon(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AuthTokens.brandMagenta),
              label: const Text(
                'Return to Sign In',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  color: AuthTokens.brandMagenta,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.success, size: 48),
        ),
        const SizedBox(height: 18),
        Text(
          'Recovery OTP Dispatched',
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We have sent a 6-digit verification code to ${_inputController.text}. Please check your inbox and spam folder.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 13,
            color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Enter OTP Verification',
          icon: Icons.verified_user_outlined,
          onPressed: () {
            ref.read(pendingRegistrationProvider.notifier).state = PendingRegistration(
              fullName: '',
              email: _inputController.text.trim(),
              dateOfBirth: '',
              gender: '',
            );
            context.push(RoutePaths.otpVerification, extra: {'purpose': 'PASSWORD_RESET'});
          },
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => setState(() => _submitted = false),
          style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
          child: Text(
            'Try a different contact email',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              color: AuthTokens.brandMagenta,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
