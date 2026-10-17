import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:her_area/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:her_area/features/auth/presentation/screens/login_screen.dart';
import 'package:her_area/features/auth/presentation/screens/signup_screen.dart';
import 'package:her_area/features/auth/presentation/widgets/auth_ui_components.dart';

void main() {
  group('HER AREA Authentication Screens Redesign Tests', () {
    testWidgets('LoginScreen renders pink mobile branding, official logo, and login form elements', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844); // iPhone 12/13/14 size
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify Brand Header & Taglines
      expect(find.byType(AuthBrandHeader), findsOneWidget);
      expect(find.textContaining('Her Area'), findsWidgets);
      expect(find.text('DISCOVER · CONNECT · GROW'), findsOneWidget);
      expect(find.text('A Safer, Brighter Everyday for Every Woman'), findsOneWidget);

      // Verify Existing Form Inputs & Labels
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password / Recovery?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create New Member Account'), findsOneWidget);

      // Verify 'I\'m a Business Owner' is completely REMOVED
      expect(find.textContaining("Business Owner"), findsNothing);
      expect(find.textContaining("I'm a Business Owner"), findsNothing);

      // Verify No Hyderabad skyline / Charminar
      expect(find.textContaining('Charminar'), findsNothing);
      expect(find.textContaining('Hyderabad'), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('SignupScreen renders pink mobile branding and all required registration fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Verify Brand Header
      expect(find.byType(AuthBrandHeader), findsOneWidget);

      // Verify Registration Form Fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Send Verification OTP Token'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);

      // Verify Checkboxes
      expect(find.byType(Checkbox), findsNWidgets(2));

      // Verify 'I\'m a Business Owner' is completely REMOVED
      expect(find.textContaining("Business Owner"), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('ForgotPasswordScreen renders pink mobile branding and recovery form', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      // Verify Header and official logo
      expect(find.byType(AuthBrandHeader), findsOneWidget);
      expect(find.text('Account Recovery'), findsOneWidget);
      expect(find.text('Registered Email Address'), findsOneWidget);
      expect(find.text('Dispatch Recovery OTP Token'), findsOneWidget);
      expect(find.text('Return to Sign In'), findsOneWidget);

      // Verify 'I\'m a Business Owner' is completely REMOVED
      expect(find.textContaining("Business Owner"), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Desktop layout maintains usable layout on wider screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Check desktop showcase panel
      expect(find.byType(AuthBrandHeader), findsOneWidget);
      expect(find.byType(AuthFeatureBadgesRow), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('100% Verified Boutiques'), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
    testWidgets('LoginScreen fits completely in one screen on short mobile screens without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640); // small standard mobile viewport
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify header, feature pills, form inputs, Sign In button, and Sign Up button are ALL visible simultaneously
      expect(find.byType(AuthBrandHeader), findsOneWidget);
      expect(find.byType(AuthFeatureBadgesRow), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create New Member Account'), findsOneWidget);

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}