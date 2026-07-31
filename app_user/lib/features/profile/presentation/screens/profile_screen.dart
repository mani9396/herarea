import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:her_area/data/mock/mock_store_repository.dart';

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
        title: const Text('My VIP Dashboard', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                tooltip: 'Notifications',
                onPressed: () => context.push(RoutePaths.notifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primaryRuby, shape: BoxShape.circle),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
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
                  // VIP Profile Hero Card
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
                                backgroundImage: NetworkImage(profile.avatarUrl),
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
                                  Text(profile.phone, style: const TextStyle(color: AppColors.blushPink, fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(profile.locality, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.accentGoldLight),
                              tooltip: 'Edit VIP Profile',
                              onPressed: () => context.push(RoutePaths.editProfile),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"${profile.bio}"',
                            style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // O2O Activity Stats
                  Row(
                    children: [
                      _buildStatTile(context, '${favIds.length}', 'Saved Stores', Icons.favorite_rounded, () => context.push(RoutePaths.favorites)),
                      const SizedBox(width: 12),
                      _buildStatTile(context, '4', 'Consultations', Icons.calendar_today_rounded, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Viewing 4 completed home fabric consultation records.'), behavior: SnackBarBehavior.floating),
                        );
                      }),
                      const SizedBox(width: 12),
                      _buildStatTile(context, '8', 'Reviews', Icons.star_rounded, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Viewing your 8 verified artisan review posts.'), behavior: SnackBarBehavior.floating),
                        );
                      }),
                    ],
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
                          icon: Icons.favorite_border_rounded,
                          title: 'Saved Favorite Stores',
                          subtitle: '${favIds.length} bookmarked neighborhood studios',
                          onTap: () => context.push(RoutePaths.favorites),
                        ),
                        const Divider(height: 1),
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
                          icon: Icons.tune_rounded,
                          title: 'Personalized Style Interests',
                          subtitle: 'Sarees, Maggam, Tailoring & Bridal makeup',
                          onTap: () => context.push(RoutePaths.interestSelection),
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
                      title: const Text('Sign Out of VIP Account', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.errorRed)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.errorRed),
                      onTap: () => _showLogoutDialog(context),
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

  Widget _buildStatTile(BuildContext context, String count, String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryRuby, size: 22),
              const SizedBox(height: 6),
              Text(
                count,
                style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, fontWeight: FontWeight.w600),
              ),
            ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out of your HER AREA account? Your saved favorites will remain securely backed up.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(RoutePaths.login);
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
