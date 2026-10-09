/// App navigation (P0-06) with role-gated redirects (P2-05).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di.dart';
import '../domain/enums.dart';
import '../features/admin/presentation/admin_ai_log_screen.dart';
import '../features/admin/presentation/admin_workspace_screens.dart';
import '../features/admin/presentation/admin_clinic_documents.dart';
import '../features/admin/presentation/admin_people_profile.dart';
import '../features/admin/presentation/admin_finance_report.dart';
import '../features/admin/presentation/admin_appointments_screen.dart';
import '../features/admin/presentation/admin_billing_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_feedback_screen.dart';
import '../features/admin/presentation/admin_forecast_screen.dart';
import '../features/admin/presentation/admin_profile_pages.dart';
import '../features/admin/presentation/admin_profile_screen.dart';
import '../features/admin/presentation/admin_referral_requests_screen.dart';
import '../features/admin/presentation/admin_top_actions.dart';
import '../features/admin/presentation/admin_work_queue_screen.dart';
import '../features/admin/presentation/ai_settings_screen.dart';
import '../features/admin/presentation/audit_log_screen.dart';
import '../features/admin/presentation/clinic_hours_screen.dart';
import '../features/admin/presentation/departments_screen.dart';
import '../features/admin/presentation/document_access_screen.dart';
import '../features/admin/presentation/document_policies_screen.dart';
import '../features/admin/presentation/system_analytics_screen.dart';
import '../features/admin/presentation/user_management_screen.dart';
import '../features/ai_chat/presentation/care_navigator_overlay.dart';
import '../features/ai_scribe/presentation/clinical_scribe_screen.dart';
import '../features/ai_summary/presentation/ai_summary_screen.dart';
import '../features/appointments/presentation/appointment_detail_screen.dart';
import '../features/appointments/presentation/appointments_screen.dart';
import '../features/auth/application/session.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/billing/presentation/payments_screen.dart';
import '../features/booking/presentation/booking_screen.dart';
import '../features/care/presentation/admin_home_visits_screen.dart';
import '../features/care/presentation/document_workspace_screen.dart';
import '../features/care/presentation/home_visit_screen.dart';
import '../features/care/presentation/issued_documents_screen.dart';
import '../features/care/presentation/messages_screen.dart';
import '../features/care/presentation/sick_leave_screen.dart';
import '../features/care/presentation/staff_inbox_screen.dart';
import '../features/consultation/presentation/consultation_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/patient/application/profile_screen.dart';
import '../features/patient/presentation/allergies_screen.dart';
import '../features/patient/presentation/linked_account_screen.dart';
import '../features/patient/presentation/profile_section_pages.dart';
import '../features/patient/presentation/visited_doctors_screen.dart';
import '../features/patient_chart/presentation/patient_chart_screen.dart';
import '../features/patient_chart/presentation/patient_summary_screen.dart';
import '../features/patient_home/presentation/patient_home_screen.dart';
import '../features/records/presentation/radiology_screen.dart';
import '../features/records/presentation/record_detail_screen.dart';
import '../features/staff_dashboard/presentation/panel_analytics_screen.dart';
import '../features/staff_dashboard/presentation/schedule_work_screen.dart';
import '../features/staff_dashboard/presentation/staff_activity_screen.dart';
import '../features/staff_dashboard/presentation/staff_dashboard_screen.dart';
import '../features/staff_dashboard/presentation/staff_directory_screen.dart';
import '../features/staff_dashboard/presentation/staff_patients_screen.dart';
import '../features/staff_dashboard/presentation/staff_profile_pages.dart';
import '../features/staff_dashboard/presentation/staff_profile_screen.dart';
import '../features/staff_dashboard/presentation/staff_schedule_screen.dart';
import '../features/staff_dashboard/presentation/staff_top_actions.dart';
import '../features/tasks/presentation/task_board_screen.dart';
import '../features/tasks/presentation/task_detail_screen.dart';
import '../features/timeline/presentation/health_records_screen.dart';
import '../features/vitals/presentation/vitals_screen.dart';
import '../l10n/app_localizations.dart';
import 'shell/app_shell.dart';

