import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _category;

  XFile? _selectedImageFile;
  Uint8List? _previewBytes;
  String? _imageFileName;

  bool _isLoading = false;
  String? _errorMessage;

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
          _selectedImageFile = picked;
          _previewBytes = bytes;
          _imageFileName = picked.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSave() async {
    if (_titleController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _category == null) {
      setState(() => _errorMessage = 'Please provide product title, price, and select a category.');
      return;
    }

    if (_selectedImageFile == null) {
      setState(() => _errorMessage = 'Please upload an original photo of your product from your gallery.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newProd = VendorProductModel(
      id: 'PROD-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      category: _category!,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      isAvailable: true,
      imageUrl: '',
      ordersCount: 0,
      description: _descController.text.trim().isEmpty
          ? 'Handcrafted studio couture item.'
          : _descController.text.trim(),
    );

    try {
      await ref.read(vendorProductsProvider.notifier).addProduct(
            newProd,
            imageFile: _selectedImageFile,
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product to Catalog'),
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
                if (_errorMessage != null) ...[
                  ErrorView(title: 'Validation Notice', message: _errorMessage!, onRetry: null),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Upload Original Product Photo ──
                Text(
                  'Original Product Photo',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload an original high-resolution picture from your studio or gallery',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Interactive Image Upload Box
                InkWell(
                  onTap: _pickFromGallery,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _previewBytes != null ? AppColors.primaryRuby : Colors.grey.shade300,
                        width: _previewBytes != null ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: _previewBytes != null ? Colors.black87 : AppColors.primaryRuby.withValues(alpha: 0.04),
                    ),
                    child: _previewBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  _previewBytes!,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _imageFileName ?? 'Original Photo Selected',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: _pickFromGallery,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryRuby,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Change 📸',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRuby.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: AppColors.primaryRuby,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tap to upload original picture',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryRuby,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Select from device gallery or studio files',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'JPG, PNG, WEBP • High Resolution',
                                  style: TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                CustomTextField(
                  label: 'Product Title',
                  hintText: 'e.g., Handloom Silk Saree with Antique Zari',
                  controller: _titleController,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final catsAsync = ref.watch(vendorCategoriesProvider);
                          return catsAsync.when(
                            data: (cats) {
                              if (cats.isEmpty) return const Text('No categories');
                              return DropdownButtonFormField<String>(
                                value: _category,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _category = v);
                                },
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (e, s) => const Text('Error loading categories'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CustomTextField(
                        label: 'Price in INR (₹)',
                        hintText: 'e.g. 8500',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Product Description & Fabric Details',
                  hintText: 'Describe material, craftsmanship, fit, and care instructions...',
                  controller: _descController,
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Publish Product ✨',
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
