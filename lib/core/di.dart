/// Dependency-injection registry (P0-07, P1-18).
///
/// Cross-cutting singletons: platform services, the database, and every
/// repository. Feature-specific providers live with their feature.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/settings/ui_prefs.dart';
import '../data/db/app_database.dart';
import '../data/repositories/ai_summary_repository_impl.dart';
import '../data/repositories/appointment_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/billing_repository_impl.dart';
import '../data/repositories/care_repository_impl.dart';
import '../data/repositories/consultation_repository_impl.dart';
import '../data/repositories/document_policy_repository_impl.dart';
import '../data/repositories/document_verification_repository_impl.dart';
import '../data/repositories/export_repository_impl.dart';
import '../data/repositories/family_link_repository_impl.dart';
import '../data/repositories/identity_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/patient_repository_impl.dart';
import '../data/repositories/record_activity_repository_impl.dart';
import '../data/repositories/record_repository_impl.dart';
import '../data/repositories/result_review_repository_impl.dart';
import '../data/repositories/scoped_grant_repository_impl.dart';
import '../data/repositories/system_repository_impl.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/seed/seeder.dart';
import '../data/sync/outbox.dart';
import '../domain/repositories/document_policy_repository.dart';
import '../domain/repositories/document_verification_repository.dart';
import '../domain/repositories/record_activity_repository.dart';
import '../domain/repositories/repositories.dart';
import '../domain/repositories/scoped_grant_repository.dart';
import '../services/ai/ai_key_store.dart';
import '../services/auth/access_policy.dart';
import '../services/auth/auth_context.dart';
import '../services/auth/password_hasher.dart';
import '../services/auth/recovery_delivery.dart';
import '../services/notifications/device_notifier.dart';
import '../services/notifications/reminder_dispatcher.dart';
import '../services/notifications/reminder_scheduler.dart';
import '../services/payments/payment_gateway.dart';
import 'app_environment.dart';
import 'observability/operational_metrics.dart';

/// Build-time runtime boundary. Override in tests where both modes need to be
/// exercised in the same process.
final appModeProvider = Provider<AppMode>((ref) => configuredAppMode);

final operationalMetricsProvider = Provider<OperationalMetrics>((ref) {
  return InMemoryOperationalMetrics();
});

/// Key–value store for lightweight local state (session, settings).
///
/// Overridden in `main()` once [SharedPreferences.getInstance] has completed —
/// reading it before then is a programming error.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// The single app-wide Drift database. Closed when the scope is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final passwordHasherProvider = Provider<PasswordHasher>(
  (ref) => const PasswordHasher(),
);

/// The authenticated principal for this app instance. Set only by a
/// successful sign-in; read by [accessPolicyProvider] on every repository
/// call.
final authContextProvider = Provider<AuthContext>((ref) {
  final context = AuthContext();
  ref.onDispose(context.dispose);
  return context;
});

/// Object-level authorization every repository enforces.
final accessPolicyProvider = Provider<AccessPolicy>(
  (ref) => AccessPolicy(
    ref.watch(appDatabaseProvider),
    ref.watch(authContextProvider),
  ),
);

final recordActivityRepositoryProvider = Provider<RecordActivityRepository>(
  (ref) => RecordActivityRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(accessPolicyProvider),
  ),
);

final scopedGrantRepositoryProvider = Provider<ScopedGrantRepository>(
  (ref) => ScopedGrantRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(accessPolicyProvider),
  ),
);

final documentPolicyRepositoryProvider = Provider<DocumentPolicyRepository>(
  (ref) => DocumentPolicyRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(accessPolicyProvider),
  ),
);

/// Where recovery codes go. Demo builds get a labelled simulated inbox;
/// production has no channel until a provider is configured, so recovery
/// falls back to an administrator-verified request.
final recoveryDeliveryProvider = Provider<RecoveryDelivery>((ref) {
  if (!ref.watch(appModeProvider).isDemo) {
    return const UnavailableRecoveryDelivery();
  }
  final outbox = DemoRecoveryOutbox();
  ref.onDispose(outbox.dispose);
  return outbox;
});

