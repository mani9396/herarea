import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// Notifier that tracks which 24-hour stories have been viewed by the customer.
/// Persists viewed story IDs to local storage so viewed state survives app reloads.
class ViewedStoriesNotifier extends StateNotifier<Set<String>> {
  static const String _storageKey = 'her_area_viewed_stories';

  ViewedStoriesNotifier() : super({}) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      if (list.isNotEmpty) {
        state = list.toSet();
      }
    } catch (_) {}
  }

  /// Mark a single story as viewed
  Future<void> markStoryViewed(String storyId) async {
    if (state.contains(storyId)) return;
    final updated = {...state, storyId};
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, updated.toList());
    } catch (_) {}
  }

  /// Mark multiple stories as viewed
  Future<void> markMultipleViewed(Iterable<String> storyIds) async {
    final toAdd = storyIds.where((id) => !state.contains(id)).toList();
    if (toAdd.isEmpty) return;
    final updated = {...state, ...toAdd};
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, updated.toList());
    } catch (_) {}
  }

  /// Check if a single story has been viewed
  bool isStoryViewed(String storyId) => state.contains(storyId);

  /// Check if all stories for a store group have been viewed
  bool isGroupAllViewed(Iterable<String> storyIds) {
    if (storyIds.isEmpty) return false;
    return storyIds.every((id) => state.contains(id));
  }
}

/// Global provider for customer viewed story IDs
final viewedStoriesProvider = StateNotifierProvider<ViewedStoriesNotifier, Set<String>>((ref) {
  return ViewedStoriesNotifier();
});
