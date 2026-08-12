import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _ownerController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final store = ref.read(vendorStoreProvider);
    _ownerController = TextEditingController(text: store.name);
    _whatsappController = TextEditingController(text: store.whatsappNumber);
    _emailController = TextEditingController();
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
      appBar: AppBar(title: const Text('Edit Owner Contact Info'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Stack(
                    children: [
                      CircleAvatar(radius: 44, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop')),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 16, backgroundColor: AppColors.primaryRuby, child: Icon(Icons.camera_alt, color: Colors.white, size: 16))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomTextField(label: 'Store / Owner Name', controller: _ownerController, prefixIcon: Icons.person_rounded),
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
                    final updated = StoreModel(
                      id: currentStore.id,
                      name: _ownerController.text.trim(),
                      category: currentStore.category,
                      rating: currentStore.rating,
                      reviewCount: currentStore.reviewCount,
                      distanceKm: currentStore.distanceKm,
                      address: currentStore.address,
                      city: currentStore.city,
                      phoneNumber: currentStore.phoneNumber,
                      whatsappNumber: _whatsappController.text.trim(),
                      isVerified: currentStore.isVerified,
                      isSponsored: currentStore.isSponsored,
                      isOpenNow: currentStore.isOpenNow,
                      closingTimeText: currentStore.closingTimeText,
                      priceTier: currentStore.priceTier,
                      imageUrls: currentStore.imageUrls,
                      specialOffers: currentStore.specialOffers,
                      serviceTags: currentStore.serviceTags,
                      reviews: currentStore.reviews,
                      latitude: currentStore.latitude,
                      longitude: currentStore.longitude,
                      description: currentStore.description,
                      hasHomeMeasurement: currentStore.hasHomeMeasurement,
                    );
                    await ref.read(vendorStoreProvider.notifier).updateStore(updated);
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    router.pop();
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
