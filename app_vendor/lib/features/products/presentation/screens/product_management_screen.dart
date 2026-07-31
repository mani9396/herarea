import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/core/widgets/vendor_status_chip.dart';
import 'package:shared/shared.dart';

class ProductManagementScreen extends ConsumerWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(vendorProductsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bridal Catalog & Inventory'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push(VendorRoutePaths.gallery),
            icon: const Icon(Icons.photo_library_rounded, color: AppColors.primaryRuby),
            tooltip: 'View Showcase Gallery',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(VendorRoutePaths.addProduct),
        backgroundColor: AppColors.primaryRuby,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add New Product'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: products.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'Catalog is Empty',
                  description: 'Tap "Add New Product" to list your Silk Sarees, Maggam Blouses, and bridal creations.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: products.length,
                  separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return CustomCard(
                      onTap: () => context.push(VendorRoutePaths.buildProductDetailsPath(p.id)),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(p.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(p.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(p.category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(CurrencyFormatter.format(p.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby, fontSize: 15)),
                                    const SizedBox(width: AppSpacing.md),
                                    VendorStatusChip(
                                      label: p.inStock ? 'In Stock' : 'Sold Out',
                                      backgroundColor: (p.inStock ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                                      textColor: p.inStock ? Colors.green[800]! : Colors.grey[700]!,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Switch(
                                value: p.inStock,
                                activeThumbColor: AppColors.primaryRuby,
                                onChanged: (_) => ref.read(vendorProductsProvider.notifier).toggleStock(p.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.grey),
                                onPressed: () => context.push(VendorRoutePaths.buildEditProductPath(p.id)),
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
