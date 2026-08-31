/// App navigation (P0-06) with role-gated redirects (P2-05).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/presentation/placeholder_screen.dart';
import '../domain/enums.dart';
import '../features/ai_summary/presentation/ai_summary_screen.dart';
import '../features/auth/application/session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/patient/application/profile_screen.dart';
import '../features/patient_home/presentation/patient_home_screen.dart';
import '../features/records/presentation/medications_screen.dart';
import '../features/records/presentation/record_detail_screen.dart';
import '../features/timeline/presentation/timeline_screen.dart';
import '../features/vitals/presentation/vitals_screen.dart';
import 'shell/app_shell.dart';

/// The app's [GoRouter], rebuilt-aware of the session.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  return buildAppRouter(ref, refresh);
});

/// Where a signed-in user of [role] belongs.
String homeForRole(UserRole role) => switch (role) {
  UserRole.patient => AppRoutes.patientHome,
  UserRole.staff => AppRoutes.staffDashboard,
  UserRole.admin => AppRoutes.adminUsers,
};

bool _canAccess(String location, UserRole role) {
  final area = switch (role) {
    UserRole.patient => '/patient',
    UserRole.staff => '/staff',
    UserRole.admin => '/admin',
  };
  return location == '/' || location.startsWith(area);
}

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
  static const patientMedications = '/patient/medications';

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

GoRouter buildAppRouter(Ref ref, Listenable refresh) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) => _guard(ref, state),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),

      // Standalone screens pushed full-screen over a shell (DESIGN.md §6:
      // "Detail = full-screen push" on compact).
      GoRoute(
        path: AppRoutes.patientSummary,
        builder: (_, _) => const AiSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.patientSettings,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.patientMedications,
        builder: (_, _) => const MedicationsScreen(),
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
    ],
  );
}

/// Role-gated routing guard (P2-05).
String? _guard(Ref ref, GoRouterState state) {
  final session = ref.read(sessionProvider);
  final loc = state.matchedLocation;
  const onSplash = '/';
  final onAuthScreen = loc == AppRoutes.login || loc == AppRoutes.register;

  // Still loading the persisted session → sit on the splash.
  if (session.isRestoring) return loc == onSplash ? null : onSplash;

  final user = session.user;
  if (user == null) {
    return onAuthScreen ? null : AppRoutes.login;
  }

  // Signed in: keep them out of the splash / auth screens, and out of
  // another role's area.
  if (loc == onSplash || onAuthScreen) return homeForRole(user.role);
  if (!_canAccess(loc, user.role)) return homeForRole(user.role);
  return null;
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

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
            builder: (_, _) => const PatientHomeScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientTimeline,
            builder: (_, _) => const TimelineScreen(),
            routes: [
              GoRoute(
                path: 'record/:id',
                builder: (_, state) =>
                    RecordDetailScreen(recordId: state.pathParameters['id']!),
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
            builder: (_, _) => const VitalsScreen(),
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
