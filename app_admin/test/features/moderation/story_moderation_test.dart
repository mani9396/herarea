import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/features/moderation/presentation/screens/story_moderation_screen.dart';

class _FakeAdminStoriesNotifier extends AdminStoriesNotifier {
  _FakeAdminStoriesNotifier(List<StoryModel> initial) : super(null) {
    state = AsyncValue.data(initial);
  }

  @override
  Future<bool> takeDownStory(String storyId) async {
    final list = state.valueOrNull ?? [];
    state = AsyncValue.data(list.where((s) => s.id != storyId).toList());
    return true;
  }
}

void main() {
  final now = DateTime.now();
  final sampleStories = <StoryModel>[
    StoryModel(
      id: 'story-prod-1',
      storeId: 'store-1',
      storeName: 'Kanchipuram Silks Studio',
      storyType: 'product_linked',
      mediaUrl: 'https://example.com/saree.jpg',
      productId: 'prod-101',
      productSummary: {
        'name': 'Royal Crimson Kanjeevaram Saree',
        'price': 28500.0,
      },
      isProductAvailable: true,
      publishedAt: now.subtract(const Duration(hours: 2)),
      expiresAt: now.add(const Duration(hours: 22)),
    ),
    StoryModel(
      id: 'story-gal-1',
      storeId: 'store-2',
      storeName: 'Ananya Bridal Studio',
      storyType: 'gallery_uploaded',
      mediaUrl: 'https://example.com/bridal.jpg',
      title: 'Handcrafted Zardozi Lookbook',
      caption: 'Exclusive backstage glimpses from yesterday fitting',
      price: 15000.0,
      publishedAt: now.subtract(const Duration(hours: 5)),
      expiresAt: now.add(const Duration(hours: 19)),
    ),
  ];

  Widget buildTestWidget({List<StoryModel>? stories}) {
    final list = stories ?? sampleStories;
    return ProviderScope(
      overrides: [
        adminStoriesProvider.overrideWith((ref) => _FakeAdminStoriesNotifier(list)),
      ],
      child: const MaterialApp(
        home: StoryModerationScreen(),
      ),
    );
  }

  testWidgets('StoryModerationScreen displays Option A and Option B stories with metadata', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Live Stories Moderation & Governance 📸'), findsOneWidget);
    expect(find.text('Kanchipuram Silks Studio'), findsOneWidget);
    expect(find.text('Ananya Bridal Studio'), findsOneWidget);

    // Option A badge and title
    expect(find.text('Option A: Store Product'), findsOneWidget);
    expect(find.text('Royal Crimson Kanjeevaram Saree'), findsOneWidget);

    // Option B badge and title
    expect(find.text('Option B: Gallery Upload'), findsOneWidget);
    expect(find.text('Handcrafted Zardozi Lookbook'), findsOneWidget);
    expect(find.text('Exclusive backstage glimpses from yesterday fitting'), findsOneWidget);

    // Moderation action button
    expect(find.text('Take Down'), findsNWidgets(2));
  });

  testWidgets('Filter chips toggle story list between Option A and Option B', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Filter to Store Products only
    await tester.tap(find.text('Option A: Store Products'));
    await tester.pumpAndSettle();

    expect(find.text('Kanchipuram Silks Studio'), findsOneWidget);
    expect(find.text('Ananya Bridal Studio'), findsNothing);

    // Filter to Gallery Uploads only
    await tester.tap(find.text('Option B: Gallery Uploads'));
    await tester.pumpAndSettle();

    expect(find.text('Kanchipuram Silks Studio'), findsNothing);
    expect(find.text('Ananya Bridal Studio'), findsOneWidget);
  });

  testWidgets('Take Down button triggers confirmation dialog and revokes story', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap first Take Down button
    await tester.tap(find.text('Take Down').first);
    await tester.pumpAndSettle();

    // Dialog appears
    expect(find.text('Revoke & Take Down Story?'), findsOneWidget);
    expect(find.textContaining('This story by "Kanchipuram Silks Studio" will be removed'), findsOneWidget);

    // Confirm take-down in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Take Down Story'));
    await tester.pumpAndSettle();

    // Story removed from list
    expect(find.text('Kanchipuram Silks Studio'), findsNothing);
    expect(find.text('Ananya Bridal Studio'), findsOneWidget);
  });
}
