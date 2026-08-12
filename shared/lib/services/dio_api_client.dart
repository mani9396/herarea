import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared/constants/api_endpoints.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/exceptions/api_exception.dart';
import 'package:shared/services/api_client_interface.dart';

/// Production HTTP network engine powered by Dio, integrating automatic JWT Token 
/// authorization headers and transforming all HTTP failures into structured [ApiException] instances.
class DioApiClient implements IApiClient {
  final Dio _dio;
  String? _authToken;
  String? _refreshToken;
  final void Function(String newAccess, String? newRefresh)? onTokenRefreshed;
  final void Function()? onRefreshFailed;

  DioApiClient({
    Dio? dioOverride,
    String baseUrl = ApiEndpoints.defaultBaseUrl,
    this.onTokenRefreshed,
    this.onRefreshFailed,
  })  : _dio = dioOverride ?? Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
            receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          ),
        ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null && _authToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 &&
            _refreshToken != null &&
            _refreshToken!.isNotEmpty &&
            e.requestOptions.path != ApiEndpoints.tokenRefresh &&
            !e.requestOptions.path.contains('token/refresh')) {
          try {
            final refreshDio = Dio(BaseOptions(
              baseUrl: _dio.options.baseUrl,
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            ));
            final refreshResponse = await refreshDio.post(
              ApiEndpoints.tokenRefresh,
              data: {'refresh': _refreshToken},
            );

            if (refreshResponse.statusCode == 200 && refreshResponse.data is Map) {
              final responseData = refreshResponse.data as Map;
              final newAccess = responseData['access'] as String?;
              final newRefresh = (responseData['refresh'] as String?) ?? _refreshToken;

              if (newAccess != null && newAccess.isNotEmpty) {
                _authToken = newAccess;
                _refreshToken = newRefresh;
                onTokenRefreshed?.call(newAccess, newRefresh);

                e.requestOptions.headers['Authorization'] = 'Bearer $_authToken';
                final retryResponse = await _dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              }
            }
          } catch (_) {
            _authToken = null;
            _refreshToken = null;
            onRefreshFailed?.call();
          }
        }
        return handler.next(e);
      },
    ));
  }

  @override
  void setAuthToken(String? token, {String? refreshToken}) {
    _authToken = token;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    } else if (token == null) {
      _refreshToken = null;
    }
  }

  String? get currentToken => _authToken;
  String? get currentRefreshToken => _refreshToken;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  @override
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      return _formatResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected read error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      return _formatResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected submission error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> postMultipart(String endpoint, {Map<String, String>? files, Map<String, dynamic>? fields}) async {
    try {
      final mapData = <String, dynamic>{};
      if (fields != null) {
        mapData.addAll(fields);
      }
      if (files != null) {
        for (final entry in files.entries) {
          mapData[entry.key] = await MultipartFile.fromFile(entry.value);
        }
      }
      final formData = FormData.fromMap(mapData);
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _formatResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected file upload error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.put(endpoint, data: body);
      return _formatResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected update error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.patch(endpoint, data: body);
      return _formatResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected partial update error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return _formatResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected delete error: ${e.toString()}');
    }
  }

  Map<String, dynamic> _formatResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      final map = Map<String, dynamic>.from(response.data as Map);
      map['status_code'] = response.statusCode;
      return map;
    } else if (response.data is List) {
      return {'results': response.data, 'status_code': response.statusCode};
    } else {
      return {'data': response.data, 'status_code': response.statusCode};
    }
  }

  ApiException _handleDioError(DioException error) {
    if (error.response != null && error.response!.data != null) {
      final responseData = error.response!.data;
      if (responseData is Map<String, dynamic>) {
        return ApiException.fromJson(responseData, defaultStatus: error.response!.statusCode);
      } else {
        return ApiException(
          message: responseData.toString(),
          statusCode: error.response!.statusCode,
        );
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: 'Network request timed out. Please check your internet connection and try again.',
        errorCode: 'NETWORK_TIMEOUT',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Unable to establish connection to HER AREA servers. Please verify server status.',
        errorCode: 'CONNECTION_ERROR',
      );
    }

    return ApiException(
      message: error.message ?? 'Unknown HTTP network communication exception occurred.',
      errorCode: 'DIO_NETWORK_EXCEPTION',
    );
  }
}
