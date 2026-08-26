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
          if (products.any((p) => p.status == 'DRAFT' || p.status == 'REJECTED'))
            TextButton.icon(
              onPressed: () async {
                try {
                  await ref.read(vendorProductsProvider.notifier).submitAllDrafts();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All drafts submitted for approval!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.upload_file_rounded, color: AppColors.primaryRuby),
              label: const Text('Submit All', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
            ),
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
                                Text(p.categoryName ?? p.category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(CurrencyFormatter.format(p.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby, fontSize: 15)),
                                    const SizedBox(width: AppSpacing.md),
                                    _buildStatusChip(p.status),
                                  ],
                                ),
                                if (p.status == 'REJECTED' && p.adminRemarks != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text('Remarks: ${p.adminRemarks}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Switch(
                                value: p.isAvailable,
                                activeThumbColor: AppColors.primaryRuby,
                                onChanged: (p.status == 'APPROVED') ? (_) => ref.read(vendorProductsProvider.notifier).toggleAvailability(p.id) : null,
                              ),
                              Row(
                                children: [
                                  if (p.status == 'DRAFT' || p.status == 'REJECTED' || p.status == 'APPROVED')
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.grey),
                                      onPressed: () => context.push(VendorRoutePaths.buildEditProductPath(p.id)),
                                    ),
                                ],
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

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'APPROVED':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green[800]!;
        label = 'Approved';
        break;
      case 'PENDING_APPROVAL':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange[800]!;
        label = 'Pending';
        break;
      case 'REJECTED':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red[800]!;
        label = 'Rejected';
        break;
      case 'DRAFT':
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey[800]!;
        label = 'Draft';
        break;
      case 'HIDDEN':
      case 'SUSPENDED':
        bg = Colors.black12;
        fg = Colors.black87;
        label = status == 'HIDDEN' ? 'Hidden' : 'Suspended';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = status;
    }
    return VendorStatusChip(label: label, backgroundColor: bg, textColor: fg);
  }
}
