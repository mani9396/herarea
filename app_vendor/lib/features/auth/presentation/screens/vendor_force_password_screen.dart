import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class VendorForcePasswordChangeScreen extends ConsumerStatefulWidget {
  const VendorForcePasswordChangeScreen({super.key});

  @override
  ConsumerState<VendorForcePasswordChangeScreen> createState() => _VendorForcePasswordChangeScreenState();
}

class _VendorForcePasswordChangeScreenState extends ConsumerState<VendorForcePasswordChangeScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _onChangePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiEndpoints.vendorForcePasswordChange,
        body: {
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmPasswordController.text,
        },
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] == true || (response['status_code'] as int? ?? 200) < 300) {
        // Clear mustChangePassword flag locally
        final user = ref.read(authSessionProvider).currentUser;
        if (user != null) {
          ref.read(authSessionProvider.notifier).setUser(user.copyWith(mustChangePassword: false));
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.'), backgroundColor: AppColors.success),
        );
        context.go(VendorRoutePaths.dashboard);
      } else {
        setState(() => _errorMessage = response['error'] ?? 'Failed to change password.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Update Temporary Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CustomCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      radius: 28, 
                      backgroundColor: AppColors.primaryRuby, 
                      child: Icon(Icons.security_rounded, color: Colors.white, size: 30)
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Action Required', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('For your security, you must update the temporary password provided by the platform administrator before accessing your dashboard.', 
                       style: textTheme.bodyMedium?.copyWith(color: AppColors.neutralCharcoal.withValues(alpha: 0.7))),
                  const SizedBox(height: AppSpacing.xl),
                  
                  if (_errorMessage != null) ...[
                    ErrorView(title: 'Update Failed', message: _errorMessage!, onRetry: null),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  CustomTextField(
                    label: 'Temporary Password',
                    hintText: 'Enter current temporary password',
                    controller: _oldPasswordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    label: 'New Password',
                    hintText: 'Enter a strong new password',
                    controller: _newPasswordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    label: 'Confirm New Password',
                    hintText: 'Re-enter your new password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  CustomButton(
                    label: 'Update & Continue',
                    isLoading: _isLoading,
                    onPressed: _onChangePassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
