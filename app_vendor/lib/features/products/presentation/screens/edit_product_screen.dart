import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  late String _imageUrl;

  XFile? _newImageFile;
  Uint8List? _previewBytes;
  String? _newImageFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final prod = ref.read(vendorProductsProvider).firstWhere((p) => p.id == widget.productId);
    _titleController = TextEditingController(text: prod.title);
    _priceController = TextEditingController(text: prod.price.toString());
    _descController = TextEditingController(text: prod.description);
    _imageUrl = prod.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _newImageFile = picked;
          _previewBytes = bytes;
          _newImageFileName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    try {
      final existing = ref.read(vendorProductsProvider).firstWhere((p) => p.id == widget.productId);
      await ref.read(vendorProductsProvider.notifier).updateProduct(
            existing.copyWith(
              title: _titleController.text.trim(),
              price: num.tryParse(_priceController.text.trim()) ?? existing.price,
              description: _descController.text.trim(),
            ),
            imageFile: _newImageFile,
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image Preview with Change button
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: _previewBytes != null
                            ? Image.memory(
                                _previewBytes!,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                ),
                              ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                          label: Text(
                            _newImageFile != null ? 'Change Photo (${_newImageFileName ?? "Selected"})' : 'Change Original Photo 📸',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: _pickFromGallery,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                CustomTextField(label: 'Product Title', controller: _titleController),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Price in INR (₹)',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'Description & Details', controller: _descController),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Save Modifications 💾',
                  isLoading: _isLoading,
                  onPressed: _onSave,
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
