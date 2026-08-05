import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/data/mock/vendor_mock_data.dart';

class VendorApiRepository {
  final IApiClient _apiClient;
  final AuthSessionState _authState;

  const VendorApiRepository(this._apiClient, this._authState);

  /// Helper verifying the global rule: "A vendor must NOT be able to create stores,
  /// products, gallery images, or offers until approved by the Admin."
  void _assertApprovedVendor() {
    if (_authState.isAuthenticated && !_authState.isApprovedVendor) {
      throw const ApiException(
        message: 'Your partner studio account is currently under review or awaiting Admin approval.',
        errorCode: 'VENDOR_NOT_APPROVED',
        statusCode: 403,
      );
    }
  }

  /// Fetch studio profile details
  Future<StoreModel?> fetchMyStore() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorProfile);
      return StoreModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update studio profile information
  Future<StoreModel?> updateStore(StoreModel store) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.vendorProfile,
        body: store.toJson(),
      );
      return StoreModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Upload verification KYC documents (PAN, GSTIN, Boutique Business License)
  Future<bool> uploadKycDocument(String filePath, {required String documentType}) async {
    try {
      final response = await _apiClient.postMultipart(
        ApiEndpoints.vendorKycUpload,
        files: {'kyc_document': filePath},
        fields: {'document_type': documentType},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Fetch studio product & service catalog inventory
  Future<List<VendorProductModel>> fetchProducts() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorProducts);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => VendorProductModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Add new item to studio showroom (requires approved vendor status)
  Future<VendorProductModel?> createProduct(VendorProductModel product) async {
    _assertApprovedVendor();
    try {
      final response = await _apiClient.post(
        ApiEndpoints.vendorProducts,
        body: product.toJson(),
      );
      return VendorProductModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Delete item from studio showroom
  Future<bool> deleteProduct(String productId) async {
    try {
      await _apiClient.delete(ApiEndpoints.vendorProductDetail(productId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch incoming bespoke consultation appointments and orders
  Future<List<VendorEnquiryModel>> fetchEnquiries() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorBookings);
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => VendorEnquiryModel.fromJson(json),
      );
      return paginated.results;
    } catch (e) {
      rethrow;
    }
  }

  /// Respond to customer booking or update inquiry progress status
  Future<bool> updateEnquiryStatus(String enquiryId, String newStatus) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.vendorBookingDetail(enquiryId),
        body: {'status': newStatus.toUpperCase()},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }
}

/// Singleton repository provider injecting the network client and auth session state
final vendorApiRepositoryProvider = Provider<VendorApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authSessionProvider);
  return VendorApiRepository(apiClient, authState);
});
