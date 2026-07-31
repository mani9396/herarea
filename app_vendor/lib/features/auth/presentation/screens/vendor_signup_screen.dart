import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class VendorSignupScreen extends StatefulWidget {
  const VendorSignupScreen({super.key});

  @override
  State<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends State<VendorSignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  void _onRegister() {
    final nameErr = ValidationHelpers.validateRequired(_nameController.text, 'Owner Name');
    final phoneErr = ValidationHelpers.validatePhoneNumber(_phoneController.text);
    if (nameErr != null || phoneErr != null) {
      setState(() => _errorMessage = nameErr ?? phoneErr);
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
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.push(VendorRoutePaths.otpVerification);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Partner Registration'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
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
                Text('We will verify your phone via OTP in the next step.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: AppSpacing.lg),
                if (_errorMessage != null) ...[
                  ErrorView(title: 'Validation Error', message: _errorMessage!, onRetry: null),
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
                  label: 'Business Mobile Number (WhatsApp Supported)',
                  hintText: '10-digit number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'GSTIN / Business Registration ID (Optional)',
                  hintText: 'e.g. 36AAAAA0000A1Z5',
                  controller: _gstController,
                  prefixIcon: Icons.receipt_long_outlined,
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
                  label: 'Proceed to OTP Verification ➡️',
                  isLoading: _isLoading,
                  onPressed: _onRegister,
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text("Already registered? ", style: textTheme.bodyMedium),
                    InkWell(
                      onTap: () => context.pop(),
                      child: Text("Login Here", style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
