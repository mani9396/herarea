import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:app_admin/data/mock/admin_mock_data.dart';

// --- Vendors State Notifier ---
class AdminVendorsNotifier extends StateNotifier<List<AdminVendorModel>> {
  AdminVendorsNotifier() : super(AdminMockData.initialVendors);

  void approveVendor(String id) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.approved, rejectionReason: null) else v,
    ];
  }

  void rejectVendor(String id, String reason) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.rejected, rejectionReason: reason) else v,
    ];
  }

  void suspendVendor(String id, String reason) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.suspended, rejectionReason: reason) else v,
    ];
  }

  void activateVendor(String id) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.approved, rejectionReason: null) else v,
    ];
  }
}

final adminVendorsProvider = StateNotifierProvider<AdminVendorsNotifier, List<AdminVendorModel>>((ref) {
  return AdminVendorsNotifier();
});

// --- Profile Updates State Notifier ---
class AdminProfileUpdatesNotifier extends StateNotifier<List<AdminProfileUpdateModel>> {
  AdminProfileUpdatesNotifier() : super(AdminMockData.initialProfileUpdates);

  void approveUpdate(String id) {
    state = [
      for (final u in state)
        if (u.id == id) u.copyWith(status: AdminStatus.approved) else u,
    ];
  }

  void rejectUpdate(String id) {
    state = [
      for (final u in state)
        if (u.id == id) u.copyWith(status: AdminStatus.rejected) else u,
    ];
  }
}

final adminProfileUpdatesProvider = StateNotifierProvider<AdminProfileUpdatesNotifier, List<AdminProfileUpdateModel>>((ref) {
  return AdminProfileUpdatesNotifier();
});

// --- Products State Notifier ---
class AdminProductsNotifier extends StateNotifier<List<AdminProductModel>> {
  AdminProductsNotifier() : super(AdminMockData.initialProducts);

  void approveProduct(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(status: AdminStatus.approved) else p,
    ];
  }

  void rejectProduct(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(status: AdminStatus.rejected) else p,
    ];
  }

  void removeProduct(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final adminProductsProvider = StateNotifierProvider<AdminProductsNotifier, List<AdminProductModel>>((ref) {
  return AdminProductsNotifier();
});

// --- Gallery State Notifier ---
class AdminGalleryNotifier extends StateNotifier<List<AdminGalleryModel>> {
  AdminGalleryNotifier() : super(AdminMockData.initialGallery);

  void approveImage(String id) {
    state = [
      for (final g in state)
        if (g.id == id) g.copyWith(status: AdminStatus.approved) else g,
    ];
  }

  void rejectImage(String id) {
    state = [
      for (final g in state)
        if (g.id == id) g.copyWith(status: AdminStatus.rejected) else g,
    ];
  }

  void deleteImage(String id) {
    state = state.where((g) => g.id != id).toList();
  }
}

final adminGalleryProvider = StateNotifierProvider<AdminGalleryNotifier, List<AdminGalleryModel>>((ref) {
  return AdminGalleryNotifier();
});

// --- Offers State Notifier ---
class AdminOffersNotifier extends StateNotifier<List<AdminOfferModel>> {
  AdminOffersNotifier() : super(AdminMockData.initialOffers);

  void approveOffer(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: AdminStatus.approved) else o,
    ];
  }

  void rejectOffer(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: AdminStatus.rejected) else o,
    ];
  }

  void expireOffer(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: AdminStatus.archived) else o,
    ];
  }
}

final adminOffersProvider = StateNotifierProvider<AdminOffersNotifier, List<AdminOfferModel>>((ref) {
  return AdminOffersNotifier();
});

// --- Customers State Notifier ---
class AdminCustomersNotifier extends StateNotifier<List<AdminCustomerModel>> {
  AdminCustomersNotifier() : super(AdminMockData.initialCustomers);

  void toggleBlockCustomer(String id, bool blocked) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(isBlocked: blocked) else c,
    ];
  }
}

final adminCustomersProvider = StateNotifierProvider<AdminCustomersNotifier, List<AdminCustomerModel>>((ref) {
  return AdminCustomersNotifier();
});

// --- Reviews State Notifier ---
class AdminReviewsNotifier extends StateNotifier<List<AdminReviewModel>> {
  AdminReviewsNotifier() : super(AdminMockData.initialReviews);

