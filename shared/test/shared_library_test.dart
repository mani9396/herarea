import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('Shared Library Core Components Verification', () {
    test('AppColors verify primary ruby and gold luxury palette bindings', () {
      expect(AppColors.primaryRuby, const Color(0xFFB03052));
      expect(AppColors.accentGold, const Color(0xFFEAA636));
    });

    test('CurrencyFormatter correctly prefixes symbol and commas for Indian Rupee', () {
      final formatted = CurrencyFormatter.format(14500);
      expect(formatted, contains('14,500'));
    });

    test('ValidationHelpers enforce phone and required field logic', () {
      expect(ValidationHelpers.validatePhoneNumber('123'), isNotNull);
      expect(ValidationHelpers.validatePhoneNumber('9811122334'), isNull);
      expect(ValidationHelpers.validateRequired('', 'Store Name'), isNotNull);
      expect(ValidationHelpers.validateRequired('Vanya Silks', 'Store Name'), isNull);
    });

    testWidgets('CustomButton renders label and responds to touch', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Verify Shared Button',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Verify Shared Button'), findsOneWidget);
      await tester.tap(find.text('Verify Shared Button'));
      expect(tapped, isTrue);
    });
  });
}
