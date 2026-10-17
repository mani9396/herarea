/// Typed exception wrapper designed to seamlessly parse standardized JSON error
/// payloads emitted by our hardened Django REST Framework backend.
/// 
/// Django Hardened JSON Schema:
/// {
///   "error": true,
///   "error_code": "RESOURCE_NOT_FOUND",
///   "status_code": 404,
///   "message": "Requested target showroom does not exist.",
///   "details": { ... },
///   "timestamp": "2026-07-31T12:00:00Z"
/// }
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;
  final String? timestamp;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
    this.timestamp,
  });

  /// Factory constructor to parse Django structured error JSON dictionary
  factory ApiException.fromJson(Map<String, dynamic> json, {int? defaultStatus}) {
    String? resolvedMessage;
    if (json['message'] != null && json['message'].toString().trim().isNotEmpty) {
      resolvedMessage = json['message'].toString();
    } else if (json['error'] != null && json['error'] is! bool && json['error'].toString().trim().isNotEmpty) {
      resolvedMessage = json['error'].toString();
    } else if (json['detail'] != null && json['detail'].toString().trim().isNotEmpty) {
      resolvedMessage = json['detail'].toString();
    } else if (json['details'] != null && json['details'] is String && (json['details'] as String).trim().isNotEmpty) {
      resolvedMessage = json['details'].toString();
    } else if (json['non_field_errors'] != null) {
      final nfe = json['non_field_errors'];
      if (nfe is List && nfe.isNotEmpty) {
        resolvedMessage = nfe.first.toString();
      } else {
        resolvedMessage = nfe.toString();
      }
    } else {
      // Check for first field-level error in map
      for (final entry in json.entries) {
        if (entry.key != 'error' && entry.key != 'status_code' && entry.key != 'error_code' && entry.key != 'timestamp') {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            resolvedMessage = (entry.value as List).first.toString();
            break;
          } else if (entry.value is String && (entry.value as String).trim().isNotEmpty) {
            resolvedMessage = entry.value.toString();
            break;
          }
        }
      }
    }

    return ApiException(
      message: resolvedMessage ?? 'An unexpected network or server exception occurred.',
      statusCode: (json['status_code'] as num?)?.toInt() ?? defaultStatus,
      errorCode: json['error_code']?.toString() ?? _defaultErrorCode(defaultStatus),
      details: json['details'] ?? json,
      timestamp: json['timestamp']?.toString(),
    );
  }

  static String _defaultErrorCode(int? status) {
    if (status == 400) return 'VALIDATION_ERROR';
    if (status == 401) return 'AUTHENTICATION_FAILED';
    if (status == 403) return 'PERMISSION_DENIED';
    if (status == 404) return 'RESOURCE_NOT_FOUND';
    if (status == 429) return 'THROTTLING_LIMIT_EXCEEDED';
    if (status != null && status >= 500) return 'INTERNAL_SERVER_ERROR';
    return 'NETWORK_ERROR';
  }

  /// Convenience boolean validators for client routing & feedback logic
  bool get isUnauthorised => statusCode == 401 || errorCode == 'AUTHENTICATION_FAILED' || errorCode == 'NOT_AUTHENTICATED';
  bool get isPermissionDenied => statusCode == 403 || errorCode == 'PERMISSION_DENIED';
  bool get isNotFound => statusCode == 404 || errorCode == 'RESOURCE_NOT_FOUND';
  bool get isValidationError => statusCode == 400 || errorCode == 'VALIDATION_ERROR';
  bool get isThrottled => statusCode == 429 || errorCode == 'THROTTLING_LIMIT_EXCEEDED';
  bool get isServerError => (statusCode ?? 0) >= 500;

  /// Extract field-specific validation errors if details is a field map
  List<String> getFieldErrors(String fieldName) {
    if (details is Map<String, dynamic> && details[fieldName] != null) {
      final val = details[fieldName];
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      } else if (val is String) {
        return [val];
      }
    }
    return const [];
  }

  @override
  String toString() {
    if (isValidationError && details is Map) {
      final fieldErrors = (details as Map).entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return 'Validation Error: $fieldErrors';
    }
    return 'ApiException(code: $errorCode, status: $statusCode, message: $message)';
  }
}
