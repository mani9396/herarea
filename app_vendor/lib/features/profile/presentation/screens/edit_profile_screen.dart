import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _ownerController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  CategoryModel? _selectedCategory;
  CategoryModel? _selectedSubcategory;
  bool _isLoading = false;
  String? _localLogoPath;
  String? _localCoverPath;

  @override
  void initState() {
    super.initState();
    final store = ref.read(vendorStoreProvider);
    _ownerController = TextEditingController(text: store?.name ?? '');
    _whatsappController = TextEditingController(text: store?.whatsappNumber ?? '');
    _emailController = TextEditingController();
    _selectedCategory = store?.category;
    _selectedSubcategory = store?.subcategory;
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Store Profile'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover Image
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() => _localCoverPath = image.path);
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: _localCoverPath != null 
                          ? DecorationImage(
                              image: kIsWeb 
                                  ? NetworkImage(_localCoverPath!) as ImageProvider 
                                  : FileImage(File(_localCoverPath!)), 
                              fit: BoxFit.cover)
                          : (ref.read(vendorStoreProvider)?.coverImage != null 
                              ? DecorationImage(image: NetworkImage(ref.read(vendorStoreProvider)!.coverImage!), fit: BoxFit.cover)
                              : null),
                    ),
                    child: _localCoverPath == null && ref.read(vendorStoreProvider)?.coverImage == null
                        ? const Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text('Add Cover Image', style: TextStyle(color: Colors.grey)),
                            ],
                          ))
                        : const Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryRuby,
                                child: Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Logo
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundImage: _localLogoPath != null
                            ? (kIsWeb ? NetworkImage(_localLogoPath!) : FileImage(File(_localLogoPath!))) as ImageProvider
                            : NetworkImage(ref.read(vendorStoreProvider)?.logo ?? 'https://i.pravatar.cc/150'),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setState(() => _localLogoPath = image.path);
                            }
                          },
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryRuby,
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomTextField(label: 'Store / Owner Name', controller: _ownerController, prefixIcon: Icons.person_rounded),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () async {
                    final res = await context.push<Map<String, dynamic>>(VendorRoutePaths.categorySelection);
                    if (res != null) {
                      setState(() {
                        _selectedCategory = res['category'];
                        _selectedSubcategory = res['subcategory'];
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'Artisanal Category & Subcategory',
                      hintText: 'Select Specialty',
                      controller: TextEditingController(
                        text: _selectedCategory != null 
                          ? '${_selectedCategory!.name}${_selectedSubcategory != null ? " - ${_selectedSubcategory!.name}" : ""}' 
                          : ''
                      ),
                      prefixIcon: Icons.category_rounded,
                      suffixWidget: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'WhatsApp Business Lead Number', controller: _whatsappController, keyboardType: TextInputType.phone, prefixIcon: Icons.chat_rounded),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'Business Email Address', controller: _emailController, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_rounded),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Update Contact Credentials 💾',
                  isLoading: _isLoading,
                  onPressed: () async {
                    final router = GoRouter.of(context);
                    setState(() => _isLoading = true);
                    final currentStore = ref.read(vendorStoreProvider);
                    if (currentStore == null) {
                      if (mounted) setState(() => _isLoading = false);
                      return;
                    }
                    final updatedStore = currentStore.copyWith(
                      name: _ownerController.text.trim(),
                      whatsappNumber: _whatsappController.text.trim(),
                      category: _selectedCategory,
                      subcategory: _selectedSubcategory,
                      logo: _localLogoPath ?? currentStore.logo,
                      coverImage: _localCoverPath ?? currentStore.coverImage,
                    );

                    try {
                      await ref.read(vendorStoreProvider.notifier).updateStore(updatedStore);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green));
                        router.pop();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
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