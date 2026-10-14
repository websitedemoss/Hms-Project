import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/auth_user.dart';

class AuthStorage {
  static const String _keyAccessToken = 'hms_access_token';
  static const String _keyRefreshToken = 'hms_refresh_token';
  static const String _keyUserProfile = 'hms_user_profile';

  /// Save active session tokens and user data
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserProfile, jsonEncode(user.toJson()));
  }

  /// Update only the access token (e.g. after silent refresh)
  static Future<void> updateAccessToken(String newAccessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, newAccessToken);
  }

  /// Read stored access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Read stored refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  /// Read stored user profile
  static Future<AuthUser?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonStr = prefs.getString(_keyUserProfile);
    if (userJsonStr == null) return null;
    try {
      final map = jsonDecode(userJsonStr) as Map<String, dynamic>;
      return AuthUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clear all stored session credentials (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserProfile);
  }
}
