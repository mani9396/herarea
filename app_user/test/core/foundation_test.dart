import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/responsive/responsive_layout.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/loading_indicator.dart';

void main() {
  group('Design System Foundation Tests', () {
    test('AppColors verify luxury brand identity bindings', () {
      expect(AppColors.primaryRuby, const Color(0xFFB03052));
      expect(AppColors.accentGold, const Color(0xFFEAA636));
    });

    test('AppSpacing verify scale consistency', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.lg, 16.0);
    });

    test('AppTheme generates valid light and dark ThemeData with M3 flag', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.useMaterial3, true);
      expect(dark.useMaterial3, true);
      expect(light.colorScheme.primary, AppColors.primaryRuby);
    });
  });

  group('Atomic Widget Library Tests', () {
    testWidgets('CustomButton displays label correctly', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Luxury Explore',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Luxury Explore'), findsOneWidget);
      await tester.tap(find.text('Luxury Explore'));
      expect(pressed, true);
    });

    testWidgets('CustomButton in loading state shows indicator and disables tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Submitting',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submitting'), findsNothing);
    });

    testWidgets('LoadingIndicator renders message cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Loading neighborhood boutiques...'),
          ),
        ),
      );

      expect(find.text('Loading neighborhood boutiques...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Responsive Layout Engine Tests', () {
    testWidgets('ResponsiveLayout displays mobile view when screen width is under 600px', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: Text('Mobile Layout'),
              tablet: Text('Tablet Layout'),
              desktop: Text('Desktop Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('ResponsiveLayout displays desktop view when screen width is over 1024px', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: Text('Mobile Layout'),
              tablet: Text('Tablet Layout'),
              desktop: Text('Desktop Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
