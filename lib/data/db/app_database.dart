/// The app's Drift database — schema assembly, versioning, migrations and the
/// platform-aware connection (P1-06).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/family_member.dart';
import '../../domain/enums.dart';
import 'converters.dart';
import 'tables/ai.dart';
import 'tables/appointments.dart';
import 'tables/billing.dart';
import 'tables/notifications.dart';
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
    // billing
    Invoices,
    PaymentMethods,
    // engagement
    Notifications,
    // system
    AuditLog,
    AppSettings,
    Feedbacks,
    AiUsageLog,
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
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Default LLM provider changed from Anthropic to Gemini (free tier).
        await customStatement(
          "UPDATE app_settings SET model_id = 'gemini-2.0-flash' "
          "WHERE model_id = 'claude-sonnet-5'",
        );
      }
      if (from < 3) {
        // Patient dashboard rebuild: ticket tag + room number, assigned once
        // at booking time (redesign v2).
        await m.addColumn(appointments, appointments.ticketTag);
        await m.addColumn(appointments, appointments.roomNumber);
      }
      if (from < 4) {
        // Patient dashboard rebuild: Family Network (redesign v2).
        await m.addColumn(patientProfiles, patientProfiles.familyMembers);
      }
      if (from < 5) {
        // Billing: patient invoices.
        await m.createTable(invoices);
      }
      if (from < 6) {
        // Notifications centre.
        await m.createTable(notifications);
      }
      if (from < 7) {
        // Wallet: saved cards.
        await m.createTable(paymentMethods);
      }
      if (from < 8) {
        // Staff dashboard rebuild: live presence status.
        await m.addColumn(staffProfiles, staffProfiles.presence);
      }
      if (from < 9) {
        // Admin dashboard Tier B: feedback inbox + AI usage log.
        await m.createTable(feedbacks);
        await m.createTable(aiUsageLog);
      }
      if (from < 10) {
        // Book an appointment for a linked family member.
        await m.addColumn(appointments, appointments.bookedForName);
      }
    },
    beforeOpen: (details) async {
      // Referential integrity is off by default in SQLite.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
