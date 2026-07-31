import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/vendor_offer.dart';

final vendorOffersProvider = NotifierProvider<VendorOffersNotifier, List<VendorOffer>>(VendorOffersNotifier.new);

class VendorOffersNotifier extends Notifier<List<VendorOffer>> {
  @override
  List<VendorOffer> build() {
    return const [
      VendorOffer(
        id: 'off_001',
        title: 'Shravanam Wedding Bridal Silk Combo',
        code: 'SHRAVAN20',
        discountPercent: '20% OFF',
        description: 'Applicable on authentic Kanjivaram zari silk drape bundles & customized bridal fittings.',
        validUntil: '31 Aug 2026',
        isActive: true,
      ),
      VendorOffer(
        id: 'off_002',
        title: 'Complimentary Maggam Blouse Stitching',
        code: 'MAGGMARI',
        discountPercent: 'FREE STITCHING',
        description: 'Free gold thread handwork stitching on store purchases exceeding ₹35,000.',
        validUntil: '15 Sep 2026',
        isActive: true,
      ),
      VendorOffer(
        id: 'off_003',
        title: 'Monsoon Early Bridal Reservation Deal',
        code: 'MONSOON10',
        discountPercent: '10% OFF',
        description: 'Special weekend bridal fitting trial discount for early bookings in Jubilee Hills.',
        validUntil: '30 Jul 2026',
        isActive: false,
      ),
    ];
  }

  void toggleStatus(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(isActive: !o.isActive) else o
    ];
  }

  void addOffer(VendorOffer offer) {
    state = [...state, offer];
  }

  void updateOffer(VendorOffer updated) {
    state = [
      for (final o in state)
        if (o.id == updated.id) updated else o
    ];
  }

  void removeOffer(String id) {
    state = state.where((o) => o.id != id).toList();
  }
}
