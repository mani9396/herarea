import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:shared/shared.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final success = await ref.read(authApiRepositoryProvider).loginWithPassword(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          if (success) {
            context.go(AdminRoutePaths.dashboard);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed. Check your credentials.')));
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
                          Icons.lock_person_rounded,
                          size: 56,
                          color: AppColors.primaryRuby,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Portal Authorization',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFont,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralCharcoal,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Enter administrator security credentials to access the HER AREA Moderation Engine.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutralCharcoal.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      CustomTextField(
                        label: 'Admin ID / Official Email',
                        hintText: 'admin@herarea.in or Phone',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.isEmpty) ? 'Admin ID required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Security Passphrase', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 20,
                              color: AppColors.neutralCharcoal.withValues(alpha: 0.6),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Password must exceed 6 characters' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push(AdminRoutePaths.forgotPassword),
                          child: const Text(
                            'Reset Access Credential?',
                            style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomButton(
                        label: 'Proceed to 2FA Challenge 🛡️',
                        isLoading: _isLoading,
                        onPressed: _onSignIn,
                      ),
                      DemoLoginButtons(
                        onDemoSelected: (email, password) {
                          _emailController.text = email;
                          _passwordController.text = password;
                        },
                      ),
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
