import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:her_area/features/onboarding/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders white HER AREA logo and no PRODUCTION MODE', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify brand name is present
    expect(find.text('HER AREA'), findsOneWidget);
    expect(find.text('LIVE DISCOVERY ENGINE'), findsOneWidget);

    // Verify diamond icon is NOT present
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.byIcon(Icons.diamond), findsNothing);

    // Verify PRODUCTION MODE is removed
    expect(find.text('PRODUCTION MODE'), findsNothing);

    // Verify white logo is loaded
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    // Pump animation forward
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('PRODUCTION MODE'), findsNothing);
  });
}
