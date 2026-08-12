import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/main.dart';

void main() {
  testWidgets('Admin console initializes cleanly with shared design system components', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: HerAreaAdminApp()));
    expect(find.byType(HerAreaAdminApp), findsOneWidget);
    expect(find.text('Ecosystem Core Telemetry'), findsOneWidget);
  });
}
