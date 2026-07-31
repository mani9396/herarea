import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(adminCustomersProvider);
    final customer = customers.cast<AdminCustomerModel?>().firstWhere(
          (c) => c?.id == customerId,
          orElse: () => null,
        );

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Dossier')),
        body: const Center(child: Text('Customer profile not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${customer.fullName} (${customer.id})'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primaryRuby,
                              child: Text(customer.fullName[0], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(customer.fullName, style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                                      const SizedBox(width: 12),
                                      if (customer.isBlocked)
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('BLOCKED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))
                                      else
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: const Text('ACTIVE BUYER', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${customer.email} • 📞 ${customer.phoneNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('City: ${customer.city} • Registered User since ${customer.joinedAt}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total Orders', '${customer.totalOrders}', Icons.shopping_bag_rounded, AppColors.primaryRuby),
                            _buildStatItem('Atelier Inquiries', '${customer.totalInquiries}', Icons.chat_bubble_outline_rounded, Colors.teal),
                            _buildStatItem('Saved Wishlist', '14 items', Icons.favorite_rounded, Colors.pink),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text('Recent Platform Activity Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                const SizedBox(height: AppSpacing.md),
                ...customer.recentActivity.map((act) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const CircleAvatar(backgroundColor: AppColors.primaryRuby, child: Icon(Icons.history_rounded, color: Colors.white, size: 20)),
                    title: Text(act, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal, fontSize: 14)),
                    subtitle: Text('Logged under session fingerprint (${customer.id})', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
