import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';

class UploadBrandingScreen extends ConsumerStatefulWidget {
  const UploadBrandingScreen({super.key});

  @override
  ConsumerState<UploadBrandingScreen> createState() => _UploadBrandingScreenState();
}

class _UploadBrandingScreenState extends ConsumerState<UploadBrandingScreen> {
  String? _logoUrl;
  String? _coverUrl;
  XFile? _logoFile;
  XFile? _coverFile;
  
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(vendorStoreProvider);
      if (store != null) {
        setState(() {
          _logoUrl = store.logo;
          _coverUrl = store.coverImage;
        });
      }
    });
  }

  Future<void> _onUploadLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 500,
      maxHeight: 500,
    );
    if (image != null) {
      setState(() => _logoFile = image);
    }
  }

  Future<void> _onUploadCover() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (image != null) {
      setState(() => _coverFile = image);
    }
  }

  Future<void> _onContinue() async {
    final currentStore = ref.read(vendorStoreProvider);
    if (currentStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store profile not found. Please complete step 1 first.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(vendorApiRepositoryProvider);
      await repo.updateStore(
        currentStore,
        logoFile: _logoFile,
        coverImageFile: _coverFile,
      );
      
      ref.read(vendorStoreProvider.notifier).loadLiveStore();
      if (mounted) context.push(VendorRoutePaths.storeTiming);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 2: Studio Branding'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Upload Store Logo & Cover Banner', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.xs),
                Text('These images define your boutique presentation across bridal category listings and search results in Jubilee Hills & Banjara Hills.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600], height: 1.4)),
                const SizedBox(height: AppSpacing.xl),
                Text('Widescreen Cover Banner (16:9)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: _onUploadCover,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.4), width: 2),
                      color: Colors.grey[200],
                      image: _coverFile != null 
                        ? DecorationImage(image: NetworkImage(_coverFile!.path), fit: BoxFit.cover)
                        : (_coverUrl != null && _coverUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(_coverUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 40),
                            SizedBox(height: 8),
                            Text('Tap to Replace Cover Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Recommended: 1920 x 1080px resolution', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Boutique Profile Logo / Emblem (1:1)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentGold, width: 3),
                        color: Colors.grey[200],
                        image: _logoFile != null
                          ? DecorationImage(image: NetworkImage(_logoFile!.path), fit: BoxFit.cover)
                          : (_logoUrl != null && _logoUrl!.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Circular Brand Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Displayed inside circular badges next to customer reviews & quotes.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: _onUploadLogo,
                            icon: const Icon(Icons.upload_rounded, size: 18, color: AppColors.primaryRuby),
                            label: const Text('Change Logo', style: TextStyle(color: AppColors.primaryRuby)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primaryRuby)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.accentGold, size: 26),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Pro Tip: Studios featuring high-resolution Maggam silk imagery receive 3.4x higher WhatsApp fitting inquiries.',
                          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Save Branding & Continue ➡️',
                  isLoading: _isLoading,
                  onPressed: _onContinue,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push(VendorRoutePaths.storeTiming),
                  child: const Text('Skip for now (Use defaults)', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
