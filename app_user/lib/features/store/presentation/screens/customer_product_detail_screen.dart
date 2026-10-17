import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:her_area/core/routing/route_paths.dart';

class CustomerProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const CustomerProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<CustomerProductDetailScreen> createState() => _CustomerProductDetailScreenState();
}

class _CustomerProductDetailScreenState extends ConsumerState<CustomerProductDetailScreen> {
  late Future<CatalogItemModel?> _productFuture;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _productFuture = ref.read(customerApiRepositoryProvider).getProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique Creation'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<CatalogItemModel?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRuby));
          }

          final product = snapshot.data;

          // Graceful handling for deleted, unpublished, or unavailable products
          if (product == null || !product.isAvailable) {
            return _buildUnavailableProductView(context, isDark);
          }

          final allImages = [product.imageUrl, ...product.additionalImages];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Image Display
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Image.network(
                          allImages[_selectedImageIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Additional Images Carousel
                    if (allImages.length > 1) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: allImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, idx) {
                            final isSelected = idx == _selectedImageIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedImageIndex = idx),
                              child: Container(
                                width: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryRuby : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    allImages[idx],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Product Title & Pricing
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.categoryName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryRuby.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.categoryName!.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryRuby,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                product.title,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (product.discountedPrice != null) ...[
                              Text(
                                CurrencyFormatter.format(product.discountedPrice!),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRuby,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(product.price),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ] else ...[
                              Text(
                                CurrencyFormatter.format(product.price),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRuby,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),

                    // Store / Showroom Attribution Card
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryRuby,
                            child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Partner Studio Showroom',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  product.storeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          if (product.storeId.isNotEmpty)
                            OutlinedButton(
                              onPressed: () => context.push(RoutePaths.buildStoreDetailsPath(product.storeId)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryRuby),
                                foregroundColor: AppTheme.primaryRuby,
                              ),
                              child: const Text('Visit Store'),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Craftsmanship & Specifications
                    const Text(
                      'Artisan Craftsmanship & Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: 'Contact Boutique',
                            icon: Icons.chat_bubble_outline_rounded,
                            isOutlined: true,
                            onPressed: () {
                              if (product.storeId.isNotEmpty) {
                                context.push(RoutePaths.buildStoreDetailsPath(product.storeId));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: CustomButton(
                            label: 'Book Studio Fitting',
                            icon: Icons.calendar_today_rounded,
                            onPressed: () {
                              if (product.storeId.isNotEmpty) {
                                context.push(RoutePaths.buildStoreDetailsPath(product.storeId));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnavailableProductView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove_shopping_cart_outlined, size: 64, color: Colors.amber.shade800),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Product Unavailable',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This catalog item is no longer available, has been unlisted, or was removed by the boutique.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CustomButton(
              label: 'Return to Discovery',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
