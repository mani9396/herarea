import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';
import 'package:shared/shared.dart';

final vendorOffersProvider = NotifierProvider<VendorOffersNotifier, List<OfferModel>>(VendorOffersNotifier.new);

class VendorOffersNotifier extends Notifier<List<OfferModel>> {
  @override
  List<OfferModel> build() {
    _loadLiveOffers();
    return const [];
  }

  Future<void> _loadLiveOffers() async {
    final repo = ref.read(vendorApiRepositoryProvider);
    final liveOffers = await repo.fetchOffers();
    state = liveOffers;
  }

  void submitForApproval(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: 'PENDING_APPROVAL') else o
    ];
    final target = state.where((o) => o.id == id).firstOrNull;
    if (target != null) {
      ref.read(vendorApiRepositoryProvider).updateOffer(target);
    }
  }

  void addOffer(OfferModel offer) async {
    final repo = ref.read(vendorApiRepositoryProvider);
    final created = await repo.createOffer(offer);
    if (created != null) {
        state = [...state, created];
    }
  }

  void updateOffer(OfferModel updated) {
    state = [
      for (final o in state)
        if (o.id == updated.id) updated else o
    ];
    ref.read(vendorApiRepositoryProvider).updateOffer(updated);
  }

  void removeOffer(String id) {
    state = state.where((o) => o.id != id).toList();
    ref.read(vendorApiRepositoryProvider).deleteOffer(id);
  }
}
