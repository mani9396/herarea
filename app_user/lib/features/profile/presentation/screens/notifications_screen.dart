import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

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
              tooltip: 'Clear Notifications',
              onPressed: () {
                ref.read(notificationsProvider.notifier).clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleared all notifications.'), behavior: SnackBarBehavior.floating),
                );
              },
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
                    },
                    child: InkWell(
                      onTap: () {
                        if (!item.isRead) {
                          ref.read(notificationsProvider.notifier).toggleRead(item.id);
                        }
                      },
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
                                      Text(
                                        item.isRead ? 'Read' : 'Tap to mark read',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: item.isRead ? Colors.grey : AppColors.primaryRuby,
                                        ),
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
