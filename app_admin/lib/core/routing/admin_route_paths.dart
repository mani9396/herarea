class AdminRoutePaths {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';

  // Primary Console Tabs (Shell Routes)
  static const String dashboard = '/dashboard';
  static const String vendors = '/vendors';
  static const String moderation = '/moderation';
  static const String customers = '/customers';
  static const String analytics = '/analytics';

  // Detail & Action Routes
  static const String vendorDetails = '/vendor-details/:id';
  static const String profileApprovals = '/profile-approvals';
  
  static const String productModeration = '/moderation/products';
  static const String galleryModeration = '/moderation/gallery';
  static const String offerModeration = '/moderation/offers';
  static const String reviewModeration = '/moderation/reviews';
  
  static const String customerDetails = '/customer-details/:id';
  static const String categories = '/categories';
  
  static const String notifications = '/notifications';
  static const String notificationComposer = '/notifications/compose';
  
  static const String reports = '/analytics/reports';
  
  static const String settings = '/settings';
  static const String adminProfile = '/settings/profile';
  static const String rolesPermissions = '/settings/roles';
  static const String systemStatesShowcase = '/settings/system-states';
  static const String privacyPolicy = '/settings/privacy';
  static const String termsConditions = '/settings/terms';
  static const String helpSupport = '/settings/support';
  static const String about = '/settings/about';

  // Helper methods to generate dynamic parameterized URLs
  static String getVendorDetailsUrl(String vendorId) => '/vendor-details/$vendorId';
  static String getCustomerDetailsUrl(String customerId) => '/customer-details/$customerId';
}
