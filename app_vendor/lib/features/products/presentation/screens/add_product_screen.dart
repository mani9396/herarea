import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Maggam Blouses';
  final bool _isLoading = false;
  String? _errorMessage;

  void _onSave() {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter product title and price in INR.');
      return;
    }
    final newProd = VendorProductModel(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      category: _category,
      price: num.tryParse(_priceController.text.trim()) ?? 8500,
      inStock: true,
      imageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?q=80&w=600&auto=format&fit=crop',
      ordersCount: 0,
      description: _descController.text.trim().isEmpty ? 'Masterfully crafted silk and bead stitching for weddings.' : _descController.text.trim(),
    );
    ref.read(vendorProductsProvider.notifier).addProduct(newProd);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Bridal Creation'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  ErrorView(title: 'Validation Notice', message: _errorMessage!, onRetry: null),
                  const SizedBox(height: AppSpacing.md),
                ],
                CustomTextField(
                  label: 'Product Title',
                  hintText: 'e.g., Royal Kanjivaram Bridal Blouse with Zardosi',
                  controller: _titleController,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Maggam Blouses', 'Aari Embroidery', 'Saree Styling', 'Antique Jewellery', 'Bridal Dupattas']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _category = v);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CustomTextField(
                        label: 'Price in INR (₹)',
                        hintText: 'e.g. 14500',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Detailed Craftsmanship & Fabric Description',
                  hintText: 'Explain raw materials, gold zari density, and customization time...',
                  controller: _descController,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Upload High-Res Product Image', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryRuby, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primaryRuby.withValues(alpha: 0.05),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, color: AppColors.primaryRuby, size: 36),
                      SizedBox(height: 8),
                      Text('Tap to select from Gallery / Studio Folder', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                      Text('Recommended format: 1:1 square ratio, min 1080p', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Publish to O2O Catalog ✨',
                  isLoading: _isLoading,
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
