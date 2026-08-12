import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class VendorOtpVerificationScreen extends ConsumerStatefulWidget {
  const VendorOtpVerificationScreen({super.key});

  @override
  ConsumerState<VendorOtpVerificationScreen> createState() => _VendorOtpVerificationScreenState();
}

class _VendorOtpVerificationScreenState extends ConsumerState<VendorOtpVerificationScreen> {
  final _pinController = TextEditingController();
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _onVerify() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authApiRepositoryProvider).verifyOtp(_pinController.text.trim(), role: 'VENDOR');
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      context.go(VendorRoutePaths.businessRegistration);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification code.'), backgroundColor: AppColors.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Mobile OTP'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.sms_rounded, size: 64, color: AppColors.primaryRuby),
                const SizedBox(height: AppSpacing.lg),
                Text('Authentication Code Sent', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text('Please enter the 4-digit verification code sent to your partner mobile via WhatsApp & SMS.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xxl),
                CustomTextField(
                  label: '4-Digit OTP Code',
                  hintText: '7 7 8 8',
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  label: 'Confirm & Setup Boutique 👑',
                  isLoading: _isLoading,
                  onPressed: _onVerify,
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: _secondsRemaining > 0
                      ? Text('Resend OTP available in $_secondsRemaining seconds', style: textTheme.bodySmall)
                      : TextButton.icon(
                          onPressed: _startCountdown,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Resend Verification Code'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
