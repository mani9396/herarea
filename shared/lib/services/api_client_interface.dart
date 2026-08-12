import 'dart:async';

/// Abstract REST API client interface designed to connect all three Flutter apps
/// (app_user, app_vendor, app_admin) to our single Django REST Framework (DRF)
/// backend and PostgreSQL database.
abstract class IApiClient {
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters});
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> delete(String endpoint);
  
  /// Multipart file uploads for gallery visuals, store documents, and KYC verifications
  Future<Map<String, dynamic>> postMultipart(String endpoint, {Map<String, String>? files, Map<String, dynamic>? fields});
  
  /// Inject JWT / OAuth token and refresh token issued by Django authentication endpoints
  void setAuthToken(String? token, {String? refreshToken});
}
