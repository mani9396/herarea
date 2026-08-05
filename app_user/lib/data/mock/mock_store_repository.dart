import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:her_area/domain/repositories/store_repository_interface.dart';
import 'package:her_area/data/mock/mock_data.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class MockStoreRepository implements IStoreRepository {
  @override
  Future<List<StoreModel>> getNearbyStores(double radiusKm) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate networking
    return MockData.allStores.where((s) => s.distanceKm <= radiusKm).toList();
  }

  @override
  Future<List<StoreModel>> getStoresByCategory(BusinessCategory category) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockData.allStores.where((s) => s.category == category).toList();
  }

  @override
  Future<List<StoreModel>> searchStores(String query, {double? maxDistance, double? minRating, String? priceTier, bool onlyOpen = false}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.allStores.where((s) {
      if (onlyOpen && !s.isOpenNow) return false;
      if (maxDistance != null && s.distanceKm > maxDistance) return false;
      if (minRating != null && s.rating < minRating) return false;
      if (priceTier != null && s.priceTier != priceTier) return false;
      if (query.isEmpty) return true;
      
      final q = query.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
             s.category.displayName.toLowerCase().contains(q) ||
             s.serviceTags.any((t) => t.toLowerCase().contains(q)) ||
             s.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<StoreModel?> getStoreById(String id) async {
    try {
      return MockData.allStores.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Global Riverpod Providers connected to Live Django API Repository
final storeRepositoryProvider = Provider<IStoreRepository>((ref) {
  return ref.watch(customerApiRepositoryProvider);
});

final allStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final repo = ref.read(storeRepositoryProvider);
  return repo.getNearbyStores(15.0);
});

final nearbyRadiusProvider = StateProvider<double>((ref) => 5.0); // 5km default

final nearbyStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final radius = ref.watch(nearbyRadiusProvider);
  final repo = ref.read(storeRepositoryProvider);
  return repo.getNearbyStores(radius);
});

// Favorites Provider with Live Backend Synchronization
class FavoritesNotifier extends StateNotifier<Set<String>> {
  final CustomerApiRepository? _repository;

  FavoritesNotifier([this._repository]) : super({'store_1', 'store_2'}); // Pre-seed favorites for demonstration

  void toggleFavorite(String storeId) {
    if (state.contains(storeId)) {
      state = {...state}..remove(storeId);
    } else {
      state = {...state, storeId};
    }
    _repository?.toggleFavoriteStore(storeId);
  }

  bool isFavorite(String storeId) => state.contains(storeId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final repo = ref.watch(customerApiRepositoryProvider);
  return FavoritesNotifier(repo);
});

// Theme Mode Provider has been centralized in lib/core/state/app_state_provider.dart
