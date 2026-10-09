import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/document_verification_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/documents/proposed_policies.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/identity.dart';
import 'package:myhealthcare/domain/identity/operational_roles.dart';
import 'package:myhealthcare/domain/identity/permissions.dart';
import 'package:myhealthcare/domain/repositories/document_service.dart';
import 'package:myhealthcare/domain/repositories/export_repository.dart';
import 'package:myhealthcare/features/auth/application/session.dart';

import '../support/sessions.dart';

T value<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

Future<AppointmentRow> visit(AppDatabase db) =>
    (db.select(db.appointments)
          ..where((a) => a.staffId.equals('staff_01'))
          ..limit(1))
        .getSingle();

Future<void> grantRow(
  AppDatabase db,
  String account,
  Permission permission, {
  String? patient,
  String? department,
  DateTime? expires,
}) => db
    .into(db.scopedGrants)
    .insert(
      ScopedGrantsCompanion.insert(
        id: '$account-${permission.name}-${patient ?? department ?? 'clinic'}',
        accountId: account,
        permission: permission.name,
        scope: patient != null
            ? 'patient'
            : department != null
            ? 'department'
            : 'clinic',
        scopeId: patient ?? department ?? '',
        grantedBy: 'admin_01',
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: Value(expires),
        reason: 'Test grant',
      ),
    );

Future<void> qualify(
  AppDatabase db,
  AppointmentRow a, {
  String account = 'admin_01',
}) async {
  if (account == 'admin_01') {
    await db
        .into(db.staffProfiles)
        .insert(
          StaffProfilesCompanion.insert(
            userId: account,
            jobTitle: const Value('Consultant'),
          ),
        );
    await db
        .into(db.careTeamAssignments)
        .insert(
          CareTeamAssignmentsCompanion.insert(
            id: 'admin-care',
            patientId: a.patientId,
            staffId: account,
            role: CareTeamRole.primaryClinician,
            assignedAt: DateTime.now(),
          ),
        );
  }
  await db
      .into(db.staffCredentials)
      .insert(
        StaffCredentialsCompanion.insert(
          id: 'licence-$account',
          staffId: account,
          kind: CredentialKind.medicalLicense,
          identifier: 'MED-123',
          recordedAt: DateTime.now(),
          verifiedAt: Value(DateTime.now()),
        ),
      );
}

