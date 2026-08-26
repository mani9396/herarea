import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/state/admin_subscription_state.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardStatsProvider);
    final recentActivities = ref.watch(adminActivityLogProvider);
    final adminRevenueAsync = ref.watch(adminRevenueProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBanner(context, stats),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Pending Moderation Queues',
                  style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPendingApprovalsGrid(context, stats),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Marketplace Revenue Overview (Verified Subscriptions)',
                            style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildRevenueOverviewCard(adminRevenueAsync),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Recent Platform Activities',
                            style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildActivityLogCard(recentActivities),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'Administrative Quick Actions',
                  style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildQuickActionsGrid(context),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, AdminDashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B1020), Color(0xFF4B1832)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primaryRuby.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Executive Command Center', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(
                    'Hyderabad Regional Operations 📌',
                    style: TextStyle(fontFamily: AppTypography.displayFont, color: Colors.white, fontSize: MediaQuery.of(context).size.width < 600 ? 22 : 30, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 8),
                    Text('All Systems Green', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildBannerStatItem('Total Customers', '${stats.totalCustomers}', Icons.groups_rounded, Colors.cyanAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildBannerStatItem('Verified Vendors', '${stats.totalVendors}', Icons.storefront_rounded, Colors.orangeAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildBannerStatItem('Est. Platform GMV', '₹${(stats.totalEstimatedRevenue / 1000).toStringAsFixed(1)}k', Icons.account_balance_wallet_rounded, Colors.greenAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatItem(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalsGrid(BuildContext context, AdminDashboardStats stats) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 700 ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.3,
      children: [
        _buildPendingCard(
          context,
          'Pending Vendors',
          '${stats.pendingVendors}',
          Icons.store_mall_directory_rounded,
          Colors.orange.shade700,
          () => context.go(AdminRoutePaths.vendors),
        ),
        _buildPendingCard(
          context,
          'Profile Updates',
          '${stats.pendingProfileUpdates}',
          Icons.update_rounded,
          Colors.blue.shade700,
          () => context.push(AdminRoutePaths.profileApprovals),
        ),
        _buildPendingCard(
          context,
          'Store Approvals',
          '${stats.pendingVendors}', // Reusing pendingVendors for now or could be a new stat
          Icons.store_rounded,
          Colors.green.shade700,
          () => context.push(AdminRoutePaths.storeApprovals),
        ),
        _buildPendingCard(
          context,
          'Product Approvals',
          '${stats.pendingProducts}',
          Icons.checkroom_rounded,
          Colors.purple.shade700,
          () => context.push(AdminRoutePaths.productModeration),
        ),
        _buildPendingCard(
          context,
          'Gallery Approvals',
          '${stats.pendingGallery}',
          Icons.photo_library_rounded,
          Colors.teal.shade700,
          () => context.push(AdminRoutePaths.galleryModeration),
        ),
        _buildPendingCard(
          context,
          'Offer Approvals',
          '${stats.pendingOffers}',
          Icons.local_offer_rounded,
          Colors.indigo.shade700,
          () => context.push(AdminRoutePaths.offerModeration),
        ),
        _buildPendingCard(
          context,
          'Reported Reviews',
          '${stats.reportedReviews}',
          Icons.flag_rounded,
          Colors.red.shade700,
          () => context.push(AdminRoutePaths.reviewModeration),
        ),
      ],
    );
  }

  Widget _buildPendingCard(BuildContext context, String title, String count, IconData icon, Color color, VoidCallback onTap) {
    final bool isZero = count == '0';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isZero ? Colors.grey.shade300 : color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.neutralCharcoal)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        count,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isZero ? Colors.grey : color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isZero ? 'All Clear' : 'Review ->',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isZero ? Colors.green.shade600 : color,
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
    );
  }

  Widget _buildRevenueOverviewCard(AsyncValue<double> adminRevenueAsync) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Revenue (Verified Subscriptions)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    adminRevenueAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => const Text('Error', style: TextStyle(color: Colors.red)),
                      data: (rev) => Text('₹${rev.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryRuby)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up_rounded, color: Colors.green, size: 18),
                      SizedBox(width: 4),
                      Text('Live', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Platform Take Rate: 8.5% avg', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('Real-time ledger projection', style: TextStyle(fontSize: 12, color: AppColors.primaryRuby, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildActivityLogCard(List<String> activities) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: activities.length > 6 ? 6 : activities.length,
        separatorBuilder: (context, index) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final text = activities[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryRuby,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13, color: AppColors.neutralCharcoal, height: 1.4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 700 ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.6,
      children: [
        _buildActionShortcut(
          context,
          'Push Announcement',
          'Notify buyers or studios',
          Icons.notification_add_rounded,
          Colors.pink.shade700,
          () => context.push(AdminRoutePaths.notificationComposer),
        ),
        _buildActionShortcut(
          context,
          'Manage Categories',
          'Taxonomy & icons',
          Icons.category_rounded,
          Colors.indigo.shade700,
          () => context.push(AdminRoutePaths.categories),
        ),
        _buildActionShortcut(
          context,
          'Export CSV Reports',
          'Ledgers & vendor audits',
          Icons.file_download_rounded,
          Colors.teal.shade700,
          () => context.push(AdminRoutePaths.reports),
        ),
        _buildActionShortcut(
          context,
          'System UI States',
          'Verify error & retry views',
          Icons.devices_rounded,
          Colors.amber.shade800,
          () => context.push(AdminRoutePaths.systemStatesShowcase),
        ),
      ],
    );
  }

  Widget _buildActionShortcut(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