/// Delivers side effects recorded in the outbox. Drained after each
/// mutation that raises one, at start-up, and at sign-in — so anything a
/// previous run failed to deliver is retried without redoing the change.
final outboxDispatcherProvider = Provider<OutboxDispatcher>((ref) {
  // Retries wake themselves up (one timer, only while something is
  // undelivered), so a failure is retried without another user action.
  final metrics = ref.watch(operationalMetricsProvider);
  final dispatcher = OutboxDispatcher(ref.watch(appDatabaseProvider))
    ..autoRetry = true
    ..onFailure = ({required exhausted}) => recordSafely(
      metrics,
      OperationalSignal.deliveryFailed,
      workflow: 'outbox',
      reasonCode: exhausted ? 'exhausted' : 'retrying',
    );
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});

/// Deliver pending side effects now. Never fails the caller: an undelivered
/// event stays queued with its retry time.
Future<void> deliverPendingSideEffects(Ref ref) async {
  try {
    await ref.read(outboxDispatcherProvider).drain();
  } on Object {
    // Recorded on the event; retried on the next drain.
  }
}

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(ref.watch(appDatabaseProvider)),
);

/// Browser alerts on web; none elsewhere (outside the release scope).
final deviceNotifierProvider = Provider<DeviceNotifier>(
  (ref) => platformDeviceNotifier(),
);

/// Delivers due reminders: at start-up (catching up whatever fell due while
/// the app was closed) and on its own timer while the app is open.
final reminderDispatcherProvider = Provider<ReminderDispatcher>((ref) {
  final dispatcher =
      ReminderDispatcher(
          ref.watch(appDatabaseProvider),
          device: ref.watch(deviceNotifierProvider),
        )
        ..autoRetry = true
        ..onDelivered = () => deliverPendingSideEffects(ref);
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});

/// Deliver due reminders now, then their in-app notices. Never fails the
/// caller: each reminder records its own outcome.
Future<void> deliverDueReminders(Ref ref) async {
  try {
    final run = await ref.read(reminderDispatcherProvider).deliverDue();
    final failed = run.failed + run.retrying;
    if (failed > 0) {
      recordSafely(
        ref.read(operationalMetricsProvider),
        OperationalSignal.deliveryFailed,
        workflow: 'reminders',
        count: failed,
      );
    }
  } on Object {
    // Left queued; the dispatcher's timer or the next start retries.
  }
  await deliverPendingSideEffects(ref);
}

// --- Repositories (P1-18) -------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(appDatabaseProvider),
    hasher: ref.watch(passwordHasherProvider),
    context: ref.watch(authContextProvider),
    recovery: ref.watch(recoveryDeliveryProvider),
    allowDemoSignIn: ref.watch(appModeProvider).isDemo,
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    ref.watch(appDatabaseProvider),
    hasher: ref.watch(passwordHasherProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => PatientRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final departmentRepositoryProvider = Provider<DepartmentRepository>(
  (ref) => DepartmentRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

/// The card-payment provider. The prototype ships only the simulated one
/// (release scope: no real payments); the UI labels it as such.
final paymentGatewayProvider = Provider<PaymentGateway>(
  (ref) => SimulatedPaymentGateway(ref.watch(appDatabaseProvider)),
);

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
    gateway: ref.watch(paymentGatewayProvider),
  ),
);

/// Resolve payments a previous run left unconfirmed (app closed or network
/// lost mid-payment) against the provider. A system task at start-up: it
/// never charges, and a failure just leaves them for next time.
Future<void> reconcilePendingPayments(Ref ref) async {
  try {
    final resolved = await BillingRepositoryImpl(
      ref.read(appDatabaseProvider),
      gateway: ref.read(paymentGatewayProvider),
    ).reconcilePending();
    if (resolved > 0) {
      recordSafely(
        ref.read(operationalMetricsProvider),
        OperationalSignal.workResolved,
        workflow: 'payment.reconcile',
        count: resolved,
      );
    }
  } on Object {
    // Still in flight; the payments screen and the next start retry.
  }
}

