import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class ModerationHubScreen extends ConsumerWidget {
  const ModerationHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Moderation Command Center'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Content Governance & Trust Queues',
                  style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neutralCharcoal),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select a moderation queue below to inspect incoming bridal wear listings, studio lookbook gallery images, promotional discount voucher campaigns, or reported dispute reviews.',
                  style: TextStyle(fontSize: 14, color: AppColors.neutralCharcoal.withValues(alpha: 0.7), height: 1.4),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.xl,
                  crossAxisSpacing: AppSpacing.xl,
                  childAspectRatio: 1.8,
                  children: [
                    _buildHubCard(
                      context,
                      'Product Catalog Moderation',
                      'Review Maggam blouses, silk sarees, and custom bridal trousseau items submitted by partner boutiques.',
                      Icons.checkroom_rounded,
                      Colors.purple.shade700,
                      '${stats.pendingProducts} pending inspection',
                      () => context.push(AdminRoutePaths.productModeration),
                    ),
                    _buildHubCard(
                      context,
                      'Studio Gallery Lookbooks',
                      'Moderate studio photos and bridal client measurement session snapshots before publication.',
                      Icons.photo_library_rounded,
                      Colors.teal.shade700,
                      '${stats.pendingGallery} pending inspection',
                      () => context.push(AdminRoutePaths.galleryModeration),
                    ),
                    _buildHubCard(
                      context,
                      'Promotional Offer & Vouchers',
                      'Audit discount codes, free custom tassel bonuses, and seasonal wedding promotion banners.',
                      Icons.local_offer_rounded,
                      Colors.indigo.shade700,
                      '${stats.pendingOffers} pending inspection',
                      () => context.push(AdminRoutePaths.offerModeration),
                    ),
                    _buildHubCard(
                      context,
                      'Customer Review Disputes',
                      'Investigate 1-star reviews flagged by partner boutiques for abusive wording or fitting schedule mismatches.',
                      Icons.gavel_rounded,
                      Colors.red.shade700,
                      '${stats.reportedReviews} active reports',
                      () => context.push(AdminRoutePaths.reviewModeration),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHubCard(BuildContext context, String title, String description, IconData icon, Color color, String countText, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: AppColors.neutralCharcoal.withValues(alpha: 0.7), height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                    child: Text(countText, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  Row(
                    children: [
                      Text('Enter Queue', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
