import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVacation = ref.watch(vendorVacationModeProvider);
    final isAutoReply = ref.watch(vendorAutoReplyProvider);
    final themeMode = ref.watch(vendorThemeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Store Operation Settings ⚙️'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Partner Management & Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.sm),
                CustomCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle_rounded, color: AppColors.primaryRuby),
                        title: const Text('Account & 2FA Security', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Partner mobile, business email, master cutter contact details.'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.accountSettings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryRuby),
                        title: const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('WhatsApp lead alerts, SMS backup, review badge notifications.'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.notificationSettings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.local_offer_rounded, color: AppColors.accentGoldDark),
                        title: const Text('Promotional Offers & Vouchers', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Create discount packages and Shravanam bridal vouchers.'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.offers),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.visibility_rounded, color: Colors.purple),
                        title: const Text('System States Showcase (Demo & Diagnostics)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Preview all Empty States, Skeleton Loaders, and Error/Retry UI.'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.systemStatesShowcase),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Operational Toggles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.sm),
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('Vacation / Holiday Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Temporarily hide your boutique from active search results when taking studio leaves.'),
                        value: isVacation,
                        onChanged: (v) => ref.read(vendorVacationModeProvider.notifier).state = v,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('WhatsApp Auto-Reply Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Automatically send pricing tier brochures when a bride taps WhatsApp inquiry after 8:30 PM.'),
                        value: isAutoReply,
                        onChanged: (v) => ref.read(vendorAutoReplyProvider.notifier).state = v,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('Dark Obsidian Portal Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Switch between luxury blush pearl and midnight obsidian color palettes.'),
                        value: isDark,
                        onChanged: (v) {
                          ref.read(vendorThemeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Legal & Support Resources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.sm),
                CustomCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.help_outline_rounded, color: Colors.blue),
                        title: const Text('Help & Partner Support'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.helpSupport),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded, color: Colors.teal),
                        title: const Text('About HER AREA Partner Portal'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.about),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.privacyPolicy),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description_outlined, color: Colors.grey),
                        title: const Text('Terms & Conditions'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: () => context.push(VendorRoutePaths.termsConditions),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Logout Partner Atelier',
                  variant: ButtonVariant.outline,
                  isOutlined: true,
                  onPressed: () {
                    CustomDialog.show(
                      context: context,
                      title: 'Confirm Studio Logout? 🔒',
                      description: 'You will need to re-verify via SMS OTP to sign back into your partner dashboard.',
                      confirmText: 'Logout',
                      onConfirm: () {
                        ref.read(authApiRepositoryProvider).logout();
                        context.go(VendorRoutePaths.login);
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
