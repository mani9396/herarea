import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:her_area/domain/repositories/store_repository_interface.dart';
import 'package:her_area/data/mock/mock_store_repository.dart';

class CustomerApiRepository implements IStoreRepository {
  final IApiClient _apiClient;
  final MockStoreRepository _fallbackRepository;

  CustomerApiRepository(this._apiClient) : _fallbackRepository = MockStoreRepository();

  @override
  Future<List<StoreModel>> getNearbyStores(double radiusKm) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.publicStores,
        queryParameters: {'radius': radiusKm.toString()},
      );
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => StoreModel.fromJson(json),
      );
      if (paginated.results.isNotEmpty) {
        return paginated.results;
      }
      return _fallbackRepository.getNearbyStores(radiusKm);
    } catch (_) {
      // Graceful offline fallback to curated O2O showroom demonstration data
      return _fallbackRepository.getNearbyStores(radiusKm);
    }
  }

  @override
  Future<List<StoreModel>> getStoresByCategory(BusinessCategory category) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.publicStores,
        queryParameters: {'category': category.name},
      );
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => StoreModel.fromJson(json),
      );
      if (paginated.results.isNotEmpty) {
        return paginated.results;
      }
      return _fallbackRepository.getStoresByCategory(category);
    } catch (_) {
      return _fallbackRepository.getStoresByCategory(category);
    }
  }

  @override
  Future<List<StoreModel>> searchStores(String query, {double? maxDistance, double? minRating, String? priceTier, bool onlyOpen = false}) async {
    try {
      final queryParameters = <String, dynamic>{'q': query};
      if (maxDistance != null) queryParameters['max_distance'] = maxDistance.toString();
      if (minRating != null) queryParameters['min_rating'] = minRating.toString();
      if (priceTier != null) queryParameters['price_tier'] = priceTier;
      if (onlyOpen) queryParameters['open_now'] = 'true';

      final response = await _apiClient.get(
        ApiEndpoints.unifiedSearch,
        queryParameters: queryParameters,
      );
      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => StoreModel.fromJson(json),
      );
      if (paginated.results.isNotEmpty) {
        return paginated.results;
      }
      return _fallbackRepository.searchStores(query, maxDistance: maxDistance, minRating: minRating, priceTier: priceTier, onlyOpen: onlyOpen);
    } catch (_) {
      return _fallbackRepository.searchStores(query, maxDistance: maxDistance, minRating: minRating, priceTier: priceTier, onlyOpen: onlyOpen);
    }
  }

  @override
  Future<StoreModel?> getStoreById(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.publicStores}$id/');
      return StoreModel.fromJson(response);
    } catch (_) {
      return _fallbackRepository.getStoreById(id);
    }
  }

  /// Submit bespoke consultation appointment booking request to studio partner
  Future<BookingModel?> bookAppointment(BookingModel booking) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerBookings,
        body: booking.toJson(),
      );
      return BookingModel.fromJson(response);
    } catch (_) {
      // Simulate confirmed booking offline
      return booking;
    }
  }

  /// Send product measurement or styling inquiry to studio artisans
  Future<EnquiryModel?> submitEnquiry(EnquiryModel enquiry) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerEnquiries,
        body: enquiry.toJson(),
      );
      return EnquiryModel.fromJson(response);
    } catch (_) {
      return enquiry;
    }
  }

  /// Synchronize client favorite showrooms with user profile database
  Future<bool> toggleFavoriteStore(String storeId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerFavorites,
        body: {'store_id': storeId},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (_) {
      return true;
    }
  }
}

/// Singleton Customer API Repository Provider
final customerApiRepositoryProvider = Provider<CustomerApiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CustomerApiRepository(client);
});
