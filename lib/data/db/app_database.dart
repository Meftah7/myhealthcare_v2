/// The app's Drift database — schema assembly, versioning, migrations and the
/// platform-aware connection (P1-06).
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import '../../core/app_environment.dart';
import '../../domain/documents/proposed_policies.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/entities/medication.dart';
import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../domain/risk_sources.dart';
import '../../services/crypto/device_key_store.dart';
import 'converters.dart';
import 'demo_snapshot.dart';
import 'tables/ai.dart';
import 'tables/appointments.dart';
import 'tables/billing.dart';
import 'tables/care.dart';
import 'tables/document_workflow.dart';
import 'tables/family.dart';
import 'tables/identity.dart';
import 'tables/notifications.dart';
import 'tables/records.dart';
import 'tables/sync.dart';
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
    AccountRecoveryTokens,
    CareTeamAssignments,
    StaffCredentials,
    // scheduling
    ScheduleTemplates,
    AvailabilityExceptions,
    Appointments,
    Reminders,
    // clinical content
    MedicalRecords,
    LabValues,
    ResultReviews,
    Vitals,
    Medications,
    EncounterDrafts,
    SignedNotes,
    SignedNoteAmendments,
    DocumentFiles,
    RecordReads,
    RecordCorrections,
    DocumentVerifications,
    ScopedGrants,
    DocumentTemplates,
    DocumentRequests,
    IssuedDocumentVersions,
    DocumentArtifacts,
    DocumentDeliveryEvents,
    TaskSources,
    TaskHistory,
    // AI
    AiSummaries,
    StaffTasks,
    RiskFlags,
    RiskSourceAliases,
    // billing
    Invoices,
    PaymentMethods,
    WalletTransactions,
    PaymentTransactions,
    SimulatedGatewayCharges,
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
    // mutation safety (Phase 2)
    IdempotencyRecords,
    OutboxEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openEncrypted());

  /// Opens a database under an arbitrary [name] on the same platform paths —
  /// used by tests that need an isolated file (and by re-open persistence
  /// checks). Never call from app code.
  @visibleForTesting
  AppDatabase.named(String name)
    : super(driftDatabase(name: name, web: _webOptions));

  /// Native: SQLite3MultipleCiphers (ChaCha20-Poly1305) keyed from platform
  /// secure storage (SEC-XCUT-02). A database left in plaintext by an older
  /// build is encrypted in place on first open. Web has no keystore, so its
  /// OPFS database stays unencrypted (SEC-XCUT-03).
  static QueryExecutor _openEncrypted() {
    if (kIsWeb) {
      return driftDatabase(
        name: _dbName,
        web: configuredAppMode.isDemo ? _demoWebOptions : _webOptions,
      );
    }
    return LazyDatabase(() async {
      final key = DeviceKeyStore.toHex(
        await DeviceKeyStore().keyFor(DeviceKeyStore.databaseKey),
      );
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}${Platform.pathSeparator}$_dbName.sqlite';
      final plaintext = await _isPlaintextSqlite(path);
      return driftDatabase(
        name: _dbName,
        web: _webOptions,
        native: DriftNativeOptions(
          databasePath: () async => path,
          setup: _keySetup(key, encryptExisting: plaintext),
        ),
      );
    });
  }

  /// Built outside any instance so the closure sent to drift's background
  /// isolate captures only the key and flag.
  static void Function(CommonDatabase) _keySetup(
    String hexKey, {
    required bool encryptExisting,
  }) {
    return (db) {
      if (encryptExisting) {
        db.execute("PRAGMA hexrekey = '$hexKey'");
      } else {
        db.execute("PRAGMA hexkey = '$hexKey'");
      }
      // Fails fast with "file is not a database" on a wrong key.
      db.select('SELECT count(*) FROM sqlite_master');
    };
  }

  /// An unencrypted SQLite file starts with this 16-byte header; an
  /// encrypted one does not.
  static Future<bool> _isPlaintextSqlite(String path) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    final raf = await file.open();
    try {
      final head = await raf.read(16);
      return String.fromCharCodes(head) == 'SQLite format 3\u0000';
    } finally {
      await raf.close();
    }
  }

  static const _dbName = 'myhealthcare';

  /// Web needs sqlite3 compiled to WASM plus a worker for OPFS-backed storage.
  /// Both files are served from web/ (P0-11). On native platforms this is
  /// ignored.
  static final _webOptions = DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  );

  /// Demo web builds start a brand-new browser database from the shipped
  /// pre-seeded snapshot (see demo_snapshot.dart). Drift calls this only
  /// when no database exists yet.
  static final _demoWebOptions = DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
    initializeDatabase: loadDemoSnapshot,
  );

  @override
  int get schemaVersion => 30;

  /// Preserve legacy flag/task IDs by aliasing only sources known when the
  /// old flag was last detected. Later readings/reports get their own work.
  Future<void> backfillRiskSourceAliases() async {
    final flags = await select(riskFlags).get();
    for (final flag in flags) {
      final prefix = '${flag.patientId}:';
      if (!flag.dedupeKey.startsWith(prefix) ||
          flag.dedupeKey.contains(':source:')) {
        continue;
      }
      final rule = flag.dedupeKey.substring(prefix.length);
      final sources = <String>[];
      if (rule.startsWith('vitals:')) {
        final rows =
            await (select(vitals)..where(
                  (v) =>
                      v.patientId.equals(flag.patientId) &
                      v.recordedAt.isSmallerOrEqualValue(flag.detectedAt),
                ))
                .get();
        sources.addAll(rows.map((v) => v.id));
      } else if (rule == 'lab:critical' || rule == 'followup:overdue') {
        final rows =
            await (select(medicalRecords)..where(
                  (r) =>
                      r.patientId.equals(flag.patientId) &
                      r.createdAt.isSmallerOrEqualValue(flag.detectedAt) &
                      r.occurredAt.isSmallerOrEqualValue(flag.detectedAt),
                ))
                .get();
        sources.addAll(rows.map((r) => r.id));
      } else if (rule.startsWith('medgap:')) {
        final condition = rule.substring('medgap:'.length);
        final rows =
            await (select(medications)..where(
                  (m) =>
                      m.patientId.equals(flag.patientId) &
                      m.startDate.isSmallerOrEqualValue(flag.detectedAt) &
                      (m.endDate.isNull() |
                          m.endDate.isSmallerOrEqualValue(flag.detectedAt)),
                ))
                .get();
        sources.add(
          RiskSources.medicationCourse(
            condition,
            rows.map(
              (m) => Medication(
                id: m.id,
                patientId: m.patientId,
                name: m.name,
                startDate: m.startDate,
                endDate: m.endDate,
                isActive: m.isActive,
              ),
            ),
          ),
        );
      }
      for (final source in sources) {
        await into(riskSourceAliases).insert(
          RiskSourceAliasesCompanion.insert(
            sourceKey: RiskSources.key(flag.dedupeKey, source),
            canonicalKey: flag.dedupeKey,
            patientId: flag.patientId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

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

  /// Opens a result review for every lab result that needs one and has
  /// none: abnormal, critical or unjudgeable values. Results filed since
  /// [recentSince] (default: the last 14 days) open with their author (or
  /// unassigned); older ones are recorded as reviewed when filed. Idempotent; used by the v25 migration and the
  /// demo seeder.
  Future<void> backfillResultReviews({DateTime? recentSince}) async {
    final since =
        recentSince ?? DateTime.now().subtract(const Duration(days: 14));
    final recent = since.millisecondsSinceEpoch ~/ 1000;
    await customStatement(
      'INSERT INTO result_reviews (id, record_id, owner_staff_id, due_at, '
      'priority, status, resolved_at, resolution_note, created_at, version) '
      "SELECT 'rrv_' || r.id, r.id, r.author_staff_id, "
      'r.created_at + CASE WHEN EXISTS (SELECT 1 FROM lab_values l '
      "WHERE l.record_id = r.id AND l.abnormal_flag = 'critical') "
      'THEN 3600 ELSE 86400 END, '
      'CASE WHEN EXISTS (SELECT 1 FROM lab_values l WHERE l.record_id = r.id '
      "AND l.abnormal_flag = 'critical') THEN 'urgent' "
      'WHEN EXISTS (SELECT 1 FROM lab_values l WHERE l.record_id = r.id '
      "AND l.abnormal_flag IN ('low', 'high')) THEN 'priority' "
      "ELSE 'routine' END, "
      'CASE WHEN r.created_at < $recent '
      "THEN 'resolved' WHEN r.author_staff_id IS NULL THEN 'unassigned' "
      "ELSE 'assigned' END, "
      'CASE WHEN r.created_at < $recent THEN r.created_at END, '
      'CASE WHEN r.created_at < $recent '
      "THEN 'Filed before review tracking' END, "
      'r.created_at, 1 '
      'FROM medical_records r '
      "WHERE r.record_type = 'labResult' "
      'AND EXISTS (SELECT 1 FROM lab_values l WHERE l.record_id = r.id '
      "AND l.abnormal_flag <> 'normal') "
      'AND NOT EXISTS (SELECT 1 FROM result_reviews v '
      'WHERE v.record_id = r.id)',
    );
  }

  /// Tables whose rows can be edited concurrently, with their key column.
  static const _versionedTables = {
    'appointments': 'id',
    'walk_in_tickets': 'id',
    'referral_requests': 'id',
    'home_visit_requests': 'id',
    'invoices': 'id',
    'patient_profiles': 'user_id',
    'staff_tasks': 'id',
    'result_reviews': 'id',
    'document_requests': 'id',
  };

  /// Rules the database itself enforces, whatever code writes to it:
  ///
  /// * every update to a versioned row bumps `version`, so optimistic
  ///   concurrency can't be bypassed by a write path that forgets;
  /// * the audit log is append-only — no update, no delete;
  /// * an outbox event delivers at most one notification.
  ///
  /// Idempotent (`IF NOT EXISTS`); run on create and on upgrade.
  Future<void> installIntegrityRules() async {
    for (final MapEntry(key: table, value: pk) in _versionedTables.entries) {
      // An older migration step runs this before later tables exist.
      if (!await _hasTableNamed(table)) continue;
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_${table}_version '
        'AFTER UPDATE ON $table FOR EACH ROW '
        'WHEN NEW.version = OLD.version BEGIN '
        'UPDATE $table SET version = OLD.version + 1 WHERE $pk = NEW.$pk; '
        'END',
      );
    }
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS trg_audit_log_no_update '
      'BEFORE UPDATE ON audit_log BEGIN '
      "SELECT RAISE(ABORT, 'audit_log is append-only'); END",
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS $auditNoDeleteTrigger '
      'BEFORE DELETE ON audit_log BEGIN '
      "SELECT RAISE(ABORT, 'audit_log is append-only'); END",
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_source_event '
      'ON notifications (source_event_id) WHERE source_event_id IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_outbox_due '
      'ON outbox_events (status, next_attempt_at)',
    );
    await customStatement('DROP INDEX IF EXISTS idx_appointments_ticket_tag');
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_appointments_daily_ticket '
      "ON appointments (date(slot_start, 'unixepoch'), ticket_tag) "
      'WHERE ticket_tag IS NOT NULL',
    );
    if (await _hasTable(signedNotes)) {
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_signed_notes_no_update '
        'BEFORE UPDATE ON signed_notes BEGIN '
        "SELECT RAISE(ABORT, 'signed notes are immutable'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_signed_notes_no_delete '
        'BEFORE DELETE ON signed_notes BEGIN '
        "SELECT RAISE(ABORT, 'signed notes are immutable'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_signed_note_amendments_no_update '
        'BEFORE UPDATE ON signed_note_amendments BEGIN '
        "SELECT RAISE(ABORT, 'signed note amendments are append-only'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_signed_note_amendments_no_delete '
        'BEFORE DELETE ON signed_note_amendments BEGIN '
        "SELECT RAISE(ABORT, 'signed note amendments are append-only'); END",
      );
    }
    await _installPaymentRules();
    for (final table in ['issued_document_versions', 'task_history']) {
      if (!await _hasTableNamed(table)) continue;
      for (final action in ['update', 'delete']) {
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS trg_${table}_no_$action '
          'BEFORE ${action.toUpperCase()} ON $table BEGIN '
          "SELECT RAISE(ABORT, '$table is immutable'); END",
        );
      }
    }
    if (await _hasTableNamed('issued_document_versions')) {
      for (final action in ['update', 'delete']) {
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS trg_issued_sick_leave_no_$action '
          'BEFORE ${action.toUpperCase()} ON sick_leave_certificates '
          'WHEN EXISTS (SELECT 1 FROM issued_document_versions WHERE id = OLD.id) BEGIN '
          "SELECT RAISE(ABORT, 'issued sick leave is immutable'); END",
        );
      }
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_ready_document_artifact_no_delete '
        "BEFORE DELETE ON document_artifacts WHEN OLD.status = 'ready' BEGIN "
        "SELECT RAISE(ABORT, 'ready document artifacts are immutable'); END",
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_verification_issued_version '
        'ON document_verifications (issued_version_id) WHERE issued_version_id IS NOT NULL',
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_approved_template_no_delete '
        'BEFORE DELETE ON document_templates WHEN OLD.approved_at IS NOT NULL BEGIN '
        "SELECT RAISE(ABORT, 'approved templates are immutable'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_verification_validity_transition '
        'BEFORE UPDATE ON document_verifications WHEN OLD.issued_version_id IS NOT NULL AND ('
        "NEW.validity NOT IN ('valid','revoked','superseded') "
        "OR (OLD.validity = 'revoked' AND NEW.validity != 'revoked') "
        "OR (OLD.validity = 'superseded' AND NEW.validity = 'valid')) BEGIN "
        "SELECT RAISE(ABORT, 'invalid document validity transition'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_ready_document_artifact_immutable '
        "BEFORE UPDATE ON document_artifacts WHEN OLD.status = 'ready' AND ("
        'NEW.bytes IS NOT OLD.bytes OR NEW.sha256 IS NOT OLD.sha256 '
        'OR NEW.issued_version_id IS NOT OLD.issued_version_id '
        'OR NEW.status IS NOT OLD.status OR NEW.rendered_at IS NOT OLD.rendered_at) BEGIN '
        "SELECT RAISE(ABORT, 'ready document artifacts are immutable'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_approved_template_no_content_update '
        'BEFORE UPDATE ON document_templates WHEN OLD.approved_at IS NOT NULL AND ('
        'NEW.id IS NOT OLD.id OR NEW.document_type IS NOT OLD.document_type '
        'OR NEW.version IS NOT OLD.version OR NEW.language IS NOT OLD.language '
        'OR NEW.disclosure_profile IS NOT OLD.disclosure_profile '
        'OR NEW.wording IS NOT OLD.wording '
        'OR NEW.clinical_signature_required IS NOT OLD.clinical_signature_required '
        'OR NEW.required_credential IS NOT OLD.required_credential '
        'OR NEW.approved_by IS NOT OLD.approved_by OR NEW.approved_at IS NOT OLD.approved_at) BEGIN '
        "SELECT RAISE(ABORT, 'approved template content is immutable'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_bound_verification_no_content_update '
        'BEFORE UPDATE ON document_verifications '
        'WHEN OLD.issued_version_id IS NOT NULL AND ('
        'NEW.code IS NOT OLD.code OR NEW.document_type IS NOT OLD.document_type '
        'OR NEW.entity_id IS NOT OLD.entity_id OR NEW.patient_id IS NOT OLD.patient_id '
        'OR NEW.issuer IS NOT OLD.issuer OR NEW.summary IS NOT OLD.summary '
        'OR NEW.issued_at IS NOT OLD.issued_at '
        'OR NEW.issued_version_id IS NOT OLD.issued_version_id) BEGIN '
        "SELECT RAISE(ABORT, 'issued verification content is immutable'); END",
      );
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_bound_verification_no_delete '
        'BEFORE DELETE ON document_verifications '
        'WHEN OLD.issued_version_id IS NOT NULL BEGIN '
        "SELECT RAISE(ABORT, 'issued verification is immutable'); END",
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_scoped_grants_account '
        'ON scoped_grants (account_id, permission, scope, scope_id)',
      );
    }
  }

  /// Payments (Phase 5): a transaction row is never deleted and never moves
  /// backwards out of a final state, and an invoice only changes status along
  /// pending → paid → refunded or pending → cancelled — whatever code writes.
  Future<void> _installPaymentRules() async {
    if (!await _hasTable(paymentTransactions)) return;
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS $paymentNoDeleteTrigger '
      'BEFORE DELETE ON payment_transactions BEGIN '
      "SELECT RAISE(ABORT, 'payment transactions are permanent'); END",
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS trg_payment_transactions_final '
      'BEFORE UPDATE OF status ON payment_transactions '
      "WHEN OLD.status IN ('settled', 'failed', 'voided') "
      'AND NEW.status <> OLD.status BEGIN '
      "SELECT RAISE(ABORT, 'a finished payment cannot change status'); END",
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS trg_payment_transactions_amount '
      'BEFORE UPDATE OF amount, kind, invoice_id, patient_id '
      'ON payment_transactions BEGIN '
      "SELECT RAISE(ABORT, 'a payment cannot be re-targeted'); END",
    );
    // At most one charge per invoice may be in flight or settled.
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_one_live_charge '
      'ON payment_transactions (invoice_id) '
      "WHERE kind = 'invoiceCharge' "
      "AND status IN ('initiated', 'authorized', 'settled')",
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS trg_invoices_status_transition '
      'BEFORE UPDATE OF status ON invoices '
      'WHEN NEW.status <> OLD.status AND NOT ('
      "(OLD.status = 'pending' AND NEW.status IN ('paid', 'cancelled')) OR "
      "(OLD.status = 'paid' AND NEW.status = 'refunded')) BEGIN "
      "SELECT RAISE(ABORT, 'invalid invoice status change'); END",
    );
  }

  /// Name of the trigger that blocks payment deletes. Only the demo seeder's
  /// full dataset reset lifts it, and reinstalls it straight after.
  static const paymentNoDeleteTrigger = 'trg_payment_transactions_no_delete';

  /// Triggers that block deleting signed notes and amendments; lifted only by
  /// the demo seeder's full reset.
  static const signedNoteDeleteTriggers = [
    'trg_signed_notes_no_delete',
    'trg_signed_note_amendments_no_delete',
    'trg_issued_document_versions_no_delete',
    'trg_task_history_no_delete',
    'trg_bound_verification_no_delete',
    'trg_approved_template_no_delete',
    'trg_issued_sick_leave_no_delete',
    'trg_ready_document_artifact_no_delete',
  ];

  /// Name of the trigger that blocks audit deletes. Only the demo seeder's
  /// full dataset reset lifts it, and reinstalls it straight after.
  static const auditNoDeleteTrigger = 'trg_audit_log_no_delete';

  Future<void> installProposedDocumentPolicies() async {
    for (final draft in ProposedDocumentPolicies.all()) {
      await into(documentTemplates).insert(
        DocumentTemplatesCompanion.insert(
          id: draft.id,
          documentType: draft.document.name,
          version: draft.version,
          language: draft.language,
          disclosureProfile: draft.disclosure.name,
          wording: draft.wording,
          clinicalSignatureRequired: draft.clinicalSignatureRequired,
          requiredCredential: Value(
            draft.clinicalSignatureRequired ? 'medicalLicense' : null,
          ),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  Future<bool> _hasTable(TableInfo<Table, dynamic> table) =>
      _hasTableNamed(table.actualTableName);

  Future<bool> _hasTableNamed(String name) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
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
    onCreate: (m) async {
      await m.createAll();
      await installProposedDocumentPolicies();
      await installIntegrityRules();
    },
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
      if (from < 18) {
        // Identity + authorization (Phase 1): dependents without a login,
        // verified self-service recovery, care-team assignments, staff
        // credentials, and the acting account on patient-facing rows.
        await _addColumnIfMissing(m, users, users.hasLogin);
        await _createTableIfMissing(m, accountRecoveryTokens);
        await _createTableIfMissing(m, careTeamAssignments);
        await _createTableIfMissing(m, staffCredentials);
        await _addColumnIfMissing(
          m,
          appointments,
          appointments.bookedByAccountId,
        );
        await _addColumnIfMissing(
          m,
          medicalRecords,
          medicalRecords.createdByAccountId,
        );
        await _addColumnIfMissing(m, invoices, invoices.paidByAccountId);
        await _addColumnIfMissing(
          m,
          walletTransactions,
          walletTransactions.actorAccountId,
        );
        await _addColumnIfMissing(
          m,
          careMessages,
          careMessages.senderAccountId,
        );
        await _addColumnIfMissing(
          m,
          homeVisitRequests,
          homeVisitRequests.requestedByAccountId,
        );
        await _addColumnIfMissing(m, auditLog, auditLog.subjectPatientId);
        // Licence numbers already on staff profiles become credentials.
        await customStatement(
          'INSERT OR IGNORE INTO staff_credentials '
          '(id, staff_id, kind, identifier, recorded_at) '
          "SELECT 'cred_' || user_id, user_id, 'medicalLicense', license_no, "
          "CAST(strftime('%s', 'now') AS INTEGER) "
          'FROM staff_profiles WHERE license_no IS NOT NULL',
        );
      }
      if (from < 19) {
        // Authoritative data (Phase 2): optimistic-concurrency versions,
        // idempotent mutations, the outbox, delivery dedupe, and an
        // append-only audit log. Existing rows start at version 1.
        for (final (table, column)
            in <(TableInfo<Table, dynamic>, GeneratedColumn)>[
              (appointments, appointments.version),
              (walkInTickets, walkInTickets.version),
              (referralRequests, referralRequests.version),
              (homeVisitRequests, homeVisitRequests.version),
              (invoices, invoices.version),
              (patientProfiles, patientProfiles.version),
              (staffTasks, staffTasks.version),
            ]) {
          await _addColumnIfMissing(m, table, column);
        }
        await _addColumnIfMissing(
          m,
          notifications,
          notifications.sourceEventId,
        );
        await _createTableIfMissing(m, idempotencyRecords);
        await _createTableIfMissing(m, outboxEvents);
        await installIntegrityRules();
      }
      if (from < 20) {
        // Profile photo (merged from the avatar-photo branch): a local file
        // path, null for the monogram fallback.
        await _addColumnIfMissing(m, users, users.avatarPath);
      }
      if (from < 21) {
        await _addColumnIfMissing(m, reminders, reminders.deliveryStatus);
        await _addColumnIfMissing(m, reminders, reminders.deliveryAttempts);
        await _addColumnIfMissing(m, reminders, reminders.lastError);
      }
      if (from < 22) {
        await _createTableIfMissing(m, availabilityExceptions);
      }
      if (from < 23) {
        await _createTableIfMissing(m, encounterDrafts);
        await _createTableIfMissing(m, signedNotes);
        await _createTableIfMissing(m, signedNoteAmendments);
      }
      if (from < 24) {
        // Billing, documents and delivery (Phase 5): a payment ledger with a
        // simulated provider behind it, import provenance and the original
        // file, and reminder retry timing.
        await _createTableIfMissing(m, paymentTransactions);
        await _createTableIfMissing(m, simulatedGatewayCharges);
        await _createTableIfMissing(m, documentFiles);
        await _addColumnIfMissing(
          m,
          medicalRecords,
          medicalRecords.reviewStatus,
        );
        await _addColumnIfMissing(
          m,
          medicalRecords,
          medicalRecords.reviewedByStaffId,
        );
        await _addColumnIfMissing(m, medicalRecords, medicalRecords.reviewedAt);
        await _addColumnIfMissing(m, medicalRecords, medicalRecords.reviewNote);
        await _addColumnIfMissing(m, reminders, reminders.nextAttemptAt);
        // Imports made before review tracking have never been reviewed.
        await customStatement(
          "UPDATE medical_records SET review_status = 'pendingReview' "
          'WHERE uploaded_by_patient = 1',
        );
        // Invoices paid before the ledger existed get a settled transaction,
        // so every paid invoice has payment history behind it.
        await customStatement(
          'INSERT OR IGNORE INTO payment_transactions '
          '(id, patient_id, invoice_id, kind, method, status, amount, '
          'provider, request_reference, provider_reference, '
          'method_descriptor, created_at, updated_at, settled_at) '
          "SELECT 'ptx_legacy_' || id, patient_id, id, 'invoiceCharge', "
          "CASE WHEN payment_method = 'Wallet balance' THEN 'wallet' "
          "ELSE 'card' END, 'settled', total_amount, "
          "CASE WHEN payment_method = 'Wallet balance' THEN 'wallet' "
          "ELSE 'legacy' END, 'legacy_' || id, NULL, payment_method, "
          'COALESCE(paid_at, issued_at), COALESCE(paid_at, issued_at), '
          'COALESCE(paid_at, issued_at) '
          "FROM invoices WHERE status = 'paid'",
        );
        await installIntegrityRules();
      }
      if (from < 25) {
        for (final (table, column)
            in <(TableInfo<Table, dynamic>, GeneratedColumn)>[
              (labValues, labValues.source),
              (labValues, labValues.provenance),
              (labValues, labValues.verificationStatus),
              (labValues, labValues.verifiedByStaffId),
              (labValues, labValues.verifiedAt),
              (careMessages, careMessages.queueOwnerStaffId),
              (careMessages, careMessages.coverageStaffId),
              (careMessages, careMessages.responseDueAt),
              (referralRequests, referralRequests.ownerStaffId),
              (referralRequests, referralRequests.coverageStaffId),
              (referralRequests, referralRequests.dueAt),
              (referralRequests, referralRequests.priority),
              (referralRequests, referralRequests.handoverNote),
              (staffTasks, staffTasks.priority),
              (staffTasks, staffTasks.coverageStaffId),
              (staffTasks, staffTasks.escalatedAt),
            ]) {
          await _addColumnIfMissing(m, table, column);
        }
        await _createTableIfMissing(m, resultReviews);
        for (final column in <GeneratedColumn>[
          resultReviews.resolvedByStaffId,
          resultReviews.resolutionNote,
          resultReviews.createdAt,
        ]) {
          await _addColumnIfMissing(m, resultReviews, column);
        }
        // Results already on file that were abnormal or had no range get an
        // owned review: recent ones open with their author, older ones are
        // recorded as reviewed at filing so queues aren't flooded with
        // history.
        await backfillResultReviews();
        await installIntegrityRules();
      }
      if (from < 26) {
        await _addColumnIfMissing(m, vitals, vitals.appointmentId);
        // Recover only known demo seed IDs. Never infer links for real
        // unlinked records from matching dates or names.
        final visits =
            await (select(appointments)..where(
                  (a) => a.status.equalsValue(AppointmentStatus.completed),
                ))
                .get();
        for (final visit in visits) {
          final stamp = visit.slotStart.millisecondsSinceEpoch;
          final base = 'rec_${visit.patientId}_$stamp';
          await (update(medicalRecords)..where(
                (r) =>
                    r.id.isIn([base, '${base}_lab', '${base}_img']) &
                    r.patientId.equals(visit.patientId) &
                    r.authorStaffId.equals(visit.staffId) &
                    r.appointmentId.isNull(),
              ))
              .write(MedicalRecordsCompanion(appointmentId: Value(visit.id)));
          await (update(vitals)..where(
                (v) =>
                    v.id.equals('vit_${visit.patientId}_$stamp') &
                    v.patientId.equals(visit.patientId) &
                    v.recordedByStaffId.equals(visit.staffId) &
                    v.appointmentId.isNull(),
              ))
              .write(VitalsCompanion(appointmentId: Value(visit.id)));
        }
      }
      if (from < 27) {
        await _addColumnIfMissing(
          m,
          medicalRecords,
          medicalRecords.referralUrgency,
        );
        await _createTableIfMissing(m, documentVerifications);
      }
      if (from < 28) {
        await _createTableIfMissing(m, riskSourceAliases);
        await backfillRiskSourceAliases();
      }
      if (from < 29) {
        await _createTableIfMissing(m, recordReads);
        await _createTableIfMissing(m, recordCorrections);
      }
      if (from < 30) {
        for (final table in <TableInfo<Table, dynamic>>[
          scopedGrants,
          documentTemplates,
          documentRequests,
          issuedDocumentVersions,
          documentArtifacts,
          documentDeliveryEvents,
          taskSources,
          taskHistory,
        ]) {
          await _createTableIfMissing(m, table);
        }
        await _addColumnIfMissing(
          m,
          documentVerifications,
          documentVerifications.issuedVersionId,
        );
        await _addColumnIfMissing(
          m,
          documentVerifications,
          documentVerifications.validity,
        );
        await _addColumnIfMissing(
          m,
          documentVerifications,
          documentVerifications.revokedAt,
        );
        await _addColumnIfMissing(
          m,
          documentVerifications,
          documentVerifications.revokedBy,
        );
        await _addColumnIfMissing(
          m,
          documentVerifications,
          documentVerifications.revocationReason,
        );
        // Preserve old task IDs/workflow; only record their known identity.
        await customStatement(
          'INSERT OR IGNORE INTO task_sources '
          '(task_id, source_type, source_id, episode_key, recorded_at) '
          "SELECT id, 'legacyTask', id, id, created_at FROM staff_tasks",
        );
        await installProposedDocumentPolicies();
      }
    }),
    beforeOpen: (details) async {
      // Referential integrity is off by default in SQLite.
      await customStatement('PRAGMA foreign_keys = ON');
      await installProposedDocumentPolicies();
      await installIntegrityRules();
    },
  );
}
