/// App navigation (task P0-06).
///
/// go_router with a placeholder screen behind every route and one adaptive
/// [AppShell] per role. Role-gated guards (redirect by session/role) land in
/// P2-05 — [_guard] is a no-op stub until then.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/presentation/placeholder_screen.dart';
import '../dev/db_spike_screen.dart';
import 'shell/app_shell.dart';

/// The app's [GoRouter]. P2-05 makes this session-aware (redirect by role).
final routerProvider = Provider<GoRouter>((ref) => buildAppRouter());

/// Every route path in the app, in one place.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';

  // Patient
  static const patientHome = '/patient/home';
  static const patientTimeline = '/patient/timeline';
  static const patientVitals = '/patient/vitals';
  static const patientAppointments = '/patient/appointments';
  static const patientBook = '/patient/appointments/book';
  static const patientSummary = '/patient/summary';
  static const patientSettings = '/patient/settings';

  /// Record detail — pass the record id: `'$patientTimeline/record/$id'`.
  static String patientRecord(String id) => '$patientTimeline/record/$id';

  // Staff
  static const staffDashboard = '/staff/dashboard';
  static const staffPatients = '/staff/patients';
  static const staffTasks = '/staff/tasks';
  static const staffSchedule = '/staff/schedule';
  static const staffAnalytics = '/staff/analytics';

  static String staffPatientChart(String id) => '$staffPatients/$id';

  // Admin
  static const adminUsers = '/admin/users';
  static const adminDepartments = '/admin/departments';
  static const adminAnalytics = '/admin/analytics';
  static const adminAudit = '/admin/audit';
  static const adminAiSettings = '/admin/ai';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, _) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) =>
            const PlaceholderScreen(title: 'Sign in', task: 'P2-02'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) =>
            const PlaceholderScreen(title: 'Create account', task: 'P2-03'),
      ),

      // Standalone screens pushed full-screen over a shell (DESIGN.md §6:
      // "Detail = full-screen push" on compact).
      GoRoute(
        path: AppRoutes.patientSummary,
        builder: (_, _) =>
            const PlaceholderScreen(title: 'AI health summary', task: 'P3-09'),
      ),
      GoRoute(
        path: AppRoutes.patientSettings,
        builder: (_, _) =>
            const PlaceholderScreen(title: 'Profile & settings', task: 'P2-17'),
      ),
      GoRoute(
        path: AppRoutes.staffAnalytics,
        builder: (_, _) =>
            const PlaceholderScreen(title: 'Panel analytics', task: 'P5-13'),
      ),
      GoRoute(
        path: AppRoutes.adminAiSettings,
        builder: (_, _) =>
            const PlaceholderScreen(title: 'AI settings', task: 'P5-16'),
      ),

      _patientShell(),
      _staffShell(),
      _adminShell(),

      // Debug-only spike screens (P0-09/10/11).
      if (kDebugMode)
        GoRoute(
          path: '/dev/db-spike',
          builder: (_, _) => const DbSpikeScreen(),
        ),
    ],
  );
}

/// Role-gated routing guard. Stub until P2-05 wires it to the session.
String? _guard(BuildContext context, GoRouterState state) => null;

// ---------------------------------------------------------------------------
// Patient
// ---------------------------------------------------------------------------

StatefulShellRoute _patientShell() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AppShell(
      navigationShell: navigationShell,
      destinations: const [
        AppDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Home',
        ),
        AppDestination(
          icon: Icons.timeline_outlined,
          selectedIcon: Icons.timeline,
          label: 'Timeline',
        ),
        AppDestination(
          icon: Icons.event_outlined,
          selectedIcon: Icons.event,
          label: 'Appointments',
        ),
        AppDestination(
          icon: Icons.favorite_outline,
          selectedIcon: Icons.favorite,
          label: 'Vitals',
        ),
      ],
    ),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientHome,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Home',
              task: 'P2-07',
              showAppBar: false,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientTimeline,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Health timeline',
              task: 'P2-08',
              showAppBar: false,
            ),
            routes: [
              GoRoute(
                path: 'record/:id',
                builder: (_, state) => PlaceholderScreen(
                  title: 'Record ${state.pathParameters['id']}',
                  task: 'P2-10',
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientAppointments,
            builder: (_, _) => const PlaceholderScreen(
              title: 'My appointments',
              task: 'P4-16',
              showAppBar: false,
            ),
            routes: [
              GoRoute(
                path: 'book',
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Book appointment',
                  task: 'P4-13',
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientVitals,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Vitals',
              task: 'P2-14',
              showAppBar: false,
            ),
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Staff
// ---------------------------------------------------------------------------

StatefulShellRoute _staffShell() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AppShell(
      navigationShell: navigationShell,
      destinations: const [
        AppDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Dashboard',
        ),
        AppDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Patients',
        ),
        AppDestination(
          icon: Icons.checklist_outlined,
          selectedIcon: Icons.checklist,
          label: 'Tasks',
        ),
        AppDestination(
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          label: 'Schedule',
        ),
      ],
    ),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffDashboard,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Staff dashboard',
              task: 'P5-05',
              showAppBar: false,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffPatients,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Patients',
              task: 'P5-06',
              showAppBar: false,
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => PlaceholderScreen(
                  title: 'Patient chart ${state.pathParameters['id']}',
                  task: 'P5-07',
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffTasks,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Task board',
              task: 'P5-11',
              showAppBar: false,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffSchedule,
            builder: (_, _) => const PlaceholderScreen(
              title: 'My schedule',
              task: 'P5-12',
              showAppBar: false,
            ),
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

StatefulShellRoute _adminShell() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AppShell(
      navigationShell: navigationShell,
      destinations: const [
        AppDestination(
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
          label: 'Users',
        ),
        AppDestination(
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment,
          label: 'Departments',
        ),
        AppDestination(
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
          label: 'Analytics',
        ),
        AppDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Audit',
        ),
      ],
    ),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (_, _) => const PlaceholderScreen(
              title: 'User management',
              task: 'P5-14',
              showAppBar: false,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminDepartments,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Departments & templates',
              task: 'P5-15',
              showAppBar: false,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminAnalytics,
            builder: (_, _) => const PlaceholderScreen(
              title: 'System analytics',
              task: 'P5-17',
              showAppBar: false,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminAudit,
            builder: (_, _) => const PlaceholderScreen(
              title: 'Audit log',
              task: 'P5-17',
              showAppBar: false,
            ),
          ),
        ],
      ),
    ],
  );
}
