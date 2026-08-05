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
  
  /// Inject JWT / OAuth token issued by Django authentication endpoints
  void setAuthToken(String? token);
}

/// Mock realization of IApiClient to support frontend Phase 1 & 2 evaluation
/// without activating actual Django HTTP endpoints.
class MockApiClient implements IApiClient {
  String? _authToken;

  @override
  void setAuthToken(String? token) {
    _authToken = token;
  }

  @override
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'status_code': 200, 'message': 'Mock DRF GET response for $endpoint', 'token': _authToken};
  }

  @override
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return {'status_code': 201, 'message': 'Mock DRF POST creation for $endpoint', 'data': body};
  }

  @override
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return {'status_code': 200, 'message': 'Mock DRF PUT update for $endpoint'};
  }

  @override
  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'status_code': 200, 'message': 'Mock DRF PATCH update for $endpoint', 'data': body};
  }

  @override
  Future<Map<String, dynamic>> postMultipart(String endpoint, {Map<String, String>? files, Map<String, dynamic>? fields}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {'status_code': 201, 'message': 'Mock DRF Multipart upload successful for $endpoint', 'files_uploaded': files?.keys.toList()};
  }

  @override
  Future<Map<String, dynamic>> delete(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'status_code': 204, 'message': 'Mock DRF DELETE for $endpoint'};
  }
}
