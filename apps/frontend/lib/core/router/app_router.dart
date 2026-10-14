import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/adaptive_shell.dart';
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

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
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
