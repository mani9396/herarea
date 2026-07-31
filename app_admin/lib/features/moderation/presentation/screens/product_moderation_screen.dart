import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/widgets/admin_status_chip.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class ProductModerationScreen extends ConsumerStatefulWidget {
  const ProductModerationScreen({super.key});

  @override
  ConsumerState<ProductModerationScreen> createState() => _ProductModerationScreenState();
}

class _ProductModerationScreenState extends ConsumerState<ProductModerationScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'Pending';
  final List<String> _tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  void _onApprove(AdminProductModel p) {
    ref.read(adminProductsProvider.notifier).approveProduct(p.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Approved catalog product: "${p.title}" (${p.vendorName})');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved "${p.title}" for catalog display.')));
  }

  void _onReject(AdminProductModel p) {
    ref.read(adminProductsProvider.notifier).rejectProduct(p.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Rejected catalog product: "${p.title}" (${p.vendorName})');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejected "${p.title}" from catalog.')));
  }

  void _onRemove(AdminProductModel p) {
    ref.read(adminProductsProvider.notifier).removeProduct(p.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Permanently deleted product: "${p.title}"');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed "${p.title}" permanently.')));
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(adminProductsProvider);

    final displayed = products.where((p) {
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedStatus == 'All') return matchesSearch;
      return matchesSearch && p.status.displayName == _selectedStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bridal Product & Trousseau Moderation'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products by title, vendor atelier name, or fabric craft...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRuby),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _tabs.map((tab) {
                          final isSelected = _selectedStatus == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(tab),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedStatus = tab),
                              backgroundColor: Theme.of(context).cardColor,
                              selectedColor: AppColors.primaryRuby.withValues(alpha: 0.2),
                              labelStyle: TextStyle(color: isSelected ? AppColors.primaryRuby : AppColors.neutralCharcoal, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: displayed.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.checkroom_outlined,
                        title: 'No Products in "$_selectedStatus" Queue',
                        description: 'There are currently zero bridal fashion products matching this status filter or query.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                        itemCount: displayed.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final product = displayed[index];
                          return _buildProductCard(context, product);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, AdminProductModel product) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                product.imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 110, height: 110, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.neutralCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      AdminStatusChip(status: product.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('By: ${product.vendorName} • Category: ${product.category}', style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(product.description, style: TextStyle(color: AppColors.neutralCharcoal.withValues(alpha: 0.7), fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Listing Price: ₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.neutralCharcoal)),
                      Row(
                        children: [
                          if (product.status != AdminStatus.approved)
                            CustomButton(
                              label: 'Approve ✅',
                              isFullWidth: false,
                              onPressed: () => _onApprove(product),
                            ),
                          if (product.status != AdminStatus.approved) const SizedBox(width: 10),
                          if (product.status != AdminStatus.rejected)
                            CustomButton(
                              label: 'Reject ❌',
                              variant: ButtonVariant.outline,
                              isOutlined: true,
                              isFullWidth: false,
                              onPressed: () => _onReject(product),
                            ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: 'Permanently Remove',
                            onPressed: () => _onRemove(product),
                          ),
                        ],
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
}
