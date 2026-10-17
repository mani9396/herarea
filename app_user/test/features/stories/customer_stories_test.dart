import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:her_area/features/home/presentation/screens/story_viewer_screen.dart';
import 'package:her_area/features/store/presentation/screens/customer_product_detail_screen.dart';

void main() {
  group('StoryModel Unit Tests', () {
    test('Correctly identifies product_linked vs gallery_uploaded', () {
      final productStory = StoryModel(
        id: 'story-1',
        storeId: 'store-1',
        storeName: 'Royal Boutique',
        storyType: 'product_linked',
        mediaUrl: 'https://example.com/item.jpg',
        productId: 'prod-100',
        isProductAvailable: true,
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      expect(productStory.isProductLinked, isTrue);
      expect(productStory.isGalleryUploaded, isFalse);
      expect(productStory.productId, 'prod-100');
      expect(productStory.isProductAvailable, isTrue);

      final galleryStory = StoryModel(
        id: 'story-2',
        storeId: 'store-1',
        storeName: 'Royal Boutique',
        storyType: 'gallery_uploaded',
        mediaUrl: 'https://example.com/gallery.jpg',
        title: 'Artisan Workshop Behind The Scenes',
        caption: 'Pure silk threads crafted by hand',
        price: 4999.0,
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      expect(galleryStory.isProductLinked, isFalse);
      expect(galleryStory.isGalleryUploaded, isTrue);
      expect(galleryStory.hasAdditionalInfo, isTrue);
      expect(galleryStory.productId, isNull);
    });

    test('Gallery story without optional fields hasAdditionalInfo is false', () {
      final bareStory = StoryModel(
        id: 'story-3',
        storeId: 'store-1',
        storeName: 'Royal Boutique',
        storyType: 'gallery_uploaded',
        mediaUrl: 'https://example.com/bare.jpg',
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      expect(bareStory.hasAdditionalInfo, isFalse);
      expect(bareStory.title, isNull);
      expect(bareStory.caption, isNull);
      expect(bareStory.price, isNull);
      expect(bareStory.promotionalPrice, isNull);
    });

    test('groupByStore groups multiple stories from the same vendor into a single circle group', () {
      final stories = [
        StoryModel(
          id: 'story-1',
          storeId: 'vendor-aaa',
          storeName: 'aaa',
          storyType: 'product_linked',
          mediaUrl: 'https://example.com/saree1.jpg',
          publishedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
        StoryModel(
          id: 'story-2',
          storeId: 'vendor-aaa',
          storeName: 'aaa',
          storyType: 'gallery_uploaded',
          mediaUrl: 'https://example.com/saree2.jpg',
          publishedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
        StoryModel(
          id: 'story-3',
          storeId: 'vendor-bbb',
          storeName: 'Boutique BBB',
          storyType: 'gallery_uploaded',
          mediaUrl: 'https://example.com/lehenga.jpg',
          publishedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      ];

      final groups = stories.groupByStore();

      // Must have exactly 2 groups (one for vendor-aaa, one for vendor-bbb)
      expect(groups.length, 2);
      expect(groups[0].storeId, 'vendor-aaa');
      expect(groups[0].storeName, 'aaa');
      expect(groups[0].stories.length, 2); // Both stories of vendor aaa are grouped together!
      expect(groups[1].storeId, 'vendor-bbb');
      expect(groups[1].storeName, 'Boutique BBB');
      expect(groups[1].stories.length, 1);
    });

    test('StoryModel fromJson and resolveUrl converts relative media paths to absolute URLs', () {
      final json = {
        'id': 'story-rel-1',
        'store': {
          'id': 'store-1',
          'name': 'Store 1',
          'logo': '/media/stores/logos/my_logo.png',
        },
        'story_type': 'gallery_uploaded',
        'media_url': '/media/stories/media/photo.png',
        'published_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      };

      final story = StoryModel.fromJson(json);
      expect(story.mediaUrl.startsWith('http://') || story.mediaUrl.startsWith('https://'), isTrue);
      expect(story.mediaUrl.endsWith('/media/stories/media/photo.png'), isTrue);
      expect(story.effectiveMediaUrl, equals(story.mediaUrl));
      expect(story.storeLogo?.endsWith('/media/stores/logos/my_logo.png'), isTrue);
    });
  });

  group('Customer Story Viewer Widget Tests', () {
    testWidgets('product_linked story displays "See More About Product" when product is available', (tester) async {
      final story = StoryModel(
        id: 'story-p1',
        storeId: 'store-1',
        storeName: 'Silk Emporium',
        storyType: 'product_linked',
        mediaUrl: 'https://example.com/silk.jpg',
        productId: 'prod-123',
        productSummary: {
          'id': 'prod-123',
          'name': 'Banarasi Silk Saree',
          'price': '12500',
        },
        isProductAvailable: true,
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StoryViewerScreen(
            stories: [story],
            initialIndex: 0,
          ),
        ),
      );

      expect(find.text('See More About Product'), findsOneWidget);
      expect(find.text('Silk Emporium'), findsOneWidget);
      expect(find.text('Banarasi Silk Saree'), findsOneWidget);
      expect(find.text('View Details'), findsNothing);
    });

    testWidgets('product_linked story with unavailable product disables action gracefully', (tester) async {
      final story = StoryModel(
        id: 'story-p2',
        storeId: 'store-1',
        storeName: 'Silk Emporium',
        storyType: 'product_linked',
        mediaUrl: 'https://example.com/deleted.jpg',
        productId: 'prod-deleted',
        isProductAvailable: false, // Product is unlisted/deleted
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StoryViewerScreen(
            stories: [story],
            initialIndex: 0,
          ),
        ),
      );

      expect(find.text('See More About Product'), findsNothing);
      expect(find.text('Product Currently Unavailable'), findsOneWidget);
    });

    testWidgets('gallery_uploaded story displays "View Details" and opens info sheet, never product detail', (tester) async {
      final story = StoryModel(
        id: 'story-g1',
        storeId: 'store-1',
        storeName: 'Zari Studio',
        storyType: 'gallery_uploaded',
        mediaUrl: 'https://example.com/craft.jpg',
        title: 'Master Craftsman Weaving',
        caption: 'Handcrafted over 14 days with heritage metallic zardozi threads.',
        price: 18000.0,
        promotionalPrice: 15500.0,
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StoryViewerScreen(
            stories: [story],
            initialIndex: 0,
          ),
        ),
      );

      // Must NOT show product navigation action
      expect(find.text('See More About Product'), findsNothing);

      // Shows View Details action
      expect(find.text('View Details'), findsOneWidget);

      // Tap View Details to open sheet
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      // Modal info sheet displays provided fields
      expect(find.text('Master Craftsman Weaving'), findsWidgets);
      expect(find.text('Handcrafted over 14 days with heritage metallic zardozi threads.'), findsWidgets);
      expect(find.text('₹15,500'), findsWidgets);
      expect(find.text('₹18,000'), findsWidgets);

      // Confirms boutique source is displayed
      expect(find.text('Zari Studio'), findsWidgets);
    });

    testWidgets('gallery_uploaded story with no optional info omits button without crashing', (tester) async {
      final story = StoryModel(
        id: 'story-g2',
        storeId: 'store-1',
        storeName: 'Minimalist Boutique',
        storyType: 'gallery_uploaded',
        mediaUrl: 'https://example.com/just-image.jpg',
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StoryViewerScreen(
            stories: [story],
            initialIndex: 0,
          ),
        ),
      );

      // No broken or meaningless buttons shown
      expect(find.text('See More About Product'), findsNothing);
      expect(find.text('View Details'), findsNothing);
    });

    testWidgets('CustomerProductDetailScreen shows graceful unavailable view when product does not exist', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerProductDetailScreen(
              productId: 'non-existent-product-id',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Gracefully handles 404 / unavailable without a crash
      expect(find.text('Product Unavailable'), findsOneWidget);
      expect(find.text('Return to Discovery'), findsOneWidget);
    });

    testWidgets('StoryViewerScreen invokes onStoryViewed callback when story begins playing', (tester) async {
      final viewed = <String>[];
      final story = StoryModel(
        id: 'story-v1',
        storeId: 'store-1',
        storeName: 'Royal Silk',
        storyType: 'gallery_uploaded',
        mediaUrl: 'https://example.com/item.jpg',
        publishedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StoryViewerScreen(
            stories: [story],
            initialIndex: 0,
            onStoryViewed: (s) {
              viewed.add(s.id);
            },
          ),
        ),
      );

      // Verify that the callback fired immediately upon story presentation
      expect(viewed.contains('story-v1'), isTrue);
    });
  });
}