  void deleteReview(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: AdminStatus.rejected, isReported: false) else r,
    ];
  }

  void restoreReview(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: AdminStatus.approved, isReported: false) else r,
    ];
  }
}

final adminReviewsProvider = StateNotifierProvider<AdminReviewsNotifier, List<AdminReviewModel>>((ref) {
  return AdminReviewsNotifier();
});

// --- Categories State Notifier ---
class AdminCategoriesNotifier extends StateNotifier<List<AdminCategoryModel>> {
  AdminCategoriesNotifier() : super(AdminMockData.initialCategories);

  void addCategory(AdminCategoryModel cat) {
    state = [...state, cat];
  }

  void updateCategory(AdminCategoryModel cat) {
    state = [
      for (final c in state)
        if (c.id == cat.id) cat else c,
    ];
  }

  void deleteCategory(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final list = List<AdminCategoryModel>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    
    // update display order numbers
    state = [
      for (int i = 0; i < list.length; i++)
        list[i].copyWith(displayOrder: i + 1),
    ];
  }
}

final adminCategoriesProvider = StateNotifierProvider<AdminCategoriesNotifier, List<AdminCategoryModel>>((ref) {
  return AdminCategoriesNotifier();
});

// --- Notifications & Announcements ---
class AdminNotificationsNotifier extends StateNotifier<List<AdminNotificationItem>> {
  AdminNotificationsNotifier() : super(AdminMockData.initialNotifications);

  void addAnnouncement(String title, String body, String target) {
    final newItem = AdminNotificationItem(
      id: 'NOTIF-${state.length + 1}',
      title: title,
      body: body,
      targetGroup: target,
      sentAt: 'Just now',
    );
    state = [newItem, ...state];
  }
}

final adminNotificationsProvider = StateNotifierProvider<AdminNotificationsNotifier, List<AdminNotificationItem>>((ref) {
  return AdminNotificationsNotifier();
});

// --- Recent Activity Log ---
class AdminActivityLogNotifier extends StateNotifier<List<String>> {
  AdminActivityLogNotifier() : super(AdminMockData.recentActivities);

  void logActivity(String action) {
    state = [action, ...state];
  }
}

final adminActivityLogProvider = StateNotifierProvider<AdminActivityLogNotifier, List<String>>((ref) {
  return AdminActivityLogNotifier();
});

// --- Aggregated KPI Stats Provider ---
class AdminDashboardStats {
  final int totalCustomers;
  final int totalVendors;
  final int pendingVendors;
  final int pendingProducts;
  final int pendingGallery;
  final int pendingOffers;
  final int pendingProfileUpdates;
  final int reportedReviews;
  final double totalEstimatedRevenue;

  const AdminDashboardStats({
    required this.totalCustomers,
    required this.totalVendors,
    required this.pendingVendors,
    required this.pendingProducts,
    required this.pendingGallery,
    required this.pendingOffers,
    required this.pendingProfileUpdates,
    required this.reportedReviews,
    required this.totalEstimatedRevenue,
  });
}

final adminDashboardStatsProvider = Provider<AdminDashboardStats>((ref) {
  final customers = ref.watch(adminCustomersProvider);
  final vendors = ref.watch(adminVendorsProvider);
  final products = ref.watch(adminProductsProvider);
  final gallery = ref.watch(adminGalleryProvider);
  final offers = ref.watch(adminOffersProvider);
  final profileUpdates = ref.watch(adminProfileUpdatesProvider);
  final reviews = ref.watch(adminReviewsProvider);

  double revenue = 0;
  for (final v in vendors) {
    if (v.status == AdminStatus.approved) {
      revenue += v.totalRevenue;
    }
  }

  return AdminDashboardStats(
    totalCustomers: customers.length,
    totalVendors: vendors.length,
    pendingVendors: vendors.where((v) => v.status == AdminStatus.pending).length,
    pendingProducts: products.where((p) => p.status == AdminStatus.pending).length,
    pendingGallery: gallery.where((g) => g.status == AdminStatus.pending).length,
    pendingOffers: offers.where((o) => o.status == AdminStatus.pending).length,
    pendingProfileUpdates: profileUpdates.where((u) => u.status == AdminStatus.pending).length,
    reportedReviews: reviews.where((r) => r.isReported && r.status == AdminStatus.pending).length,
    totalEstimatedRevenue: revenue,
  );
});
