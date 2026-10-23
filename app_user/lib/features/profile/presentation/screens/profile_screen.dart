import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/constants/avatar_constants.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/shared.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final favIds = ref.watch(favoritesProvider);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Hero Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRuby.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white24,
                                backgroundImage: profile.avatarUrl.trim().isNotEmpty
                                    ? UserAvatars.getImageProvider(profile.avatarUrl)
                                    : null,
                                child: profile.avatarUrl.trim().isEmpty
                                    ? const Icon(Icons.person_rounded, size: 36, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          profile.name,
                                          style: const TextStyle(
                                            fontFamily: AppTypography.displayFont,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.workspace_premium_rounded, color: AppColors.accentGoldLight, size: 22),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (profile.phone.isNotEmpty && !profile.phone.startsWith('+00'))
                                    Text(profile.phone, style: const TextStyle(color: AppColors.blushPink, fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (profile.email.isNotEmpty)
                                    Text(profile.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.accentGoldLight),
                              tooltip: 'Edit Profile',
                              onPressed: () => context.push(RoutePaths.editProfile),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Saved Stores Quick Access Card
                  InkWell(
                    onTap: () => context.push(RoutePaths.favorites),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRuby.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, color: AppColors.primaryRuby, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saved Stores',
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textHighLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${favIds.length} boutique${favIds.length == 1 ? '' : 's'} bookmarked in your area',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.primaryRuby.withValues(alpha: 0.25) : AppColors.blushPink.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${favIds.length}',
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFont,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryRuby,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Account Navigation Menu
                  Text(
                    'DASHBOARD & PREFERENCES',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.accentGold : AppColors.primaryRuby,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          context,
                          icon: Icons.notifications_none_rounded,
                          title: 'Notification Center',
                          subtitle: unreadCount > 0 ? '$unreadCount unread updates & alerts' : 'All caught up on announcements',
                          badgeCount: unreadCount,
                          onTap: () => context.push(RoutePaths.notifications),
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          context,
                          icon: Icons.history_rounded,
                          title: 'Recently Viewed Stores',
                          subtitle: 'Your browsing history of boutiques',
                          onTap: () => context.push(RoutePaths.recentlyViewed),
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          context,
                          icon: Icons.settings_outlined,
                          title: 'App Settings & Theme',
                          subtitle: 'Dark mode, search radius, & push toggles',
                          onTap: () => context.push(RoutePaths.settings),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'SUPPORT & ABOUT HER AREA',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.accentGold : AppColors.primaryRuby,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          context,
                          icon: Icons.support_agent_rounded,
                          title: 'Help & Personal Concierge',
                          subtitle: 'FAQs, ticketing & 24/7 live WhatsApp support',
                          onTap: () => context.push(RoutePaths.helpSupport),
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          context,
                          icon: Icons.info_outline_rounded,
                          title: 'About HER AREA',
                          subtitle: 'Our story, community impact, and mission',
                          onTap: () => context.push(RoutePaths.about),
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          context,
                          icon: Icons.policy_outlined,
                          title: 'Terms of Service & Privacy Policy',
                          subtitle: 'O2O customer assurances & location security',
                          onTap: () => context.push(RoutePaths.termsPrivacy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Logout Option
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 22),
                      ),
                      title: const Text('Sign Out of Her Account', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.errorRed)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.errorRed),
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryRuby.withValues(alpha: 0.2) : AppColors.blushPink.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryRuby, size: 22),
      ),
      title: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryRuby, borderRadius: BorderRadius.circular(10)),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out of Her Account', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out of Her Account? Your saved favorites will remain securely backed up.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authApiRepositoryProvider).logout();
              } catch (_) {}
              ref.invalidate(userProfileProvider);
              ref.invalidate(favoritesProvider);
              ref.invalidate(notificationsProvider);
              if (context.mounted) {
                try {
                  context.go(RoutePaths.login);
                } catch (_) {}
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}