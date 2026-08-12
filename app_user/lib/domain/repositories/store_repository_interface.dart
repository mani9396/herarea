import 'package:shared/models/store_model.dart';

abstract class IStoreRepository {
  Future<List<StoreModel>> getNearbyStores(double radiusKm, {double? lat, double? lon});
  Future<List<StoreModel>> getStoresByCategory(BusinessCategory category);
  Future<List<StoreModel>> searchStores(String query, {double? maxDistance, double? minRating, String? priceTier, bool onlyOpen = false});
  Future<StoreModel?> getStoreById(String id);
}
