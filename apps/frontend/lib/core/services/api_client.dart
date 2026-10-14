import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../features/auth/data/auth_storage.dart';

class ApiClient {
  static final http.Client _client = http.Client();

  /// Default headers with JSON content type and optional Bearer token
  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Resolve URL string
  static Uri _buildUri(String endpoint) {
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('${ApiConstants.baseUrl}/$cleanEndpoint');
  }

  /// HTTP GET
  static Future<http.Response> get(String endpoint, {bool requiresAuth = true}) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    var response = await _client.get(uri, headers: headers);

    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final retryHeaders = await _getHeaders(requiresAuth: requiresAuth);
        response = await _client.get(uri, headers: retryHeaders);
      }
    }

    return response;
  }

  /// HTTP POST
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final bodyStr = body != null ? jsonEncode(body) : null;

    var response = await _client.post(uri, headers: headers, body: bodyStr);

    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final retryHeaders = await _getHeaders(requiresAuth: requiresAuth);
        response = await _client.post(uri, headers: retryHeaders, body: bodyStr);
      }
    }

    return response;
  }

  /// HTTP PUT
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final bodyStr = body != null ? jsonEncode(body) : null;

    var response = await _client.put(uri, headers: headers, body: bodyStr);

    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final retryHeaders = await _getHeaders(requiresAuth: requiresAuth);
        response = await _client.put(uri, headers: retryHeaders, body: bodyStr);
      }
    }

    return response;
  }

  /// HTTP PATCH
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final bodyStr = body != null ? jsonEncode(body) : null;

    var response = await _client.patch(uri, headers: headers, body: bodyStr);

    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final retryHeaders = await _getHeaders(requiresAuth: requiresAuth);
        response = await _client.patch(uri, headers: retryHeaders, body: bodyStr);
      }
    }

    return response;
  }

  /// HTTP DELETE
  static Future<http.Response> delete(String endpoint, {bool requiresAuth = true}) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    var response = await _client.delete(uri, headers: headers);

    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final retryHeaders = await _getHeaders(requiresAuth: requiresAuth);
        response = await _client.delete(uri, headers: retryHeaders);
      }
    }

    return response;
  }

  /// Silent token refresh on 401 Unauthorized
  static Future<bool> _attemptTokenRefresh() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await AuthStorage.clearSession();
      return false;
    }

    try {
      final refreshUri = _buildUri('/auth/refresh');
      final response = await _client.post(
        refreshUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null && data['accessToken'] != null) {
          final newAccessToken = data['accessToken'] as String;
          await AuthStorage.updateAccessToken(newAccessToken);
          return true;
        }
      }
    } catch (_) {
      // Refresh failed
    }

    await AuthStorage.clearSession();
    return false;
  }
}
