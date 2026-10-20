import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:shared/shared.dart';

/// Interactive modal dialog for secure, permanent customer account deletion.
///
/// Follows regulatory and application security best practices:
/// 1. Explicit warnings of permanence and data purges.
/// 2. Transparent disclosure of legal audit retention (anonymized bookings).
/// 3. Mandatory confirmation checkbox.
/// 4. Password re-authentication challenge.
/// 5. Async processing with loading indicator and retryable error handling.
/// 6. Immediate cache invalidation, push token deregistration, and redirect to login.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _confirmed = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty || !_confirmed || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authRepo = ref.read(authApiRepositoryProvider);
      final result = await authRepo.deleteAccount(
        password: password,
        confirmation: true,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isLoading = false;
        });
        // Invalidate active application caches
        ref.invalidate(userProfileProvider);
        ref.invalidate(favoritesProvider);
        ref.invalidate(notificationsProvider);

        // Close the dialog if can pop
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show confirmation banner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message']?.toString() ?? 'Your account has been permanently deleted.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryRuby,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate back to login screen
        try {
          context.go(RoutePaths.login);
        } catch (_) {}
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message']?.toString() ?? 'Account deletion failed. Please check your password.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canSubmit = _confirmed && _passwordController.text.isNotEmpty && !_isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Danger Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.errorRed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Delete Account Permanently',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Danger Warning Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Warning: This action is permanent and cannot be undone.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.errorRed,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Once deleted, your account will be permanently removed. You will not be able to log in or recover your account.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Detailed explanation of what will and won't be deleted
              const Text(
                'What happens when you delete your account:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletItem(
                Icons.person_remove_rounded,
                'Your profile, email, phone number, and authentication credentials will be permanently erased.',
                isDark,
              ),
              _buildBulletItem(
                Icons.favorite_border_rounded,
                'All saved wishlist items, favorites, and browsing history will be permanently cleared.',
                isDark,
              ),
              _buildBulletItem(
                Icons.rate_review_outlined,
                'Personal reviews, notifications, and active device push tokens will be purged.',
                isDark,
              ),
              _buildBulletItem(
                Icons.receipt_long_rounded,
                'Legally required records: Past appointment bookings or receipts are disassociated and anonymized for vendor tax and audit compliance, with all personal identifiers removed.',
                isDark,
              ),
              const SizedBox(height: AppSpacing.md),

              // Re-authentication Password Field
              const Text(
                'Confirm your password to proceed:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('delete_account_password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_isLoading,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter your account password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Explicit Confirmation Checkbox
              InkWell(
                onTap: _isLoading
                    ? null
                    : () => setState(() => _confirmed = !_confirmed),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          key: const Key('delete_account_checkbox'),
                          value: _confirmed,
                          onChanged: _isLoading ? null : (v) => setState(() => _confirmed = v ?? false),
                          activeColor: AppColors.errorRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'I explicitly confirm that I want to permanently delete my HER AREA account and eligible personal data.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Error Display Banner (if failed)
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('delete_account_cancel_button'),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    key: const Key('delete_account_confirm_button'),
                    onPressed: canSubmit ? _handleDelete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.errorRed.withValues(alpha: 0.3),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: canSubmit ? 2 : 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Permanently Delete',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
