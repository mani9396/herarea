import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/empty_state_widget.dart';

import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _navigateToRespectiveScreen(BuildContext context, NotificationItemModel item) async {
    final rawUrl = (item.actionUrl ?? '').trim();

    // 1. External Web URL
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 2. Validate in-app route (strictly ignore '/' or '/splash' to avoid resetting to splash)
    String? validRoute;
    if (rawUrl.isNotEmpty && rawUrl != '/' && rawUrl != RoutePaths.splash) {
      if (rawUrl.startsWith('/store-details/') || rawUrl.startsWith('/store/')) {
        final id = rawUrl.split('/').last;
        validRoute = RoutePaths.buildStoreDetailsPath(id);
      } else if (rawUrl.startsWith('/product-details/') || rawUrl.startsWith('/product/')) {
        final id = rawUrl.split('/').last;
        validRoute = RoutePaths.buildProductDetailsPath(id);
      } else if (rawUrl == RoutePaths.categories || rawUrl.startsWith('/categories')) {
        validRoute = RoutePaths.categories;
      } else if (rawUrl == RoutePaths.home || rawUrl.startsWith('/home')) {
        validRoute = RoutePaths.home;
      } else if (rawUrl == RoutePaths.nearby || rawUrl.startsWith('/nearby')) {
        validRoute = RoutePaths.nearby;
      } else if (rawUrl == RoutePaths.games || rawUrl.startsWith('/games')) {
        validRoute = RoutePaths.games;
      } else if (rawUrl == RoutePaths.messages || rawUrl.startsWith('/chat') || rawUrl.startsWith('/messages')) {
        validRoute = rawUrl;
      } else if (rawUrl == RoutePaths.favorites) {
        validRoute = RoutePaths.favorites;
      } else if (rawUrl == RoutePaths.profile) {
        validRoute = RoutePaths.profile;
      }
    }

    // 3. Fallback resolution if route is missing, invalid, or was '/'
    if (validRoute == null) {
      final titleLower = item.title.toLowerCase();
      final messageLower = item.message.toLowerCase();
      final categoryUpper = (item.category ?? '').toUpperCase();

      final uuidRegex = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');
      final match = uuidRegex.firstMatch(rawUrl.isNotEmpty ? rawUrl : '$titleLower $messageLower');
      if (match != null) {
        validRoute = RoutePaths.buildStoreDetailsPath(match.group(0)!);
      } else if (categoryUpper.contains('CHAT') || messageLower.contains('message') || messageLower.contains('chat')) {
        validRoute = RoutePaths.messages;
      } else if (categoryUpper.contains('GAME') || messageLower.contains('game') || messageLower.contains('ludo') || messageLower.contains('spin')) {
        validRoute = RoutePaths.games;
      } else if (titleLower.contains('food') || messageLower.contains('food') ||
                 titleLower.contains('category') || messageLower.contains('category') ||
                 titleLower.contains('specialty') || messageLower.contains('specialt')) {
        validRoute = RoutePaths.categories;
      } else {
        validRoute = RoutePaths.home;
      }
    }

    // 4. Safely navigate
    if (context.mounted) {
      if (validRoute == RoutePaths.home ||
          validRoute == RoutePaths.categories ||
          validRoute == RoutePaths.nearby ||
          validRoute == RoutePaths.games ||
          validRoute == RoutePaths.messages ||
          validRoute == RoutePaths.profile) {
        context.go(validRoute);
      } else {
        context.push(validRoute);
      }
    }
  }

  void _showNotificationDetail(BuildContext context, NotificationItemModel item, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Ensure it is marked as read
    if (!item.isRead) {
      ref.read(notificationsProvider.notifier).toggleRead(item.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRuby.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.iconData, color: AppColors.primaryRuby, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category ?? 'ALERT',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentGoldDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.timeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.blushPink.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Text(
                  item.message,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRuby,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToRespectiveScreen(context, item);
                },
                child: const Text('Explore Now 🌟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  side: const BorderSide(color: AppColors.errorRed),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Delete This Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  ref.read(notificationsProvider.notifier).removeNotification(item.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted.'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationsProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared.'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              TextButton(
                onPressed: () {
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked all notifications as read.'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: const Text(
                  'Read All',
                  style: TextStyle(
                    color: AppColors.primaryRuby,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTypography.bodyFont,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
              tooltip: 'Clear All Notifications',
              onPressed: () => _confirmClearAll(context, ref),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: EmptyStateWidget(
                  icon: Icons.notifications_none_rounded,
                  title: 'No New Notifications',
                  description: 'You are completely caught up! We will alert you here whenever your favorite boutiques release new collections, confirm your home measurement slots, or announce VIP discounts.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
                    ),
                    onDismissed: (_) {
                      ref.read(notificationsProvider.notifier).removeNotification(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification removed.'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: InkWell(
                      onTap: () => _showNotificationDetail(context, item, ref),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? (isDark ? AppColors.surfaceVariantDark : Colors.white)
                              : (isDark ? AppColors.primaryRuby.withValues(alpha: 0.15) : AppColors.blushPink.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isRead
                                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                                : AppColors.accentGold.withValues(alpha: 0.6),
                            width: item.isRead ? 1.0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? (isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight)
                                    : AppColors.primaryRuby,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.iconData,
                                color: item.isRead ? AppColors.primaryRuby : AppColors.accentGoldLight,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontFamily: AppTypography.displayFont,
                                            fontSize: 16,
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                            color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryRuby,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      fontSize: 14,
                                      color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.timeText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.isRead
                                                  ? Colors.grey.withValues(alpha: 0.15)
                                                  : AppColors.primaryRuby.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              item.isRead ? 'Read' : 'Tap to open',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: item.isRead ? Colors.grey : AppColors.primaryRuby,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.errorRed),
                                            tooltip: 'Delete Notification',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: () {
                                              ref.read(notificationsProvider.notifier).removeNotification(item.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Notification deleted.'), behavior: SnackBarBehavior.floating),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