final familyLinkRepositoryProvider = Provider<FamilyLinkRepository>(
  (ref) => FamilyLinkRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final sickLeaveRepositoryProvider = Provider<SickLeaveRepository>(
  (ref) => SickLeaveRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final careMessageRepositoryProvider = Provider<CareMessageRepository>(
  (ref) => CareMessageRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final homeVisitRepositoryProvider = Provider<HomeVisitRepository>(
  (ref) => HomeVisitRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final walkInTicketRepositoryProvider = Provider<WalkInTicketRepository>(
  (ref) => WalkInTicketRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final encounterDraftRepositoryProvider = Provider<EncounterDraftRepository>(
  (ref) => EncounterDraftRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final encounterRepositoryProvider = Provider<EncounterRepository>(
  (ref) => EncounterRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
    appointments: ref.watch(appointmentRepositoryProvider),
    walkIns: ref.watch(walkInTicketRepositoryProvider),
  ),
);

final documentVerificationRepositoryProvider =
    Provider<DocumentVerificationRepository>(
      (ref) => DocumentVerificationRepositoryImpl(
        ref.watch(appDatabaseProvider),
        access: ref.watch(accessPolicyProvider),
      ),
    );

final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => ExportRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final resultReviewRepositoryProvider = Provider<ResultReviewRepository>(
  (ref) => ResultReviewRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final referralRequestRepositoryProvider = Provider<ReferralRequestRepository>(
  (ref) => ReferralRequestRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final recordRepositoryProvider = Provider<RecordRepository>(
  (ref) => RecordRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final vitalsRepositoryProvider = Provider<VitalsRepository>(
  (ref) => VitalsRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final riskRepositoryProvider = Provider<RiskRepository>(
  (ref) => RiskRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final aiSummaryRepositoryProvider = Provider<AiSummaryRepository>(
  (ref) => AiSummaryRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final aiUsageRepositoryProvider = Provider<AiUsageRepository>(
  (ref) => AiUsageRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final careTeamRepositoryProvider = Provider<CareTeamRepository>(
  (ref) => CareTeamRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final staffCredentialRepositoryProvider = Provider<StaffCredentialRepository>(
  (ref) => StaffCredentialRepositoryImpl(
    ref.watch(appDatabaseProvider),
    access: ref.watch(accessPolicyProvider),
  ),
);

final seederProvider = Provider<Seeder>(
  (ref) => Seeder(
    ref.watch(appDatabaseProvider),
    seedingEnabled: ref.watch(appModeProvider).isDemo,
  ),
);

/// One-time app bootstrap. Demo mode populates its synthetic dataset;
/// production mode only opens/migrates storage and hydrates shared settings.
/// The router holds on the splash while this is still running.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  if (ref.read(appModeProvider).isDemo) {
    await ref.read(seederProvider).run();
  }
  // The clinic schedule is shared data in the database; SharedPreferences
  // only caches it so the first frame has something to show.
  await ref.read(clinicScheduleProvider.notifier).hydrateFromDatabase();
  // Reminders that fell due while the app was closed, then side effects a
  // previous run recorded but never delivered.
  await deliverDueReminders(ref);
  // Payments a previous run sent but never heard back about.
  await reconcilePendingPayments(ref);
  // Visits nobody turned up for. `main()` repeats this every minute.
  await sweepNoShows(ref);
});

/// Marks visits as no-shows 30 minutes after their start when the patient
/// never arrived and nobody marked them. Never fails the caller.
Future<void> sweepNoShows(Ref ref) async {
  try {
    await ref.read(appointmentRepositoryProvider).markOverdueNoShows();
  } on Object {
    // Best effort: the next sweep tries again.
  }
}

/// Repeats [sweepNoShows] every minute while the app runs. Started from
/// `main()` only, so widget tests never inherit a live periodic timer.
final noShowSweepProvider = Provider<void>((ref) {
  final timer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => sweepNoShows(ref),
  );
  ref.onDispose(timer.cancel);
});
