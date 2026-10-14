import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_storage.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    // Asynchronously verify session on app startup
    Future.microtask(() => checkAuthStatus());
    return AuthState.initial();
  }

  /// Check persisted session on app launch
  Future<void> checkAuthStatus() async {
    try {
      final token = await AuthStorage.getAccessToken();
      final refreshToken = await AuthStorage.getRefreshToken();
      final savedUser = await AuthStorage.getUserProfile();

      if (token == null || token.isEmpty || savedUser == null) {
        state = AuthState.unauthenticated();
        return;
      }

      // Restore session immediately from cache for zero-latency UI
      state = AuthState.authenticated(
        user: savedUser,
        accessToken: token,
        refreshToken: refreshToken ?? '',
      );

      // Verify and sync permissions in the background
      try {
        final freshUser = await _repository.getMe();
        await AuthStorage.saveSession(
          accessToken: token,
          refreshToken: refreshToken ?? '',
          user: freshUser,
        );
        state = AuthState.authenticated(
          user: freshUser,
          accessToken: token,
          refreshToken: refreshToken ?? '',
        );
      } catch (_) {
        // If offline, keep cached session; if token expired, refresh will handle on next request
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  /// Perform user login
  Future<bool> login({
    required String username,
    required String password,
    String? hospitalCode,
  }) async {
    state = AuthState.loading();
    try {
      final result = await _repository.login(
        username: username,
        password: password,
        hospitalCode: hospitalCode,
      );

      final user = result['user'] as AuthUser;
      final accessToken = result['accessToken'] as String;
      final refreshToken = result['refreshToken'] as String;

      state = AuthState.authenticated(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = AuthState.unauthenticated(message: msg);
      return false;
    }
  }

  /// Log out staff user
  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  /// Check if the currently authenticated user has a specific permission
  bool hasPermission(String perm) {
    return state.user?.hasPermission(perm) ?? false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
