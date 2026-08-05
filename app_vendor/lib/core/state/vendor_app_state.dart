import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/data/mock/vendor_mock_data.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';
import 'package:shared/shared.dart';

// Theme mode provider for Vendor App
final vendorThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Active store profile provider
final vendorStoreProvider = StateProvider<StoreModel>((ref) => VendorMockData.vendorStoreProfile);

// Reactive Product Catalog Provider
class VendorProductsNotifier extends StateNotifier<List<VendorProductModel>> {
  final VendorApiRepository? _repository;

  VendorProductsNotifier([this._repository]) : super(VendorMockData.initialProducts) {
    loadLiveProducts();
  }

  /// Synchronize studio catalog inventory with live Django backend
  Future<void> loadLiveProducts() async {
    if (_repository == null) return;
    try {
      final liveProducts = await _repository.fetchProducts();
      if (liveProducts.isNotEmpty) {
        state = liveProducts;
      }
    } catch (_) {
      // Keep realistic fallback catalog when disconnected or demonstrating offline
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
  }

  void toggleStock(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(inStock: !p.inStock) else p,
    ];
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

  VendorEnquiriesNotifier([this._repository]) : super(VendorMockData.initialEnquiries) {
    loadLiveEnquiries();
  }

  /// Synchronize appointment consultations with live Django backend
  Future<void> loadLiveEnquiries() async {
    if (_repository == null) return;
    try {
      final liveEnquiries = await _repository.fetchEnquiries();
      if (liveEnquiries.isNotEmpty) {
        state = liveEnquiries;
      }
    } catch (_) {
      // Keep fallback inquiry data when offline
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
  VendorNotificationsNotifier() : super(VendorMockData.initialNotifications);

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
  }
}

final vendorNotificationsProvider = StateNotifierProvider<VendorNotificationsNotifier, List<VendorNotificationModel>>((ref) => VendorNotificationsNotifier());

// Business Settings State Provider
final vendorVacationModeProvider = StateProvider<bool>((ref) => false);
final vendorAutoReplyProvider = StateProvider<bool>((ref) => true);
