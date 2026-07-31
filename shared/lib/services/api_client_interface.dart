import 'dart:async';

/// Abstract REST API client interface designed to connect all three Flutter apps
/// (app_user, app_vendor, app_admin) to our single Django REST Framework (DRF)
/// backend and PostgreSQL database.
abstract class IApiClient {
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters});
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> delete(String endpoint);
  
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
    return {'status': 200, 'message': 'Mock DRF GET response for $endpoint', 'token': _authToken};
  }

  @override
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return {'status': 201, 'message': 'Mock DRF POST creation for $endpoint', 'data': body};
  }

  @override
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return {'status': 200, 'message': 'Mock DRF PUT update for $endpoint'};
  }

  @override
  Future<Map<String, dynamic>> delete(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'status': 204, 'message': 'Mock DRF DELETE for $endpoint'};
  }
}
