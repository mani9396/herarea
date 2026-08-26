import 'package:shared/shared.dart';

class SubscriptionApiRepository {
  final IApiClient _apiClient;

  SubscriptionApiRepository(this._apiClient);

  Future<List<ListingPlanModel>> getListingPlans() async {
    try {
      final response = await _apiClient.get('/api/v1/subscriptions/plans/');
      if (response['status_code'] == 200) {
        final List<dynamic> data = response['results'] ?? [];
        return data.map((json) => ListingPlanModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load listing plans: $e');
    }
  }

  Future<VendorSubscriptionModel?> getMySubscription() async {
    try {
      final response = await _apiClient.get('/api/v1/subscriptions/me/');
      if (response['status_code'] == 200) {
        return VendorSubscriptionModel.fromJson(response);
      }
      return null;
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Failed to load active subscription: $e');
    }
  }

  Future<Map<String, dynamic>> createRazorpayOrder(int planId) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/subscriptions/payment/initiate/',
        body: {'plan_id': planId},
      );
      if (response['status_code'] == 200 || response['status_code'] == 201) {
        return response;
      }
      throw Exception('Failed to create order: ${response['detail']}');
    } catch (e) {
      throw Exception('Order creation failed: $e');
    }
  }

  Future<VendorSubscriptionModel> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/subscriptions/payment/verify/',
        body: {
          'transaction_id': orderId,
          'action': 'simulate_success',
        },
      );
      if (response['status_code'] == 200) {
        return VendorSubscriptionModel.fromJson(response['subscription']);
      }
      throw Exception('Payment verification failed');
    } catch (e) {
      throw Exception('Payment verification failed: $e');
    }
  }
}
