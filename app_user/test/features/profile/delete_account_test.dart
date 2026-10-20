import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:her_area/features/profile/presentation/screens/settings_screen.dart';
import 'package:her_area/features/profile/presentation/screens/profile_screen.dart';
import 'package:her_area/features/profile/presentation/widgets/delete_account_dialog.dart';

class FakeApiClient implements IApiClient {
  bool deleteCalled = false;
  Map<String, dynamic>? lastPostBody;
  bool shouldFail = false;
  String failureMessage = 'Incorrect password. Account deletion rejected.';

  @override
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    if (endpoint == ApiEndpoints.customerDeleteAccount) {
      deleteCalled = true;
      lastPostBody = body;
      if (shouldFail) {
        throw ApiException(message: failureMessage, statusCode: 400);
      }
      return {
        'status': 'success',
        'message': 'Your account has been permanently deleted.',
      };
    }
    if (endpoint == ApiEndpoints.logout) {
      return {'detail': 'Logged out.'};
    }
    return {'status_code': 200};
  }

  @override
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    if (endpoint == ApiEndpoints.userProfile) {
      return {
        'id': 'user-123',
        'email': 'customer@example.com',
        'phone_number': '+919876543210',
        'full_name': 'Ananya Sharma',
        'role': 'CUSTOMER',
      };
    }
    if (endpoint.contains('notification')) {
      return {'results': []};
    }
    return {'results': []};
  }

  @override
  Future<Map<String, dynamic>> delete(String endpoint) async => {'status': 'deleted'};
  @override
  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async => {'status': 'updated'};
  @override
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async => {'status': 'updated'};
  @override
  Future<Map<String, dynamic>> postMultipart(String endpoint, {Map<String, dynamic>? files, Map<String, dynamic>? fields}) async => {};
  @override
  Future<Map<String, dynamic>> putMultipart(String endpoint, {Map<String, dynamic>? files, Map<String, dynamic>? fields}) async => {};
  @override
  void setAuthToken(String? token, {String? refreshToken}) {}
}

void main() {
  late FakeApiClient fakeApi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeApi = FakeApiClient();
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApi),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('DeleteAccountDialog Unit & Widget Tests', () {
    testWidgets('renders dialog with permanence warnings, data deletion breakdown, and audit notice', (tester) async {
      await tester.pumpWidget(createTestWidget(const DeleteAccountDialog()));

      // 1. Header & Danger warning
      expect(find.text('Delete Account Permanently'), findsOneWidget);
      expect(find.textContaining('This action is permanent and cannot be undone'), findsOneWidget);

      // 2. Data deletion bullet points
      expect(find.textContaining('authentication credentials will be permanently erased'), findsOneWidget);
      expect(find.textContaining('wishlist items, favorites, and browsing history'), findsOneWidget);
      expect(find.textContaining('reviews, notifications, and active device push tokens'), findsOneWidget);

      // 3. Legal and audit retention notice
      expect(find.textContaining('Legally required records: Past appointment bookings or receipts are disassociated and anonymized'), findsOneWidget);

      // 4. Form elements
      expect(find.byKey(const Key('delete_account_password_field')), findsOneWidget);
      expect(find.byKey(const Key('delete_account_checkbox')), findsOneWidget);
      expect(find.byKey(const Key('delete_account_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('delete_account_confirm_button')), findsOneWidget);
    });

    testWidgets('Permanently Delete button is disabled until BOTH checkbox confirmed AND password entered', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(const DeleteAccountDialog()));

      final confirmBtnFinder = find.byKey(const Key('delete_account_confirm_button'));
      ElevatedButton btn = tester.widget(confirmBtnFinder);
      expect(btn.onPressed, isNull, reason: 'Button must be disabled initially');

      // Check the checkbox only
      await tester.tap(find.byKey(const Key('delete_account_checkbox')));
      await tester.pump();

      btn = tester.widget(confirmBtnFinder);
      expect(btn.onPressed, isNull, reason: 'Button must be disabled if password is empty');

      // Enter password
      await tester.enterText(find.byKey(const Key('delete_account_password_field')), 'MyPassword123!');
      await tester.pump();

      btn = tester.widget(confirmBtnFinder);
      expect(btn.onPressed, isNotNull, reason: 'Button must be enabled when checkbox is checked and password is entered');

      // Uncheck the checkbox
      await tester.tap(find.byKey(const Key('delete_account_checkbox')));
      await tester.pump();

      btn = tester.widget(confirmBtnFinder);
      expect(btn.onPressed, isNull, reason: 'Button must be disabled when checkbox is unchecked even if password is entered');

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('displays error message on password failure and allows retry', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      fakeApi.shouldFail = true;
      fakeApi.failureMessage = 'Incorrect password. Account deletion rejected.';

      await tester.pumpWidget(createTestWidget(const DeleteAccountDialog()));

      // Check confirmation and enter wrong password
      await tester.tap(find.byKey(const Key('delete_account_checkbox')));
      await tester.enterText(find.byKey(const Key('delete_account_password_field')), 'WrongPassword');
      await tester.pump();

      // Tap confirm button
      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pump(); // Start loading
      await tester.pumpAndSettle(); // Settle async call

      expect(fakeApi.deleteCalled, isTrue);
      expect(fakeApi.lastPostBody?['confirmation'], isTrue);
      expect(fakeApi.lastPostBody?['password'], 'WrongPassword');

      // Error message is displayed in dialog
      expect(find.text('Incorrect password. Account deletion rejected.'), findsOneWidget);

      // Verify user can retry: enter new password and try again
      fakeApi.shouldFail = false;
      await tester.enterText(find.byKey(const Key('delete_account_password_field')), 'CorrectPassword123!');
      await tester.pump();

      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeApi.lastPostBody?['password'], 'CorrectPassword123!');

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('successful deletion executes API with confirmation and password', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      fakeApi.shouldFail = false;

      await tester.pumpWidget(createTestWidget(const DeleteAccountDialog()));

      await tester.tap(find.byKey(const Key('delete_account_checkbox')));
      await tester.enterText(find.byKey(const Key('delete_account_password_field')), 'ValidSecretPassword123!');
      await tester.pump();

      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeApi.deleteCalled, isTrue);
      expect(fakeApi.lastPostBody?['confirmation'], isTrue);
      expect(fakeApi.lastPostBody?['password'], 'ValidSecretPassword123!');

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('Settings and Profile Screen Integration Tests', () {
    testWidgets('SettingsScreen contains Delete Account option', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Verify the tile is present
      expect(find.byKey(const Key('settings_delete_account_tile')), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Permanently remove your account and eligible personal data'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('ProfileScreen does not contain Delete Account option (only in Settings)', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Verify Delete Account is NOT present on ProfileScreen
      expect(find.byKey(const Key('profile_delete_account_tile')), findsNothing);
      expect(find.text('Delete Account'), findsNothing);

      // Verify Sign Out is still present
      expect(find.text('Sign Out of VIP Account'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
