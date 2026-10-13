/// Shared-server mode: the full myhealth app on the shared API.
///
/// Built with `--dart-define=SHARED_API_ORIGIN=https://…`, every repository
/// provider is replaced by a server adapter or by a stub that fails with
/// [SharedModeUnavailableFailure]. Screens that read the local database
/// directly are blocked by the router with an explanation. The local
/// database is a separate, never-seeded scratch store, so no local or demo
/// data can appear as if it were the clinic's.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_environment.dart';
import '../core/di.dart';
import '../core/failures.dart';
import '../core/presentation/app_card.dart';
import '../core/presentation/app_scaffold.dart';
import '../core/ui/patient/patient_components.dart';
import '../core/utils/format.dart';
import '../data/db/app_database.dart';
import '../data/remote/shared_client.dart';
import '../data/remote/shared_repositories.dart';
import '../domain/identity/principal.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/shared/presentation/shared_clinic_views.dart';
import '../features/staff_dashboard/application/staff_providers.dart';
import '../services/auth/access_policy.dart';
import '../services/auth/access_snapshot.dart';
import '../services/auth/auth_context.dart';
import 'theme/theme.dart';

const kSharedApiOrigin = String.fromEnvironment('SHARED_API_ORIGIN');

/// Whether the app runs on the shared server. Overridden in tests.
final sharedModeProvider = Provider<bool>((ref) => kSharedApiOrigin != '');

/// The shared API client; only provided in shared mode.
final sharedClientProvider = Provider<SharedClient>(
  (ref) => throw StateError('Shared client is only available in shared mode.'),
);

/// Routes whose screens read the local database directly. In shared mode
/// they show [SharedModeUnavailableScreen] instead of empty local data.
bool sharedModeBlocks(String location) {
  if (location.startsWith('/admin')) {
    return location != '/admin/dashboard' &&
        !location.startsWith('/admin/profile/preferences');
  }
  return location.startsWith('/patient/timeline/documents') ||
      location.startsWith('/patient/home/vitals') ||
      RegExp(r'^/staff/tasks/[^/]+$').hasMatch(location) ||
      location.startsWith('/staff/schedule/work');
}

const sharedUnavailableRoute = '/shared-unavailable';

/// Server-authoritative policy: the principal is the signed-in shared
/// session; the server re-authorizes every request and revocation surfaces
/// as 401/403 from it, never as a local database lookup.
class SharedAccessPolicy extends AccessPolicy {
  SharedAccessPolicy(AppDatabase db, this._auth, this._client)
    : super(db, _auth);

  final AuthContext _auth;
  final SharedClient _client;

  @override
  Future<Principal?> principal() async => _auth.principal;

  @override
  Future<AccessSnapshot> authorizationSnapshot() async {
    final p = _auth.principal;
    if (p == null) throw const SessionExpiredFailure();
    return AccessSnapshot(
      sessionId: p.sessionId,
      patients: const {},
      permissions: p.permissions,
      manageProxies: const {},
      credentials: const {},
    );
  }

  @override
  Stream<AccessSnapshot> watchAuthorization() =>
      const Stream<AccessSnapshot>.empty();

  @override
  Future<Set<String>?> clinicallyVisiblePatientIds() async {
    final rows =
        (await _client.request('/api/patients', query: {'query': ''})) as List;
    return {
      for (final r in rows.cast<Map<String, dynamic>>()) r['id'] as String,
    };
  }
}