Future<String> issued(
  AppDatabase db,
  AppointmentRow a, {
  String id = 'issued-1',
  String? previous,
  int number = 1,
}) async {
  const template = 'sick-leave-v1-en-employer';
  if (number == 1) {
    await db
        .into(db.documentRequests)
        .insert(
          DocumentRequestsCompanion.insert(
            id: 'request-1',
            patientId: a.patientId,
            appointmentId: Value(a.id),
            templateId: template,
            requestedBy: 'admin_01',
            status: const Value('approved'),
            contentJson: '{}',
            idempotencyKey: 'request-key',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }
  await db
      .into(db.issuedDocumentVersions)
      .insert(
        IssuedDocumentVersionsCompanion.insert(
          id: id,
          requestId: 'request-1',
          patientId: a.patientId,
          templateId: template,
          version: number,
          documentType: ExportDocument.sickLeaveCertificate.name,
          language: 'en',
          disclosureProfile: 'employer',
          patientSnapshotJson: jsonEncode({
            'id': a.patientId,
            'name': 'Frozen patient',
          }),
          issuerSnapshotJson: jsonEncode({
            'accountId': 'admin_01',
            'name': 'Frozen doctor',
            'licence': 'MED-123',
          }),
          contentJson: '{"leaveStart":"2026-10-01","leaveEnd":"2026-10-02"}',
          templateSnapshotJson: '{"version":1}',
          issuerAccountId: 'admin_01',
          supersedesId: Value(previous),
          idempotencyKey: 'issue-$number',
          issuedAt: DateTime.now(),
        ),
      );
  return id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'presets never grant clinical signing; proposed external copies omit diagnosis',
    () {
      for (final permissions in OperationalRoles.permissions.values) {
        expect(permissions, isNot(contains(Permission.signClinicalDocument)));
      }
      final drafts = ProposedDocumentPolicies.sickLeave();
      expect(drafts, hasLength(6));
      for (final draft in drafts.where(
        (d) => d.disclosure != DisclosureProfile.clinic,
      )) {
        expect(draft.wording, isNot(contains('{diagnosis}')));
        expect(draft.wording, contains('{verificationCode}'));
        expect(draft.clinicalSignatureRequired, isTrue);
      }
      expect(
        RolePermissions.admin,
        isNot(contains(Permission.signClinicalDocument)),
      );
    },
  );

  test(
    'grant management validates scope/recipient and rolls back audit failures',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final repo = c.read(scopedGrantRepositoryProvider);
      expect(
        (await repo.grant(
          accountId: 'patient_003',
          permission: Permission.prepareDocument,
          scope: GrantScope.clinic,
          scopeId: '',
          reason: 'Invalid target',
        )).isErr,
        isTrue,
      );
      expect(
        (await repo.grant(
          accountId: 'staff_01',
          permission: Permission.signEncounter,
          scope: GrantScope.clinic,
          scopeId: '',
          reason: 'Invalid permission',
        )).isErr,
        isTrue,
      );
      final grant = value(
        await repo.grant(
          accountId: 'staff_01',
          permission: Permission.prepareDocument,
          scope: GrantScope.patient,
          scopeId: 'patient_003',
          reason: 'Document desk coverage',
        ),
      );
      expect(
        (await db.select(db.auditLog).get()).any(
          (a) => a.action == 'grant.create' && a.entityId == grant.id,
        ),
        isTrue,
      );
      final before = (await db.select(db.scopedGrants).get()).length;
      await db.customStatement(
        "CREATE TRIGGER fail_grant_audit BEFORE INSERT ON audit_log WHEN NEW.action = 'grant.create' BEGIN SELECT RAISE(ABORT,'injected audit failure'); END",
      );
      expect(
        (await repo.grant(
          accountId: 'staff_01',
          permission: Permission.reprintApprovedDocument,
          scope: GrantScope.clinic,
          scopeId: '',
          reason: 'Test rollback',
        )).isErr,
        isTrue,
      );
      expect(await db.select(db.scopedGrants).get(), hasLength(before));
      await signInAs(c, 'staff1@myhealth.demo');
      expect(
        (await repo.revoke(grant.id, reason: 'Unauthorized')).failureOrNull,
        isA<AccessDeniedFailure>(),
      );
    },
  );

  test(
    'scopes use actual visit departments and reject other patients, expired grants and mismatches',
    () async {
      final (c, db) = await seededContainer();
      final a = await visit(db);
      await grantRow(
        db,
        'staff_01',
        Permission.prepareDocument,
        patient: a.patientId,
      );
      await grantRow(
        db,
        'staff_01',
        Permission.reprintApprovedDocument,
        department: a.departmentId!,
      );
      await grantRow(
        db,
        'staff_01',
        Permission.revokeDocument,
        expires: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      await signInAs(c, 'staff1@myhealth.demo');
      final access = c.read(accessPolicyProvider);
      await access.requireScoped(
        Permission.prepareDocument,
        patientId: a.patientId,
      );
      await access.requireScoped(
        Permission.reprintApprovedDocument,
        patientId: a.patientId,
        appointmentId: a.id,
      );
      await expectLater(
        access.requireScoped(
          Permission.prepareDocument,
          patientId: 'unrelated',
        ),
        throwsA(isA<AccessDeniedFailure>()),
      );
      await expectLater(
        access.requireScoped(
          Permission.reprintApprovedDocument,
          patientId: 'patient_wrong',
          appointmentId: a.id,
        ),
        throwsA(isA<AccessDeniedFailure>()),
      );
      await expectLater(
        access.requireScoped(
          Permission.reprintApprovedDocument,
          patientId: a.patientId,
        ),
        throwsA(isA<AccessDeniedFailure>()),
      );
      await expectLater(
        access.requireScoped(Permission.revokeDocument, patientId: a.patientId),
        throwsA(isA<AccessDeniedFailure>()),
      );
    },
  );

  test(
    'administrator signing needs grant, verified medical credential and care relationship',
    () async {
      final (c, db) = await seededContainer();
      final a = await visit(db);
      await signInAs(c, 'admin@myhealth.demo');
      final access = c.read(accessPolicyProvider);
      Future<void> sign() async {
        await access.requireClinicalDocumentSigner(
          patientId: a.patientId,
          appointmentId: a.id,
        );
      }

      await expectLater(sign(), throwsA(isA<AccessDeniedFailure>()));
      await grantRow(
        db,
        'admin_01',
        Permission.signClinicalDocument,
        patient: a.patientId,
      );
      await expectLater(sign(), throwsA(isA<AccessDeniedFailure>()));
      await qualify(db, a);
      await sign();
      await (db.update(db.staffProfiles)
            ..where((s) => s.userId.equals('admin_01')))
          .write(const StaffProfilesCompanion(jobTitle: Value('Nurse')));
      await expectLater(sign(), throwsA(isA<AuthFailure>()));
    },
  );

  test(
    'draft policy blocks binding; approved snapshots stay immutable and verification redacts clinical content',
    () async {
      final (c, db) = await seededContainer();
      final a = await visit(db);
      await grantRow(db, 'admin_01', Permission.signClinicalDocument);
      await grantRow(db, 'admin_01', Permission.manageDocumentTemplates);
      await grantRow(db, 'admin_01', Permission.revokeDocument);
      await qualify(db, a);
      await signInAs(c, 'admin@myhealth.demo');
      final repo = c.read(documentVerificationRepositoryProvider);
      final id = await issued(db, a);
      expect(
        (await repo.bindIssuedVersion(id)).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(await db.select(db.documentVerifications).get(), isEmpty);
      final policies = c.read(documentPolicyRepositoryProvider);
      value(
        await policies.approve(
          'sick-leave-v1-en-employer',
          expectedDraft: ProposedDocumentPolicies.sickLeave().firstWhere(
            (d) => d.id == 'sick-leave-v1-en-employer',
          ),
        ),
      );
      final code = value(await repo.bindIssuedVersion(id));
      expect(value(await repo.bindIssuedVersion(id)), code);
      expect(await db.select(db.documentVerifications).get(), hasLength(1));
      final result = value(await repo.verify(code))!;
      expect(result.validity, DocumentValidity.valid);
      expect(result.patientName, 'Frozen patient');
      expect(result.summary, isEmpty);
      expect(result.issuer, 'Frozen doctor');
      expect(
        (await policies.saveDraft(
          ProposedDocumentPolicies.sickLeave().firstWhere(
            (d) => d.id == 'sick-leave-v1-en-employer',
          ),
        )).failureOrNull,
        isA<ConflictFailure>(),
      );
      await expectLater(
        db.customStatement(
          "UPDATE document_templates SET wording='tampered' WHERE id='sick-leave-v1-en-employer'",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          "UPDATE issued_document_versions SET content_json='tampered' WHERE id='issued-1'",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          "UPDATE document_verifications SET summary='tampered' WHERE issued_version_id='issued-1'",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          "DELETE FROM issued_document_versions WHERE id='issued-1'",
        ),
        throwsA(anything),
      );
      await (db.update(db.users)..where((u) => u.id.equals(a.patientId))).write(
        const UsersCompanion(fullName: Value('Changed patient name')),
      );
      expect(value(await repo.verify(code))!.patientName, 'Frozen patient');
      final second = await issued(
        db,
        a,
        id: 'issued-2',
        previous: id,
        number: 2,
      );
      final nextCode = value(await repo.bindIssuedVersion(second));
      expect(nextCode, isNot(code));
      expect(
        value(await repo.verify(code))!.validity,
        DocumentValidity.superseded,
      );
      value(
        await repo.revokeIssuedVersion(second, reason: 'Incorrect leave dates'),
      );
      value(await repo.revokeIssuedVersion(second, reason: 'Retry'));
      expect(
        value(await repo.verify(nextCode))!.validity,
        DocumentValidity.revoked,
      );
      expect(
        (await db.select(db.auditLog).get()).where(
          (e) => e.action == 'document.revoke',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'scoped grant revocation immediately locks an open staff session',
    () async {
      final (c, db) = await seededContainer();
      await grantRow(db, 'staff_01', Permission.prepareDocument);
      await signInAs(c, 'staff1@myhealth.demo');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final locked = Completer<void>();
      final sub = c.listen(sessionProvider, (_, next) {
        if (!next.isAuthenticated && !locked.isCompleted) locked.complete();
      });
      addTearDown(sub.close);
      await (db.update(db.scopedGrants)
            ..where((g) => g.accountId.equals('staff_01')))
          .write(ScopedGrantsCompanion(revokedAt: Value(DateTime.now())));
      await locked.future.timeout(const Duration(seconds: 8));
      expect(c.read(authContextProvider).principal, isNull);
    },
  );

  test(
    'scoped grant expiry locks an open session without a database update',
    () async {
      final (c, db) = await seededContainer();
      await grantRow(
        db,
        'staff_01',
        Permission.prepareDocument,
        expires: DateTime.now().add(const Duration(seconds: 2)),
      );
      await signInAs(c, 'staff1@myhealth.demo');
      final locked = Completer<void>();
      final sub = c.listen(sessionProvider, (_, next) {
        if (!next.isAuthenticated && !locked.isCompleted) locked.complete();
      });
      addTearDown(sub.close);
      await locked.future.timeout(const Duration(seconds: 8));
      expect(c.read(authContextProvider).principal, isNull);
    },
  );

  test('administrator clinical care reduction locks the session', () async {
    final (c, db) = await seededContainer();
    final a = await visit(db);
    await qualify(db, a);
    await grantRow(db, 'admin_01', Permission.signClinicalDocument);
    await signInAs(c, 'admin@myhealth.demo');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final locked = Completer<void>();
    final sub = c.listen(sessionProvider, (_, next) {
      if (!next.isAuthenticated && !locked.isCompleted) locked.complete();
    });
    addTearDown(sub.close);
    await (db.update(db.careTeamAssignments)
          ..where((a) => a.id.equals('admin-care')))
        .write(CareTeamAssignmentsCompanion(endedAt: Value(DateTime.now())));
    await locked.future.timeout(const Duration(seconds: 8));
    expect(c.read(authContextProvider).principal, isNull);
  });

  test(
    'real schema 29 migration preserves codes, tasks, signed records and originals; reopen and backup work',
    () async {
      final temp = await Directory.systemTemp.createTemp('shared-foundation-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}/schema29.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());
      await Seeder(db).run();
      final existingVisit = await visit(db);
      await db
          .into(db.staffTasks)
          .insert(
            StaffTasksCompanion.insert(
              id: 'preserved-task',
              staffId: 'staff_01',
              patientId: Value(existingVisit.patientId),
              title: 'Completed work',
              kind: TaskKind.followUpDue,
              status: const Value(TaskStatus.done),
              dueAt: Value(DateTime(2020)),
              aiRationale: const Value('Preserved rationale'),
              aiPriorityScore: const Value(0.8),
            ),
          );
      if ((await db.select(db.signedNotes).get()).isEmpty) {
        await db
            .into(db.signedNotes)
            .insert(
              SignedNotesCompanion.insert(
                id: 'preserved-note',
                appointmentId: existingVisit.id,
                patientId: existingVisit.patientId,
                authorStaffId: 'staff_01',
                body: 'Signed original content',
              ),
            );
      }
      final record = await (db.select(db.medicalRecords)..limit(1)).getSingle();
      final originalBytes = Uint8List.fromList('%PDF-1.4 fixture'.codeUnits);
      await db
          .into(db.documentFiles)
          .insert(
            DocumentFilesCompanion.insert(
              id: 'original-file',
              recordId: record.id,
              fileName: 'original.pdf',
              mimeType: 'application/pdf',
              sizeBytes: originalBytes.length,
              sha256: 'fixture-fingerprint',
              bytes: originalBytes,
              storedAt: DateTime.now(),
            ),
          );
      final code = value(
        await DocumentVerificationRepositoryImpl(db).issue(
          document: ExportDocument.sickLeaveCertificate,
          entityId: 'old-leave',
          patientId: 'patient_003',
          issuer: 'Legacy doctor',
          summary: ['Legacy contents'],
        ),
      );
      final tasks = await db
          .customSelect('SELECT * FROM staff_tasks ORDER BY id')
          .get();
      final signed = await db
          .customSelect('SELECT * FROM signed_notes ORDER BY id')
          .get();
      final originals = await db
          .customSelect('SELECT * FROM document_files ORDER BY record_id')
          .get();
      // Reconstruct the actual old verification shape, rather than only
      // lowering user_version on a database that already has new columns.
      for (final trigger in [
        'trg_bound_verification_no_content_update',
        'trg_bound_verification_no_delete',
      ]) {
        await db.customStatement('DROP TRIGGER IF EXISTS $trigger');
      }
      await db.customStatement(
        'ALTER TABLE document_verifications RENAME TO verification_new',
      );
      await db.customStatement(
        'CREATE TABLE document_verifications (code TEXT NOT NULL PRIMARY KEY,document_type TEXT NOT NULL,entity_id TEXT NOT NULL,patient_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,issuer TEXT NOT NULL,summary TEXT NOT NULL,issued_at INTEGER NOT NULL,UNIQUE(document_type,entity_id))',
      );
      await db.customStatement(
        'INSERT INTO document_verifications SELECT code,document_type,entity_id,patient_id,issuer,summary,issued_at FROM verification_new',
      );
      await db.customStatement('DROP TABLE verification_new');
      for (final table in [
        'document_delivery_events',
        'document_artifacts',
        'issued_document_versions',
        'document_requests',
        'document_templates',
        'scoped_grants',
        'task_history',
        'task_sources',
      ]) {
        await db.customStatement('DROP TABLE $table');
      }
      await db.customStatement('PRAGMA user_version = 29');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect(
        await db
            .customSelect('PRAGMA user_version')
            .getSingle()
            .then((r) => r.read<int>('user_version')),
        31,
      );
      expect(
        (await db.customSelect('SELECT * FROM staff_tasks ORDER BY id').get())
            .map((r) => r.data),
        tasks.map((r) => r.data),
      );
      expect(
        (await db.customSelect('SELECT * FROM signed_notes ORDER BY id').get())
            .map((r) => r.data),
        signed.map((r) => r.data),
      );
      expect(
        (await db
                .customSelect('SELECT * FROM document_files ORDER BY record_id')
                .get())
            .map((r) => r.data),
        originals.map((r) => r.data),
      );
      expect(await db.select(db.taskSources).get(), hasLength(tasks.length));
      expect(
        await db.select(db.documentTemplates).get(),
        hasLength(ProposedDocumentPolicies.all().length),
      );
      expect(
        (await db.select(db.documentTemplates).get()).every(
          (t) => t.approvedAt == null,
        ),
        isTrue,
      );
      final legacy = value(
        await DocumentVerificationRepositoryImpl(db).verify(code),
      )!;
      expect(legacy.validity, DocumentValidity.legacy);
      expect(legacy.summary, ['Legacy contents']);
      final a = await visit(db);
      await issued(db, a);
      await db
          .into(db.documentArtifacts)
          .insert(
            DocumentArtifactsCompanion.insert(
              issuedVersionId: 'issued-1',
              status: const Value('ready'),
              bytes: Value(originalBytes),
              sha256: const Value('fixture-fingerprint'),
              renderedAt: Value(DateTime.now()),
            ),
          );
      await db
          .into(db.documentDeliveryEvents)
          .insert(
            DocumentDeliveryEventsCompanion.insert(
              id: 'delivery-1',
              issuedVersionId: 'issued-1',
              recipientAccountId: a.patientId,
              channel: 'inApp',
              createdAt: DateTime.now(),
            ),
          );
      await grantRow(
        db,
        'staff_01',
        Permission.prepareDocument,
        patient: a.patientId,
      );
      await db
          .into(db.taskHistory)
          .insert(
            TaskHistoryCompanion.insert(
              id: 'task-history',
              taskId: tasks.first.read<String>('id'),
              action: 'legacyOutcome',
              beforeJson: '{}',
              afterJson: '{}',
              outcome: const Value('Retained outcome'),
              at: DateTime.now(),
            ),
          );
      await db.close();
      final backup = await file.copy('${temp.path}/backup.sqlite');
      db = AppDatabase(NativeDatabase(backup));
      expect(
        value(
          await DocumentVerificationRepositoryImpl(db).verify(code),
        )!.issuer,
        'Legacy doctor',
      );
      expect(
        (await db.select(db.issuedDocumentVersions).get())
            .single
            .patientSnapshotJson,
        contains('Frozen patient'),
      );
      expect(
        (await db.select(db.documentArtifacts).get()).single.bytes,
        originalBytes,
      );
      expect(
        (await db.select(db.documentDeliveryEvents).get()).single.status,
        'pending',
      );
      expect(
        (await db.select(db.scopedGrants).get()).single.accountId,
        'staff_01',
      );
      expect(
        (await db.select(db.taskHistory).get()).single.outcome,
        'Retained outcome',
      );
      await expectLater(
        db.customStatement(
          "UPDATE document_artifacts SET bytes=X'00' WHERE issued_version_id='issued-1'",
        ),
        throwsA(anything),
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );
}
