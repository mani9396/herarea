import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/data/mock/vendor_mock_data.dart';
import 'package:shared/shared.dart';

// Theme mode provider for Vendor App
final vendorThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Active store profile provider
final vendorStoreProvider = StateProvider<StoreModel>((ref) => VendorMockData.vendorStoreProfile);

// Reactive Product Catalog Provider
class VendorProductsNotifier extends StateNotifier<List<VendorProductModel>> {
  VendorProductsNotifier() : super(VendorMockData.initialProducts);

  void addProduct(VendorProductModel product) {
    state = [product, ...state];
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
  }
}

final vendorProductsProvider = StateNotifierProvider<VendorProductsNotifier, List<VendorProductModel>>((ref) => VendorProductsNotifier());

// Reactive Enquiries Provider
class VendorEnquiriesNotifier extends StateNotifier<List<VendorEnquiryModel>> {
  VendorEnquiriesNotifier() : super(VendorMockData.initialEnquiries);

  void updateStatus(String id, String newStatus) {
    state = [
      for (final e in state)
        if (e.id == id) e.copyWith(status: newStatus) else e,
    ];
  }
}

final vendorEnquiriesProvider = StateNotifierProvider<VendorEnquiriesNotifier, List<VendorEnquiryModel>>((ref) => VendorEnquiriesNotifier());

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
