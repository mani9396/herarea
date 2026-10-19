import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/constants/api_endpoints.dart';
import 'package:shared/models/user_model.dart';
import 'package:shared/services/api_client_interface.dart';
import 'package:shared/services/api_providers.dart';
import 'package:shared/services/push_notification_service.dart';
import 'package:shared/exceptions/api_exception.dart';

class AuthApiRepository {
  final IApiClient _apiClient;
  final AuthSessionNotifier _authNotifier;

  /// Stores the last identifier used (email or phone) for use in OTP verification.
  static String lastAttemptedIdentifier = '';

  /// Stores the last error message returned from authentication endpoints.
  static String lastErrorMessage = '';

  const AuthApiRepository(this._apiClient, this._authNotifier);

  /// Determines if an identifier is an email address.
  static bool _isEmail(String identifier) => identifier.contains('@');

  /// Send verification OTP challenge.
  /// Customers pass their email address; Vendors/Admins pass their phone number.
  Future<bool> requestOtp(
    String identifier, {
    String role = 'CUSTOMER',
    String purpose = 'LOGIN',
    String? fullName,
    String? phoneNumber,
  }) async {
    if (identifier.isNotEmpty) {
      lastAttemptedIdentifier = identifier;
    }
    lastErrorMessage = '';
    try {
      final Map<String, dynamic> body;
      if (_isEmail(identifier)) {
        body = {'email': identifier, 'role': role, 'purpose': purpose};
        if (fullName != null && fullName.isNotEmpty) {
          body['full_name'] = fullName;
        }
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          body['phone_number'] = phoneNumber;
        }
      } else {
        body = {'phone_number': identifier, 'role': role, 'purpose': purpose};
      }

      final response = await _apiClient.post(
        ApiEndpoints.requestOtp,
        body: body,
      );
      if (response.containsKey('error')) {
        lastErrorMessage = response['error'].toString();
        return false;
      }
      return (response['status_code'] as int? ?? 200) <= 204 ||
          response.containsKey('message') ||
          response.containsKey('expires_in_seconds');
    } on ApiException catch (e) {
      lastErrorMessage = e.message;
      return false;
    } catch (e) {
      lastErrorMessage = e.toString();
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

      return _processJwtResponse(response, targetIdentifier, role);
    } catch (_) {
      return false;
    }
  }

  /// Login with email or mobile number and password.
  Future<bool> loginWithPassword(String identifier, String password, {String role = 'CUSTOMER'}) async {
    lastAttemptedIdentifier = identifier;
    lastErrorMessage = '';
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerLogin,
        body: {
          'email': identifier,
          'identifier': identifier,
          'phone_number': identifier,
          'password': password,
          'role': role,
        },
      );
      if (response.containsKey('error')) {
        lastErrorMessage = response['error'].toString();
        return false;
      }
      return _processJwtResponse(response, identifier, role);
    } on ApiException catch (e) {
      lastErrorMessage = e.message;
      return false;
    } catch (e) {
      lastErrorMessage = e.toString();
      return false;
    }
  }

  /// Complete registration with password after email verification.
  Future<void> completeRegistration({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String dateOfBirth,
    required String gender,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.customerRegister,
      body: {
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
      },
    );
    final success = await _processJwtResponse(response, email, 'CUSTOMER');
    if (!success) {
      throw const ApiException(message: 'Invalid response from server.');
    }
  }

  /// Self-register a new Vendor account with verified Email OTP.
  Future<String?> vendorSelfRegister({
    required String ownerName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String otp,
  }) async {
    lastErrorMessage = '';
    try {
      await _apiClient.post(
        ApiEndpoints.vendorAuthRegister,
        body: {
          'owner_name': ownerName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'confirm_password': confirmPassword,
          'otp': otp,
        },
      );
      // Registration successful, requires login manually afterwards
      return null; // Return null on success
    } on ApiException catch (e) {
      lastErrorMessage = e.message;
      return e.message;
    } catch (e) {
      lastErrorMessage = e.toString();
      return 'An unexpected error occurred: $e';
    }
  }

  /// Verify OTP for a specific purpose (REGISTRATION or PASSWORD_RESET) without returning JWT.
  /// Returns the reset_token if purpose is PASSWORD_RESET, 'true' if REGISTRATION succeeded, or null on failure.
  Future<String?> verifyOtpForPurpose(String email, String otp, String purpose) async {
    lastErrorMessage = '';
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtpPurpose,
        body: {'email': email, 'otp': otp, 'purpose': purpose},
      );
      if (response.containsKey('error')) {
        lastErrorMessage = response['error'].toString();
        return null;
      }
      if (purpose == 'PASSWORD_RESET') {
        return response['reset_token']?.toString();
      }
      if (purpose == 'REGISTRATION') {
        return (response['verified'] == true) ? 'true' : null;
      }
      return null;
    } on ApiException catch (e) {
      lastErrorMessage = e.message;
      return null;
    } catch (e) {
      lastErrorMessage = e.toString();
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
    lastErrorMessage = '';
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
      if (response.containsKey('error')) {
        lastErrorMessage = response['error'].toString();
        return false;
      }
      return response['success'] == true;
    } on ApiException catch (e) {
      lastErrorMessage = e.message;
      return false;
    } catch (e) {
      lastErrorMessage = e.toString();
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
          fullName: response['owner_name']?.toString() ?? 'HER AREA $resRole',
          role: UserRole.fromCode(resRole),
          studioStatus: resRole.toUpperCase() == 'VENDOR' ? (response['vendor_status']?.toString() ?? 'APPROVED') : null,
          mustChangePassword: response['must_change_password'] == true,
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

      // Register device for push notifications in the background
      unawaited(PushNotificationService().registerDeviceToken(
        apiClient: _apiClient,
        appType: user.role.code,
      ));

      return true;
    }
    return false;
  }

  /// Restore user session credentials from storage
  Future<void> restoreSession() async {
    await _authNotifier.restoreSession(_apiClient);
    final user = _authNotifier.user;
    if (user != null) {
      unawaited(PushNotificationService().registerDeviceToken(
        apiClient: _apiClient,
        appType: user.role.code,
      ));
    }
  }

  /// Revoke tokens on server and completely terminate local session
  Future<void> logout() async {
    unawaited(PushNotificationService().unregisterDeviceToken(apiClient: _apiClient));
    await _authNotifier.logout(_apiClient);
  }

  /// Admin OTP request
  Future<bool> adminRequestOtp(String email, String adminName) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminRequestOtp,
        body: {'email': email, 'admin_name': adminName},
      );
      return (response['status_code'] as int? ?? 200) <= 204 ||
          response.containsKey('message');
    } catch (_) {
      return false;
    }
  }

  /// Admin OTP verify
  Future<bool> adminVerifyOtp(String email, String otp, String adminName) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminVerifyOtp,
        body: {'email': email, 'otp': otp, 'admin_name': adminName},
      );
      return _processJwtResponse(response, email, 'ADMIN');
    } catch (_) {
      return false;
    }
  }
}

/// Singleton Auth API repository provider
final authApiRepositoryProvider = Provider<AuthApiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final notifier = ref.watch(authSessionProvider.notifier);
  return AuthApiRepository(client, notifier);
});

