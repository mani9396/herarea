import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final prod = ref.read(vendorProductsProvider).firstWhere((p) => p.id == widget.productId);
    _titleController = TextEditingController(text: prod.title);
    _priceController = TextEditingController(text: prod.price.toString());
    _descController = TextEditingController(text: prod.description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bridal Creation'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(label: 'Product Title', controller: _titleController),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'Price in INR (₹)', controller: _priceController, keyboardType: TextInputType.number),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'Description & Details', controller: _descController),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Save Modifications 💾',
                  isLoading: _isLoading,
                  onPressed: () {
                    final router = GoRouter.of(context);
                    setState(() => _isLoading = true);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (!mounted) return;
                      final existing = ref.read(vendorProductsProvider).firstWhere((p) => p.id == widget.productId);
                      ref.read(vendorProductsProvider.notifier).updateProduct(existing.copyWith(
                        title: _titleController.text.trim(),
                        price: num.tryParse(_priceController.text.trim()) ?? existing.price,
                        description: _descController.text.trim(),
                      ));
                      router.pop();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: 'Delete Product from Catalog',
                  isOutlined: true,
                  onPressed: () {
                    ref.read(vendorProductsProvider.notifier).deleteProduct(widget.productId);
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
