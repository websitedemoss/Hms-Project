import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../domain/models/auth_user.dart';
import 'auth_storage.dart';

class AuthRepository {
  /// 1. Authenticate user credentials
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? hospitalCode,
  }) async {
    final response = await ApiClient.post(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
        if (hospitalCode != null && hospitalCode.isNotEmpty)
          'hospitalCode': hospitalCode,
      },
      requiresAuth: false,
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      final msg = json['message'];
      final errorText = msg is List ? msg.join(', ') : (msg?.toString() ?? 'Login failed');
      throw Exception(errorText);
    }

    final data = json['data'] as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

    await AuthStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user,
    };
  }

  /// 2. Fetch fresh user profile and active permissions
  Future<AuthUser> getMe() async {
    final response = await ApiClient.get('/auth/me');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception('Failed to fetch user session profile.');
    }

    final data = json['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data);
  }

  /// 3. Terminate session on server and locally
  Future<void> logout() async {
    try {
      final refreshToken = await AuthStorage.getRefreshToken();
      await ApiClient.post('/auth/logout', body: {
        if (refreshToken != null) 'refreshToken': refreshToken,
      });
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await AuthStorage.clearSession();
    }
  }

  /// 4. Fetch Role Presets
  Future<Map<String, dynamic>> getRolePresets() async {
    final response = await ApiClient.get('/permissions/presets');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception('Failed to fetch role presets.');
    }
    return json['data'] as Map<String, dynamic>;
  }

  /// 5. Fetch Permissions for a specific staff member
  Future<Map<String, dynamic>> getStaffPermissions(int staffId) async {
    final response = await ApiClient.get('/permissions/$staffId');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception('Failed to fetch staff permissions.');
    }
    return json['data'] as Map<String, dynamic>;
  }

  /// 6. Update Permissions Matrix for a staff member
  Future<Map<String, dynamic>> updateStaffPermissions(
    int staffId,
    Map<String, bool> permissions, {
    String? accountStatus,
  }) async {
    final response = await ApiClient.put(
      '/permissions/$staffId',
      body: {
        'permissions': permissions,
        if (accountStatus != null) 'accountStatus': accountStatus,
      },
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception('Failed to update staff permissions.');
    }
    return json['data'] as Map<String, dynamic>;
  }
}
