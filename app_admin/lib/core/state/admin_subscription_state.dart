import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_admin/data/repositories/admin_subscription_api_repository.dart';
final adminSubscriptionRepoProvider = Provider<AdminSubscriptionApiRepository>((ref) {
  return AdminSubscriptionApiRepository(ref.watch(apiClientProvider));
});

final adminPlansProvider = FutureProvider<List<ListingPlanModel>>((ref) async {
  return ref.watch(adminSubscriptionRepoProvider).getListingPlans();
});

final adminPaymentsProvider = FutureProvider<List<PaymentRecordModel>>((ref) async {
  return ref.watch(adminSubscriptionRepoProvider).getPayments();
});

final adminRevenueProvider = FutureProvider<double>((ref) async {
  return ref.watch(adminSubscriptionRepoProvider).getRevenue();
});

final adminSubscriptionsProvider = FutureProvider<List<VendorSubscriptionModel>>((ref) async {
  return ref.watch(adminSubscriptionRepoProvider).getSubscriptions();
});
