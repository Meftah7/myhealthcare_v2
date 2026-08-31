/// Dependency-injection registry (P0-07, P1-18).
///
/// Cross-cutting singletons: platform services, the database, and every
/// repository. Feature-specific providers live with their feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/repositories/ai_summary_repository_impl.dart';
import '../data/repositories/appointment_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/patient_repository_impl.dart';
import '../data/repositories/record_repository_impl.dart';
import '../data/repositories/system_repository_impl.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/seed/seeder.dart';
import '../domain/repositories/repositories.dart';
import '../services/ai/ai_key_store.dart';
import '../services/auth/password_hasher.dart';
import '../services/notifications/reminder_scheduler.dart';

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

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(ref.watch(appDatabaseProvider)),
);

// --- Repositories (P1-18) -------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(appDatabaseProvider),
    hasher: ref.watch(passwordHasherProvider),
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    ref.watch(appDatabaseProvider),
    hasher: ref.watch(passwordHasherProvider),
  ),
);

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => PatientRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final departmentRepositoryProvider = Provider<DepartmentRepository>(
  (ref) => DepartmentRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final recordRepositoryProvider = Provider<RecordRepository>(
  (ref) => RecordRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final vitalsRepositoryProvider = Provider<VitalsRepository>(
  (ref) => VitalsRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final riskRepositoryProvider = Provider<RiskRepository>(
  (ref) => RiskRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final aiSummaryRepositoryProvider = Provider<AiSummaryRepository>(
  (ref) => AiSummaryRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final seederProvider = Provider<Seeder>(
  (ref) => Seeder(ref.watch(appDatabaseProvider)),
);
