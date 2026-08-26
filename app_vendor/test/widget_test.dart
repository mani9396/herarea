import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/main.dart';

void main() {
  testWidgets('Vendor app splash screen and navigation to login work cleanly without overflow', (WidgetTester tester) async {
    // Set view size to realistic desktop/tablet or wider mobile viewport to accommodate uncompressed Ahem font in test environment
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: HerAreaVendorApp()));
    expect(find.text('HER AREA'), findsOneWidget);
    expect(find.text('PARTNER PORTAL'), findsOneWidget);

    // Fast-forward time to let the splash screen timer and animation finish
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Existing Partner? Login Here'), findsOneWidget);
  });
}
