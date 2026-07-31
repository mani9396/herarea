import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() => _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  final _emailController = TextEditingController(text: 'admin@herarea.in');
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _submitted ? _buildSuccessState() : _buildInputForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(Icons.mark_email_read_rounded, size: 52, color: AppColors.primaryRuby),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Credential Recovery Request',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Submit your verified corporate admin email. Our platform governance bot will send an encrypted temporary access link.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.neutralCharcoal.withValues(alpha: 0.7), height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomTextField(
          label: 'Corporate Admin Email',
          hintText: 'admin@herarea.in',
          controller: _emailController,
        ),
        const SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Transmit Recovery Link 📨',
          onPressed: () => setState(() => _submitted = true),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Recovery Token Transmitted',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'An urgent security challenge link has been routed to ${_emailController.text}. Please complete verification within 15 minutes.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.neutralCharcoal.withValues(alpha: 0.7), height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Return to Login Console',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
