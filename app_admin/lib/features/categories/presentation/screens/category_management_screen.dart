import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:shared/models/category_model.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  void _showAddOrEditDialog({CategoryModel? existing, CategoryModel? parent}) {
    final titleController = TextEditingController(text: existing?.name ?? '');
    final iconController = TextEditingController(text: existing?.iconUrl ?? 'brush');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? (parent == null ? 'Create New Category ✨' : 'Create Subcategory ✨') : 'Edit Category ✏️', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Category Title (e.g. Designer Footwear)', border: OutlineInputBorder()),
                ),
                if (parent == null) ...[
                  TextField(
                    controller: iconController,
                    decoration: const InputDecoration(labelText: 'Material Icon Name', hintText: 'brush, face, diamond', border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRuby, foregroundColor: Colors.white),
            onPressed: () {
              if (titleController.text.isEmpty) return;
              final notif = ref.read(adminCategoriesProvider.notifier);
              final allCats = ref.read(adminCategoriesProvider);

              if (existing == null) {
                // TODO: For subcategories, API should accept parent_category
                // Right now we'll just optimistically update or depend on API
                notif.addCategory(CategoryModel(
                  id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                  name: titleController.text.trim(),
                  slug: titleController.text.trim().toLowerCase().replaceAll(' ', '-'),
                  iconUrl: parent == null ? iconController.text.trim() : null,
                  displayOrder: allCats.length + 1,
                  isActive: true,
                  subcategories: const [],
                ));
              } else {
                notif.updateCategory(existing.copyWith(
                  name: titleController.text.trim(),
                  iconUrl: parent == null ? iconController.text.trim() : existing.iconUrl,
                ));
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Taxonomy successfully updated.')));
            },
            child: Text(existing == null ? 'Create Category' : 'Save Alterations'),
          ),
        ],
      ),
    );
  }

  void _onToggleActive(CategoryModel cat) {
    ref.read(adminCategoriesProvider.notifier).updateCategory(cat.copyWith(isActive: !cat.isActive));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${cat.name} visibility toggled to ${!cat.isActive ? "ACTIVE" : "HIDDEN"}.')));
  }

  void _onDelete(CategoryModel cat) {
    ref.read(adminCategoriesProvider.notifier).deleteCategory(cat.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${cat.name} removed from global marketplace classification.')));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Category & Taxonomy Engine'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomButton(
              label: '+ New Category',
              isFullWidth: false,
              onPressed: () => _showAddOrEditDialog(),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: categories.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.category_outlined,
                  title: 'Taxonomy Empty',
                  description: 'No classification categories have been populated in the marketplace.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return _buildCategoryCard(context, cat, index, categories.length);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel cat, int index, int total) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cat.isActive ? AppColors.accentGold.withValues(alpha: 0.3) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: index > 0 ? () => ref.read(adminCategoriesProvider.notifier).reorderCategories(index, index - 1) : null,
                  child: Icon(Icons.arrow_upward_rounded, size: 20, color: index > 0 ? AppColors.primaryRuby : Colors.grey.shade300),
                ),
                const SizedBox(height: 4),
                Text('#${cat.displayOrder}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.neutralCharcoal)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: index < total - 1 ? () => ref.read(adminCategoriesProvider.notifier).reorderCategories(index, index + 2) : null,
                  child: Icon(Icons.arrow_downward_rounded, size: 20, color: index < total - 1 ? AppColors.primaryRuby : Colors.grey.shade300),
                ),
              ],
            ),
            const SizedBox(width: 20),
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.12),
              child: Icon(_mapIcon(cat.iconUrl ?? 'category'), color: AppColors.primaryRuby, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.neutralCharcoal)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: cat.isActive ? Colors.green.withValues(alpha: 0.15) : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        child: Text(cat.isActive ? 'VISIBLE' : 'HIDDEN', style: TextStyle(color: cat.isActive ? Colors.green : Colors.grey.shade700, fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${cat.subcategories.length} Subcategories', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Icon Reference: ${cat.iconUrl ?? "none"}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(cat.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: cat.isActive ? Colors.green : Colors.grey),
                  tooltip: 'Toggle Marketplace Visibility',
                  onPressed: () => _onToggleActive(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.primaryRuby),
                  tooltip: 'Edit Category Properties',
                  onPressed: () => _showAddOrEditDialog(existing: cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Delete Category',
                  onPressed: () => _onDelete(cat),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _mapIcon(String name) {
    switch (name.toLowerCase()) {
      case 'brush':
        return Icons.brush_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'face_retouching_natural':
        return Icons.face_retouching_natural_rounded;
      case 'design_services':
        return Icons.design_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
