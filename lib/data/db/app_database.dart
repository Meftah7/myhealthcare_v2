/// The app's Drift database — schema assembly, versioning, migrations and the
/// platform-aware connection (P1-06).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../domain/enums.dart';
import 'converters.dart';
import 'tables/ai.dart';
import 'tables/appointments.dart';
import 'tables/records.dart';
import 'tables/system.dart';
import 'tables/users.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // identity + org
    Departments,
    Users,
    PatientProfiles,
    StaffProfiles,
    // scheduling
    ScheduleTemplates,
    Appointments,
    Reminders,
    // clinical content
    MedicalRecords,
    LabValues,
    Vitals,
    Medications,
    // AI
    AiSummaries,
    StaffTasks,
    RiskFlags,
    // system
    AuditLog,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: _dbName, web: _webOptions));

  /// Opens a database under an arbitrary [name] on the same platform paths —
  /// used by tests that need an isolated file (and by re-open persistence
  /// checks). Never call from app code.
  @visibleForTesting
  AppDatabase.named(String name)
    : super(driftDatabase(name: name, web: _webOptions));

  static const _dbName = 'myhealthcare';

  /// Web needs sqlite3 compiled to WASM plus a worker for OPFS-backed storage.
  /// Both files are served from web/ (P0-11). On native platforms this is
  /// ignored.
  static final _webOptions = DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Referential integrity is off by default in SQLite.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
