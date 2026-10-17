import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';

const int kMaxActiveStoriesPerVendor = 25;

final vendorStoriesProvider = AsyncNotifierProvider<VendorStoriesNotifier, List<StoryModel>>(
  VendorStoriesNotifier.new,
);

class VendorStoriesNotifier extends AsyncNotifier<List<StoryModel>> {
  @override
  Future<List<StoryModel>> build() async {
    return _fetchStories();
  }

  Future<List<StoryModel>> _fetchStories() async {
    final repo = ref.read(vendorApiRepositoryProvider);
    return repo.fetchStories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStories());
  }

  Future<StoryModel?> createStory({
    required String storyType,
    String? productId,
    dynamic mediaFile,
    String? mediaUrl,
    String? title,
    String? caption,
    double? price,
    double? promotionalPrice,
  }) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.length >= kMaxActiveStoriesPerVendor) {
      throw Exception('Active story limit ($kMaxActiveStoriesPerVendor) reached. Please delete an older story or wait for it to expire.');
    }

    final repo = ref.read(vendorApiRepositoryProvider);
    final created = await repo.createStory(
      storyType: storyType,
      productId: productId,
      mediaFile: mediaFile,
      mediaUrl: mediaUrl,
      title: title,
      caption: caption,
      price: price,
      promotionalPrice: promotionalPrice,
    );

    if (created != null) {
      state = AsyncValue.data([created, ...currentList]);
    }
    return created;
  }

  Future<bool> deleteStory(String storyId) async {
    final repo = ref.read(vendorApiRepositoryProvider);
    final success = await repo.deleteStory(storyId);
    if (success) {
      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data(currentList.where((s) => s.id != storyId).toList());
    }
    return success;
  }
}