/// Provider overrides that put the whole app on the shared server.
List<Override> sharedModeOverrides(
  SharedClient client, {
  AppDatabase Function()? openScratch,
}) => [
  sharedModeProvider.overrideWithValue(true),
  sharedClientProvider.overrideWithValue(client),
  appModeProvider.overrideWithValue(AppMode.production),
  // A separate scratch store, never seeded: nothing local can pass as
  // clinic data.
  appDatabaseProvider.overrideWith((ref) {
    final db =
        openScratch?.call() ??
        // ignore: invalid_use_of_visible_for_testing_member
        AppDatabase.named('myhealth_shared_scratch');
    ref.onDispose(db.close);
    return db;
  }),
  appBootstrapProvider.overrideWith((ref) async {}),
  accessPolicyProvider.overrideWith(
    (ref) => SharedAccessPolicy(
      ref.watch(appDatabaseProvider),
      ref.watch(authContextProvider),
      client,
    ),
  ),
  staffAuthorizationProvider.overrideWith(
    (ref) => const Stream<AccessSnapshot>.empty(),
  ),
  authRepositoryProvider.overrideWith(
    (ref) => RemoteAuthRepository(client, ref.watch(authContextProvider)),
  ),
  userRepositoryProvider.overrideWithValue(RemoteUserRepository(client)),
  patientRepositoryProvider.overrideWithValue(RemotePatientRepository(client)),
  departmentRepositoryProvider.overrideWithValue(
    RemoteDepartmentRepository(client),
  ),
  appointmentRepositoryProvider.overrideWithValue(
    RemoteAppointmentRepository(client),
  ),
  encounterDraftRepositoryProvider.overrideWithValue(
    RemoteEncounterDraftRepository(client),
  ),
  encounterRepositoryProvider.overrideWithValue(
    RemoteEncounterRepository(client),
  ),
  careMessageRepositoryProvider.overrideWithValue(
    RemoteCareMessageRepository(client),
  ),
  billingRepositoryProvider.overrideWithValue(RemoteBillingRepository(client)),
  taskRepositoryProvider.overrideWithValue(RemoteTaskRepository(client)),
  medicationRepositoryProvider.overrideWithValue(
    RemoteMedicationRepository(client),
  ),
  dentalChartRepositoryProvider.overrideWithValue(
    RemoteDentalChartRepository(client),
  ),
  pharmacyRepositoryProvider.overrideWithValue(
    RemotePharmacyRepository(client),
  ),
  // No server adapter yet: visible failures, never local data.
  recordActivityRepositoryProvider.overrideWithValue(
    UnavailableRecordActivityRepository(),
  ),
  scopedGrantRepositoryProvider.overrideWithValue(
    UnavailableScopedGrantRepository(),
  ),
  documentPolicyRepositoryProvider.overrideWithValue(
    UnavailableDocumentPolicyRepository(),
  ),
  documentServiceProvider.overrideWithValue(UnavailableDocumentService()),
  familyLinkRepositoryProvider.overrideWithValue(
    UnavailableFamilyLinkRepository(),
  ),
  sickLeaveRepositoryProvider.overrideWithValue(
    UnavailableSickLeaveRepository(),
  ),
  homeVisitRepositoryProvider.overrideWithValue(
    UnavailableHomeVisitRepository(),
  ),
  walkInTicketRepositoryProvider.overrideWithValue(
    UnavailableWalkInTicketRepository(),
  ),
  documentVerificationRepositoryProvider.overrideWithValue(
    UnavailableDocumentVerificationRepository(),
  ),
  exportRepositoryProvider.overrideWithValue(UnavailableExportRepository()),
  resultReviewRepositoryProvider.overrideWithValue(
    UnavailableResultReviewRepository(),
  ),
  referralRequestRepositoryProvider.overrideWithValue(
    UnavailableReferralRequestRepository(),
  ),
  notificationRepositoryProvider.overrideWithValue(
    UnavailableNotificationRepository(),
  ),
  recordRepositoryProvider.overrideWithValue(UnavailableRecordRepository()),
  vitalsRepositoryProvider.overrideWithValue(UnavailableVitalsRepository()),
  riskRepositoryProvider.overrideWithValue(UnavailableRiskRepository()),
  aiSummaryRepositoryProvider.overrideWithValue(
    UnavailableAiSummaryRepository(),
  ),
  auditRepositoryProvider.overrideWithValue(UnavailableAuditRepository()),
  settingsRepositoryProvider.overrideWithValue(UnavailableSettingsRepository()),
  feedbackRepositoryProvider.overrideWithValue(UnavailableFeedbackRepository()),
  aiUsageRepositoryProvider.overrideWithValue(UnavailableAiUsageRepository()),
  careTeamRepositoryProvider.overrideWithValue(UnavailableCareTeamRepository()),
  staffCredentialRepositoryProvider.overrideWithValue(
    UnavailableStaffCredentialRepository(),
  ),
];

/// Shown instead of a screen that has no server adapter yet.
class SharedModeUnavailableScreen extends StatelessWidget {
  const SharedModeUnavailableScreen({this.from, super.key});

