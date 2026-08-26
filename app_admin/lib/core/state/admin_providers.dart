import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/models/category_model.dart';
import 'package:app_admin/data/repositories/admin_api_repository.dart';

// --- Vendors State Notifier ---
class AdminVendorsNotifier extends StateNotifier<List<AdminVendorModel>> {
  final AdminApiRepository? _repository;

  AdminVendorsNotifier([this._repository]) : super(const []) {
    loadLiveVendors();
  }

  /// Synchronize with live Django REST backend if connected
  Future<void> loadLiveVendors() async {
    if (_repository == null) return;
    try {
      final liveVendors = await _repository.fetchAllVendors();
      state = liveVendors;
    } catch (_) {
      state = const [];
    }
  }

  void approveVendor(String id) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.approved, rejectionReason: null) else v,
    ];
    _repository?.approveVendor(id);
  }

  void rejectVendor(String id, String reason) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.rejected, rejectionReason: reason) else v,
    ];
    _repository?.rejectVendor(id, reason);
  }

  void suspendVendor(String id, String reason) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.suspended, rejectionReason: reason) else v,
    ];
    _repository?.suspendVendor(id, reason);
  }

  void activateVendor(String id) {
    state = [
      for (final v in state)
        if (v.id == id) v.copyWith(status: AdminStatus.approved, rejectionReason: null) else v,
    ];
    _repository?.approveVendor(id);
  }
}

final adminVendorsProvider = StateNotifierProvider<AdminVendorsNotifier, List<AdminVendorModel>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminVendorsNotifier(repo);
});

// --- Profile Updates State Notifier ---
class AdminProfileUpdatesNotifier extends StateNotifier<List<AdminProfileUpdateModel>> {
  AdminProfileUpdatesNotifier() : super(const []);

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
  final AdminApiRepository? _repository;

  AdminProductsNotifier([this._repository]) : super(const []) {
    loadLiveProducts();
  }

  Future<void> loadLiveProducts() async {
    if (_repository == null) return;
    try {
      final liveProducts = await _repository.fetchProducts();
      state = liveProducts;
    } catch (_) {
      state = const [];
    }
  }

  Future<void> moderateProduct(String id, String action, String remarks) async {
    if (_repository == null) return;
    try {
      final updatedProduct = await _repository!.moderateProduct(id, action, remarks);
      state = [
        for (final p in state)
          if (p.id == id) updatedProduct else p,
      ];
    } catch (_) {
      // Keep old state or handle error
    }
  }

  Future<void> deleteProduct(String id) async {
    if (_repository == null) return;
    try {
      final success = await _repository!.deleteProduct(id);
      if (success) {
        state = state.where((p) => p.id != id).toList();
      }
    } catch (_) {}
  }

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
    _repository?.deleteProduct(id);
  }

  void removeProduct(String id) {
    state = state.where((p) => p.id != id).toList();
    _repository?.deleteProduct(id);
  }
}

final adminProductsProvider = StateNotifierProvider<AdminProductsNotifier, List<AdminProductModel>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminProductsNotifier(repo);
});

// --- Gallery State Notifier ---
class AdminGalleryNotifier extends StateNotifier<List<AdminGalleryModel>> {
  final AdminApiRepository? _repository;

  AdminGalleryNotifier([this._repository]) : super(const []) {
    loadLiveGallery();
  }

  Future<void> loadLiveGallery() async {
    if (_repository == null) return;
    try {
      final liveGallery = await _repository.fetchGallery();
      state = liveGallery;
    } catch (_) {
      state = const [];
    }
  }

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
    _repository?.deleteGalleryImage(id);
  }

  void deleteImage(String id) {
    state = state.where((g) => g.id != id).toList();
    _repository?.deleteGalleryImage(id);
  }
}

final adminGalleryProvider = StateNotifierProvider<AdminGalleryNotifier, List<AdminGalleryModel>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminGalleryNotifier(repo);
});

// --- Offers State Notifier ---
class AdminOffersNotifier extends StateNotifier<List<AdminOfferModel>> {
  final AdminApiRepository? _repository;

  AdminOffersNotifier([this._repository]) : super(const []) {
    loadLiveOffers();
  }

  Future<void> loadLiveOffers() async {
    if (_repository == null) return;
    try {
      final liveOffers = await _repository.fetchOffers();
      state = liveOffers;
    } catch (_) {
      state = const [];
    }
  }

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
    _repository?.deleteOffer(id);
  }

  void expireOffer(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: AdminStatus.archived) else o,
    ];
    _repository?.deleteOffer(id);
  }
}

final adminOffersProvider = StateNotifierProvider<AdminOffersNotifier, List<AdminOfferModel>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminOffersNotifier(repo);
});

// --- Customers State Notifier ---
class AdminCustomersNotifier extends StateNotifier<List<AdminCustomerModel>> {
  final AdminApiRepository? _repository;

  AdminCustomersNotifier([this._repository]) : super(const []) {
    loadLiveCustomers();
  }

  Future<void> loadLiveCustomers() async {
    if (_repository == null) return;
    try {
      final liveCustomers = await _repository.fetchCustomers();
      state = liveCustomers;
    } catch (_) {
      state = const [];
    }
  }

  void toggleBlockCustomer(String id, bool blocked) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(isBlocked: blocked) else c,
    ];
    _repository?.updateCustomerBlockStatus(id, blocked);
  }
}

final adminCustomersProvider = StateNotifierProvider<AdminCustomersNotifier, List<AdminCustomerModel>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminCustomersNotifier(repo);
});

// --- Reviews State Notifier ---
class AdminReviewsNotifier extends StateNotifier<List<AdminReviewModel>> {
  final AdminApiRepository? _repository;

  AdminReviewsNotifier([this._repository]) : super(const []) {
    loadLiveReviews();
  }

