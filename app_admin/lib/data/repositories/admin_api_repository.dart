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

  /// Fetch all active and inactive marketplace categories
  Future<List<AdminCategoryModel>> fetchCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.publicCategories);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => AdminCategoryModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new taxonomy category
  Future<AdminCategoryModel?> createCategory(AdminCategoryModel category) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminCategories,
        body: category.toJson(),
      );
      return AdminCategoryModel.fromJson(response);
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
}

/// Singleton repository provider injecting the shared API network client
final adminApiRepositoryProvider = Provider<AdminApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminApiRepository(apiClient);
});