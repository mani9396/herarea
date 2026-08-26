import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/data/repositories/subscription_api_repository.dart';


final subscriptionRepositoryProvider = Provider<SubscriptionApiRepository>((ref) {
  return SubscriptionApiRepository(ref.watch(apiClientProvider));
});

final listingPlansProvider = FutureProvider<List<ListingPlanModel>>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getListingPlans();
});

class MySubscriptionNotifier extends StateNotifier<AsyncValue<VendorSubscriptionModel?>> {
  final SubscriptionApiRepository _repository;

  MySubscriptionNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repository.getMySubscription();
      state = AsyncValue.data(sub);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<VendorSubscriptionModel?> verifyAndRefresh(String orderId, String paymentId, String signature) async {
    try {
      final sub = await _repository.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      state = AsyncValue.data(sub);
      return sub;
    } catch (e) {
      // Refresh to get latest state in case of failure
      await refresh();
      rethrow;
    }
  }
}

final mySubscriptionProvider = StateNotifierProvider<MySubscriptionNotifier, AsyncValue<VendorSubscriptionModel?>>((ref) {
  return MySubscriptionNotifier(ref.watch(subscriptionRepositoryProvider));
});
