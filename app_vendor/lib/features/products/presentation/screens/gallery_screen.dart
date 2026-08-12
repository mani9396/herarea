import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(vendorGalleryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Showcase Gallery 📸'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(vendorGalleryProvider.notifier).addImage('https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=800&auto=format&fit=crop');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New bridal portfolio photo added to studio showroom!')));
        },
        backgroundColor: AppColors.primaryRuby,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Upload Photo'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: images.isEmpty
              ? const Center(child: Text('No showcase images found. Upload your finest creations!', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(images[index], fit: BoxFit.cover),
                          Positioned(
                            top: 8, right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                                onPressed: () => ref.read(vendorGalleryProvider.notifier).removeImageAt(index),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}