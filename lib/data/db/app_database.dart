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
import 'tables/care.dart';
import 'tables/family.dart';
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
    PasswordResetRequests,
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
    WalletTransactions,
    // family network
    FamilyLinks,
    // engagement
    Notifications,
    // care services (P10 Batch B)
    SickLeaveCertificates,
    CareMessages,
    HomeVisitRequests,
    // consultation flow + admin referral outcomes
    WalkInTickets,
    ReferralRequests,
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
  int get schemaVersion => 17;

  /// True when [table] already has a column named [columnName] — lets a
  /// migration step that already partly ran (e.g. the app/tab was closed or
  /// crashed mid-upgrade, so the schema changed but [schemaVersion] was never
  /// recorded) skip work it already did instead of failing on "duplicate
  /// column"/"table already exists" and leaving the database permanently
  /// stuck retrying the same broken step forever.
  Future<bool> _hasColumn(
    TableInfo<Table, dynamic> table,
    String columnName,
  ) async {
    final rows = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    return rows.any((r) => r.read<String>('name') == columnName);
  }

  Future<bool> _hasTable(TableInfo<Table, dynamic> table) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(table.actualTableName)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn column,
  ) async {
    if (!await _hasColumn(table, column.name)) {
      await m.addColumn(table, column);
    }
  }

  Future<void> _createTableIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
  ) async {
    if (!await _hasTable(table)) {
      await m.createTable(table);
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // The whole upgrade runs as one transaction: if any step throws (a
    // browser tab closed mid-migration, a transient storage error), SQLite
    // rolls every statement in it back together, so the schema and the
    // recorded [schemaVersion] never disagree with each other. Combined with
    // the per-step guards below, a database that somehow still got stuck
    // partway through (e.g. from before this fix) can self-heal on its next
    // open instead of failing the same "duplicate column" error forever.
    onUpgrade: (m, from, to) => m.database.transaction(() async {
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
        await _addColumnIfMissing(m, appointments, appointments.ticketTag);
        await _addColumnIfMissing(m, appointments, appointments.roomNumber);
      }
      if (from < 4) {
        // Patient dashboard rebuild: Family Network (redesign v2).
        await _addColumnIfMissing(
          m,
          patientProfiles,
          patientProfiles.familyMembers,
        );
      }
      if (from < 5) {
        // Billing: patient invoices.
        await _createTableIfMissing(m, invoices);
      }
      if (from < 6) {
        // Notifications centre.
        await _createTableIfMissing(m, notifications);
      }
      if (from < 7) {
        // Wallet: saved cards.
        await _createTableIfMissing(m, paymentMethods);
      }
      if (from < 8) {
        // Staff dashboard rebuild: live presence status.
        await _addColumnIfMissing(m, staffProfiles, staffProfiles.presence);
      }
      if (from < 9) {
        // Admin dashboard Tier B: feedback inbox + AI usage log.
        await _createTableIfMissing(m, feedbacks);
        await _createTableIfMissing(m, aiUsageLog);
      }
      if (from < 10) {
        // Book an appointment for a linked family member.
        await _addColumnIfMissing(m, appointments, appointments.bookedForName);
      }
      if (from < 11) {
        // Care services: sick-leave notes, patient<->doctor messages, home
        // visits (P10 Batch B).
        await _createTableIfMissing(m, sickLeaveCertificates);
        await _createTableIfMissing(m, careMessages);
        await _createTableIfMissing(m, homeVisitRequests);
      }
      if (from < 12) {
        // Consultation flow: call/arrive timestamps + closing note on a visit,
        // the visit link on records/prescriptions, the department walk-in
        // queue, and the doctor→admin referral request.
        await _addColumnIfMissing(m, appointments, appointments.calledInAt);
        await _addColumnIfMissing(m, appointments, appointments.outcomeNote);
        await _addColumnIfMissing(
          m,
          medicalRecords,
          medicalRecords.appointmentId,
        );
        await _addColumnIfMissing(m, medications, medications.appointmentId);
        await _createTableIfMissing(m, walkInTickets);
        await _createTableIfMissing(m, referralRequests);
      }
      if (from < 13) {
        // Wallet: a real credit balance (top-up + redemption ledger),
        // replacing the old cards-only "Wallet" page. Billing + Wallet merge
        // into one Payments screen.
        await _createTableIfMissing(m, walletTransactions);
      }
      if (from < 14) {
        // Family Network: link two real patient accounts, with a
        // view-only/manage permission the owner must accept.
        await _createTableIfMissing(m, familyLinks);
      }
      if (from < 15) {
        // Patient-imported records are flagged so they never pass as a
        // clinician-reviewed result.
        await _addColumnIfMissing(
          m,
          medicalRecords,
          medicalRecords.uploadedByPatient,
        );
      }
      if (from < 16) {
        // Login throttling (consecutive-failure counter + lockout) and the
        // admin-queued password-reset request flow.
        await _addColumnIfMissing(m, users, users.failedLoginAttempts);
        await _addColumnIfMissing(m, users, users.lockedUntil);
        await _createTableIfMissing(m, passwordResetRequests);
        // A partial index — SQLite allows many NULL national IDs but not two
        // accounts sharing the same non-null one.
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_national_id '
          'ON users (national_id) WHERE national_id IS NOT NULL',
        );
      }
      if (from < 17) {
        // Clinic opening schedule moves from per-device SharedPreferences
        // into the shared settings row.
        await _addColumnIfMissing(m, appSettings, appSettings.clinicOpenDays);
        await _addColumnIfMissing(m, appSettings, appSettings.clinicOpenHour);
        await _addColumnIfMissing(m, appSettings, appSettings.clinicCloseHour);
      }
    }),
    beforeOpen: (details) async {
      // Referential integrity is off by default in SQLite.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
