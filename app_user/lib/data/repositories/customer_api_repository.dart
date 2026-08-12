import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:her_area/domain/repositories/store_repository_interface.dart';
import 'package:her_area/core/state/app_state_provider.dart';

class CustomerApiRepository implements IStoreRepository {
  final IApiClient _apiClient;

  CustomerApiRepository(this._apiClient);

  @override
  Future<List<StoreModel>> getNearbyStores(double radiusKm, {double? lat, double? lon}) async {
    try {
      final queryParams = {'radius_km': radiusKm.toString()};
      if (lat != null && lon != null) {
        queryParams['latitude'] = lat.toString();
        queryParams['longitude'] = lon.toString();
      }
      final response = await _apiClient.get(
        ApiEndpoints.publicStoresNearby,
        queryParameters: queryParams,
      );
      if (response is List) {
        return (response as List).map((json) => StoreModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      final paginated = PaginatedResponse.fromJson(
        response as Map<String, dynamic>,
        (json) => StoreModel.fromJson(json),
      );
      return paginated.results;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<StoreModel>> getStoresByCategory(BusinessCategory category) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.publicStores,
        queryParameters: {'category': category.name},
      );
      if (response is List) {
        return (response as List).map((json) => StoreModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      final paginated = PaginatedResponse.fromJson(
        response as Map<String, dynamic>,
        (json) => StoreModel.fromJson(json),
      );
      return paginated.results;
    } catch (_) {
      return [];
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
      if (response is List) {
        return (response as List).map((json) => StoreModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      final paginated = PaginatedResponse.fromJson(
        response as Map<String, dynamic>,
        (json) => StoreModel.fromJson(json),
      );
      return paginated.results;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<StoreModel?> getStoreById(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.publicStores}$id/');
      return StoreModel.fromJson(response);
    } catch (_) {
      return null;
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
      return null;
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
      return null;
    }
  }

  /// Synchronize client favorite showrooms with user profile database
  Future<bool> toggleFavoriteStore(String storeId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerFavoritesToggle,
        body: {'store': storeId},
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve active promotional banner image URLs
  Future<List<String>> getPromoBanners() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.publicPromotions);
      if (response['results'] is List) {
        final list = response['results'] as List;
        final urls = list
            .map((item) => (item as Map<String, dynamic>)['image_url']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList();
        if (urls.isNotEmpty) return urls;
      }
    } catch (_) {}
    try {
      final stores = await getNearbyStores(15.0);
      final urls = stores.map((s) => s.imageUrls.isNotEmpty ? s.imageUrls.first : '').where((url) => url.isNotEmpty).toList();
      if (urls.isNotEmpty) return urls;
    } catch (_) {}
    return [];
  }

  /// Retrieve active catalog categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.publicCategories);
      if (response['results'] is List) {
        final list = response['results'] as List;
        final cats = list
            .map((item) => (item as Map<String, dynamic>)['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        if (cats.isNotEmpty) return cats;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch authenticated customer's favorite store IDs
  Future<List<String>> getFavoriteStoreIds() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.customerFavorites);
      if (response['results'] is List) {
        final list = response['results'] as List;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          if (map['store'] != null) return map['store'].toString();
          if (map['store_details'] != null) {
            return (map['store_details'] as Map<String, dynamic>)['id']?.toString() ?? '';
          }
          return '';
        }).where((id) => id.isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch customer reviews for a specific showroom
  Future<List<ReviewModel>> getStoreReviews(String storeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.storeReviews(storeId));
      if (response['reviews'] is List) {
        final list = response['reviews'] as List;
        return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (response['results'] is List) {
        final list = response['results'] as List;
        return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Submit a customer review for a showroom
  Future<ReviewModel?> submitReview(String storeId, {required double rating, required String comment, String title = ''}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.storeReviews(storeId),
        body: {
          'rating': rating,
          'comment': comment,
          'title': title.isEmpty ? 'Customer Review' : title,
        },
      );
      if ((response['status_code'] as int? ?? 200) <= 201) {
        if (response['review'] is Map<String, dynamic>) {
          return ReviewModel.fromJson(response['review'] as Map<String, dynamic>);
        }
        return ReviewModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  /// Retrieve authenticated customer notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notifications);
      if (response['results'] is List) {
        final list = response['results'] as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Mark notification as read
  Future<bool> markNotificationRead(String id) async {
    try {
      final response = await _apiClient.post('${ApiEndpoints.notifications}$id/read/', body: {});
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (_) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsRead() async {
    try {
      final response = await _apiClient.post('${ApiEndpoints.notifications}read-all/', body: {});
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (_) {
      return false;
    }
  }

  /// Get authenticated user profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userProfile);
      if ((response['status_code'] as int? ?? 200) == 200) {
        return response;
      }
    } catch (_) {}
    return null;
  }

  /// Update authenticated user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.userProfile,
        body: data,
      );
      return (response['status_code'] as int? ?? 200) <= 204;
    } catch (_) {
      return false;
    }
  }
}

/// Singleton Customer API Repository Provider
final customerApiRepositoryProvider = Provider<CustomerApiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CustomerApiRepository(client);
});

final storeRepositoryProvider = Provider<IStoreRepository>((ref) {
  return ref.watch(customerApiRepositoryProvider);
});

final allStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final repo = ref.read(customerApiRepositoryProvider);
  return repo.getNearbyStores(15.0);
});

final nearbyRadiusProvider = StateProvider<double>((ref) => 25.0);

final nearbyStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final radius = ref.watch(nearbyRadiusProvider);
  final location = ref.watch(userLocationProvider);
  final repo = ref.read(customerApiRepositoryProvider);
  return repo.getNearbyStores(radius, lat: location.latitude, lon: location.longitude);
});

final promoBannersProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(customerApiRepositoryProvider);
  return repo.getPromoBanners();
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(customerApiRepositoryProvider);
  return repo.getCategories();
});

// Favorites Provider with Live Backend Synchronization
class FavoritesNotifier extends StateNotifier<Set<String>> {
  final CustomerApiRepository _repository;

  FavoritesNotifier(this._repository) : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favIds = await _repository.getFavoriteStoreIds();
      if (favIds.isNotEmpty) {
        state = favIds.toSet();
      }
    } catch (_) {}
  }

  Future<bool> toggleFavorite(String storeId) async {
    final currentlyFavorite = state.contains(storeId);
    if (currentlyFavorite) {
      state = {...state}..remove(storeId);
    } else {
      state = {...state, storeId};
    }
    try {
      final success = await _repository.toggleFavoriteStore(storeId);
      if (!success) {
        if (currentlyFavorite) {
          state = {...state, storeId};
        } else {
          state = {...state}..remove(storeId);
        }
        return false;
      }
      return true;
    } catch (_) {
      if (currentlyFavorite) {
        state = {...state, storeId};
      } else {
        state = {...state}..remove(storeId);
      }
      return false;
    }
  }

  bool isFavorite(String storeId) => state.contains(storeId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final repo = ref.watch(customerApiRepositoryProvider);
  return FavoritesNotifier(repo);
});
