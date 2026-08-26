import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  ConsumerState<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends ConsumerState<CategorySelectionScreen> {
  CategoryModel? _selectedParent;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(vendorCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedParent == null ? 'Select Store Category' : 'Select Subcategory'),
        centerTitle: true,
        elevation: 0,
        leading: _selectedParent != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedParent = null),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories available'));
          }

          if (_selectedParent == null) {
            return _buildCategoryList(categories);
          } else {
            if (_selectedParent!.subcategories.isEmpty) {
              return const Center(child: Text('No subcategories available'));
            }
            return _buildSubcategoryList(_selectedParent!.subcategories);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRuby)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: categories.length,
      separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return CustomCard(
          onTap: () {
            if (cat.subcategories.isNotEmpty) {
              setState(() => _selectedParent = cat);
            } else {
              context.pop({'category': cat, 'subcategory': null});
            }
          },
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.1),
                child: Icon(_mapIcon(cat.iconUrl ?? ''), color: AppColors.primaryRuby),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${cat.subcategories.length} subcategories', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubcategoryList(List<CategoryModel> subcategories) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: subcategories.length,
      separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final sub = subcategories[index];
        return CustomCard(
          onTap: () {
            context.pop({'category': _selectedParent, 'subcategory': sub});
          },
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentGold),
            ],
          ),
        );
      },
    );
  }

  IconData _mapIcon(String name) {
    switch (name.toLowerCase()) {
      case 'styler': return Icons.style;
      case 'face': return Icons.face;
      case 'diamond': return Icons.diamond;
      case 'chair': return Icons.chair;
      case 'restaurant': return Icons.restaurant;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'work': return Icons.work;
      case 'plumbing': return Icons.plumbing;
      case 'celebration': return Icons.celebration;
      case 'menu_book': return Icons.menu_book;
      case 'redeem': return Icons.redeem;
      case 'storefront': return Icons.storefront;
      default: return Icons.category_rounded;
    }
  }
}
