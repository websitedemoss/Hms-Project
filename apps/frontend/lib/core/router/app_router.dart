import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../layout/adaptive_shell.dart';
import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/permissions_manager_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/patients/presentation/screens/patients_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/beds/presentation/screens/beds_screen.dart';
import '../../features/doctors/presentation/screens/doctors_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/bhooma_ai/presentation/screens/bhooma_ai_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Listenable bridge connecting Riverpod auth state changes to GoRouter refresh
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final currentAuth = ref.read(authProvider);
      final isLoggingIn = state.uri.path == '/login';

      // Don't interrupt while checking initial stored credentials on boot
      if (currentAuth.status == AuthStatus.initial || currentAuth.status == AuthStatus.loading) {
        return null;
      }

      final isAuth = currentAuth.isAuthenticated;

      // 1. Unauthenticated users are redirected to /login
      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      // 2. Authenticated users attempting to view /login are redirected to /dashboard
      if (isAuth && isLoggingIn) {
        return '/dashboard';
      }

      // 3. Permission route guards
      if (isAuth && currentAuth.user != null) {
        final path = state.uri.path;
        final user = currentAuth.user!;

        if (path == '/patients' && !user.hasPermission('patients')) {
          return '/dashboard';
        }
        if (path == '/appointments' && !user.hasPermission('appointments')) {
          return '/dashboard';
        }
        if (path == '/beds' && !user.hasPermission('bed')) {
          return '/dashboard';
        }
        if (path == '/doctors' && !user.hasPermission('doctors')) {
          return '/dashboard';
        }
        if (path == '/attendance' && !user.hasPermission('attendance')) {
          return '/dashboard';
        }
        if (path == '/permissions' && !user.hasPermission('staff')) {
          return '/dashboard';
        }
        if (path == '/bhooma-ai' && !user.hasPermission('bhooma_ai')) {
          return '/dashboard';
        }
        if (path == '/settings' && !user.hasPermission('settings')) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AdaptiveShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/patients',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PatientsScreen(),
            ),
          ),
          GoRoute(
            path: '/appointments',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AppointmentsScreen(),
            ),
          ),
          GoRoute(
            path: '/beds',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BedsScreen(),
            ),
          ),
          GoRoute(
            path: '/doctors',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DoctorsScreen(),
            ),
          ),
          GoRoute(
            path: '/attendance',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AttendanceScreen(),
            ),
          ),
          GoRoute(
            path: '/permissions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PermissionsManagerScreen(),
            ),
          ),
          GoRoute(
            path: '/bhooma-ai',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BhoomaAiScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
