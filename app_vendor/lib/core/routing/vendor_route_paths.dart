class VendorRoutePaths {
  VendorRoutePaths._();

  // Onboarding & Auth
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';
  
  // Business Setup & Onboarding Steps
  static const String businessRegistration = '/business-registration';
  static const String categorySelection = '/category-selection';
  static const String locationPicker = '/location-picker';
  static const String storeTiming = '/store-timing';
  static const String uploadBranding = '/upload-branding';
  static const String verificationStatus = '/verification-status';

  // Primary O2O Vendor Management Tabs (StatefulShellRoute)
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String ordersEnquiries = '/orders';
  static const String analytics = '/analytics';
  static const String profile = '/profile';

  // Catalog, Offers & Inventory Sub-routes
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit/:id';
  static const String productDetails = '/products/details/:id';
  static const String gallery = '/gallery';
  static const String offers = '/offers';
  static const String addOffer = '/offers/add';
  static const String editOffer = '/offers/edit/:id';
  static const String businessProfile = '/business-profile';

  // Operations & Client Interaction Sub-routes
  static const String enquiryDetails = '/orders/details/:id';
  static const String customerReviews = '/reviews';
  static const String reviewDetails = '/reviews/details/:id';
  static const String notifications = '/notifications';
  static const String notificationDetails = '/notifications/details/:id';
  static const String earnings = '/earnings';

  // Account & Legal Auxiliary
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String accountSettings = '/settings/account';
  static const String notificationSettings = '/settings/notifications';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  
  // Showcase & Diagnostics
  static const String systemStatesShowcase = '/system-states-showcase';

  static String buildEditProductPath(String id) => '/products/edit/$id';
  static String buildProductDetailsPath(String id) => '/products/details/$id';
  static String buildEditOfferPath(String id) => '/offers/edit/$id';
  static String buildEnquiryDetailsPath(String id) => '/orders/details/$id';
  static String buildReviewDetailsPath(String id) => '/reviews/details/$id';
  static String buildNotificationDetailsPath(String id) => '/notifications/details/$id';
}
