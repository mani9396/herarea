import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/models/store_model.dart';
import 'package:her_area/core/widgets/store_card.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  BusinessCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final allStores = ref.watch(allStoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory == null ? 'All Specialty Categories' : _selectedCategory!.displayName),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedCategory = null),
              )
            : null,
      ),
      body: SafeArea(
        child: _selectedCategory == null
            ? _buildCategoryGrid(context)
            : _buildCategoryStoreList(context, allStores, _selectedCategory!),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: BusinessCategory.values.length,
      itemBuilder: (context, index) {
        final category = BusinessCategory.values[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: AppTheme.blushPink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.iconData, size: 34, color: AppTheme.primaryRuby),
                ),
                const SizedBox(height: 12),
                Text(
                  category.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryStoreList(BuildContext context, AsyncValue<List<StoreModel>> allStores, BusinessCategory category) {
    return allStores.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (stores) {
        final filtered = stores.where((s) => s.category == category).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No ${category.displayName} discovered near you yet.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final store = filtered[index];
            return StoreCard(
              store: store,
              onTap: () => context.push('/store-details/${store.id}'),
            );
          },
        );
      },
    );
  }
}
