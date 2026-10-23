import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:her_area/features/profile/presentation/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';

class FakeApiClient implements IApiClient {
  String? token;
  String? refreshToken;
  bool logoutCalled = false;

  @override
  void setAuthToken(String? token, {String? refreshToken}) {
    this.token = token;
    this.refreshToken = refreshToken;
  }

  @override
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    if (endpoint == ApiEndpoints.userProfile) {
      if (token == null || token!.isEmpty) {
        throw const ApiException(statusCode: 401, message: 'Authentication credentials were not provided.');
      }
      return {
        'id': 'user-123',
        'full_name': 'mani',
        'email': 'mani@gmail.com',
        'phone_number': '9876543210',
        'city': 'Hyderabad',
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    if (endpoint == ApiEndpoints.logout) {
      logoutCalled = true;
      return {'message': 'Successfully logged out'};
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return {'status_code': 200};
  }

  @override
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    return {'status_code': 200};
  }

  @override
  Future<Map<String, dynamic>> delete(String endpoint) async {
    return {'status_code': 200};
  }

  @override
  Future<Map<String, dynamic>> postMultipart(String endpoint, {Map<String, dynamic>? files, Map<String, dynamic>? fields}) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> putMultipart(String endpoint, {Map<String, dynamic>? files, Map<String, dynamic>? fields}) async {
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Session Restoration on Refresh / App Reload Tests', () {
    test('AuthTokenStorage persists and restores user name and tokens', () async {
      final storage = AuthTokenStorage();

      await storage.saveTokens(
        accessToken: 'access-jwt-token-123',
        refreshToken: 'refresh-jwt-token-123',
        role: 'CUSTOMER',
        userName: 'mani',
        email: 'mani@gmail.com',
        userId: 'user-123',
      );

      final token = await storage.getAccessToken();
      final name = await storage.getUserName();
      final email = await storage.getUserEmail();
      final role = await storage.getUserRole();

      expect(token, equals('access-jwt-token-123'));
      expect(name, equals('mani'));
      expect(email, equals('mani@gmail.com'));
      expect(role, equals('CUSTOMER'));
    });

    test('AuthSessionNotifier restores cached user name "mani" on initialization', () async {
      final storage = AuthTokenStorage();
      await storage.saveTokens(
        accessToken: 'access-jwt-token-123',
        refreshToken: 'refresh-jwt-token-123',
        role: 'CUSTOMER',
        userName: 'mani',
        email: 'mani@gmail.com',
        userId: 'user-123',
      );

      final notifier = AuthSessionNotifier(storage);
      // Wait for _initRestore to complete
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.currentUser, isNotNull);
      expect(notifier.state.currentUser!.fullName, equals('mani'));
      expect(notifier.state.currentUser!.email, equals('mani@gmail.com'));
    });

    test('UserProfileNotifier immediately populates name from storage without reverting to Welcome', () async {
      final storage = AuthTokenStorage();
      await storage.saveTokens(
        accessToken: 'access-jwt-token-123',
        refreshToken: 'refresh-jwt-token-123',
        role: 'CUSTOMER',
        userName: 'mani',
        email: 'mani@gmail.com',
        userId: 'user-123',
      );

      final fakeApi = FakeApiClient()..setAuthToken('access-jwt-token-123');
      final repo = CustomerApiRepository(fakeApi);
      final authNotifier = AuthSessionNotifier(storage);
      final authRepo = AuthApiRepository(fakeApi, authNotifier);

      final userProfileNotifier = UserProfileNotifier(
        repo,
        authRepo,
        initialName: 'mani',
      );

      // Verify immediate state has "mani"
      expect(userProfileNotifier.state.name, equals('mani'));

      // Wait for loadProfile to fetch from fake backend
      await userProfileNotifier.loadProfile();
      expect(userProfileNotifier.state.name, equals('mani'));
    });
  });

  group('Sign Out Flow Tests', () {
    test('AuthSessionNotifier logout wipes all tokens, user data, and resets state', () async {
      final storage = AuthTokenStorage();
      await storage.saveTokens(
        accessToken: 'access-jwt-token-123',
        refreshToken: 'refresh-jwt-token-123',
        role: 'CUSTOMER',
        userName: 'mani',
        email: 'mani@gmail.com',
        userId: 'user-123',
      );

      final fakeApi = FakeApiClient()..setAuthToken('access-jwt-token-123');
      final notifier = AuthSessionNotifier(storage);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, isTrue);

      bool notified = false;
      void listener() {
        notified = true;
      }
      AuthRouterListenable.instance.addListener(listener);

      // Execute logout
      await notifier.logout(fakeApi);
      AuthRouterListenable.instance.removeListener(listener);

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.currentUser, isNull);
      expect(notifier.state.accessToken, isNull);

      final storedToken = await storage.getAccessToken();
      final storedName = await storage.getUserName();
      expect(storedToken, isNull);
      expect(storedName, isNull);
      expect(fakeApi.token, isNull);
      expect(notified, isTrue);
    });

    testWidgets('ProfileScreen Sign Out dialog performs clean sign out and triggers logout', (tester) async {
      final storage = AuthTokenStorage();
      await storage.saveTokens(
        accessToken: 'access-jwt-token-123',
        refreshToken: 'refresh-jwt-token-123',
        role: 'CUSTOMER',
        userName: 'mani',
        email: 'mani@gmail.com',
      );

      final fakeApi = FakeApiClient()..setAuthToken('access-jwt-token-123');
      final authNotifier = AuthSessionNotifier(storage);
      final authRepo = AuthApiRepository(fakeApi, authNotifier);

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: RoutePaths.login, builder: (context, state) => const Scaffold(body: Text('Login Screen'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenStorageProvider.overrideWithValue(storage),
            authSessionProvider.overrideWith((ref) => authNotifier),
            authApiRepositoryProvider.overrideWithValue(authRepo),
            apiClientProvider.overrideWithValue(fakeApi),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find "Sign Out of Her Account" tile and scroll into view
      final signOutTile = find.text('Sign Out of Her Account');
      expect(signOutTile, findsOneWidget);

      await tester.scrollUntilVisible(signOutTile, 500);
      await tester.tap(signOutTile);
      await tester.pumpAndSettle();

      // Verify Sign Out alert dialog is displayed
      expect(find.text('Sign Out of Her Account'), findsWidgets);
      expect(find.text('Are you sure you want to sign out of Her Account? Your saved favorites will remain securely backed up.'), findsOneWidget);

      // Tap the "Sign Out" confirmation button
      final confirmButton = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Token and stored name must now be completely removed from storage
      final remainingToken = await storage.getAccessToken();
      final remainingName = await storage.getUserName();
      expect(remainingToken, isNull);
      expect(remainingName, isNull);
      expect(authNotifier.state.isAuthenticated, isFalse);
    });
  });
}
