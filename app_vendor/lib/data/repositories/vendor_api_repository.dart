import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/data/models/vendor_models.dart';
import 'package:app_vendor/features/offers/domain/models/vendor_offer.dart';

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

  /// Update existing item in studio showroom
  Future<VendorProductModel?> updateProduct(VendorProductModel product) async {
    _assertApprovedVendor();
    try {
      final response = await _apiClient.put(
        ApiEndpoints.vendorProductDetail(product.id),
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
        ApiEndpoints.vendorBookingStatus(enquiryId),
        body: {'status': newStatus.toUpperCase()},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (e) {
      return false;
    }
  }

  /// Save studio business profile during onboarding or editing
  Future<bool> saveBusinessProfile(Map<String, dynamic> profileData) async {
    try {
      await _apiClient.put(
        ApiEndpoints.vendorBusinessProfile,
        body: profileData,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save studio operating timings and schedules
  Future<bool> saveStoreTimings(Map<String, dynamic> scheduleData) async {
    try {
      await _apiClient.post(
        ApiEndpoints.vendorSchedules,
        body: scheduleData,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch studio showcase gallery images
  Future<List<String>> fetchGalleryImages() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorGallery);
      final list = (response as List?) ?? (response['results'] as List?) ?? [];
      return list.map((e) => e['image_url']?.toString() ?? e['url']?.toString() ?? '').where((u) => u.isNotEmpty).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Upload new gallery image to backend
  Future<String?> uploadGalleryImage(String imageUrlOrPath) async {
    _assertApprovedVendor();
    try {
      if (imageUrlOrPath.startsWith('http')) {
        await _apiClient.post(ApiEndpoints.vendorGallery, body: {'image_url': imageUrlOrPath});
        return imageUrlOrPath;
      } else {
        final response = await _apiClient.postMultipart(
          ApiEndpoints.vendorGallery,
          files: {'image': imageUrlOrPath},
        );
        return response['image_url']?.toString() ?? imageUrlOrPath;
      }
    } catch (e) {
      return null;
    }
  }

  /// Delete gallery image from backend
  Future<bool> deleteGalleryImage(String imageIdOrUrl) async {
    try {
      final id = Uri.encodeComponent(imageIdOrUrl);
      await _apiClient.delete('${ApiEndpoints.vendorGallery}$id/');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch promotional offers from backend catalog
  Future<List<VendorOffer>> fetchOffers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorOffers);
      final list = (response as List?) ?? (response['results'] as List?) ?? [];
      return list.map((json) => VendorOffer.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Create new offer in backend catalog
  Future<VendorOffer?> createOffer(VendorOffer offer) async {
    _assertApprovedVendor();
    try {
      final response = await _apiClient.post(
        ApiEndpoints.vendorOffers,
        body: offer.toJson(),
      );
      return VendorOffer.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update offer in backend catalog
  Future<VendorOffer?> updateOffer(VendorOffer offer) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.vendorOffers}${offer.id}/',
        body: offer.toJson(),
      );
      return VendorOffer.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Delete offer from backend catalog
  Future<bool> deleteOffer(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.vendorOffers}$id/');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch live notifications for vendor
  Future<List<VendorNotificationModel>> fetchNotifications() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notifications);
      final list = (response as List?) ?? (response['results'] as List?) ?? [];
      return list.map((json) => VendorNotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _apiClient.patch('${ApiEndpoints.notifications}$notificationId/read/', body: {'is_unread': false});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch vendor business statistics and analytics metrics from backend
  Future<VendorStatsModel> fetchVendorStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorAnalytics);
      return VendorStatsModel.fromJson(response);
    } catch (e) {
      return const VendorStatsModel.empty();
    }
  }

  /// Fetch live verified customer reviews for the vendor store
  Future<List<VendorCustomerReviewModel>> fetchCustomerReviews(String storeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.storeReviews(storeId));
      final list = (response as List?) ?? (response['results'] as List?) ?? [];
      return list.map((json) => VendorCustomerReviewModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Reply to a customer review via backend API
  Future<bool> replyToReview(String reviewId, String reply) async {
    try {
      await _apiClient.post(
        '/api/v1/vendor/reviews/$reviewId/reply/',
        body: {'reply': reply},
      );
      return true;
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
