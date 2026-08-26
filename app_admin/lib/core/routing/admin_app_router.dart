import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';

// Auth Screens
import 'package:app_admin/features/auth/presentation/screens/admin_splash_screen.dart';
import 'package:app_admin/features/auth/presentation/screens/admin_login_screen.dart';
import 'package:app_admin/features/auth/presentation/screens/admin_forgot_password_screen.dart';
import 'package:app_admin/features/auth/presentation/screens/admin_otp_screen.dart';

// Navigation Wrapper & Shell
import 'package:app_admin/features/navigation/presentation/screens/admin_main_wrapper_screen.dart';

// Dashboard
import 'package:app_admin/features/dashboard/presentation/screens/admin_dashboard_screen.dart';

// Vendors
import 'package:app_admin/features/vendors/presentation/screens/vendor_list_screen.dart';
import 'package:app_admin/features/vendors/presentation/screens/vendor_details_screen.dart';
import 'package:app_admin/features/vendors/presentation/screens/profile_approvals_screen.dart';
import 'package:app_admin/features/vendors/presentation/screens/store_approvals_screen.dart';

// Moderation
import 'package:app_admin/features/moderation/presentation/screens/moderation_hub_screen.dart';
import 'package:app_admin/features/moderation/presentation/screens/product_moderation_screen.dart';
import 'package:app_admin/features/moderation/presentation/screens/gallery_moderation_screen.dart';
import 'package:app_admin/features/moderation/presentation/screens/offer_moderation_screen.dart';
import 'package:app_admin/features/moderation/presentation/screens/review_moderation_screen.dart';

// Customers & Categories
import 'package:app_admin/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:app_admin/features/customers/presentation/screens/customer_details_screen.dart';
import 'package:app_admin/features/categories/presentation/screens/category_management_screen.dart';

// Analytics & Reports
import 'package:app_admin/features/analytics/presentation/screens/analytics_hub_screen.dart';
import 'package:app_admin/features/analytics/presentation/screens/reports_export_screen.dart';

// Settings & Support
import 'package:app_admin/features/subscriptions/presentation/screens/plan_management_screen.dart';
import 'package:app_admin/features/subscriptions/presentation/screens/payment_history_screen.dart';
import 'package:app_admin/features/settings/presentation/screens/notification_composer_screen.dart';
import 'package:app_admin/features/settings/presentation/screens/roles_permissions_screen.dart';
import 'package:app_admin/features/settings/presentation/screens/system_states_showcase_screen.dart';
import 'package:app_admin/features/settings/presentation/screens/admin_legal_screen.dart';
import 'package:app_admin/features/settings/presentation/screens/admin_settings_screen.dart';
import 'package:app_admin/features/settings/presentation/screens/admin_profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

final GoRouter adminAppRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AdminRoutePaths.splash,
  routes: [
    GoRoute(
      path: AdminRoutePaths.splash,
      builder: (context, state) => const AdminSplashScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.login,
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.forgotPassword,
      builder: (context, state) => const AdminForgotPasswordScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.otpVerification,
      builder: (context, state) => const AdminOtpScreen(),
    ),

    // Stateful Shell Route for the 5 console tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AdminMainWrapperScreen(navigationShell: navigationShell),
      branches: [
        // Branch 0: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.dashboard,
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ],
        ),
        // Branch 1: Vendors
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.vendors,
              builder: (context, state) => const VendorListScreen(),
            ),
          ],
        ),
        // Branch 2: Moderation
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.moderation,
              builder: (context, state) => const ModerationHubScreen(),
            ),
          ],
        ),
        // Branch 3: Customers
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.customers,
              builder: (context, state) => const CustomerListScreen(),
            ),
          ],
        ),
        // Branch 4: Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.analytics,
              builder: (context, state) => const AnalyticsHubScreen(),
            ),
          ],
        ),
      ],
    ),

    // Detail & Sub-routes (rendered over root navigator)
    GoRoute(
      path: AdminRoutePaths.vendorDetails,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final vendorId = state.pathParameters['id'] ?? '';
        return VendorDetailsScreen(vendorId: vendorId);
      },
    ),
    GoRoute(
      path: AdminRoutePaths.profileApprovals,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileApprovalsScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.storeApprovals,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StoreApprovalsScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.productModeration,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProductModerationScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.planManagement,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PlanManagementScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.paymentHistory,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PaymentHistoryScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.galleryModeration,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GalleryModerationScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.offerModeration,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OfferModerationScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.reviewModeration,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReviewModerationScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.customerDetails,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomerDetailsScreen(customerId: id);
      },
    ),
    GoRoute(
      path: AdminRoutePaths.categories,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoryManagementScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.reports,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportsExportScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.notificationComposer,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationComposerScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminSettingsScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.adminProfile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminProfileScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.rolesPermissions,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RolesPermissionsScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.systemStatesShowcase,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SystemStatesShowcaseScreen(),
    ),
    GoRoute(
      path: AdminRoutePaths.privacyPolicy,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminLegalScreen(title: 'Customer & Studio Privacy Policy', isPrivacy: true),
    ),
    GoRoute(
      path: AdminRoutePaths.termsConditions,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminLegalScreen(title: 'Platform Terms of Service', isPrivacy: false),
    ),
    GoRoute(
      path: AdminRoutePaths.helpSupport,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminLegalScreen(title: 'Executive IT & Operations Support', isPrivacy: false),
    ),
  ],
);
