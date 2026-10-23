import 'package:shared_preferences/shared_preferences.dart';
import '../providers/pending_registration_provider.dart';

/// Persistent secure token and session storage engine utilizing SharedPreferences
/// to retain JWT credentials and role state across app restarts.
class AuthTokenStorage {
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _userRoleKey = 'auth_user_role';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userIdKey = 'auth_user_id';
  static const String _userAvatarKey = 'auth_user_avatar';
  static const String _userGenderKey = 'auth_user_gender';
  static const String _userPhoneKey = 'auth_user_phone';

  static const String _pendingRegNameKey = 'pending_reg_full_name';
  static const String _pendingRegEmailKey = 'pending_reg_email';
  static const String _pendingRegPhoneKey = 'pending_reg_phone';
  static const String _pendingRegDobKey = 'pending_reg_dob';
  static const String _pendingRegGenderKey = 'pending_reg_gender';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? role,
    String? userName,
    String? email,
    String? userId,
    String? avatar,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    if (role != null && role.isNotEmpty) {
      await prefs.setString(_userRoleKey, role);
    }
    if (userName != null && userName.isNotEmpty) {
      await prefs.setString(_userNameKey, userName);
    }
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_userEmailKey, email);
    }
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }
    if (avatar != null && avatar.isNotEmpty) {
      await prefs.setString(_userAvatarKey, avatar);
    }
    if (gender != null && gender.isNotEmpty) {
      await prefs.setString(_userGenderKey, gender);
    }
  }

  Future<void> saveUserData({
    String? userName,
    String? email,
    String? userId,
    String? role,
    String? avatar,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null && userName.isNotEmpty) {
      await prefs.setString(_userNameKey, userName);
    }
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_userEmailKey, email);
    }
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }
    if (role != null && role.isNotEmpty) {
      await prefs.setString(_userRoleKey, role);
    }
    if (avatar != null && avatar.isNotEmpty) {
      await prefs.setString(_userAvatarKey, avatar);
    }
    if (gender != null && gender.isNotEmpty) {
      await prefs.setString(_userGenderKey, gender);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAvatarKey);
  }

  Future<String?> getUserGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userGenderKey);
  }

  Future<void> savePendingRegistration({
    required String fullName,
    required String email,
    String? phoneNumber,
    required String dateOfBirth,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRegNameKey, fullName);
    await prefs.setString(_pendingRegEmailKey, email);
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      await prefs.setString(_pendingRegPhoneKey, phoneNumber.trim());
    } else {
      await prefs.remove(_pendingRegPhoneKey);
    }
    await prefs.setString(_pendingRegDobKey, dateOfBirth);
    await prefs.setString(_pendingRegGenderKey, gender);
  }

  Future<PendingRegistration?> getPendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingRegEmailKey);
    if (email == null || email.trim().isEmpty) {
      return null;
    }
    return PendingRegistration(
      fullName: prefs.getString(_pendingRegNameKey) ?? '',
      email: email.trim(),
      phoneNumber: prefs.getString(_pendingRegPhoneKey),
      dateOfBirth: prefs.getString(_pendingRegDobKey) ?? '',
      gender: prefs.getString(_pendingRegGenderKey) ?? 'FEMALE',
    );
  }

  Future<void> clearPendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRegNameKey);
    await prefs.remove(_pendingRegEmailKey);
    await prefs.remove(_pendingRegPhoneKey);
    await prefs.remove(_pendingRegDobKey);
    await prefs.remove(_pendingRegGenderKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userAvatarKey);
    await prefs.remove(_userGenderKey);
    await prefs.remove(_userPhoneKey);
  }
}

