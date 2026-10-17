import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/features/stories/state/vendor_stories_provider.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';

class AddStoryScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AddStoryScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends ConsumerState<AddStoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Option A state (Product-Linked)
  VendorProductModel? _selectedProduct;
  final TextEditingController _productSearchController = TextEditingController();
  String _productSearchQuery = '';
  bool _includeStorePrice = true;

  // Option B state (Gallery Upload)
  XFile? _pickedMedia;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _promoPriceController = TextEditingController();
  final _galleryFormKey = GlobalKey<FormState>();
  bool _includePrice = false;

  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productSearchController.dispose();
    _titleController.dispose();
    _captionController.dispose();
    _priceController.dispose();
    _promoPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        maxHeight: 2560,
        imageQuality: 88,
      );
      if (picked != null) {
        setState(() {
          _pickedMedia = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _publishProductStory() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product from your store first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await ref.read(vendorStoriesProvider.notifier).createStory(
            storyType: 'product_linked',
            productId: _selectedProduct!.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product Story published successfully! (Live for 24h)'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _handlePublishError(e);
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _handlePublishError(dynamic e) {
    if (!mounted) return;
    final errStr = e.toString();
    final isAuthErr = errStr.contains('401') ||
        errStr.toLowerCase().contains('token') ||
        errStr.toLowerCase().contains('unauthorized');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAuthErr
              ? 'Your session expired. Please log in again to publish stories.'
              : 'Failed to publish story: ${errStr.replaceAll('Exception: ', '').replaceAll('ApiException: ', '')}',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: isAuthErr
            ? SnackBarAction(
                label: 'Login',
                textColor: Colors.yellow,
                onPressed: () => context.go(VendorRoutePaths.login),
              )
            : null,
      ),
    );
  }

  Future<void> _publishGalleryStory() async {
    if (!_galleryFormKey.currentState!.validate()) {
      return;
    }

    if (_pickedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image from your gallery first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final priceText = _priceController.text.trim();
    final promoPriceText = _promoPriceController.text.trim();

    final price = _includePrice && priceText.isNotEmpty ? double.tryParse(priceText) : null;
    final promoPrice = _includePrice && promoPriceText.isNotEmpty ? double.tryParse(promoPriceText) : null;

    setState(() => _isPublishing = true);
    try {
      await ref.read(vendorStoriesProvider.notifier).createStory(
            storyType: 'gallery_uploaded',
            mediaFile: _pickedMedia,
            title: _titleController.text.trim(),
            caption: _captionController.text.trim(),
            price: price,
            promotionalPrice: promoPrice,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery Story published successfully! (Live for 24h)'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _handlePublishError(e);
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add 24h Story'),
        centerTitle: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryRuby,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryRuby,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.storefront_rounded),
              text: 'Option A: My Products',
            ),
            Tab(
              icon: Icon(Icons.add_photo_alternate_rounded),
              text: 'Option B: Gallery Upload',
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOptionAStoreProducts(),
              _buildOptionBGalleryUpload(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // OPTION A: Select from My Store Products
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildOptionAStoreProducts() {
    final products = ref.watch(vendorProductsProvider);
    final filtered = products.where((p) {
      if (_productSearchQuery.isEmpty) return true;
      final q = _productSearchQuery.toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          (p.categoryName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Guidance Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.indigo, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Option A: Link an Existing Store Product',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Story will automatically sync the product image, title, and current price. When customers tap "See More About Product", they will be taken straight to this product\'s detail page in your store.',
                      style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Product Search Bar
        TextField(
          controller: _productSearchController,
          onChanged: (val) => setState(() => _productSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search my products by name or category...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRuby),
            suffixIcon: _productSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _productSearchController.clear();
                      setState(() => _productSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Products List
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('No products found in your store.', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Add products to your catalog before creating a product-linked story.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text('No products match "$_productSearchQuery".',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = filtered[index];
              final isSelected = _selectedProduct?.id == product.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedProduct = product;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRuby.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryRuby : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade100,
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                                )
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${product.price.toStringAsFixed(0)} • ${product.category}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? AppColors.primaryRuby : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: product.id,
                        groupValue: _selectedProduct?.id,
                        activeColor: AppColors.primaryRuby,
                        onChanged: (_) {
                          setState(() {
                            _selectedProduct = product;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: AppSpacing.lg),

        // Live Story Preview
        if (_selectedProduct != null) ...[
          const Divider(),
          const SizedBox(height: 8),

          // Option A Price Display Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _includeStorePrice,
              activeColor: Colors.indigo,
              title: Text(
                'Show Listing Price (₹${_selectedProduct!.price.toStringAsFixed(0)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                _includeStorePrice
                    ? 'Current catalog listing price will be highlighted on the story'
                    : 'Price tag will be hidden on story; customers tap to view full product details',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              onChanged: (val) => setState(() => _includeStorePrice = val),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          const Text(
            'Story Preview (Customer View)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      _selectedProduct!.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.broken_image, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedProduct!.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (_includeStorePrice)
                            Text(
                              '₹${_selectedProduct!.price.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.accentGoldLight, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRuby,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'See More About Product',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Publish Button
        CustomButton(
          label: _isPublishing ? 'Publishing Story...' : 'Publish Product Story 🚀',
          isLoading: _isPublishing,
          onPressed: _isPublishing ? null : _publishProductStory,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // OPTION B: Upload from Gallery
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildOptionBGalleryUpload() {
    return Form(
      key: _galleryFormKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Guidance Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryRuby.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.photo_camera_back_outlined, color: AppColors.primaryRuby, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Option B: Showcase Gallery Upload',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Upload photos or behind-the-scenes moments from your device. Customers tapping "View Details" will view your caption and price in an expanded story panel without leaving the story.',
                        style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Media Picker / Preview Box
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _pickedMedia != null ? AppColors.primaryRuby : Colors.grey.shade300,
                  width: _pickedMedia != null ? 2 : 1,
                ),
              ),
              child: _pickedMedia != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (kIsWeb)
                            Image.network(_pickedMedia!.path, fit: BoxFit.cover)
                          else
                            Image.file(File(_pickedMedia!.path), fit: BoxFit.cover),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Change Photo', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRuby.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 36,
                              color: AppColors.primaryRuby,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Select Image from Device Gallery',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supports JPG, PNG, WEBP',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Optional Story Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Story Title (Optional)',
              hintText: 'e.g., Bespoke Hand-Embroidered Lehenga',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Optional Description / Caption
          TextFormField(
            controller: _captionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Story Caption / Notes (Optional)',
              hintText: 'Share craftsmanship details, fabric notes, or custom bridal order timelines...',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Listing Price Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _includePrice,
              activeColor: AppColors.primaryRuby,
              title: const Text('Add Listing Price to Story', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                _includePrice
                    ? 'Price & promotional offer tags will be attached to this story'
                    : 'Toggle on to specify custom listing price and promotional offer',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              onChanged: (val) {
                setState(() {
                  _includePrice = val;
                  if (!val) {
                    _priceController.clear();
                    _promoPriceController.clear();
                  }
                });
              },
            ),
          ),
          if (_includePrice) ...[
            const SizedBox(height: AppSpacing.md),
            // Price & Promotional Price Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price (₹, Optional)',
                      hintText: 'e.g., 8500',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (!_includePrice) return null;
                      if (val == null || val.trim().isEmpty) return null;
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Must be >= 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _promoPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Offer Price (₹, Optional)',
                      hintText: 'e.g., 6999',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (!_includePrice) return null;
                      if (val == null || val.trim().isEmpty) return null;
                      final parsedPromo = double.tryParse(val.trim());
                      if (parsedPromo == null || parsedPromo < 0) {
                        return 'Must be >= 0';
                      }
                      final regText = _priceController.text.trim();
                      if (regText.isNotEmpty) {
                        final parsedReg = double.tryParse(regText);
                        if (parsedReg != null && parsedPromo > parsedReg) {
                          return 'Cannot exceed price';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          // Publish Button
          CustomButton(
            label: _isPublishing ? 'Publishing Story...' : 'Publish Gallery Story 📸',
            isLoading: _isPublishing,
            onPressed: _isPublishing ? null : _publishGalleryStory,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
