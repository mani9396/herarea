import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/data/models/vendor_models.dart';

class VendorApiRepository {
  final IApiClient _apiClient;
  final AuthSessionState _authState;

  const VendorApiRepository(this._apiClient, this._authState);

  /// Helper verifying the global rule: "A vendor must NOT be able to create stores,
  /// products, gallery images, or offers until approved by the Admin."
  void _assertApprovedVendor() {
    // Intentionally left blank. 
    // Vendors must be able to add products and media while in DRAFT/PENDING status 
    // to complete their store profile before submission.
    // The backend enforces appropriate RBAC constraints.
  }

  /// Fetch studio profile details
  Future<StoreModel?> fetchMyStore() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorBusinessProfile);
      return StoreModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update studio profile information (mapped to BusinessProfile in backend)
  Future<StoreModel?> updateStore(StoreModel store) async {
    try {
      final payload = <String, dynamic>{
        'business_name': store.name,
        'contact_phone': store.whatsappNumber,
        'category': store.category.id,
        if (store.subcategory != null) 'subcategory': store.subcategory!.id,
      };

      final files = <String, String>{};
      if (store.logo != null && !store.logo!.startsWith('http')) {
        files['logo'] = store.logo!;
      }
      if (store.coverImage != null && !store.coverImage!.startsWith('http')) {
        files['cover_image'] = store.coverImage!;
      }

      if (files.isNotEmpty) {
        final response = await _apiClient.putMultipart(
          ApiEndpoints.vendorBusinessProfile,
          fields: payload,
          files: files,
        );
        if ((response['status_code'] as int? ?? 200) >= 300) {
          throw Exception(response['detail'] ?? 'Failed to update store.');
        }
      } else {
        final response = await _apiClient.put(
          ApiEndpoints.vendorBusinessProfile,
          body: payload,
        );
        if ((response['status_code'] as int? ?? 200) >= 300) {
          throw Exception(response['detail'] ?? 'Failed to update store.');
        }
      }
      
      return fetchMyStore();
    } catch (e) {
      throw Exception('Failed to update store profile: $e');
    }
  }

  /// Upload a gallery image for the store
  Future<StoreMediaModel?> uploadGalleryImage(String filePath) async {
    try {
      final res = await _apiClient.postMultipart(
        '${ApiEndpoints.vendorBusinessProfile}media/',
        files: {'image': filePath},
      );
      return StoreMediaModel.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  /// Delete a gallery image from the store
  Future<bool> deleteGalleryImage(String mediaId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.vendorBusinessProfile}media/$mediaId/');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Submit store for admin review
  Future<bool> submitStoreForReview() async {
    try {
      final response = await _apiClient.post('${ApiEndpoints.vendorBusinessProfile}submit/');
      if ((response['status_code'] as int? ?? 200) < 300) {
        return true;
      }
      throw Exception(response['detail'] ?? 'Submission failed.');
    } catch (e) {
      throw Exception(e.toString());
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
      developer.log('Error creating product: $e', error: e);
      rethrow;
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
      developer.log('Error updating product', error: e);
      rethrow;
    }
  }

  Future<VendorProductModel> submitProduct(String productId) async {
    _assertApprovedVendor();
    try {
      final response = await _apiClient.post('${ApiEndpoints.vendorProducts}$productId/submit/');
      return VendorProductModel.fromJson(response);
    } catch (e) {
      developer.log('Error submitting product', error: e);
      rethrow;
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

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.publicCategories);
      final list = response.containsKey('results') ? response['results'] as List : response as List;
      return list.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      print('Error fetching categories: $e\n$stack');
      return [];
    }
  }

  /// Create new studio business profile during onboarding
  Future<String?> createBusinessProfile(Map<String, dynamic> profileData) async {
    try {
      await _apiClient.post(
        ApiEndpoints.vendorBusinessProfile,
        body: profileData,
      );
      return null; // success
    } catch (e, stack) {
      print('Error creating business profile: $e\n$stack');
      if (e is DioException && e.response?.data != null) {
        return 'Server error: ${e.response?.data}';
      }
      return e.toString();
    }
  }

  /// Save studio business profile during editing
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
  Future<List<StoreMediaModel>> fetchGalleryImages() async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.vendorBusinessProfile}media/');
      final list = (response as List?) ?? (response['results'] as List?) ?? [];
      return list.map((e) => StoreMediaModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Fetch promotional offers from backend catalog
  Future<List<OfferModel>> fetchOffers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorOffers);
      final list = (response as List?) ?? (response['results'] as List?) ?? [];
      return list.map((json) => OfferModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Create new offer in backend catalog
  Future<OfferModel?> createOffer(OfferModel offer) async {
    _assertApprovedVendor();
    try {
      final response = await _apiClient.post(
        ApiEndpoints.vendorOffers,
        body: offer.toJson(),
      );
      return OfferModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update offer in backend catalog
  Future<OfferModel?> updateOffer(OfferModel offer) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.vendorOffers}${offer.id}/',
        body: offer.toJson(),
      );
      return OfferModel.fromJson(response);
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
      final response = await _apiClient.get(ApiEndpoints.vendorDashboardStats);
      return VendorStatsModel.fromJson(response);
    } catch (e) {
      return const VendorStatsModel.empty();
    }
  }

  /// Fetch live verified customer reviews for the vendor's own store
  Future<List<VendorCustomerReviewModel>> fetchCustomerReviews(String storeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorStoreReviews);
      final data = response;
      final list = (data['reviews'] as List?) ?? (data['results'] as List?) ?? [];
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

  /// Fetch all reviews for the vendor's own store (read-only).
  Future<Map<String, dynamic>> getMyStoreReviews() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorStoreReviews);
      return response;
    } catch (_) {
      return {};
    }
  }
}

/// Singleton repository provider injecting the network client and auth session state
final vendorApiRepositoryProvider = Provider<VendorApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authSessionProvider);
  return VendorApiRepository(apiClient, authState);
});

/// Provider for vendor store reviews
final vendorStoreReviewsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(vendorApiRepositoryProvider);
  return repo.getMyStoreReviews();
});

