import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';
import '../domain/models/vendor_offer.dart';

final vendorOffersProvider = NotifierProvider<VendorOffersNotifier, List<VendorOffer>>(VendorOffersNotifier.new);

class VendorOffersNotifier extends Notifier<List<VendorOffer>> {
  @override
  List<VendorOffer> build() {
    _loadLiveOffers();
    return const [];
  }

  Future<void> _loadLiveOffers() async {
    final repo = ref.read(vendorApiRepositoryProvider);
    final liveOffers = await repo.fetchOffers();
    state = liveOffers;
  }

  void toggleStatus(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(isActive: !o.isActive) else o
    ];
    final target = state.where((o) => o.id == id).firstOrNull;
    if (target != null) {
      ref.read(vendorApiRepositoryProvider).updateOffer(target);
    }
  }

  void addOffer(VendorOffer offer) {
    state = [...state, offer];
    ref.read(vendorApiRepositoryProvider).createOffer(offer);
  }

  void updateOffer(VendorOffer updated) {
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
