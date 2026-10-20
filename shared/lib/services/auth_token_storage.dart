import 'package:shared_preferences/shared_preferences.dart';

/// Persistent secure token and session storage engine utilizing SharedPreferences
/// to retain JWT credentials and role state across app restarts.
class AuthTokenStorage {
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _userRoleKey = 'auth_user_role';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userIdKey = 'auth_user_id';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? role,
    String? userName,
    String? email,
    String? userId,
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
  }

  Future<void> saveUserData({
    String? userName,
    String? email,
    String? userId,
    String? role,
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

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
  }
}

