import 'package:shared/shared.dart';

class AdminSubscriptionApiRepository {
  final IApiClient _apiClient;

  AdminSubscriptionApiRepository(this._apiClient);

  Future<List<ListingPlanModel>> getListingPlans() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/subscriptions/plans/');
      if (response['status_code'] == 200) {
        final List<dynamic> data = response['results'] ?? [];
        return data.map((json) => ListingPlanModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load plans: $e');
    }
  }

  Future<ListingPlanModel> createPlan(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/admin/subscriptions/plans/', body: data);
      if (response['status_code'] == 201) {
        return ListingPlanModel.fromJson(response);
      }
      throw Exception('Failed to create plan');
    } catch (e) {
      throw Exception('Plan creation failed: $e');
    }
  }

  Future<ListingPlanModel> updatePlan(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/api/v1/admin/subscriptions/plans/$id/', body: data);
      if (response['status_code'] == 200) {
        return ListingPlanModel.fromJson(response);
      }
      throw Exception('Failed to update plan');
    } catch (e) {
      throw Exception('Plan update failed: $e');
    }
  }

  Future<void> deletePlan(int id) async {
    try {
      await _apiClient.delete('/api/v1/admin/subscriptions/plans/$id/');
    } catch (e) {
      throw Exception('Plan deletion failed: $e');
    }
  }

  Future<List<VendorSubscriptionModel>> getSubscriptions() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/subscriptions/subscriptions/');
      if (response['status_code'] == 200) {
        final List<dynamic> data = response['results'] ?? [];
        return data.map((json) => VendorSubscriptionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load subscriptions: $e');
    }
  }

  Future<List<PaymentRecordModel>> getPayments() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/subscriptions/payments/');
      if (response['status_code'] == 200) {
        final List<dynamic> data = response['results'] ?? [];
        return data.map((json) => PaymentRecordModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }
  
  Future<double> getRevenue() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/subscriptions/revenue/');
      if (response['status_code'] == 200) {
        return (response['total_revenue'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
