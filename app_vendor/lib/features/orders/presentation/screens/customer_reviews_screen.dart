import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class CustomerReviewsScreen extends ConsumerWidget {
  const CustomerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final reviews = ref.watch(vendorReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verified Customer Reviews ⭐'), centerTitle: true, elevation: 0),
      body: RefreshIndicator(
        onRefresh: () => ref.read(vendorReviewsProvider.notifier).loadLiveReviews(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: reviews.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No verified reviews yet. Complete bookings to gain feedback!', style: TextStyle(color: Colors.grey))),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: reviews.length,
                    separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final r = reviews[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push(VendorRoutePaths.buildReviewDetailsPath(r.id)),
                        child: CustomCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(radius: 24, backgroundImage: NetworkImage(r.avatarUrl)),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(r.customerName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 6),
                                            if (r.verified)
                                              const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 16),
                                          ],
                                        ),
                                        Text(r.dateText, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text('${r.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(r.comment, style: textTheme.bodyMedium?.copyWith(height: 1.5)),
                              if (r.vendorReply != null && r.vendorReply!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRuby.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.storefront_rounded, color: AppColors.primaryRuby, size: 16),
                                          SizedBox(width: 6),
                                          Text('Your Reply:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(r.vendorReply!, style: textTheme.bodySmall?.copyWith(height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => context.push(VendorRoutePaths.buildReviewDetailsPath(r.id)),
                                  icon: Icon(r.vendorReply != null && r.vendorReply!.isNotEmpty ? Icons.edit_rounded : Icons.reply_rounded, size: 16, color: AppColors.primaryRuby),
                                  label: Text(r.vendorReply != null && r.vendorReply!.isNotEmpty ? 'Edit Response' : 'Reply to Customer', style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
