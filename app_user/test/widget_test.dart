import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:her_area/main.dart';

void main() {
  testWidgets('HER AREA App initializes cleanly with ProviderScope and theme state', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HerAreaApp()));
    expect(find.byType(HerAreaApp), findsOneWidget);

    // Fast-forward time to let any initial screen animations settle cleanly
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
