import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:her_area/features/auth/presentation/screens/login_screen.dart';
import 'package:her_area/features/auth/presentation/screens/signup_screen.dart';
import 'package:her_area/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:her_area/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:her_area/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:her_area/features/auth/presentation/screens/create_password_screen.dart';
import 'package:her_area/features/location/presentation/screens/location_permission_screen.dart';
import 'package:her_area/features/onboarding/presentation/screens/interest_selection_screen.dart';
import 'package:her_area/features/home/presentation/screens/main_wrapper_screen.dart';
import 'package:her_area/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:her_area/features/discovery/presentation/screens/categories_screen.dart';
import 'package:her_area/features/discovery/presentation/screens/nearby_stores_screen.dart';
import 'package:her_area/features/store/presentation/screens/store_details_screen.dart';
import 'package:her_area/features/search/presentation/screens/search_screen.dart';
import 'package:her_area/features/profile/presentation/screens/profile_screen.dart';
import 'package:her_area/features/profile/presentation/screens/favorites_screen.dart';
import 'package:her_area/features/profile/presentation/screens/recently_viewed_screen.dart';
import 'package:her_area/features/profile/presentation/screens/notifications_screen.dart';
import 'package:her_area/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:her_area/features/profile/presentation/screens/settings_screen.dart';
import 'package:her_area/features/profile/presentation/screens/help_support_screen.dart';
import 'package:her_area/features/profile/presentation/screens/about_screen.dart';
import 'package:her_area/features/profile/presentation/screens/terms_privacy_screen.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashScreen()),
    GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
    GoRoute(path: RoutePaths.signup, builder: (context, state) => const SignupScreen()),
    GoRoute(path: RoutePaths.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(
      path: RoutePaths.recentlyViewed,
      builder: (context, state) => const RecentlyViewedScreen(),
    ),
    GoRoute(
      path: RoutePaths.resetPassword, 
      builder: (context, state) {
        final resetToken = (state.extra as Map<String, dynamic>?)?['reset_token'] as String? ?? '';
        return ResetPasswordScreen(resetToken: resetToken);
      }
    ),
    GoRoute(
      path: RoutePaths.otpVerification, 
      builder: (context, state) {
        final purpose = (state.extra as Map<String, dynamic>?)?['purpose'] as String? ?? 'LOGIN';
        return OtpVerificationScreen(purpose: purpose);
      }
    ),
    GoRoute(path: RoutePaths.createPassword, builder: (context, state) => const CreatePasswordScreen()),
    GoRoute(path: RoutePaths.locationPermission, builder: (context, state) => const LocationPermissionScreen()),
    GoRoute(path: RoutePaths.interestSelection, builder: (context, state) => const InterestSelectionScreen()),
    
    // Customer Profile & Auxiliary Endpoints
    GoRoute(path: RoutePaths.favorites, builder: (context, state) => const FavoritesScreen()),
    GoRoute(path: RoutePaths.notifications, builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: RoutePaths.editProfile, builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: RoutePaths.settings, builder: (context, state) => const SettingsScreen()),
    GoRoute(path: RoutePaths.helpSupport, builder: (context, state) => const HelpSupportScreen()),
    GoRoute(path: RoutePaths.about, builder: (context, state) => const AboutScreen()),
    GoRoute(path: RoutePaths.termsPrivacy, builder: (context, state) => const TermsPrivacyScreen()),

    GoRoute(
      path: RoutePaths.storeDetails,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'store_1';
        return StoreDetailsScreen(storeId: id);
      },
    ),
    // StatefulShellRoute utilizing RoutePaths for clean web URL endpoint transitions
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapperScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomeDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.categories,
              builder: (context, state) => const CategoriesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.nearby,
              builder: (context, state) => const NearbyStoresScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.search,
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
