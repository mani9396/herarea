import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_vendor/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Vendor app splash screen and navigation to login work cleanly without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: HerAreaVendorApp()));
    expect(find.text('HER AREA'), findsOneWidget);
    expect(find.text('PARTNER PORTAL'), findsOneWidget);

    // Fast-forward time to let splash delay and auth check complete
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Existing Partner? Login Here'), findsOneWidget);
  });
}
