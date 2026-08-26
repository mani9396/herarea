import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/core/widgets/vendor_status_chip.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';
import 'package:shared/shared.dart';

class BusinessProfileScreen extends ConsumerWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(vendorStoreProvider);
    final textTheme = Theme.of(context).textTheme;

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Profile Preview'), centerTitle: true, elevation: 0),
        body: const Center(
          child: Text('Please set up your store first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Store Profile Preview'), centerTitle: true, elevation: 0),
      body: ResponsiveLayout(
        mobile: _buildProfileContent(context, store, textTheme, ref),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildProfileContent(context, store, textTheme, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, StoreModel store, TextTheme textTheme, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.visibility_rounded, color: AppColors.accentGoldDark),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('This is how your boutique card & catalog appears to brides across HER AREA.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(store.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () => _showEditDialog(context, ref, 'Store Title & Category', store.name),
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primaryRuby),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    VendorStatusChip(label: store.category.name, backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.1), textColor: AppColors.primaryRuby),
                    const SizedBox(width: 8),
                    VendorStatusChip(label: store.priceTier, backgroundColor: Colors.grey.withValues(alpha: 0.2), textColor: Colors.black87),
                    const SizedBox(width: 8),
                    if (store.isVerified)
                      const VendorStatusChip(label: 'Verified Gold', backgroundColor: Color(0xFFFFF7E6), textColor: AppColors.accentGoldDark),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(store.description, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryRuby),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${store.address}${store.city.isNotEmpty ? ', ${store.city}' : ''}', style: textTheme.bodySmall)),
                    IconButton(
                      onPressed: () async {
                        final res = await context.push<Map<String, dynamic>>(VendorRoutePaths.locationPicker);
                        if (res != null) {
                          // Update Location API call
                          final repo = ref.read(vendorApiRepositoryProvider);
                          final success = await repo.saveBusinessProfile({
                            'business_name': store.name,
                            'category_name': store.category.name,
                            'latitude': res['latitude'],
                            'longitude': res['longitude'],
                            'area': res['area'],
                            'city': res['city'],
                            'state': res['state'],
                            'country': res['country'],
                            'postal_code': res['postal_code'],
                          });
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Store location updated successfully.')),
                            );
                            ref.read(vendorStoreProvider.notifier).updateStore(
                              store.copyWith(
                                address: res['area'] ?? res['address'] ?? store.address,
                                city: res['city'] ?? store.city,
                                latitude: res['latitude'] ?? store.latitude,
                                longitude: res['longitude'] ?? store.longitude,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.edit_location_alt_rounded, color: AppColors.primaryRuby, size: 20),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 20, color: Colors.green),
                    const SizedBox(width: 6),
                    Text('WhatsApp Business & Calls: ${store.whatsappNumber}', style: textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Active Specialties & Service Tags', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: store.serviceTags.map((t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.05),
              side: const BorderSide(color: AppColors.primaryRuby),
            )).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Special Offers Displayed to Brides', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...store.specialOffers.map((o) => CustomCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: AppColors.accentGold),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String field, String currentVal) {
    CustomDialog.show(
      context: context,
      title: 'Edit $field',
      description: 'Modifying this setting will instantly synchronize across live customer applications and marketplace feeds via O2O backend APIs.',
      confirmText: 'Acknowledge & Save',
      onConfirm: () {},
      icon: Icons.edit_rounded,
    );
  }
}
