import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/features/offers/state/offers_provider.dart';
import 'package:shared/shared.dart';

class OffersManagementScreen extends ConsumerWidget {
  const OffersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(vendorOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotional Offers & Vouchers 🎟️'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryRuby, size: 28),
            tooltip: 'Create New Offer',
            onPressed: () => context.push(VendorRoutePaths.addOffer),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryRuby,
        foregroundColor: Colors.white,
        onPressed: () => context.push(VendorRoutePaths.addOffer),
        icon: const Icon(Icons.local_offer_rounded),
        label: const Text('Create Offer'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: offers.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.local_offer_outlined,
                  title: 'No Active Promotions',
                  description: 'Create discount coupons and seasonal wedding packages to incentivize brides in Hyderabad.',
                  actionLabel: 'Launch First Offer',
                  onActionPressed: () => context.push(VendorRoutePaths.addOffer),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: offers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (offer.promoCode != null && offer.promoCode!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRuby.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: AppColors.primaryRuby),
                                  ),
                                  child: Text(
                                    offer.promoCode!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby, fontSize: 13, letterSpacing: 1),
                                  ),
                                ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: offer.status == 'APPROVED' ? AppColors.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: offer.status == 'APPROVED' ? AppColors.success : Colors.orange),
                                ),
                                child: Text(
                                  offer.status,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: offer.status == 'APPROVED' ? AppColors.success : Colors.orange, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 4),
                                    Text(offer.description, style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              if (offer.discountValue != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    offer.discountValue!,
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accentGold, fontSize: 16),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(),
                          Row(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Valid till: ${offer.endDate ?? "No expiry"}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              if (offer.status == 'DRAFT' || offer.status == 'REJECTED')
                                TextButton.icon(
                                  onPressed: () => ref.read(vendorOffersProvider.notifier).submitForApproval(offer.id),
                                  icon: const Icon(Icons.send_rounded, size: 16),
                                  label: const Text('Submit for Approval'),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryRuby),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                tooltip: 'Delete Offer',
                                onPressed: () => ref.read(vendorOffersProvider.notifier).removeOffer(offer.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
