import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(vendorStoreProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Profile & Settings 👑'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(store.imageUrls.first),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.name, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Text('Owner Profile', style: textTheme.bodySmall?.copyWith(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                            Text(store.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push(VendorRoutePaths.editProfile),
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primaryRuby),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildMenuSection('Boutique & Catalog Management', [
                  _buildMenuItem(context, 'Preview Store Profile As Bride', Icons.visibility_rounded, () => context.push(VendorRoutePaths.businessProfile)),
                  _buildMenuItem(context, 'Edit Owner Personal & Contact Info', Icons.person_outline_rounded, () => context.push(VendorRoutePaths.editProfile)),
                  _buildMenuItem(context, 'Showcase Portfolio Gallery', Icons.photo_library_outlined, () => context.push(VendorRoutePaths.gallery)),
                ]),
                const SizedBox(height: AppSpacing.md),
                _buildMenuSection('Preferences & Support', [
                  _buildMenuItem(context, 'Store Operation Settings (Vacation Mode)', Icons.settings_outlined, () => context.push(VendorRoutePaths.settings)),
                  _buildMenuItem(context, 'Partner Help & Artisan Support Hotline', Icons.support_agent_rounded, () => context.push(VendorRoutePaths.helpSupport)),
                  _buildMenuItem(context, 'About HER AREA Partner Network', Icons.info_outline_rounded, () => context.push(VendorRoutePaths.about)),
                ]),
                const SizedBox(height: AppSpacing.md),
                _buildMenuSection('Legal & Compliance', [
                  _buildMenuItem(context, 'Zero Commission Privacy Policy', Icons.privacy_tip_outlined, () => context.push(VendorRoutePaths.privacyPolicy)),
                  _buildMenuItem(context, 'Partner Terms & Conditions', Icons.gavel_outlined, () => context.push(VendorRoutePaths.termsConditions)),
                ]),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  label: 'Sign Out of Partner Portal',
                  isOutlined: true,
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    CustomDialog.show(
                      context: context,
                      title: 'Confirm Sign Out',
                      description: 'You will stop receiving real-time WhatsApp & push notifications for bridal measurements.',
                      confirmText: 'Sign Out',
                      onConfirm: () {
                        ref.read(authApiRepositoryProvider).logout();
                        context.go(VendorRoutePaths.login);
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(String header, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        ),
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryRuby, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
