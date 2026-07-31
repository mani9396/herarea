import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class VendorNotificationsScreen extends ConsumerWidget {
  const VendorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(vendorNotificationsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => ref.read(vendorNotificationsProvider.notifier).markAllAsRead(),
            child: const Text('Mark Read', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: notifs.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.notifications_none_rounded,
                  title: 'All caught up!',
                  description: 'No pending booking requests or alerts.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: notifs.length,
                  separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final n = notifs[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push(VendorRoutePaths.buildNotificationDetailsPath(n.id)),
                      child: CustomCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: (n.isUnread ? AppColors.primaryRuby : Colors.grey).withValues(alpha: 0.1),
                              child: Icon(n.icon, color: n.isUnread ? AppColors.primaryRuby : Colors.grey[700]),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(n.title, style: textTheme.titleMedium?.copyWith(fontWeight: n.isUnread ? FontWeight.bold : FontWeight.w600))),
                                      if (n.isUnread)
                                        Container(
                                          width: 8, height: 8,
                                          decoration: const BoxDecoration(color: AppColors.primaryRuby, shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(n.description, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                  const SizedBox(height: 6),
                                  Text(n.timestamp, style: textTheme.bodySmall?.copyWith(color: AppColors.accentGoldDark, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
