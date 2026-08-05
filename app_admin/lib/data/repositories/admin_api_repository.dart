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
        ApiEndpoints.publicCategories,
        body: category.toJson(),
      );
      return AdminCategoryModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

/// Singleton repository provider injecting the shared API network client
final adminApiRepositoryProvider = Provider<AdminApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminApiRepository(apiClient);
});