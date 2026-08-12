import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/data/models/vendor_models.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';
import 'package:shared/shared.dart';

export 'package:app_vendor/data/models/vendor_models.dart';

// Theme mode provider for Vendor App
final vendorThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

const _defaultStore = StoreModel(
  id: 'vendor_store',
  name: 'My Partner Studio',
  category: BusinessCategory.maggam,
  rating: 0.0,
  reviewCount: 0,
  distanceKm: 0.0,
  address: 'Address not configured',
  city: 'City',
  phoneNumber: '',
  whatsappNumber: '',
  isVerified: false,
  isOpenNow: true,
  closingTimeText: 'Closing time not configured',
  priceTier: '₹₹',
  description: 'Studio profile under setup.',
  imageUrls: [],
  specialOffers: [],
  serviceTags: [],
  latitude: 0.0,
  longitude: 0.0,
);

// Active store profile provider
class VendorStoreNotifier extends StateNotifier<StoreModel> {
  final VendorApiRepository? _repository;
  VendorStoreNotifier([this._repository]) : super(_defaultStore) {
    loadLiveStore();
  }

  Future<void> loadLiveStore() async {
    if (_repository == null) return;
    try {
      final liveStore = await _repository.fetchMyStore();
      if (liveStore != null) {
        state = liveStore;
      }
    } catch (_) {}
  }

  Future<void> updateStore(StoreModel newStore) async {
    state = newStore;
    if (_repository != null) {
      await _repository.updateStore(newStore);
    }
  }
}

final vendorStoreProvider = StateNotifierProvider<VendorStoreNotifier, StoreModel>((ref) {
  final repo = ref.watch(vendorApiRepositoryProvider);
  return VendorStoreNotifier(repo);
});

// Reactive Product Catalog Provider
class VendorProductsNotifier extends StateNotifier<List<VendorProductModel>> {
  final VendorApiRepository? _repository;

  VendorProductsNotifier([this._repository]) : super([]) {
    loadLiveProducts();
  }

  /// Synchronize studio catalog inventory with live Django backend
  Future<void> loadLiveProducts() async {
    if (_repository == null) return;
    try {
      final liveProducts = await _repository.fetchProducts();
      state = liveProducts;
    } catch (_) {
      state = [];
    }
  }

  void addProduct(VendorProductModel product) {
    state = [product, ...state];
    _repository?.createProduct(product);
  }

  void updateProduct(VendorProductModel updated) {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
    _repository?.updateProduct(updated);
  }

  void toggleStock(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(inStock: !p.inStock) else p,
    ];
    final target = state.where((p) => p.id == id).firstOrNull;
    if (target != null) {
      _repository?.updateProduct(target);
    }
  }

  void deleteProduct(String id) {
    state = state.where((p) => p.id != id).toList();
    _repository?.deleteProduct(id);
  }
}

final vendorProductsProvider = StateNotifierProvider<VendorProductsNotifier, List<VendorProductModel>>((ref) {
  final repo = ref.watch(vendorApiRepositoryProvider);
  return VendorProductsNotifier(repo);
});

// Reactive Enquiries & Appointments Provider
class VendorEnquiriesNotifier extends StateNotifier<List<VendorEnquiryModel>> {
  final VendorApiRepository? _repository;

  VendorEnquiriesNotifier([this._repository]) : super([]) {
    loadLiveEnquiries();
  }

  /// Synchronize appointment consultations with live Django backend
  Future<void> loadLiveEnquiries() async {
    if (_repository == null) return;
    try {
      final liveEnquiries = await _repository.fetchEnquiries();
      state = liveEnquiries;
    } catch (_) {
      state = [];
    }
  }

  void updateStatus(String id, String newStatus) {
    state = [
      for (final e in state)
        if (e.id == id) e.copyWith(status: newStatus) else e,
    ];
    _repository?.updateEnquiryStatus(id, newStatus);
  }
}

final vendorEnquiriesProvider = StateNotifierProvider<VendorEnquiriesNotifier, List<VendorEnquiryModel>>((ref) {
  final repo = ref.watch(vendorApiRepositoryProvider);
  return VendorEnquiriesNotifier(repo);
});

// Reactive Notifications Provider
class VendorNotificationsNotifier extends StateNotifier<List<VendorNotificationModel>> {
  final VendorApiRepository? _repository;

  VendorNotificationsNotifier([this._repository]) : super([]) {
    loadLiveNotifications();
  }

  Future<void> loadLiveNotifications() async {
    if (_repository == null) return;
    final live = await _repository.fetchNotifications();
    state = live;
  }

  void markAllAsRead() {
    state = [
      for (final n in state)
        VendorNotificationModel(
          id: n.id,
          title: n.title,
          description: n.description,
          timestamp: n.timestamp,
          icon: n.icon,
          isUnread: false,
        ),
    ];
    for (final n in state) {
      _repository?.markNotificationAsRead(n.id);
    }
  }
}

final vendorNotificationsProvider = StateNotifierProvider<VendorNotificationsNotifier, List<VendorNotificationModel>>((ref) {
  final repo = ref.watch(vendorApiRepositoryProvider);
  return VendorNotificationsNotifier(repo);
});

// Reactive Gallery Provider
class VendorGalleryNotifier extends StateNotifier<List<String>> {
  final VendorApiRepository? _repository;

  VendorGalleryNotifier([this._repository]) : super([]) {
    loadLiveGallery();
  }

  Future<void> loadLiveGallery() async {
    if (_repository == null) return;
    final images = await _repository.fetchGalleryImages();
    state = images;
  }

  Future<void> addImage(String urlOrPath) async {
    state = [urlOrPath, ...state];
    await _repository?.uploadGalleryImage(urlOrPath);
  }

  Future<void> removeImageAt(int index) async {
    if (index >= 0 && index < state.length) {
      final url = state[index];
      state = [...state]..removeAt(index);
      await _repository?.deleteGalleryImage(url);
    }
  }
}

final vendorGalleryProvider = StateNotifierProvider<VendorGalleryNotifier, List<String>>((ref) {
  final repo = ref.watch(vendorApiRepositoryProvider);
  return VendorGalleryNotifier(repo);
});

// Reactive Analytics Stats Provider
final vendorStatsProvider = FutureProvider<VendorStatsModel>((ref) async {
  final repo = ref.watch(vendorApiRepositoryProvider);
  return repo.fetchVendorStats();
});

// Reactive Customer Reviews Provider
class VendorReviewsNotifier extends StateNotifier<List<VendorCustomerReviewModel>> {
  final VendorApiRepository? _repository;
  final String _storeId;

  VendorReviewsNotifier(this._repository, this._storeId) : super([]) {
    loadLiveReviews();
  }

  Future<void> loadLiveReviews() async {
    if (_repository == null) return;
    final live = await _repository.fetchCustomerReviews(_storeId);
    state = live;
  }

  Future<void> replyToReview(String reviewId, String replyText) async {
    state = [
      for (final r in state)
        if (r.id == reviewId) r.copyWith(vendorReply: replyText) else r,
    ];
    await _repository?.replyToReview(reviewId, replyText);
  }
}

final vendorReviewsProvider = StateNotifierProvider<VendorReviewsNotifier, List<VendorCustomerReviewModel>>((ref) {
  final repo = ref.watch(vendorApiRepositoryProvider);
  final store = ref.watch(vendorStoreProvider);
  return VendorReviewsNotifier(repo, store.id);
});

// Business Settings State Provider
final vendorVacationModeProvider = StateProvider<bool>((ref) => false);
final vendorAutoReplyProvider = StateProvider<bool>((ref) => true);
