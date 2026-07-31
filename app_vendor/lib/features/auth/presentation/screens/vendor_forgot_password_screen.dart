import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class VendorForgotPasswordScreen extends StatefulWidget {
  const VendorForgotPasswordScreen({super.key});

  @override
  State<VendorForgotPasswordScreen> createState() => _VendorForgotPasswordScreenState();
}

class _VendorForgotPasswordScreenState extends State<VendorForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _isSent = false;
  bool _isLoading = false;

  void _onReset() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSent = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Partner PIN'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _isSent ? _buildSuccess(textTheme) : _buildForm(textTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(TextTheme textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.primaryRuby),
        const SizedBox(height: AppSpacing.lg),
        Text('Recover Your Account', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text('We will send a temporary one-time PIN reset link to your registered business mobile number.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        CustomTextField(
          label: 'Registered Business Phone Number',
          hintText: 'Enter 10-digit mobile number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_rounded,
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomButton(
          label: 'Send Reset Link 🔒',
          isLoading: _isLoading,
          onPressed: _onReset,
        ),
      ],
    );
  }

  Widget _buildSuccess(TextTheme textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 72, color: AppColors.success),
        const SizedBox(height: AppSpacing.lg),
        Text('Reset Instructions Dispatched', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text('Check your WhatsApp and SMS inbox for secure instructions to choose a new 4-digit partner PIN.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Return to Login',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
