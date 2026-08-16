import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/shared.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String purpose;

  const OtpVerificationScreen({
    super.key,
    required this.purpose,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _counter = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 0) {
        if (mounted) setState(() => _counter--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onVerify() async {
    setState(() => _isLoading = true);
    final otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter all 6 digits of the verification code.'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    final email = AuthApiRepository.lastAttemptedIdentifier;
    final result = await ref.read(authApiRepositoryProvider).verifyOtpForPurpose(email, otpCode, widget.purpose);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        if (widget.purpose == 'REGISTRATION') {
          context.push(RoutePaths.createPassword);
        } else if (widget.purpose == 'PASSWORD_RESET') {
          context.push(RoutePaths.resetPassword, extra: {'reset_token': result});
        }
      } else {
        // Clear all boxes
        for (var c in _controllers) { c.clear(); }
        if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired code. Please check your email and try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onResend() async {
    if (_isResending) return;
    final identifier = AuthApiRepository.lastAttemptedIdentifier;
    if (identifier.isEmpty) return;
    setState(() { _isResending = true; });
    await ref.read(authApiRepositoryProvider).requestOtp(identifier, role: 'CUSTOMER', purpose: widget.purpose);
    if (mounted) {
      setState(() {
        _isResending = false;
        _counter = 60;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new verification code has been sent to your email.'), backgroundColor: AppColors.success),
      );
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}***@$domain';
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 650;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Verification', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Go back',
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
                padding: EdgeInsets.all(isWide ? 42 : 0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Security shield icon',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.accentGold, size: 36),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Enter 6-Digit Verification Code',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontFamily: AppTypography.displayFont,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                              height: 1.5,
                            ),
                        children: [
                          const TextSpan(text: 'We sent a verification code to your email '),
                          TextSpan(
                            text: _maskEmail(AuthApiRepository.lastAttemptedIdentifier),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryRuby,
                              fontFamily: AppTypography.bodyFont,
                            ),
                          ),
                          const TextSpan(text: '. Check your inbox (and spam folder).'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Accessible PIN Input Row
                    Semantics(
                      label: '4 digit one time password entry field',
                      child: Row(
                        children: List.generate(6, (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index == 5 ? 0 : AppSpacing.sm),
                              child: AspectRatio(
                                aspectRatio: 0.95,
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.displayFont,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryRuby,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: isDark ? AppColors.surfaceVariantDark.withValues(alpha: 0.5) : AppColors.surfaceVariantLight.withValues(alpha: 0.3),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.primaryRuby, width: 2.5),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val.isNotEmpty && index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (val.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    CustomButton(
                      label: 'Verify Authentication Token',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: _onVerify,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Center(
                      child: _counter > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceVariantDark.withValues(alpha: 0.5) : AppColors.surfaceVariantLight.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 18, color: AppColors.accentGold),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Resend security token in ${_counter}s',
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton.icon(
                              onPressed: _onResend,
                              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                              icon: _isResending
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRuby))
                                  : const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryRuby),
                              label: const Text(
                                'Resend Verification Code',
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFont,
                                  color: AppColors.primaryRuby,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        child: Text(
                          'Wrong email? Go back and change it',
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
