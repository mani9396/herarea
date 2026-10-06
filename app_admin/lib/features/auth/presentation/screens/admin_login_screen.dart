import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:shared/shared.dart';
import 'dart:async';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@herarea.com');
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _onRequestOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final success = await ref.read(authApiRepositoryProvider).adminRequestOtp(
          _emailController.text.trim(),
          _nameController.text.trim(),
        );
        if (mounted) {
          if (success) {
            setState(() => _otpSent = true);
            _startCooldown();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent successfully if authorized.')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to request OTP. Check email or try again.')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _onVerifyOtp() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 6-digit OTP.')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authApiRepositoryProvider).adminVerifyOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _nameController.text.trim(),
      );
      if (mounted) {
        if (success) {
          context.go(AdminRoutePaths.dashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or expired OTP.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.security_rounded,
                          size: 56,
                          color: AppColors.primaryRuby,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'HER AREA ADMIN LOGIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFont,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralCharcoal,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Secure OTP Authorization Flow',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutralCharcoal.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      CustomTextField(
                        label: 'Admin Official Email',
                        hintText: 'admin@herarea.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        label: 'Admin Name',
                        hintText: 'Enter your authorized name',
                        controller: _nameController,
                        validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      if (_otpSent) ...[
                        const Text('One-Time Passcode (OTP)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: '123456',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: (_resendCooldown == 0 && !_isLoading) ? _onRequestOtp : null,
                            child: Text(
                              _resendCooldown > 0 ? 'Resend OTP in ${_resendCooldown}s' : 'Resend OTP',
                              style: TextStyle(
                                color: _resendCooldown > 0 ? Colors.grey : AppColors.primaryRuby,
                                fontWeight: FontWeight.w600, 
                                fontSize: 13
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CustomButton(
                          label: 'Verify OTP',
                          isLoading: _isLoading,
                          onPressed: _onVerifyOtp,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _resendCooldown = 0;
                              _cooldownTimer?.cancel();
                            });
                          },
                          child: const Text('Change Email', style: TextStyle(color: Colors.grey)),
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.lg),
                        CustomButton(
                          label: 'Send OTP',
                          isLoading: _isLoading,
                          onPressed: _onRequestOtp,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),
                      Divider(color: Colors.grey.shade300),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Text(
                          'Strictly restricted to HER AREA Platform Executives.\nUnauthorized access attempts are audited and logged.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
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
      ),
    );
  }
}
