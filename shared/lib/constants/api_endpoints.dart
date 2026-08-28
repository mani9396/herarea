/// Central REST API endpoint routes matching our Django backend configuration.
class ApiEndpoints {
  ApiEndpoints._();

  // Base API configuration
  static const String defaultBaseUrl = 'https://herarea.onrender.com';
  static const String apiVersionPrefix = '/api/v1';
  static String get baseApiUrl => '$defaultBaseUrl$apiVersionPrefix';

  // 1. Common & Health checks
  static const String healthCheck = '/api/v1/health/';

  // 2. Authentication & Accounts (/api/v1/auth/)
  static const String customerLogin = '/api/v1/auth/login/';
  static const String customerRegister = '/api/v1/auth/register/';
  static const String requestOtp = '/api/v1/auth/otp/send/';
  static const String verifyOtp = '/api/v1/auth/otp/verify/';
  static const String verifyOtpPurpose = '/api/v1/auth/otp/verify-purpose/';
  static const String passwordReset = '/api/v1/auth/password-reset/';
  static const String vendorForcePasswordChange = '/api/v1/auth/vendor/force-password-change/';
  static const String tokenRefresh = '/api/v1/auth/token/refresh/';
  static const String logout = '/api/v1/auth/logout/';
  static const String userProfile = '/api/v1/auth/me/';

  // 3. Vendor Onboarding & Management (/api/v1/vendor/)
  static const String vendorAuthRegister = '/api/v1/vendor/auth/register/';
  static const String vendorRegister = '/api/v1/vendor/register/';
  static const String vendorProfile = '/api/v1/vendor/me/';
  static const String vendorBusinessProfile = '/api/v1/business/me/';
  static const String vendorKycUpload = '/api/v1/vendor/kyc/';
  static const String vendorStatusCheck = '/api/v1/vendor/status/';
  static const String vendorAnalytics = '/api/v1/vendor/analytics/';
  static const String vendorDashboardStats = '/api/v1/vendor/dashboard/stats/';

  // 4. Catalog Management (/api/v1/vendor/catalog/)
  static const String vendorProducts = '/api/v1/vendor/catalog/products/';
  static String vendorProductDetail(String id) => '/api/v1/vendor/catalog/products/$id/';
  static const String vendorGallery = '/api/v1/vendor/catalog/gallery/';
  static const String vendorOffers = '/api/v1/vendor/catalog/offers/';
  static const String vendorStoreReviews = '/api/v1/vendor/store/reviews/';

  // 5. Public Showroom & Catalog Discovery (/api/v1/)
  static const String publicStores = '/api/v1/stores/';
  static const String publicStoresNearby = '/api/v1/stores/nearby/';
  static const String publicProducts = '/api/v1/products/';
  static const String publicCategories = '/api/v1/categories/';
  static const String publicPromotions = '/api/v1/promotions/';
  static const String unifiedSearch = '/api/v1/search/';
  static String storeReviews(String storeId) => '/api/v1/stores/$storeId/reviews/';
  static String storeVisit(String storeId) => '/api/v1/stores/$storeId/visit/';
  static String customerReview(String reviewId) => '/api/v1/stores/customer/$reviewId/';

  // 6. Customer Interactions (/api/v1/)
  static const String customerFavorites = '/api/v1/favorites/';
  static const String customerFavoritesToggle = '/api/v1/favorites/toggle/';
  static const String notifications = '/api/v1/notifications/';

  // 7. Booking, Orders & Business Operations (Sprint 5)
  static const String customerBookings = '/api/v1/bookings/';
  static const String customerEnquiries = '/api/v1/enquiries/';
  static const String vendorSchedules = '/api/v1/vendor/schedules/';
  static const String vendorBookings = '/api/v1/vendor/bookings/';
  static String vendorBookingDetail(String id) => '/api/v1/vendor/bookings/$id/';
  static String vendorBookingStatus(String id) => '/api/v1/vendor/bookings/$id/status/';
  static const String vendorEnquiries = '/api/v1/vendor/enquiries/';
  static const String adminBookings = '/api/v1/admin/bookings/';
  static const String adminEnquiries = '/api/v1/admin/enquiries/';

  // 8. Executive Admin Governance (/api/v1/admin/)
  static const String adminDashboardStats = '/api/v1/admin/dashboard/stats/';
  static const String adminCategories = '/api/v1/admin/categories/';
  static const String adminAllVendors = '/api/v1/admin/vendors/all/';
  static const String adminPendingVendors = '/api/v1/admin/vendors/pending/';
  static const String adminVendorCreate = '/api/v1/admin/vendors/create/';
  static String adminVendorApprove(String vendorId) => '/api/v1/admin/vendors/$vendorId/approve/';
  static String adminVendorReject(String vendorId) => '/api/v1/admin/vendors/$vendorId/reject/';
  static String adminVendorSuspend(String vendorId) => '/api/v1/admin/vendors/$vendorId/suspend/';

  // 8b. Store Governance
  static const String adminStores = '/api/v1/admin/business/stores/';
  static String adminStoreApprove(String storeId) => '/api/v1/admin/business/stores/$storeId/approve/';
  static String adminStoreReject(String storeId) => '/api/v1/admin/business/stores/$storeId/reject/';
  static String adminStoreSuspend(String storeId) => '/api/v1/admin/business/stores/$storeId/suspend/';

  static const String adminProducts = '/api/v1/admin/products/';
  static String adminProductDetail(String id) => '/api/v1/admin/products/$id/';
  
  static const String adminOffers = '/api/v1/admin/offers/';
  static String adminOfferDetail(String id) => '/api/v1/admin/offers/$id/';
  
  static const String adminGallery = '/api/v1/admin/gallery/';
  static String adminGalleryDetail(String id) => '/api/v1/admin/gallery/$id/';
  
  static const String adminCustomers = '/api/v1/admin/customers/';
  static String adminCustomerDetail(String id) => '/api/v1/admin/customers/$id/';
  
  static const String adminReviews = '/api/v1/admin/reviews/';
  static String adminReviewDetail(String id) => '/api/v1/admin/reviews/$id/';
  
  static const String adminActivityLogs = '/api/v1/admin/activity-logs/';
  static const String adminNotifications = '/api/v1/admin/notifications/';
  static const String adminBroadcastNotification = '/api/v1/admin/notifications/broadcast/';
  static const String adminAnalytics = '/api/v1/admin/analytics/';
}

