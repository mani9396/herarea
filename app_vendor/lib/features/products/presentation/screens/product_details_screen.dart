import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/core/widgets/vendor_status_chip.dart';
import 'package:shared/shared.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prodList = ref.watch(vendorProductsProvider).where((p) => p.id == productId);
    if (prodList.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Product removed.')));
    }
    final prod = prodList.first;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(prod.category),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push(VendorRoutePaths.buildEditProductPath(prod.id)),
            icon: const Icon(Icons.edit_rounded, color: AppColors.primaryRuby),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(prod.imageUrl, height: 320, fit: BoxFit.cover),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(prod.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                    Text(CurrencyFormatter.format(prod.price), style: textTheme.headlineMedium?.copyWith(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    VendorStatusChip(label: prod.inStock ? 'Active & Listed' : 'Hidden / Out of Stock', backgroundColor: (prod.inStock ? Colors.green : Colors.grey).withValues(alpha: 0.15), textColor: prod.inStock ? Colors.green[800]! : Colors.grey),
                    const SizedBox(width: AppSpacing.md),
                    Text('Total Inquiries: ${prod.ordersCount}', style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.accentGoldDark)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Text('Craftsmanship & Specifications:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Text(prod.description, style: textTheme.bodyMedium?.copyWith(height: 1.6)),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Edit Product Settings',
                  isOutlined: true,
                  onPressed: () => context.push(VendorRoutePaths.buildEditProductPath(prod.id)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
