import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class NotificationDetailsScreen extends ConsumerWidget {
  final String notificationId;
  const NotificationDetailsScreen({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(vendorNotificationsProvider);
    final notif = notifs.firstWhere((n) => n.id == notificationId, orElse: () => notifs.first);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Alert Details'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.15),
                            child: Icon(notif.icon, color: AppColors.primaryRuby, size: 36),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notif.title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(notif.timestamp, style: const TextStyle(color: AppColors.accentGoldDark, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 36),
                      Text('Alert Message Content:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        notif.description,
                        style: textTheme.bodyLarge?.copyWith(height: 1.5, color: AppColors.neutralCharcoal),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.blue, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('This automated alert was dispatched by the HER AREA lead routing engine via WhatsApp O2O infrastructure.', style: TextStyle(fontSize: 12, color: Colors.black87)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'View Associated Consultation Bookings',
                  onPressed: () => context.go(VendorRoutePaths.ordersEnquiries),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Notifications Overview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
