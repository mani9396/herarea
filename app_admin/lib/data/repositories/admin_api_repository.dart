import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_admin/domain/models/admin_models.dart';

class AdminApiRepository {
  final IApiClient _apiClient;

  const AdminApiRepository(this._apiClient);

  /// Fetch list of pending studio partner onboarding applications
  Future<List<AdminVendorModel>> fetchPendingVendors() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminPendingVendors);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminVendorModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      // Re-throw or log for state controllers to fall back gracefully to offline cache
      rethrow;
    }
  }

  /// Fetch list of all studio partner applications (all statuses)
  Future<List<AdminVendorModel>> fetchAllVendors() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminAllVendors);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminVendorModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch admin dashboard statistics
  Future<Map<String, dynamic>> fetchAdminDashboardStats() async {
    try {
      return await _apiClient.get(ApiEndpoints.adminDashboardStats);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new vendor and return the temporary credentials response
  Future<Map<String, dynamic>> createVendor({
    required String ownerName,
    required String officialEmail,
    required String phoneNumber,
    required String businessName,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminVendorCreate,
        body: {
          'owner_name': ownerName,
          'official_email': officialEmail,
          'phone_number': phoneNumber,
          'business_name': businessName,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Execute executive approval on a pending partner studio
  Future<bool> approveVendor(String vendorId) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.adminVendorApprove(vendorId));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Reject an onboarding application with documented executive rationale
  Future<bool> rejectVendor(String vendorId, String reason) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminVendorReject(vendorId),
        body: {'reason': reason},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Suspend an active studio partner due to compliance audit or dispute resolution
  Future<bool> suspendVendor(String vendorId, String reason) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminVendorSuspend(vendorId),
        body: {'reason': reason},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Store Governance: Fetch stores by status
  Future<List<StoreModel>> fetchStores({String? status}) async {
    try {
      final url = status != null ? '${ApiEndpoints.adminStores}?status=$status' : ApiEndpoints.adminStores;
      final response = await _apiClient.get(url);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => StoreModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Store Governance: Approve store
  Future<bool> approveStore(String storeId) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.adminStoreApprove(storeId));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Store Governance: Reject store
  Future<bool> rejectStore(String storeId, String reason) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminStoreReject(storeId),
        body: {'reason': reason},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Store Governance: Suspend store
  Future<bool> suspendStore(String storeId, String reason) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminStoreSuspend(storeId),
        body: {'reason': reason},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all active and inactive marketplace categories
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.publicCategories);
      final list = response.containsKey('results') ? response['results'] as List : response as List;
      return list.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Create a new taxonomy category
  Future<CategoryModel?> createCategory(CategoryModel category) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminCategories,
        body: category.toJson(),
      );
      return CategoryModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Fetch all catalog products across all vendor studios for moderation
  Future<List<AdminProductModel>> fetchProducts() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminProducts);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminProductModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete or reject a product catalog item
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.adminProductDetail(id));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Moderate a product
  Future<AdminProductModel> moderateProduct(String id, String action, String remarks) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.adminProducts}$id/$action/',
        body: {'admin_remarks': remarks},
      );
      return AdminProductModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all promotional offers across marketplace
  Future<List<AdminOfferModel>> fetchOffers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminOffers);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminOfferModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete or expire a promotional offer
  Future<bool> deleteOffer(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.adminOfferDetail(id));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Fetch studio gallery imagery for platform quality review
  Future<List<AdminGalleryModel>> fetchGallery() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminGallery);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminGalleryModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove non-compliant gallery photo
  Future<bool> deleteGalleryImage(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.adminGalleryDetail(id));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Fetch registered consumer user accounts
  Future<List<AdminCustomerModel>> fetchCustomers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminCustomers);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminCustomerModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle suspension / block status of consumer account
  Future<bool> updateCustomerBlockStatus(String id, bool isBlocked) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.adminCustomerDetail(id),
        body: {'is_blocked': isBlocked},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Update vendor chat status
  Future<bool> updateVendorChatStatus(String vendorId, AdminChatStatus chatStatus) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminVendorChatStatus(vendorId),
        body: {'chat_status': chatStatus.apiCode},
      );
      return (response['status_code'] as int? ?? 200) <= 204 || response['id'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all customer reviews across showrooms
  Future<List<AdminReviewModel>> fetchReviews() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminReviews);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminReviewModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete spam or inappropriate review
  Future<bool> deleteReview(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.adminReviewDetail(id));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Approve a customer review — makes it publicly visible
  Future<bool> approveReview(String id) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.adminReviewDetail(id),
        body: {'status': 'APPROVED'},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Reject a customer review — hides it from public
  Future<bool> rejectReview(String id) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.adminReviewDetail(id),
        body: {'status': 'REJECTED'},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Hide a previously approved review
  Future<bool> hideReview(String id) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.adminReviewDetail(id),
        body: {'status': 'HIDDEN'},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Fetch system activity audit log feed
  Future<List<String>> fetchActivityLogs() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminActivityLogs);
      final list = response['results'] as List?;
      if (list != null) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Broadcast push announcements to targeted user cohorts
  Future<bool> broadcastNotification(String title, String body, String targetGroup) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminBroadcastNotification,
        body: {
          'title': title,
          'body': body,
          'targetGroup': targetGroup,
        },
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Fetch historical administrative broadcast announcements and alerts
  Future<List<AdminNotificationItem>> fetchNotifications() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminNotifications);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminNotificationItem.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch executive platform health, infrastructure telemetry, and database KPI analytics aggregated in real-time
  Future<Map<String, dynamic>> fetchPlatformAnalytics() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminAnalytics);
      return response;
    } catch (e) {
      return {};
    }
  }

  // ===========================================================================
  // Promotion Management (Banners)
  // ===========================================================================

  /// Fetch all promotional banners
  Future<List<AdminPromotionModel>> fetchPromotions() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminBanners);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminPromotionModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new promotional banner
  Future<AdminPromotionModel> createPromotion(Map<String, dynamic> data, {dynamic imageFile}) async {
    final files = <String, dynamic>{};
    if (imageFile != null) {
      files['image_url'] = imageFile;
    }

    final response = await _apiClient.postMultipart(
      ApiEndpoints.adminBanners,
      fields: data,
      files: files.isNotEmpty ? files : null,
    );
    return AdminPromotionModel.fromJson(response);
  }

  /// Update an existing promotional banner
  Future<AdminPromotionModel> updatePromotion(String id, Map<String, dynamic> data, {dynamic imageFile}) async {
    final files = <String, dynamic>{};
    if (imageFile != null) {
      files['image_url'] = imageFile;
    }

    Map<String, dynamic> response;
    if (files.isNotEmpty) {
      response = await _apiClient.putMultipart(
        ApiEndpoints.adminBannerDetail(id),
        fields: data,
        files: files,
      );
    } else {
      response = await _apiClient.patch(
        ApiEndpoints.adminBannerDetail(id),
        body: data,
      );
    }
    return AdminPromotionModel.fromJson(response);
  }

  /// Delete a promotional banner
  Future<bool> deletePromotion(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.adminBannerDetail(id));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Suspend an active banner
  Future<bool> suspendPromotion(String id) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.adminBannerSuspend(id));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Resume a suspended banner
  Future<bool> resumePromotion(String id) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.adminBannerResume(id));
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }
}

/// Singleton repository provider injecting the shared API network client
final adminApiRepositoryProvider = Provider<AdminApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminApiRepository(apiClient);
});