  final String? from;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return AppScaffold(
      title: ar ? 'غير متاح في الوضع المشترك' : 'Not available in shared mode',
      children: [
        PatientStateView(
          kind: PatientStateKind.unavailable,
          title: ar
              ? 'هذه الشاشة غير متاحة بعد'
              : 'This screen is not available yet',
          message: ar
              ? 'يعمل التطبيق على الخادم المشترك، وهذه الشاشة لا تملك محوّل خادم بعد. لا تُعرض أي بيانات محلية بدلاً منها.'
              : 'The app is running on the shared server and this screen has no server adapter yet. No local data is shown in its place.',
          actionLabel: ar ? 'رجوع' : 'Go back',
          onAction: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ],
    );
  }
}

/// Admin home in shared mode: server health, people and desk billing from
/// the shared API (the local admin workspace reads the device database).
class SharedAdminHomeScreen extends ConsumerStatefulWidget {
  const SharedAdminHomeScreen({super.key});

  @override
  ConsumerState<SharedAdminHomeScreen> createState() => _SharedAdminState();
}

class _SharedAdminState extends ConsumerState<SharedAdminHomeScreen> {
  late final SharedWorkspaceRepository _repo = SharedWorkspaceRepository(
    ref.read(sharedClientProvider),
  );
  late Future<Map<String, dynamic>> _health = _repo.health();
  late Future<List<Map<String, dynamic>>> _people = _repo.people();
  String? _patient;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String en, String a) => ar ? a : en;
    final client = ref.watch(sharedClientProvider);
    return AppScaffold(
      title: tr('Shared server administration', 'إدارة الخادم المشترك'),
      onRefresh: () async => setState(() {
        _health = _repo.health();
        _people = _repo.people();
      }),
      children: [
        InlineBanner.info(
          tr(
            'Running on the shared server. Admin tools that still read the device database are unavailable here.',
            'يعمل على الخادم المشترك. أدوات الإدارة التي تقرأ قاعدة بيانات الجهاز غير متاحة هنا.',
          ),
        ),
        const SizedBox(height: Space.md),
        FutureBuilder<Map<String, dynamic>>(
          future: _health,
          builder: (context, snap) {
            if (snap.hasError) return Text('${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            final h = snap.data!;
            return SurfaceCard(
              child: Text(
                '${tr('Storage', 'التخزين')}: ${h['storage']} · Schema ${h['schema']}\n'
                '${tr('Payments', 'المدفوعات')}: ${h['payments']} · '
                '${tr('Pending delivery', 'تسليم معلق')}: ${h['pendingDelivery']}',
              ),
            );
          },
        ),
        const SizedBox(height: Space.md),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _people,
          builder: (context, snap) {
            if (snap.hasError) return Text('${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            final people = snap.data!;
            final patients = [
              for (final p in people)
                if (p['role'] == 'patient') p,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('People', 'الأشخاص'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final p in people)
                  ListTile(
                    dense: true,
                    title: Text('${p['fullName']}'),
                    subtitle: Text([p['role'], ?p['job']].join(' · ')),
                  ),
                const SizedBox(height: Space.md),
                DropdownButtonFormField<String>(
                  initialValue: _patient,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr('Billing for patient', 'فواتير المريض'),
                  ),
                  items: [
                    for (final p in patients)
                      DropdownMenuItem(
                        value: p['id'] as String,
                        child: Text('${p['fullName']}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _patient = v),
                ),
                if (_patient != null)
                  SharedBillingView(
                    repository: _repo,
                    user: client.user!,
                    patient: _patient,
                    tr: tr,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: Space.sm),
        Text(
          '${tr('Signed in', 'تسجيل الدخول')}: ${client.user?['email'] ?? ''} · ${fmtDate(DateTime.now())}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// When the server ends the session (401/expiry), end the app's session too.
void bindSharedSession(ProviderContainer container) {
  final client = container.read(sharedClientProvider);
  client.sessions.listen((session) {
    if (session == null) container.read(authContextProvider).clear();
  });
}

/// The admin home: the local workspace, or the shared-server admin home.
class AdminHomeSwitch extends ConsumerWidget {
  const AdminHomeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(sharedModeProvider)
      ? const SharedAdminHomeScreen()
      : const AdminDashboardScreen();
}
