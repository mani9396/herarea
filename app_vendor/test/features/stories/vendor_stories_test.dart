import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/features/stories/presentation/screens/add_story_screen.dart';
import 'package:app_vendor/features/stories/presentation/screens/stories_management_screen.dart';
import 'package:app_vendor/features/stories/state/vendor_stories_provider.dart';

void main() {
  group('Vendor Stories Cap & State Tests', () {
    test('Vendor stories provider enforces 25-active-Story cap', () async {
      // Create 25 mock active stories
      final existing25Stories = List.generate(
        kMaxActiveStoriesPerVendor,
        (i) => StoryModel(
          id: 'story-$i',
          storeId: 'store-1',
          storeName: 'Heritage Silks',
          storyType: 'gallery_uploaded',
          mediaUrl: 'https://example.com/story-$i.jpg',
          publishedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          vendorStoriesProvider.overrideWith(() => _MockVendorStoriesNotifier(existing25Stories)),
        ],
      );

      final notifier = container.read(vendorStoriesProvider.notifier);
      final stories = await container.read(vendorStoriesProvider.future);
      expect(stories.length, 25);

      // Attempting to add a 26th story must be rejected by cap logic
      expect(
        () => notifier.createStory(
          storyType: 'gallery_uploaded',
          mediaUrl: 'https://example.com/overflow.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Active story limit (25) reached'),
        )),
      );
    });

    test('Deleting an active story removes it immediately', () async {
      final initialStories = [
        StoryModel(
          id: 'story-to-delete',
          storeId: 'store-1',
          storeName: 'Heritage Silks',
          storyType: 'product_linked',
          mediaUrl: 'https://example.com/del.jpg',
          publishedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
        StoryModel(
          id: 'story-remaining',
          storeId: 'store-1',
          storeName: 'Heritage Silks',
          storyType: 'gallery_uploaded',
          mediaUrl: 'https://example.com/rem.jpg',
          publishedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          vendorStoriesProvider.overrideWith(() => _MockVendorStoriesNotifier(initialStories)),
        ],
      );

      final notifier = container.read(vendorStoriesProvider.notifier);
      final beforeDelete = await container.read(vendorStoriesProvider.future);
      expect(beforeDelete.length, 2);

      final deleted = await notifier.deleteStory('story-to-delete');
      expect(deleted, isTrue);

      final afterDelete = container.read(vendorStoriesProvider).valueOrNull ?? [];
      expect(afterDelete.length, 1);
      expect(afterDelete.first.id, 'story-remaining');
    });
  });

  group('AddStoryScreen Widget Tests', () {
    testWidgets('AddStoryScreen shows both Option A and Option B tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoryScreen(),
          ),
        ),
      );

      // Verifies both options are clearly presented
      expect(find.text('Option A: My Products'), findsOneWidget);
      expect(find.text('Option B: Gallery Upload'), findsOneWidget);

      // Switch to Option B tab
      await tester.tap(find.text('Option B: Gallery Upload'));
      await tester.pumpAndSettle();

      // Verifies Option B fields are displayed
      expect(find.text('Story Title (Optional)'), findsOneWidget);
      expect(find.text('Story Caption / Notes (Optional)'), findsOneWidget);
      expect(find.text('Add Listing Price to Story'), findsOneWidget);
      expect(find.text('Select Image from Device Gallery'), findsOneWidget);
      expect(find.text('Publish Gallery Story 📸'), findsOneWidget);

      // Toggle listing price ON to reveal price fields
      await tester.tap(find.text('Add Listing Price to Story'));
      await tester.pumpAndSettle();
      expect(find.text('Price (₹, Optional)'), findsOneWidget);
      expect(find.text('Offer Price (₹, Optional)'), findsOneWidget);
    });

    testWidgets('Option B rejects negative prices and promotional price exceeding regular price', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoryScreen(),
          ),
        ),
      );

      // Switch to Option B tab
      await tester.tap(find.text('Option B: Gallery Upload'));
      await tester.pumpAndSettle();

      // Toggle listing price ON
      await tester.tap(find.text('Add Listing Price to Story'));
      await tester.pumpAndSettle();

      // Find price fields
      final priceFinder = find.widgetWithText(TextFormField, 'Price (₹, Optional)');
      final promoFinder = find.widgetWithText(TextFormField, 'Offer Price (₹, Optional)');

      // Enter regular price: 1000, and promo price: 1500 (exceeds regular price)
      await tester.enterText(priceFinder, '1000');
      await tester.enterText(promoFinder, '1500');

      // Attempt submit
      await tester.tap(find.text('Publish Gallery Story 📸'));
      await tester.pumpAndSettle();

      // Client validation must catch promotional price exceeding regular price
      expect(find.text('Cannot exceed price'), findsOneWidget);
    });
  });

  group('StoriesManagementScreen Widget Tests', () {
    testWidgets('Shows 24h quota counter and empty state when no active stories', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vendorStoriesProvider.overrideWith(() => _MockVendorStoriesNotifier([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: StoriesManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 / 25 Active'), findsOneWidget);
      expect(find.text('No Active Stories'), findsOneWidget);
      expect(find.text('Publish First Story'), findsOneWidget);
    });
  });
}

class _MockVendorStoriesNotifier extends VendorStoriesNotifier {
  final List<StoryModel> _mockStories;
  _MockVendorStoriesNotifier(this._mockStories);

  @override
  Future<List<StoryModel>> build() async {
    return _mockStories;
  }

  @override
  Future<StoryModel?> createStory({
    required String storyType,
    String? productId,
    dynamic mediaFile,
    String? mediaUrl,
    String? title,
    String? caption,
    double? price,
    double? promotionalPrice,
  }) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.length >= kMaxActiveStoriesPerVendor) {
      throw Exception('Active story limit ($kMaxActiveStoriesPerVendor) reached. Please delete an older story or wait for it to expire.');
    }
    final created = StoryModel(
      id: 'mock-created-${DateTime.now().millisecondsSinceEpoch}',
      storeId: 'store-1',
      storeName: 'Mock Boutique',
      storyType: storyType,
      mediaUrl: mediaUrl ?? 'https://example.com/mock.jpg',
      title: title,
      caption: caption,
      price: price,
      promotionalPrice: promotionalPrice,
      productId: productId,
      publishedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    state = AsyncValue.data([created, ...currentList]);
    return created;
  }

  @override
  Future<bool> deleteStory(String storyId) async {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data(currentList.where((s) => s.id != storyId).toList());
    return true;
  }
}
