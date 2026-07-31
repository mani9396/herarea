class AppConstants {
  AppConstants._();

  // Application Details
  static const String appName = 'HER AREA';
  static const String appVersion = '1.0.0-foundation';
  static const String appTagline = "Women's Local Discovery & O2O Platform";

  // Geolocation Defaults (Hyderabad Jubilee Hills center)
  static const double defaultLatitude = 17.4326;
  static const double defaultLongitude = 78.4071;
  static const double defaultDiscoveryRadiusKm = 5.0;
  static const double maxDiscoveryRadiusKm = 20.0;
  static const double minDiscoveryRadiusKm = 1.0;

  // Network & Timeout Configurations
  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 15;
  static const int defaultPaginationLimit = 20;

  // Animation Timelines
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 600);
}
