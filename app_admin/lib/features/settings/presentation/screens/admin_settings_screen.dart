import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:shared/shared.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  void _onSignOut(BuildContext context, WidgetRef ref) {
    CustomDialog.show(
      context: context,
      title: 'Terminate Admin Console Session? 🔒',
      description: 'You are about to lock your superadmin authentication credentials. Any non-broadcasted drafts will be cleared from session memory.',
      confirmText: 'Sign Out & Lock',
      cancelText: 'Remain Online',
      onConfirm: () {
        ref.read(authApiRepositoryProvider).logout();
        context.go(AdminRoutePaths.login);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Settings & System Configuration'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.4))),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(color: AppColors.primaryRuby, shape: BoxShape.circle, border: Border.all(color: AppColors.accentGold, width: 2)),
                          alignment: Alignment.center,
                          child: const Text('D', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Administrator Profile', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                              const SizedBox(height: 2),
                              const Text('Superadmin Governance HQ', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                child: const Text('SUPERADMIN FOUNDER ACCESS TIER', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                          label: const Text('Edit Profile'),
                          onPressed: () => context.push(AdminRoutePaths.adminProfile),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text('Administrative & Team Governance', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsItem(context, 'Role-Based Access Control (RBAC)', 'Manage staff permissions for moderators and finance officers', Icons.security_rounded, AppColors.primaryRuby, () => context.push(AdminRoutePaths.rolesPermissions)),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsItem(context, 'System UI States Showcase', 'Inspect empty queues, 403 forbidden access, and network error views', Icons.devices_other_rounded, Colors.amber.shade800, () => context.push(AdminRoutePaths.systemStatesShowcase)),
                const SizedBox(height: AppSpacing.xl),
                const Text('Legal Governance & Compliance', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsItem(context, 'Platform Terms of Service', 'Read legal disclaimers and merchant booking regulations', Icons.gavel_rounded, Colors.indigo, () => context.push(AdminRoutePaths.termsConditions)),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsItem(context, 'Customer & Studio Privacy Policy', 'GDPR and IT Act user data retention & encryption disclosures', Icons.privacy_tip_rounded, Colors.teal, () => context.push(AdminRoutePaths.privacyPolicy)),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsItem(context, 'Executive IT Help & Support', 'Reach database ops or cloud engineering emergency responders', Icons.help_outline_rounded, Colors.blue, () => context.push(AdminRoutePaths.helpSupport)),
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Lock & Sign Out from Admin Console', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  onPressed: () => _onSignOut(context, ref),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Text('HER AREA Admin Console v3.0.0-PROD\nPowered by Clean Architecture & Riverpod', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
