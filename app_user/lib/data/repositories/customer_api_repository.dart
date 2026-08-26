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
  Future<List<StoreModel>> getStoresByCategory(String categorySlug) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.publicStores,
        queryParameters: {'category': categorySlug},
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

  /// Fetch full store dossier including catalog and offers
  Future<Map<String, dynamic>?> getStoreDossier(String storeId) async {
    try {
      final response = await _apiClient.get('/api/v1/products/store/$storeId/dossier/');
      return response as Map<String, dynamic>;
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
      if (response is List) {
        final list = response as List;
        final urls = list
            .map((item) => (item as Map<String, dynamic>)['image_url']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList();
        if (urls.isNotEmpty) return urls;
      } else if (response is Map<String, dynamic> && response['results'] is List) {
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
      final urls = stores.map((s) => s.gallery.isNotEmpty ? s.gallery.first.image : '').where((url) => url.isNotEmpty).toList();
      if (urls.isNotEmpty) return urls;
    } catch (_) {}
    return [];
  }

  /// Retrieve active catalog categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.publicCategories);
      if (response is List) {
        final list = response as List;
        return list.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response is Map<String, dynamic> && response['results'] is List) {
        return (response['results'] as List).map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch authenticated customer's favorite store IDs
  Future<List<String>> getFavoriteStoreIds() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.customerFavorites);
      List<dynamic> list = [];
      if (response is List) {
        list = response as List;
      } else if (response is Map<String, dynamic> && response['results'] is List) {
        list = response['results'] as List;
      }
      
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        if (map['store'] != null && map['store'] is String) return map['store'].toString();
        if (map['store_details'] != null) {
          return (map['store_details'] as Map<String, dynamic>)['id']?.toString() ?? '';
        }
        return '';
      }).where((id) => id.isNotEmpty).toList();
    } catch (_) {}
    return [];
  }

  /// Fetch authenticated customer's recently viewed store IDs
  Future<List<String>> getRecentlyViewedStoreIds() async {
    try {
      final response = await _apiClient.get('/api/v1/interactions/recently-viewed/');
      List<dynamic> list = [];
      if (response is List) {
        list = response as List;
      } else if (response is Map<String, dynamic> && response['results'] is List) {
        list = response['results'] as List;
      }
      
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        if (map['store'] != null && map['store'] is String) return map['store'].toString();
        if (map['store_details'] != null) {
          return (map['store_details'] as Map<String, dynamic>)['id']?.toString() ?? '';
        }
        return '';
      }).where((id) => id.isNotEmpty).toList();
    } catch (_) {}
    return [];
  }

  /// Log a store view
  Future<bool> logStoreView(String storeId) async {
    try {
      final response = await _apiClient.post('/api/v1/interactions/recently-viewed/$storeId/');
      return (response['status_code'] as int? ?? 201) <= 204;
    } catch (_) {
      return false;
    }
  }

  /// Verify a physical store visit using the customer's current GPS location.
  /// Backend is authoritative: returns VERIFIED if within 100m.
  Future<Map<String, dynamic>> verifyStoreVisit(
    String storeId, {
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.storeVisit(storeId),
      body: {'latitude': latitude, 'longitude': longitude},
    );
    return response as Map<String, dynamic>;
  }

  /// Fetch public approved reviews for a store, plus avg rating/count from meta.
  Future<Map<String, dynamic>> getStoreReviews(String storeId) async {
    final response = await _apiClient.get(ApiEndpoints.storeReviews(storeId));
    return response as Map<String, dynamic>;
  }

  /// Submit a new customer review after a verified visit.
  Future<Map<String, dynamic>> submitReview(
    String storeId, {
    required int rating,
    required String comment,
    String title = '',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.storeReviews(storeId),
      body: {
        'rating': rating,
        'comment': comment,
        if (title.isNotEmpty) 'title': title,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Fetch the authenticated customer's own review for a store (GET with filter).
  Future<ReviewModel?> getMyReview(String storeId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.storeReviews(storeId),
        queryParameters: {'my_review': 'true'},
      );
      final data = response as Map<String, dynamic>;
      if (data['my_review'] is Map) {
        return ReviewModel.fromJson(data['my_review'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Update the customer's own review.
  Future<Map<String, dynamic>> updateReview(
    String reviewId, {
    required int rating,
    required String comment,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.customerReview(reviewId),
      body: {'rating': rating, 'comment': comment},
    );
    return response as Map<String, dynamic>;
  }

  /// Delete the customer's own review.
  Future<void> deleteReview(String reviewId) async {
    await _apiClient.delete(ApiEndpoints.customerReview(reviewId));
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

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
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

// Recently Viewed Provider
class RecentlyViewedNotifier extends StateNotifier<List<String>> {
  final CustomerApiRepository _repository;

  RecentlyViewedNotifier(this._repository) : super([]) {
    _loadRecentlyViewed();
  }

  Future<void> _loadRecentlyViewed() async {
    try {
      final rvIds = await _repository.getRecentlyViewedStoreIds();
      if (rvIds.isNotEmpty) {
        state = rvIds;
      }
    } catch (_) {}
  }

  Future<void> logView(String storeId) async {
    // Optimistic UI update: move to top or insert at top
    final currentList = List<String>.from(state);
    currentList.remove(storeId);
    currentList.insert(0, storeId);
    if (currentList.length > 20) {
      currentList.removeLast();
    }
    state = currentList;
    
    // Background sync
    await _repository.logStoreView(storeId);
  }
}

final recentlyViewedProvider = StateNotifierProvider<RecentlyViewedNotifier, List<String>>((ref) {
  final repo = ref.watch(customerApiRepositoryProvider);
  return RecentlyViewedNotifier(repo);
});

// ─── Phase 8: Store Visit & Review Providers ─────────────────────────────────

/// State for the current store-visit verification attempt.
enum VisitStatus { idle, verifying, verified, failed }

class StoreVisitState {
  final VisitStatus status;
  final String? errorMessage;
  final String? visitId;

  const StoreVisitState({
    this.status = VisitStatus.idle,
    this.errorMessage,
    this.visitId,
  });

  StoreVisitState copyWith({VisitStatus? status, String? errorMessage, String? visitId}) {
    return StoreVisitState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      visitId: visitId ?? this.visitId,
    );
  }
}

class StoreVisitNotifier extends StateNotifier<StoreVisitState> {
  final CustomerApiRepository _repo;

  StoreVisitNotifier(this._repo) : super(const StoreVisitState());

  void reset() => state = const StoreVisitState();

  Future<void> verifyVisit(
    String storeId, {
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(status: VisitStatus.verifying, errorMessage: null);
    try {
      final result = await _repo.verifyStoreVisit(
        storeId,
        latitude: latitude,
        longitude: longitude,
      );
      final visitStatus = result['status']?.toString() ?? '';
      if (visitStatus == 'VERIFIED') {
        state = state.copyWith(
          status: VisitStatus.verified,
          visitId: result['id']?.toString(),
        );
      } else {
        state = state.copyWith(
          status: VisitStatus.failed,
          errorMessage: result['detail']?.toString() ??
              'Could not verify your visit. Please try again.',
        );
      }
    } catch (e) {
      // Parse error message from API (e.g. "must be within 100.0m")
      final msg = e.toString();
      String displayMsg = 'Please move closer to the store to verify your visit.';
      if (msg.contains('within')) displayMsg = 'Please move closer to the store to verify your visit.';
      state = state.copyWith(status: VisitStatus.failed, errorMessage: displayMsg);
    }
  }
}

/// Per-store visit state — auto-reset when storeId changes.
final storeVisitProvider = StateNotifierProvider.family<StoreVisitNotifier, StoreVisitState, String>(
  (ref, storeId) {
    final repo = ref.watch(customerApiRepositoryProvider);
    return StoreVisitNotifier(repo);
  },
);

/// Fetches the approved public reviews + meta (average_rating, review_count) for a store.
final storeReviewsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, storeId) async {
  final repo = ref.read(customerApiRepositoryProvider);
  return repo.getStoreReviews(storeId);
});

/// Fetches the authenticated customer's own review for a store (nullable).
final myReviewProvider = FutureProvider.family<ReviewModel?, String>((ref, storeId) async {
  final repo = ref.read(customerApiRepositoryProvider);
  return repo.getMyReview(storeId);
});