/// The app's [GoRouter], rebuilt-aware of the session and the one-time
/// bootstrap (dataset seed / migration).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(appBootstrapProvider, (_, _) => refresh.value++);
  return buildAppRouter(ref, refresh);
});

/// Where a signed-in user of [role] belongs.
String homeForRole(UserRole role) => switch (role) {
  UserRole.patient => AppRoutes.patientHome,
  UserRole.staff => AppRoutes.staffDashboard,
  UserRole.admin => AppRoutes.adminDashboard,
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
  static const forgotPassword = '/forgot-password';

  // Patient
  static const patientHome = '/patient/home';
  static const patientTimeline = '/patient/timeline';
  static const patientVitals = '/patient/home/vitals';
  static const patientBilling = '/patient/home/billing';
  static const patientNotifications = '/patient/home/notifications';
  static const patientAppointments = '/patient/appointments';
  static const patientBook = '/patient/appointments/book';

  /// Appointment detail — pass the appointment id.
  static String patientAppointmentDetail(String id) =>
      '$patientAppointments/detail/$id';
  static const patientSummary = '/patient/summary';
  static const patientSettings = '/patient/settings';
  static const patientProfilePersonal = '/patient/settings/personal';
  static const patientProfileHealth = '/patient/settings/health';
  static const patientProfilePreferences = '/patient/settings/preferences';
  static const patientProfileFamily = '/patient/settings/family';

  /// A linked family account, viewed through the access its owner granted.
  static String linkedAccount(String ownerPatientId) =>
      '$patientProfileFamily/linked/$ownerPatientId';

  /// Opens Health Records with the Medications view selected (keeps the shell
  /// nav rail / bar visible, unlike a standalone route).
  static const patientMedications = '/patient/timeline?view=medications';
  static const patientNutrition = '/patient/nutrition';
  static const patientImaging = '/patient/timeline/imaging';
  static const patientAllergies = '/patient/timeline/allergies';
  static const patientSickLeave = '/patient/timeline/sick-leave';
  static const patientDocuments = '/patient/timeline/documents';
  static const patientVisitedDoctors = '/patient/appointments/doctors';
  static const patientMessages = '/patient/home/messages';
  static const patientHomeVisit = '/patient/home/home-visit';

  /// Record detail — pass the record id: `'$patientTimeline/record/$id'`.
  static String patientRecord(String id) => '$patientTimeline/record/$id';

  // Staff
  static const staffDashboard = '/staff/dashboard';
  static const staffPatients = '/staff/patients';
  static const staffTasks = '/staff/tasks';
  static const staffSchedule = '/staff/schedule';
  static const staffScribe = '/staff/scribe';

  /// The consultation page for one appointment — full-screen over the shell.
  static String staffConsultation(String appointmentId) =>
      '/staff/consultation/$appointmentId';
  static const staffNotifications = '/staff/dashboard/notifications';
  static const staffProfile = '/staff/profile';
  static const staffInbox = '/staff/dashboard/inbox';

  /// One patient thread in the staff inbox.
  /// [ownerId] opens a colleague's thread this clinician covers.
  static String staffInboxThread(
    String patientId, {
    String? name,
    String? ownerId,
  }) {
    final query = {'name': ?name, 'owner': ?ownerId};
    final base = '$staffInbox/$patientId';
    return query.isEmpty
        ? base
        : Uri(path: base, queryParameters: query).toString();
  }

  // Profile-section pages — each its own page, reached from the Profile hub
  // with a back button (mirrors the patient Profile).
  static const staffProfileAccount = '/staff/profile/account';
  static const staffProfileActivity = '/staff/profile/activity';
  static const staffProfileDirectory = '/staff/profile/directory';
  static const staffProfileAnalytics = '/staff/profile/analytics';
  static const staffProfilePreferences = '/staff/profile/preferences';

  static String staffPatientChart(String id) => '$staffPatients/$id';
  static String staffPatientSummary(String id) => '$staffPatients/$id/summary';

  // Admin — nav tabs
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminDepartments = '/admin/departments';
  static const adminBilling = '/admin/billing';
  static const adminProfile = '/admin/profile';

  // Admin — operational pushes from the dashboard Quick actions
  static const adminAppointments = '/admin/appointments';
  static const adminFeedback = '/admin/feedback';
  static const adminHomeVisits = '/admin/dashboard/home-visits';
  static const adminReferralRequests = '/admin/dashboard/referral-requests';

  /// Unowned / overdue clinical work and delivery problems (Phase 6).
  static const adminWorkQueue = '/admin/dashboard/work';
  static const adminNotifications = '/admin/dashboard/notifications';

  // Admin — Profile-section pages, each its own page under the Profile hub
  static const adminProfileAccount = '/admin/profile/account';
  static const adminProfileAudit = '/admin/profile/audit';
  static const adminProfileAnalytics = '/admin/profile/analytics';
  static const adminProfileForecast = '/admin/profile/forecast';
  static const adminProfileAiSettings = '/admin/profile/ai';
  static const adminProfileAiLog = '/admin/profile/ai-log';
  static const adminProfilePreferences = '/admin/profile/preferences';
  static const adminProfileClinicHours = '/admin/profile/clinic-hours';
  static const adminDocumentPolicies = '/admin/profile/document-policies';

  // Deprecated aliases — kept so old deep links / the audit `entityId`
  // strings still resolve. Prefer the `adminProfile*` names.
  static const adminAnalytics = adminProfileAnalytics;
  static const adminAudit = adminProfileAudit;
  static const adminAiSettings = adminProfileAiSettings;
  static const adminAiLog = adminProfileAiLog;
  static const adminForecast = adminProfileForecast;
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
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      // The booking wizard is a focused full-screen flow over the shell — no
      // bottom nav while a multi-step task is in progress (DESIGN.md §6).
      GoRoute(
        path: AppRoutes.patientSummary,
        builder: (_, _) => const AiSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.patientBook,
        builder: (_, state) => BookingScreen(
          mode: (state.extra as BookingMode?) ?? BookingMode.schedule,
          initialStaffId: state.uri.queryParameters['staff'],
          initialDepartmentId: state.uri.queryParameters['dept'],
          targetPatientId: state.uri.queryParameters['for'],
        ),
      ),
      GoRoute(
        path: AppRoutes.staffScribe,
        builder: (_, state) => ClinicalScribeScreen(
          patientId: state.uri.queryParameters['patient'] ?? '',
        ),
      ),
      GoRoute(
        path: '/staff/consultation/:appointmentId',
        builder: (_, state) => ConsultationScreen(
          appointmentId: state.pathParameters['appointmentId']!,
        ),
      ),
      // Operational pushes from the dashboard Quick actions — full-screen over
      // the shell, with the admin top bar.
      GoRoute(
        path: AppRoutes.adminAppointments,
        builder: (_, _) => const AdminAppointmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminFeedback,
        builder: (_, _) => const AdminFeedbackScreen(),
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
  const publicAuth = {
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  };
  final onAuthScreen = publicAuth.contains(loc);

  // Dataset still seeding/migrating (or failed to), or the persisted session
  // still loading → sit on the splash so nothing reads half-populated data.
  // A failed seed must hold here too: falling through to the login screen
  // with zero accounts actually created would make every login — including
  // every demo account — fail with "account not found" and no explanation.
  final bootstrap = ref.read(appBootstrapProvider);
  final booting = bootstrap.isLoading || bootstrap.hasError;
  if (booting || session.isRestoring) {
    return loc == onSplash ? null : onSplash;
  }

  final user = session.user;
  if (user == null) {
    return onAuthScreen ? null : AppRoutes.login;
  }

  // Signed in: keep them out of the splash / auth screens, and out of
  // another role's area. The same account signing back in after an idle
  // timeout returns to where it was (the session only carries that location
  // for the account that timed out).
  if (loc == onSplash || onAuthScreen) {
    final resume = session.resumeLocation;
    if (resume != null &&
        session.resumeAccountId == user.id &&
        _canAccess(Uri.parse(resume).path, user.role)) {
      return resume;
    }
    return homeForRole(user.role);
  }
  if (!_canAccess(loc, user.role)) return homeForRole(user.role);
  return null;
}

class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);
    if (!bootstrap.hasError) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Seeding/migration failed (e.g. the browser's local storage refused to
    // open) — say so and let the user retry, instead of silently continuing
    // to a login screen backed by an empty database.
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                t.startupFailedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                t.startupFailedSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => ref.invalidate(appBootstrapProvider),
                child: Text(t.tryAgain),
              ),
              const SizedBox(height: 12),
              // Collapsed by default (this is patient-facing), but the raw
              // exception is what actually lets a bug report be fixed —
              // "something went wrong" alone taught us nothing last time.
              if (kDebugMode)
                ExpansionTile(
                  title: Text(
                    t.technicalDetailsLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  children: [
                    SelectableText(
                      '${bootstrap.error}',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Patient
// ---------------------------------------------------------------------------

StatefulShellRoute _patientShell() {
  return StatefulShellRoute.indexedStack(
    // Bottom nav order: Home, Nutrition, Appointment, Records, Profile.
    // The bar stays visible on every patient screen (Vitals nests under Home).
    builder: (context, state, navigationShell) {
      final t = AppLocalizations.of(context)!;
      return AppShell(
        navigationShell: navigationShell,
        overlay: const CareNavigatorOverlay(),
        destinations: [
          AppDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: t.navHome,
          ),
          AppDestination(
            icon: Icons.restaurant_outlined,
            selectedIcon: Icons.restaurant,
            label: t.navNutrition,
          ),
          AppDestination(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note,
            label: t.navAppointments,
          ),
          AppDestination(
            icon: Icons.folder_shared_outlined,
            selectedIcon: Icons.folder_shared,
            label: t.navRecords,
          ),
          AppDestination(
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle,
            label: t.profile,
          ),
        ],
      );
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientHome,
            builder: (_, _) => const PatientHomeScreen(),
            routes: [
              GoRoute(path: 'vitals', builder: (_, _) => const VitalsScreen()),
              GoRoute(
                path: 'billing',
                builder: (_, _) => const PaymentsScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (_, _) => const NotificationsScreen(),
              ),
              GoRoute(
                path: 'messages',
                builder: (_, _) => const MessagesScreen(),
                routes: [
                  GoRoute(
                    path: ':staffId',
                    builder: (_, state) => PatientMessageThreadPage(
                      staffId: state.pathParameters['staffId']!,
                      title: state.uri.queryParameters['name'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'home-visit',
                builder: (_, _) => const HomeVisitScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientNutrition,
            builder: (_, _) => const NutritionScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientAppointments,
            builder: (_, _) => const AppointmentsScreen(),
            routes: [
              GoRoute(
                path: 'doctors',
                builder: (_, _) => const VisitedDoctorsScreen(),
              ),
              GoRoute(
                path: 'detail/:id',
                builder: (_, state) => AppointmentDetailScreen(
                  appointmentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.patientTimeline,
            builder: (_, state) => HealthRecordsScreen(
              startOnMedications:
                  state.uri.queryParameters['view'] == 'medications',
            ),
            routes: [
              GoRoute(
                path: 'imaging',
                builder: (_, _) => const RadiologyScreen(),
              ),
              GoRoute(
                path: 'allergies',
                builder: (_, _) => const AllergiesScreen(),
              ),
              GoRoute(
                path: 'sick-leave',
                builder: (_, state) => SickLeaveScreen(
                  patientId: state.uri.queryParameters['patientId'],
                ),
              ),
              GoRoute(
                path: 'documents',
                builder: (_, state) => IssuedDocumentsScreen(
                  patientId: state.uri.queryParameters['patientId'],
                ),
              ),
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
            path: AppRoutes.patientSettings,
            builder: (_, _) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'personal',
                builder: (_, _) => const PersonalInfoPage(),
              ),
              GoRoute(
                path: 'health',
                builder: (_, _) => const HealthDetailsPage(),
              ),
              GoRoute(
                path: 'preferences',
                builder: (_, _) => const PreferencesPage(),
              ),
              GoRoute(
                path: 'family',
                builder: (_, _) => const FamilyNetworkPage(),
                routes: [
                  GoRoute(
                    path: 'linked/:ownerId',
                    builder: (_, state) => LinkedAccountScreen(
                      ownerPatientId: state.pathParameters['ownerId']!,
                    ),
                  ),
                ],
              ),
            ],
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
    builder: (context, state, navigationShell) {
      final t = AppLocalizations.of(context)!;
      return AppShell(
        navigationShell: navigationShell,
        contextHeader: const StaffPatientContextHeader(),
        destinations: [
          AppDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: t.localeName == 'ar'
                ? '\u0627\u0644\u064a\u0648\u0645'
                : 'Today',
          ),
          AppDestination(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: t.navPatients,
          ),
          AppDestination(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: t.navTasks,
          ),
          AppDestination(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: t.navSchedule,
          ),
          AppDestination(
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle,
            label: t.profile,
          ),
        ],
      );
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffDashboard,
            builder: (_, _) => const StaffDashboardScreen(),
            routes: [
              GoRoute(
                path: 'inbox',
                builder: (_, _) => const StaffInboxScreen(),
                routes: [
                  GoRoute(
                    path: ':patientId',
                    builder: (_, state) => StaffMessageThreadPage(
                      patientId: state.pathParameters['patientId']!,
                      title: state.uri.queryParameters['name'],
                      ownerId: state.uri.queryParameters['owner'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'notifications',
                builder: (_, _) =>
                    const NotificationsScreen(topActions: StaffTopActions()),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffPatients,
            builder: (_, _) => const StaffPatientsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    PatientChartScreen(patientId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'documents',
                    builder: (_, state) => DocumentWorkspaceScreen(
                      patientId: state.pathParameters['id']!,
                      appointmentId: state.uri.queryParameters['appointmentId'],
                    ),
                  ),
                  GoRoute(
                    path: 'summary',
                    builder: (_, state) => PatientSummaryScreen(
                      patientId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffTasks,
            builder: (_, _) => const TaskBoardScreen(),
            routes: [
              GoRoute(
                path: 'handover',
                builder: (_, _) => const HandoverScreen(),
              ),
              GoRoute(
                path: ':taskId',
                builder: (_, s) =>
                    TaskDetailScreen(id: s.pathParameters['taskId']!),
                routes: [
                  GoRoute(
                    path: 'source/:type/:sourceId',
                    builder: (_, s) => TaskSourceScreen(
                      task: s.pathParameters['taskId']!,
                      type: s.pathParameters['type']!,
                      source: s.pathParameters['sourceId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffSchedule,
            builder: (_, _) => const StaffScheduleScreen(),
            routes: [
              GoRoute(
                path: 'work',
                builder: (_, _) => const ScheduleWorkScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.staffProfile,
            builder: (_, _) => const StaffProfileScreen(),
            routes: [
              GoRoute(
                path: 'account',
                builder: (_, _) => const StaffAccountPage(),
              ),
              GoRoute(
                path: 'activity',
                builder: (_, _) => const StaffActivityScreen(),
              ),
              GoRoute(
                path: 'directory',
                builder: (_, _) => const StaffDirectoryScreen(),
              ),
              GoRoute(
                path: 'analytics',
                builder: (_, _) => const PanelAnalyticsScreen(),
              ),
              GoRoute(
                path: 'preferences',
                builder: (_, _) => const StaffPreferencesPage(),
              ),
            ],
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
      compactLeadingCount: 3,
      destinations: [
        AppDestination(
          icon: Icons.dashboard,
          selectedIcon: Icons.dashboard,
          label: adminText(context, 'Overview', 'نظرة عامة'),
        ),
        AppDestination(
          icon: Icons.work_outline,
          selectedIcon: Icons.work_outline,
          label: adminText(context, 'Work', 'العمل'),
        ),
        AppDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people_outline,
          label: adminText(context, 'People', 'الأشخاص'),
        ),
        AppDestination(
          icon: Icons.local_hospital_outlined,
          selectedIcon: Icons.local_hospital_outlined,
          label: adminText(context, 'Clinic', 'العيادة'),
        ),
        AppDestination(
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_outlined,
          label: adminText(context, 'Documents', 'المستندات'),
        ),
        AppDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_outlined,
          label: adminText(context, 'Finance', 'المالية'),
        ),
        AppDestination(
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights_outlined,
          label: adminText(context, 'Reports', 'التقارير'),
        ),
        AppDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_outlined,
          label: adminText(context, 'Settings', 'الإعدادات'),
        ),
      ],
    ),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (_, _) => const AdminDashboardScreen(),
            routes: [
              GoRoute(
                path: 'search',
                builder: (_, _) => const AdminGlobalSearchScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (_, _) =>
                    const NotificationsScreen(topActions: AdminTopActions()),
              ),
              GoRoute(
                path: 'home-visits',
                builder: (_, _) => const AdminHomeVisitsScreen(),
              ),
              GoRoute(
                path: 'referral-requests',
                builder: (_, _) => const AdminReferralRequestsScreen(),
              ),
              GoRoute(
                path: 'work',
                builder: (_, _) => const AdminWorkQueueScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/admin/work',
            builder: (_, state) => AdminUnifiedWorkScreen(
              filter: state.uri.queryParameters['filter'],
              item: state.uri.queryParameters['item'],
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (_, _) => const UserManagementScreen(),
            routes: [
              GoRoute(
                path: ':person',
                builder: (_, state) =>
                    AdminPeopleProfileScreen(state.pathParameters['person']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/admin/clinic',
            builder: (_, _) => const AdminHubScreen('clinic'),
            routes: [
              GoRoute(
                path: 'schedules',
                builder: (_, _) => const AdminStaffScheduleScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.adminDepartments,
            builder: (_, _) => const DepartmentsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/admin/documents',
            builder: (_, _) => const AdminHubScreen('documents'),
            routes: [
              GoRoute(
                path: 'registry',
                builder: (_, _) => const AdminDocumentRegistryScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminBilling,
            builder: (_, _) => const AdminBillingScreen(),
            routes: [
              GoRoute(
                path: 'exceptions',
                builder: (_, _) => const AdminFinanceReportScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/admin/reports',
            builder: (_, _) => const AdminHubScreen('reports'),
            routes: [
              GoRoute(
                path: 'operations',
                builder: (_, _) => const AdminOperationsReportScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/admin/settings',
            builder: (_, _) => const AdminHubScreen('settings'),
            routes: [
              GoRoute(
                path: 'clinic',
                builder: (_, _) => const AdminConfigurationScreen('clinic'),
              ),
              GoRoute(
                path: 'integrations',
                builder: (_, _) =>
                    const AdminConfigurationScreen('integrations'),
              ),
              GoRoute(
                path: 'backup',
                builder: (_, _) => const AdminConfigurationScreen('backup'),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.adminProfile,
            builder: (_, _) => const AdminProfileScreen(),
            routes: [
              GoRoute(
                path: 'account',
                builder: (_, _) => const AdminAccountPage(),
              ),
              GoRoute(path: 'audit', builder: (_, _) => const AuditLogScreen()),
              GoRoute(
                path: 'analytics',
                builder: (_, _) => const SystemAnalyticsScreen(),
              ),
              GoRoute(
                path: 'forecast',
                builder: (_, _) => const AdminForecastScreen(),
              ),
              GoRoute(path: 'ai', builder: (_, _) => const AiSettingsScreen()),
              GoRoute(
                path: 'document-policies',
                builder: (_, _) => const DocumentPoliciesScreen(),
              ),
              GoRoute(
                path: 'document-access',
                builder: (_, _) => const DocumentAccessScreen(),
              ),
              GoRoute(
                path: 'document-workspace',
                builder: (_, state) => DocumentWorkspaceScreen(
                  patientId: state.uri.queryParameters['patientId'] ?? '',
                ),
              ),
              GoRoute(
                path: 'ai-log',
                builder: (_, _) => const AdminAiLogScreen(),
              ),
              GoRoute(
                path: 'preferences',
                builder: (_, _) => const AdminPreferencesPage(),
              ),
              GoRoute(
                path: 'clinic-hours',
                builder: (_, _) => const ClinicHoursScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
