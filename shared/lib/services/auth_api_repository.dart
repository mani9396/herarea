import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/constants/api_endpoints.dart';
import 'package:shared/models/user_model.dart';
import 'package:shared/services/api_client_interface.dart';
import 'package:shared/services/api_providers.dart';

class AuthApiRepository {
  final IApiClient _apiClient;
  final AuthSessionNotifier _authNotifier;

  /// Stores the last identifier used (email or phone) for use in OTP verification.
  static String lastAttemptedIdentifier = '';

  const AuthApiRepository(this._apiClient, this._authNotifier);

  /// Determines if an identifier is an email address.
  static bool _isEmail(String identifier) => identifier.contains('@');

  /// Send verification OTP challenge.
  /// Customers pass their email address; Vendors/Admins pass their phone number.
  Future<bool> requestOtp(String identifier, {String role = 'CUSTOMER', String purpose = 'LOGIN', String? fullName}) async {
    if (identifier.isNotEmpty) {
      lastAttemptedIdentifier = identifier;
    }
    try {
      final Map<String, dynamic> body;
      if (_isEmail(identifier)) {
        body = {'email': identifier, 'role': role, 'purpose': purpose};
        if (fullName != null && fullName.isNotEmpty) {
          body['full_name'] = fullName;
        }
      } else {
        body = {'phone_number': identifier, 'role': role, 'purpose': purpose};
      }

      final response = await _apiClient.post(
        ApiEndpoints.requestOtp,
        body: body,
      );
      return (response['status_code'] as int? ?? 200) <= 204 ||
          response.containsKey('message') ||
          response.containsKey('expires_in_seconds');
    } catch (_) {
      return false;
    }
  }

  /// Verify OTP and initialize authenticated session.
  /// Identifier can be email (Customer) or phone (Vendor/Admin).
  Future<bool> verifyOtp(String otp, {String? identifier, String role = 'CUSTOMER'}) async {
    final targetIdentifier =
        (identifier != null && identifier.isNotEmpty) ? identifier : lastAttemptedIdentifier;

    try {
      final Map<String, dynamic> body;
      if (_isEmail(targetIdentifier)) {
        body = {'email': targetIdentifier, 'otp': otp, 'role': role};
      } else {
        body = {'phone_number': targetIdentifier, 'otp': otp, 'role': role};
      }

      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        body: body,
      );

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Login with email and password.
  Future<bool> loginWithPassword(String email, String password) async {
    lastAttemptedIdentifier = email;
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerLogin,
        body: {'email': email, 'password': password},
      );
      return _processJwtResponse(response, email, 'CUSTOMER');
    } catch (_) {
      return false;
    }
  }

  /// Complete registration with password after email verification.
  Future<bool> completeRegistration({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    String locality = '',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerRegister,
        body: {
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'full_name': fullName,
          'locality': locality,
        },
      );
      return _processJwtResponse(response, email, 'CUSTOMER');
    } catch (_) {
      return false;
    }
  }

  /// Verify OTP for a specific purpose (REGISTRATION or PASSWORD_RESET) without returning JWT.
  /// Returns the reset_token if purpose is PASSWORD_RESET, 'true' if REGISTRATION succeeded, or null on failure.
  Future<String?> verifyOtpForPurpose(String email, String otp, String purpose) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtpPurpose,
        body: {'email': email, 'otp': otp, 'purpose': purpose},
      );
      if (purpose == 'PASSWORD_RESET') {
        return response['reset_token']?.toString();
      }
      if (purpose == 'REGISTRATION') {
        return (response['verified'] == true) ? 'true' : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Reset password using a valid reset token.
  Future<bool> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.passwordReset,
        body: {
          'email': email,
          'reset_token': resetToken,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Helper to process JWT token response and set user session
  Future<bool> _processJwtResponse(Map<String, dynamic> response, String identifier, String role) async {
    final access = response['access'] as String? ?? response['access_token'] as String?;
    final refresh = response['refresh'] as String? ?? response['refresh_token'] as String?;

    if (access != null && access.isNotEmpty) {
      UserModel? user;
      if (response['user'] != null && response['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      } else {
        final userId = response['user_id']?.toString() ?? '';
        final resRole = response['role']?.toString() ?? role;
        final email = response['email']?.toString();
        final phone = response['phone_number']?.toString();
        user = UserModel(
          id: userId,
          email: email ?? (_isEmail(identifier) ? identifier : ''),
          phoneNumber: phone ?? (!_isEmail(identifier) ? identifier : ''),
          fullName: 'HER AREA $resRole',
          role: UserRole.fromCode(resRole),
          studioStatus: resRole.toUpperCase() == 'VENDOR' ? 'APPROVED' : null,
        );
      }

      await _authNotifier.setTokens(access, refresh: refresh, user: user, role: user.role.code);
      _apiClient.setAuthToken(access, refreshToken: refresh);

      try {
        final meRes = await _apiClient.get(ApiEndpoints.userProfile);
        final meUser = UserModel.fromJson(meRes);
        _authNotifier.setUser(meUser);
      } catch (_) {
        // Maintain verified session even if profile fetch has a network delay
      }
      return true;
    }
    return false;
  }

  /// Restore user session credentials from storage
  Future<void> restoreSession() async {
    await _authNotifier.restoreSession(_apiClient);
  }

  /// Revoke tokens on server and completely terminate local session
  Future<void> logout() async {
    await _authNotifier.logout(_apiClient);
  }
}

/// Singleton Auth API repository provider
final authApiRepositoryProvider = Provider<AuthApiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final notifier = ref.watch(authSessionProvider.notifier);
  return AuthApiRepository(client, notifier);
});

