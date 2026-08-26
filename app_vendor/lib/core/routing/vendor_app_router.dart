import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/features/auth/presentation/screens/vendor_splash_screen.dart';
import 'package:app_vendor/features/auth/presentation/screens/vendor_login_screen.dart';
import 'package:app_vendor/features/auth/presentation/screens/vendor_force_password_screen.dart';
import 'package:app_vendor/features/auth/presentation/screens/vendor_signup_screen.dart';
import 'package:app_vendor/features/auth/presentation/screens/vendor_forgot_password_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/business_registration_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/category_selection_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/location_picker_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/business_profile_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/vendor_welcome_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/upload_branding_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/store_timing_screen.dart';
import 'package:app_vendor/features/onboarding/presentation/screens/verification_status_screen.dart';
import 'package:app_vendor/features/navigation/presentation/screens/vendor_main_wrapper_screen.dart';
import 'package:app_vendor/features/dashboard/presentation/screens/vendor_dashboard_screen.dart';
import 'package:app_vendor/features/dashboard/presentation/screens/notifications_screen.dart';
import 'package:app_vendor/features/dashboard/presentation/screens/notification_details_screen.dart';
import 'package:app_vendor/features/dashboard/presentation/screens/system_states_showcase_screen.dart';
import 'package:app_vendor/features/products/presentation/screens/product_management_screen.dart';
import 'package:app_vendor/features/products/presentation/screens/add_product_screen.dart';
import 'package:app_vendor/features/products/presentation/screens/edit_product_screen.dart';
import 'package:app_vendor/features/products/presentation/screens/product_details_screen.dart';
import 'package:app_vendor/features/products/presentation/screens/gallery_screen.dart';
import 'package:app_vendor/features/orders/presentation/screens/orders_enquiries_screen.dart';
import 'package:app_vendor/features/orders/presentation/screens/enquiry_details_screen.dart';
import 'package:app_vendor/features/orders/presentation/screens/customer_reviews_screen.dart';
import 'package:app_vendor/features/orders/presentation/screens/review_details_screen.dart';
import 'package:app_vendor/features/offers/presentation/screens/offers_management_screen.dart';
import 'package:app_vendor/features/offers/presentation/screens/add_offer_screen.dart';
import 'package:app_vendor/features/offers/presentation/screens/edit_offer_screen.dart';
import 'package:app_vendor/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:app_vendor/features/analytics/presentation/screens/earnings_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/profile_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/settings_screen.dart';
import 'package:app_vendor/features/subscription/presentation/screens/active_subscription_screen.dart';
import 'package:app_vendor/features/subscription/presentation/screens/plan_selection_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/help_support_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/about_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:app_vendor/features/profile/presentation/screens/terms_conditions_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootVendorNav');
final GlobalKey<NavigatorState> _shellDashKey = GlobalKey<NavigatorState>(debugLabel: 'dashNav');
final GlobalKey<NavigatorState> _shellProductsKey = GlobalKey<NavigatorState>(debugLabel: 'prodNav');
final GlobalKey<NavigatorState> _shellOrdersKey = GlobalKey<NavigatorState>(debugLabel: 'ordNav');
final GlobalKey<NavigatorState> _shellAnalyticsKey = GlobalKey<NavigatorState>(debugLabel: 'analyNav');
final GlobalKey<NavigatorState> _shellProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profNav');

final vendorRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: VendorRoutePaths.splash,
  routes: [
    // Onboarding & Auth routes on root navigator
    GoRoute(
      path: VendorRoutePaths.splash,
      builder: (context, state) => const VendorSplashScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.welcome,
      builder: (context, state) => const VendorWelcomeScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.login,
      builder: (context, state) => const VendorLoginScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.signup,
      builder: (context, state) => const VendorSignupScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.forcePasswordChange,
      builder: (context, state) => const VendorForcePasswordChangeScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.forgotPassword,
      builder: (context, state) => const VendorForgotPasswordScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.businessRegistration,
      builder: (context, state) => const BusinessRegistrationScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.categorySelection,
      builder: (context, state) => const CategorySelectionScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.locationPicker,
      builder: (context, state) => const LocationPickerScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.uploadBranding,
      builder: (context, state) => const UploadBrandingScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.storeTiming,
      builder: (context, state) => const StoreTimingScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.verificationStatus,
      builder: (context, state) => const VerificationStatusScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.businessProfile,
      builder: (context, state) => const BusinessProfileScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.notifications,
      builder: (context, state) => const VendorNotificationsScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.notificationDetails,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return NotificationDetailsScreen(notificationId: id);
      },
    ),
    GoRoute(
      path: VendorRoutePaths.systemStatesShowcase,
      builder: (context, state) => const SystemStatesShowcaseScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.addProduct,
      builder: (context, state) => const AddProductScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.editProduct,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditProductScreen(productId: id);
      },
    ),
    GoRoute(
      path: VendorRoutePaths.productDetails,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailsScreen(productId: id);
      },
    ),
    GoRoute(
      path: VendorRoutePaths.gallery,
      builder: (context, state) => const GalleryScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.enquiryDetails,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EnquiryDetailsScreen(enquiryId: id);
      },
    ),
    GoRoute(
      path: VendorRoutePaths.customerReviews,
      builder: (context, state) => const CustomerReviewsScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.reviewDetails,
      builder: (context, state) {
        final name = state.pathParameters['id']!;
        return ReviewDetailsScreen(customerName: name);
      },
    ),
    GoRoute(
      path: VendorRoutePaths.offers,
      builder: (context, state) => const OffersManagementScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.addOffer,
      builder: (context, state) => const AddOfferScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.editOffer,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditOfferScreen(offerId: id);
      },
    ),
    GoRoute(
      path: VendorRoutePaths.earnings,
      builder: (context, state) => const EarningsScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.accountSettings,
      builder: (context, state) => const AccountSettingsScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.notificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.helpSupport,
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.about,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.privacyPolicy,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.termsConditions,
      builder: (context, state) => const TermsConditionsScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.planSelection,
      builder: (context, state) => const PlanSelectionScreen(),
    ),
    GoRoute(
      path: VendorRoutePaths.activeSubscription,
      builder: (context, state) => const ActiveSubscriptionScreen(),
    ),

    // Stateful Shell Route for 5 primary management tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return VendorMainWrapperScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellDashKey,
          routes: [
            GoRoute(
              path: VendorRoutePaths.dashboard,
              builder: (context, state) => const VendorDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellProductsKey,
          routes: [
            GoRoute(
              path: VendorRoutePaths.products,
              builder: (context, state) => const ProductManagementScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellOrdersKey,
          routes: [
            GoRoute(
              path: VendorRoutePaths.ordersEnquiries,
              builder: (context, state) => const OrdersEnquiriesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellAnalyticsKey,
          routes: [
            GoRoute(
              path: VendorRoutePaths.analytics,
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellProfileKey,
          routes: [
            GoRoute(
              path: VendorRoutePaths.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
