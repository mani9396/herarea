class RoutePaths {
  RoutePaths._();

  // Root & Onboarding
  static const String splash = '/';
  static const String interestSelection = '/interest-selection';
  static const String locationPermission = '/location-permission';

  // Authentication Endpoints
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String otpVerification = '/otp-verification';
  static const String createPassword = '/create-password';

  // Main O2O Discovery Tabs (Web URL endpoints via StatefulShellRoute)
  static const String home = '/home';
  static const String categories = '/categories';
  static const String nearby = '/nearby';
  static const String search = '/search';
  static const String profile = '/profile';

  // Customer Profile & Auxiliary Features
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String termsPrivacy = '/terms-privacy';

  // Store Portfolio & Interaction Deep-Links
  static const String storeDetails = '/store-details/:id';

  static String buildStoreDetailsPath(String storeId) => '/store-details/$storeId';
}
