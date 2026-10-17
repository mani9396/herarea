import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/models/promotion_public_model.dart';
import 'package:her_area/features/home/presentation/screens/home_dashboard_screen.dart';

void main() {
  final sampleBanners = [
    const PromotionPublicModel(
      id: 'banner-1',
      title: 'Food Donation Offer',
      subtitle: '20% OFF',
      imageUrl: 'https://example.com/banner1.jpg',
      promotionType: 'APP',
      priority: 1,
      destination: {'type': 'STORE', 'id': 'store-123'},
    ),
    const PromotionPublicModel(
      id: 'banner-2',
      title: 'Mega Festive Sale',
      subtitle: 'Flat 50% OFF',
      imageUrl: 'https://example.com/banner2.jpg',
      promotionType: 'APP',
      priority: 2,
      destination: {'type': 'CATEGORY'},
    ),
  ];

  testWidgets('PromotionalBannerCarousel renders banners and advances automatically after 5 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromotionalBannerCarousel(banners: sampleBanners),
        ),
      ),
    );

    // Initial banner visible
    expect(find.text('Food Donation Offer'), findsOneWidget);
    expect(find.text('20% OFF'), findsOneWidget);

    // Advance time by 5 seconds
    await tester.pump(const Duration(seconds: 5));
    // Animate transition (650ms)
    await tester.pump(const Duration(milliseconds: 700));

    // Next banner visible
    expect(find.text('Mega Festive Sale'), findsOneWidget);
    expect(find.text('FLAT 50% OFF'), findsOneWidget);

    // Advance time by another 5 seconds to wrap around
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 700));

    // Wrapped back to first banner
    expect(find.text('Food Donation Offer'), findsOneWidget);

    // Clean up timers
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