  Future<void> loadLiveReviews() async {
    if (_repository == null) return;
    try {
      final liveReviews = await _repository.fetchReviews();
      state = liveReviews;
    } catch (_) {
      state = const [];
    }
  }

  void deleteReview(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: AdminStatus.rejected, isReported: false) else r,
    ];
    _repository?.deleteReview(id);
  }

  void restoreReview(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: AdminStatus.approved, isReported: false) else r,
    ];
  }

  Future<void> approveReview(String id) async {
    // Optimistic update
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: AdminStatus.approved, isReported: false) else r,
    ];
    await _repository?.approveReview(id);
    // Reload live data to ensure consistency
    await loadLiveReviews();
  }

  Future<void> rejectReview(String id) async {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: AdminStatus.rejected, isReported: false) else r,
    ];
    await _repository?.rejectReview(id);
    await loadLiveReviews();
  }

  Future<void> hideReview(String id) async {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: AdminStatus.pending, isReported: false) else r,
    ];
    await _repository?.hideReview(id);
    await loadLiveReviews();
  }
}

final adminReviewsProvider = StateNotifierProvider<AdminReviewsNotifier, List<AdminReviewModel>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminReviewsNotifier(repo);
});


// --- Categories State Notifier ---
class AdminCategoriesNotifier extends StateNotifier<List<CategoryModel>> {
  final AdminApiRepository _api;

  AdminCategoriesNotifier(this._api) : super([]) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.fetchCategories();
      state = categories;
    } catch (e) {
      // Typically, errors are handled by a dedicated UI error handler, 
      // but state can just remain empty or we can add a loading/error state if needed.
    }
  }

  void addCategory(CategoryModel cat) async {
    final created = await _api.createCategory(cat);
    if (created != null) {
      state = [...state, created];
    }
  }

  void updateCategory(CategoryModel cat) {
    // TODO: implement actual API PUT request for updates
    // For now we optimistically update state:
    final index = state.indexWhere((c) => c.id == cat.id);
    if (index != -1) {
      final list = List<CategoryModel>.from(state);
      list[index] = cat;
      state = list;
    }
  }

  void deleteCategory(String id) {
    // TODO: implement actual API DELETE
    state = state.where((c) => c.id != id).toList();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final list = List<CategoryModel>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    
    // update display order numbers
    state = [
      for (int i = 0; i < list.length; i++)
        list[i].copyWith(displayOrder: i + 1),
    ];
  }
}

final adminCategoriesProvider = StateNotifierProvider<AdminCategoriesNotifier, List<CategoryModel>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminCategoriesNotifier(repo);
});

// --- Notifications & Announcements ---
class AdminNotificationsNotifier extends StateNotifier<List<AdminNotificationItem>> {
  final AdminApiRepository? _repository;

  AdminNotificationsNotifier([this._repository]) : super(const []) {
    loadLiveNotifications();
  }

  Future<void> loadLiveNotifications() async {
    if (_repository == null) return;
    try {
      final liveNotifs = await _repository.fetchNotifications();
      state = liveNotifs;
    } catch (_) {
      state = const [];
    }
  }

  void addAnnouncement(String title, String body, String target) {
    final newItem = AdminNotificationItem(
      id: 'NOTIF-${state.length + 1}',
      title: title,
      body: body,
      targetGroup: target,
      sentAt: 'Just now',
    );
    state = [newItem, ...state];
    _repository?.broadcastNotification(title, body, target);
  }
}

final adminNotificationsProvider = StateNotifierProvider<AdminNotificationsNotifier, List<AdminNotificationItem>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminNotificationsNotifier(repo);
});

// --- Recent Activity Log ---
class AdminActivityLogNotifier extends StateNotifier<List<String>> {
  final AdminApiRepository? _repository;

  AdminActivityLogNotifier([this._repository]) : super(const []) {
    loadLiveActivityLogs();
  }

  Future<void> loadLiveActivityLogs() async {
    if (_repository == null) return;
    try {
      final liveLogs = await _repository.fetchActivityLogs();
      state = liveLogs;
    } catch (_) {
      state = const [];
    }
  }

  void logActivity(String action) {
    state = [action, ...state];
  }
}

final adminActivityLogProvider = StateNotifierProvider<AdminActivityLogNotifier, List<String>>((ref) {
  final repo = ref.watch(adminApiRepositoryProvider);
  return AdminActivityLogNotifier(repo);
});

// --- Platform Telemetry & Analytics Provider ---
final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminApiRepositoryProvider);
  return await repo.fetchAdminDashboardStats();
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
  final products = ref.watch(adminProductsProvider);
  final gallery = ref.watch(adminGalleryProvider);
  final offers = ref.watch(adminOffersProvider);
  final profileUpdates = ref.watch(adminProfileUpdatesProvider);
  final reviews = ref.watch(adminReviewsProvider);

  final analytics = ref.watch(adminAnalyticsProvider).valueOrNull;

  return AdminDashboardStats(
    totalCustomers: analytics?['total_customers'] ?? 0,
    totalVendors: analytics?['verified_vendors'] ?? 0,
    pendingVendors: analytics?['pending_vendors'] ?? 0,
    pendingProducts: products.where((p) => p.status == AdminStatus.pending).length,
    pendingGallery: gallery.where((g) => g.status == AdminStatus.pending).length,
    pendingOffers: offers.where((o) => o.status == AdminStatus.pending).length,
    pendingProfileUpdates: profileUpdates.where((u) => u.status == AdminStatus.pending).length,
    reportedReviews: reviews.where((r) => r.isReported && r.status == AdminStatus.pending).length,
    totalEstimatedRevenue: (analytics?['total_gmv'] ?? 0).toDouble(),
  );
});
