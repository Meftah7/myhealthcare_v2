import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/documents/document_rules.dart';
import 'package:myhealthcare/domain/documents/proposed_policies.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/identity.dart';
import 'package:myhealthcare/domain/identity/permissions.dart';
import 'package:myhealthcare/domain/repositories/document_service.dart';
import 'package:myhealthcare/domain/repositories/export_repository.dart';
import 'package:myhealthcare/services/pdf/issued_sick_leave_pdf.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../support/sessions.dart';

T value<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

class TestRenderer implements IssuedSickLeaveRenderer {
  String? capturedClinic;
  bool fail = false;
  int calls = 0;
  String? wording;
  @override
  Future<Uint8List> render({
    required String wording,
    required String language,
    required String reference,
    required DateTime issuedAt,
    bool draft = false,
    String title = 'Sick leave',
    String clinicName = 'MyHealth Care',
    String? verificationUrl,
  }) async {
    calls++;
    this.wording = wording;
    capturedClinic = clinicName;
    if (fail) throw StateError('Renderer unavailable');
    return Uint8List.fromList('%PDF $wording $reference'.codeUnits);
  }
}

Future<void> grant(
  AppDatabase db,
  String account,
  Permission permission,
) async {
  await db
      .into(db.scopedGrants)
      .insert(
        ScopedGrantsCompanion.insert(
          id: '$account-${permission.name}',
          accountId: account,
          permission: permission.name,
          scope: 'clinic',
          scopeId: '',
          grantedBy: 'admin_01',
          startsAt: DateTime.now().subtract(const Duration(days: 1)),
          reason: 'Test',
        ),
      );
}

Future<AppointmentRow> setup(AppDatabase db, {bool approved = true}) async {
  final visit =
      await (db.select(db.appointments)
            ..where((a) => a.staffId.equals('staff_01'))
            ..limit(1))
          .getSingle();
  await grant(db, 'staff_01', Permission.prepareDocument);
  await grant(db, 'staff_01', Permission.signClinicalDocument);
  await db
      .into(db.staffCredentials)
      .insert(
        StaffCredentialsCompanion.insert(
          id: 'test-license',
          staffId: 'staff_01',
          kind: CredentialKind.medicalLicense,
          identifier: 'MED-123',
          recordedAt: DateTime.now(),
          verifiedAt: Value(DateTime.now()),
        ),
      );
  if (approved) {
    await (db.update(
      db.documentTemplates,
    )..where((t) => t.id.equals('sick-leave-v1-en-employer'))).write(
      DocumentTemplatesCompanion(
        approvedBy: const Value('admin_01'),
        approvedAt: Value(DateTime.now()),
      ),
    );
  }
  return visit;
}

PrepareDocument input(
  AppointmentRow visit, {
  String key = 'prepare',
  Map<String, Object?>? content,
}) => PrepareDocument(
  patientId: visit.patientId,
  appointmentId: visit.id,
  templateId: 'sick-leave-v1-en-employer',
  content: content ?? {'leaveStart': '2026-10-08', 'leaveEnd': '2026-10-10'},
  idempotencyKey: key,
);

Future<DocumentRequest> approved(
  DocumentService service,
  AppointmentRow visit,
) async {
  final draft = value(await service.prepare(input(visit)));
  final submitted = value(
    await service.submit(draft.id, expectedVersion: draft.version),
  );
  return value(
    await service.approve(submitted.id, expectedVersion: submitted.version),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'configured clinic identity and verification origin freeze at issuance',
    () async {
      final renderer = TestRenderer();
      final (c, db) = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(renderer),
        ],
      );
      final visit = await setup(db);
      await db
          .into(db.clinicConfigurations)
          .insert(
            ClinicConfigurationsCompanion.insert(
              id: 'clinic',
              valueJson: jsonEncode({'name': 'Clinic A'}),
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.clinicConfigurations)
          .insert(
            ClinicConfigurationsCompanion.insert(
              id: 'integrations',
              valueJson: jsonEncode({
                'verificationOrigin': 'https://verify.example.test',
              }),
              updatedAt: DateTime.now(),
            ),
          );
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final issued = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'config-frozen',
        ),
      );
      final stored = await (db.select(
        db.issuedDocumentVersions,
      )..where((d) => d.id.equals(issued.id))).getSingle();
      final snapshot =
          jsonDecode(stored.templateSnapshotJson) as Map<String, dynamic>;
      expect(snapshot['clinicName'], 'Clinic A');
      expect(snapshot['externalBase'], 'https://verify.example.test');
      await (db.update(
        db.clinicConfigurations,
      )..where((c) => c.id.equals('clinic'))).write(
        ClinicConfigurationsCompanion(
          valueJson: Value(jsonEncode({'name': 'Clinic B'})),
        ),
      );
      value(await service.render(issued.id));
      expect(renderer.capturedClinic, 'Clinic A');
      expect(
        (await (db.select(
              db.issuedDocumentVersions,
            )..where((d) => d.id.equals(issued.id))).getSingle())
            .templateSnapshotJson,
        stored.templateSnapshotJson,
      );
    },
  );

  test('every proposed bilingual policy satisfies its disclosure rules', () {
    for (final policy in ProposedDocumentPolicies.all()) {
      DocumentRules.validatePolicy(
        policy.document,
        policy.disclosure,
        policy.clinicalSignatureRequired,
        policy.wording,
      );
    }
  });

  for (final type in DocumentRules.supported.where(
    (t) => t != ExportDocument.sickLeaveCertificate,
  )) {
    test(
      '${type.name} approves, freezes, renders and downloads with the correct authority',
      () async {
        final renderer = TestRenderer();
        final (c, db) = await seededContainer(
          overrides: [
            issuedSickLeaveRendererProvider.overrideWithValue(renderer),
          ],
        );
        final visit = await setup(db);
        await (db.update(
          db.appointments,
        )..where((a) => a.id.equals(visit.id))).write(
          const AppointmentsCompanion(
            status: Value(AppointmentStatus.completed),
            outcomeNote: Value('Recorded clinician outcome'),
          ),
        );
        final template = '${type.name}-v1-en-clinic';
        await (db.update(
          db.documentTemplates,
        )..where((t) => t.id.equals(template))).write(
          DocumentTemplatesCompanion(
            approvedBy: const Value('admin_01'),
            approvedAt: Value(DateTime.now()),
          ),
        );
        await grant(db, 'admin_01', Permission.prepareDocument);
        await grant(db, 'admin_01', Permission.issueAdministrativeDocument);
        await grant(db, 'admin_01', Permission.reprintApprovedDocument);
        await grant(db, 'admin_01', Permission.manageDocumentTemplates);
        final content = <String, Object?>{};
        if (type == ExportDocument.fitnessCertificate) {
          content.addAll({
            'activity': 'Work',
            'assessment': 'Fit following assessment',
            'restrictions': 'None recorded',
          });
        }
        if (DocumentRules.sourced(type)) {
          content['sourceId'] = 'source';
          if (type == ExportDocument.financeStatement) {
            await db
                .into(db.invoices)
                .insert(
                  InvoicesCompanion.insert(
                    id: 'source',
                    patientId: visit.patientId,
                    appointmentId: Value(visit.id),
                    subtotal: const Value(10),
                    totalAmount: const Value(11),
                    taxAmount: const Value(1),
                  ),
                );
          } else {
            final recordType = switch (type) {
              ExportDocument.referralLetter => RecordType.referral,
              ExportDocument.prescriptionCopy => RecordType.prescription,
              ExportDocument.releasedLabReport => RecordType.labResult,
              _ => RecordType.imaging,
            };
            await db
                .into(db.medicalRecords)
                .insert(
                  MedicalRecordsCompanion.insert(
                    id: 'source',
                    patientId: visit.patientId,
                    appointmentId: Value(visit.id),
                    authorStaffId: const Value('staff_01'),
                    recordType: recordType,
                    title: 'Reviewed source',
                    body: const Value('Original recorded report'),
                    occurredAt: DateTime.now(),
                  ),
                );
            if (type == ExportDocument.releasedLabReport) {
              await db
                  .into(db.labValues)
                  .insert(
                    LabValuesCompanion.insert(
                      id: 'analyte',
                      recordId: 'source',
                      analyte: 'Potassium',
                      value: 4,
                      verificationStatus: const Value(
                        VerificationStatus.verified,
                      ),
                      verifiedByStaffId: const Value('staff_01'),
                      verifiedAt: Value(DateTime.now()),
                    ),
                  );
            }
          }
        }
        await signInAs(
          c,
          DocumentRules.clinical(type)
              ? 'staff1@myhealth.demo'
              : 'admin@myhealth.demo',
        );
        final service = c.read(documentServiceProvider);
        final prepare = PrepareDocument(
          patientId: visit.patientId,
          appointmentId: visit.id,
          templateId: template,
          content: content,
          documentType: type,
          idempotencyKey: 'generic',
        );
        if (type == ExportDocument.releasedLabReport ||
            type == ExportDocument.releasedImagingReport) {
          expect(await service.prepare(prepare), isA<Err<DocumentRequest>>());
          value(
            await service.releaseSource(
              'source',
              released: true,
              reason: 'Reviewed final result',
            ),
          );
        }
        final draft = value(await service.prepare(prepare));
        final submitted = value(
          await service.submit(draft.id, expectedVersion: draft.version),
        );
        final approval = value(
          await service.approve(
            submitted.id,
            expectedVersion: submitted.version,
          ),
        );
        final issued = value(
          await service.issue(
            approval.id,
            expectedVersion: approval.version,
            idempotencyKey: 'generic-issue',
          ),
        );
        expect(issued.documentType, type);
        value(await service.render(issued.id));
        final bytes = value(await service.download(issued.id));
        expect(bytes, isNotEmpty);
        expect(
          await (db.select(
            db.sickLeaveCertificates,
          )..where((r) => r.id.equals(issued.id))).get(),
          isEmpty,
        );
        if (DocumentRules.sourced(type) &&
            type != ExportDocument.financeStatement) {
          await (db.update(
            db.medicalRecords,
          )..where((r) => r.id.equals('source'))).write(
            const MedicalRecordsCompanion(body: Value('Later amendment')),
          );
          expect(value(await service.download(issued.id)), bytes);
          if (type == ExportDocument.releasedLabReport ||
              type == ExportDocument.releasedImagingReport) {
            expect(
              await service.prepare(
                PrepareDocument(
                  patientId: visit.patientId,
                  appointmentId: visit.id,
                  templateId: template,
                  content: content,
                  documentType: type,
                  idempotencyKey: 'amended-source',
                ),
              ),
              isA<Err<DocumentRequest>>(),
            );
            await grant(db, 'staff_01', Permission.revokeDocument);
            value(
              await service.releaseSource(
                'source',
                released: false,
                reason: 'Corrected result pending review',
              ),
            );
            expect(await service.download(issued.id), isA<Err<Uint8List>>());
          }
        }
        if (type == ExportDocument.financeStatement) {
          await signInAs(c, 'staff1@myhealth.demo');
          expect(await service.download(issued.id), isA<Err<Uint8List>>());
          expect(await service.prepare(prepare), isA<Err<DocumentRequest>>());
        }
        await signInAs(c, 'admin@myhealth.demo');
        final manifest =
            jsonDecode(
                  utf8.decode(
                    value(await service.exportVerificationManifest()),
                  ),
                )
                as Map;
        final entry = (manifest['entries'] as List).single as Map;
        expect(entry.keys.toSet(), {
          'token',
          'documentType',
          'issuedAt',
          'validity',
          'sha256',
        });
        expect(entry['token'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
        expect(entry['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
        final email = (await (db.select(
          db.users,
        )..where((u) => u.id.equals(visit.patientId))).getSingle()).email;
        await signInAs(c, email);
        if (type == ExportDocument.releasedLabReport ||
            type == ExportDocument.releasedImagingReport) {
          expect(entry['validity'], 'revoked');
          expect(await service.download(issued.id), isA<Err<Uint8List>>());
        } else {
          expect(value(await service.download(issued.id)), bytes);
        }
        expect(
          await service.exportVerificationManifest(),
          isA<Err<Uint8List>>(),
        );
      },
    );
  }

  test('source amendments after approval require a fresh approval', () async {
    final (c, db) = await seededContainer();
    final visit = await setup(db);
    await (db.update(
      db.appointments,
    )..where((a) => a.id.equals(visit.id))).write(
      const AppointmentsCompanion(
        status: Value(AppointmentStatus.completed),
        outcomeNote: Value('First outcome'),
      ),
    );
    await (db.update(
      db.documentTemplates,
    )..where((t) => t.id.equals('visitSummary-v1-en-clinic'))).write(
      DocumentTemplatesCompanion(
        approvedBy: const Value('admin_01'),
        approvedAt: Value(DateTime.now()),
      ),
    );
    await signInAs(c, 'staff1@myhealth.demo');
    final service = c.read(documentServiceProvider);
    final draft = value(
      await service.prepare(
        PrepareDocument(
          patientId: visit.patientId,
          appointmentId: visit.id,
          templateId: 'visitSummary-v1-en-clinic',
          content: const {},
          documentType: ExportDocument.visitSummary,
          idempotencyKey: 'summary',
        ),
      ),
    );
    final submitted = value(
      await service.submit(draft.id, expectedVersion: draft.version),
    );
    final approval = value(
      await service.approve(submitted.id, expectedVersion: submitted.version),
    );
    await (db.update(
      db.appointments,
    )..where((a) => a.id.equals(visit.id))).write(
      const AppointmentsCompanion(outcomeNote: Value('Amended outcome')),
    );
    expect(
      await service.issue(
        approval.id,
        expectedVersion: approval.version,
        idempotencyKey: 'changed',
      ),
      isA<Err<IssuedDocument>>(),
    );
    expect(await db.select(db.issuedDocumentVersions).get(), isEmpty);
  });

  test(
    'issuance commits once, rendering retries, patient gets frozen bytes and admin reprints',
    () async {
      final renderer = TestRenderer()..fail = true;
      final (c, db) = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(renderer),
        ],
      );
      final visit = await setup(db);
      await grant(db, 'admin_01', Permission.reprintApprovedDocument);
      await grant(db, 'admin_01', Permission.prepareDocument);
      await signInAs(c, 'admin@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final draft = value(await service.prepare(input(visit)));
      final submitted = value(
        await service.submit(draft.id, expectedVersion: draft.version),
      );
      expect(
        value(await service.workspace(visit.patientId)).templates
            .where((t) => DocumentRules.clinical(t.documentType))
            .every((t) => t.disclosure != DisclosureProfile.clinic),
        isTrue,
      );
      await signInAs(c, 'staff1@myhealth.demo');
      final request = value(
        await service.approve(submitted.id, expectedVersion: submitted.version),
      );
      final results = await Future.wait([
        service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'issue',
        ),
        service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'issue',
        ),
      ]);
      final first = value(results.first);
      expect(value(results.last).id, first.id);
      expect(first.renderStatus, DocumentRenderStatus.pending);
      expect(
        (await db.select(db.sickLeaveCertificates).get()).where(
          (r) => r.id == first.id,
        ),
        hasLength(1),
      );
      final retry = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'issue',
        ),
      );
      expect(retry.id, first.id);
      expect(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'new-key',
        ),
        isA<Err<IssuedDocument>>(),
      );
      expect(await service.download(first.id), isA<Err<Uint8List>>());
      expect(await service.render(first.id), isA<Err<IssuedDocument>>());
      expect(
        (await db.select(db.documentArtifacts).get()).single.status,
        'failed',
      );
      expect(
        (await db.select(db.documentDeliveryEvents).get()).single.status,
        'pending',
      );
      renderer.fail = false;
      expect(
        value(await service.render(first.id)).renderStatus,
        DocumentRenderStatus.ready,
      );
      final bytes = value(await service.download(first.id));
      await (db.update(db.users)..where((u) => u.id.equals(visit.patientId)))
          .write(const UsersCompanion(fullName: Value('Changed patient name')));
      await (db.update(db.users)..where((u) => u.id.equals('staff_01'))).write(
        const UsersCompanion(fullName: Value('Changed doctor name')),
      );
      expect(value(await service.download(first.id)), bytes);
      value(await service.render(first.id));
      expect(renderer.calls, 2);
      expect(
        (await db.select(db.documentDeliveryEvents).get()).single.attempt,
        1,
      );
      final notices = await (db.select(
        db.notifications,
      )..where((n) => n.sourceEventId.isNotNull())).get();
      expect(notices, hasLength(1));
      expect(notices.single.deepLink, contains('/patient/timeline/documents'));
      final email = (await (db.select(
        db.users,
      )..where((u) => u.id.equals(visit.patientId))).getSingle()).email;
      await signInAs(c, email);
      expect(value(await service.download(first.id)), bytes);
      await signInAs(c, 'admin@myhealth.demo');
      expect(value(await service.download(first.id)), bytes);
      expect(await db.select(db.issuedDocumentVersions).get(), hasLength(1));
    },
  );

  test(
    'draft policy, dates, disclosure and optimistic version are enforced',
    () async {
      final (c, db) = await seededContainer();
      final visit = await setup(db, approved: false);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      expect(
        await service.prepare(
          input(
            visit,
            content: {'leaveStart': '2026-10-10', 'leaveEnd': '2026-10-08'},
          ),
        ),
        isA<Err<DocumentRequest>>(),
      );
      expect(
        await service.prepare(
          input(
            visit,
            content: {
              'leaveStart': '2026-10-08',
              'leaveEnd': '2026-10-10',
              'diagnosis': 'Secret',
            },
          ),
        ),
        isA<Err<DocumentRequest>>(),
      );
      final draft = value(await service.prepare(input(visit)));
      expect(value(await service.prepare(input(visit))).id, draft.id);
      expect(
        await service.prepare(
          input(
            visit,
            content: {'leaveStart': '2026-10-09', 'leaveEnd': '2026-10-10'},
          ),
        ),
        isA<Err<DocumentRequest>>(),
      );
      final submitted = value(
        await service.submit(draft.id, expectedVersion: draft.version),
      );
      expect(submitted.version, greaterThan(draft.version));
      expect(
        await service.approve(draft.id, expectedVersion: draft.version),
        isA<Err<DocumentRequest>>(),
      );
      expect(
        await service.approve(draft.id, expectedVersion: submitted.version),
        isA<Err<DocumentRequest>>(),
      );
      expect(await db.select(db.issuedDocumentVersions).get(), isEmpty);
    },
  );

  test(
    'nurse cannot approve or sign even with signing grant and medical credential',
    () async {
      final (c, db) = await seededContainer();
      final visit = await setup(db);
      await (db.update(db.staffProfiles)
            ..where((s) => s.userId.equals('staff_01')))
          .write(const StaffProfilesCompanion(jobTitle: Value('Nurse')));
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final draft = value(await service.prepare(input(visit)));
      final submitted = value(
        await service.submit(draft.id, expectedVersion: draft.version),
      );
      expect(
        await service.approve(draft.id, expectedVersion: submitted.version),
        isA<Err<DocumentRequest>>(),
      );
      expect(
        await service.issue(
          draft.id,
          expectedVersion: submitted.version,
          idempotencyKey: 'issue',
        ),
        isA<Err<IssuedDocument>>(),
      );
      expect(await db.select(db.issuedDocumentVersions).get(), isEmpty);
    },
  );

  test(
    'verification failure rolls back certificate, snapshot, event and issue audit',
    () async {
      final (c, db) = await seededContainer();
      final visit = await setup(db);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final count = (await db.select(db.sickLeaveCertificates).get()).length;
      await db.customStatement(
        "CREATE TRIGGER reject_registration BEFORE INSERT ON document_verifications BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      expect(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'issue',
        ),
        isA<Err<IssuedDocument>>(),
      );
      expect(await db.select(db.issuedDocumentVersions).get(), isEmpty);
      expect(await db.select(db.documentDeliveryEvents).get(), isEmpty);
      expect(await db.select(db.sickLeaveCertificates).get(), hasLength(count));
      expect(
        (await (db.select(
          db.documentRequests,
        )..where((r) => r.id.equals(request.id))).getSingle()).status,
        'approved',
      );
    },
  );

  test(
    'revocation blocks stored download while retaining the artifact',
    () async {
      final renderer = TestRenderer();
      final (c, db) = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(renderer),
        ],
      );
      final visit = await setup(db);
      await grant(db, 'staff_01', Permission.revokeDocument);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final issued = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'issue',
        ),
      );
      value(await service.render(issued.id));
      value(await service.revoke(issued.id, reason: 'Issued in error'));
      expect(
        (await service.download(issued.id)).failureOrNull,
        isA<ConflictFailure>(),
      );
      expect(
        (await db.select(db.documentArtifacts).get()).single.bytes,
        isNotNull,
      );
      expect(
        (await db.select(db.documentVerifications).get())
            .where((v) => v.issuedVersionId == issued.id)
            .single
            .validity,
        'revoked',
      );
    },
  );

  test(
    'replacement preserves the original, supersedes only after a new approval and issuance',
    () async {
      final renderer = TestRenderer();
      final (c, db) = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(renderer),
        ],
      );
      final visit = await setup(db);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final original = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'original',
        ),
      );
      value(await service.render(original.id));
      final originalBytes = value(await service.download(original.id));
      final policy = await (db.select(
        db.documentTemplates,
      )..where((t) => t.id.equals('sick-leave-v1-en-employer'))).getSingle();
      await db
          .into(db.documentTemplates)
          .insert(
            DocumentTemplatesCompanion.insert(
              id: 'sick-leave-v2-en-employer',
              documentType: policy.documentType,
              version: 2,
              language: 'en',
              disclosureProfile: 'employer',
              wording: policy.wording,
              clinicalSignatureRequired: true,
              requiredCredential: const Value('medicalLicense'),
              approvedBy: const Value('admin_01'),
              approvedAt: Value(DateTime.now()),
            ),
          );
      await (db.update(db.documentTemplates)
            ..where((t) => t.id.equals(policy.id)))
          .write(DocumentTemplatesCompanion(retiredAt: Value(DateTime.now())));
      final issuedRequest = await (db.select(
        db.documentRequests,
      )..where((r) => r.id.equals(request.id))).getSingle();
      final draft = value(
        await service.prepareReplacement(
          original.id,
          templateId: 'sick-leave-v2-en-employer',
          expectedVersion: issuedRequest.version,
          content: {'leaveStart': '2026-10-08', 'leaveEnd': '2026-10-11'},
          reason: 'Correct leave end date',
        ),
      );
      expect(value(await service.download(original.id)), originalBytes);
      final submitted = value(
        await service.submit(draft.id, expectedVersion: draft.version),
      );
      final review = value(
        await service.approve(draft.id, expectedVersion: submitted.version),
      );
      final replacement = value(
        await service.issue(
          review.id,
          expectedVersion: review.version,
          idempotencyKey: 'replacement',
        ),
      );
      value(await service.render(replacement.id));
      expect(replacement.supersedesId, original.id);
      expect(
        (await service.download(original.id)).failureOrNull,
        isA<ConflictFailure>(),
      );
      expect(
        (await db.select(db.documentArtifacts).get())
            .firstWhere((a) => a.issuedVersionId == original.id)
            .bytes,
        originalBytes,
      );
      expect(
        await (db.update(db.sickLeaveCertificates)
              ..where((c) => c.id.equals(original.id)))
            .write(
              const SickLeaveCertificatesCompanion(diagnosis: Value('Changed')),
            )
            .then((_) => false)
            .catchError((Object _) => true),
        isTrue,
      );
      expect(
        (await db.select(db.issuedDocumentVersions).get()).map(
          (v) => v.version,
        ),
        [1, 2],
      );
    },
  );

  test(
    'delivery failure is separate from ready bytes and retry sends exactly one notification',
    () async {
      final renderer = TestRenderer();
      final (c, db) = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(renderer),
        ],
      );
      final visit = await setup(db);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final issued = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'issue',
        ),
      );
      await db.customStatement(
        "CREATE TRIGGER reject_notification BEFORE INSERT ON notifications BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      expect(await service.render(issued.id), isA<Err<IssuedDocument>>());
      expect(
        (await db.select(db.documentArtifacts).get()).single.status,
        'ready',
      );
      expect(
        (await db.select(db.documentDeliveryEvents).get()).single.status,
        'failed',
      );
      expect(value(await service.download(issued.id)), isNotEmpty);
      await db.customStatement('DROP TRIGGER reject_notification');
      value(await service.deliver(issued.id));
      value(await service.deliver(issued.id));
      expect(
        (await db.select(db.documentDeliveryEvents).get()).single.attempt,
        2,
      );
      expect(
        await (db.select(
          db.notifications,
        )..where((n) => n.sourceEventId.isNotNull())).get(),
        hasLength(1),
      );
      expect(renderer.calls, 1);
    },
  );

  test(
    'mismatched visits and normalized invalid calendar dates are rejected',
    () async {
      final (c, db) = await seededContainer();
      final visit = await setup(db);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      expect(
        await service.prepare(
          input(
            visit,
            content: {'leaveStart': '2026-02-30', 'leaveEnd': '2026-03-05'},
          ),
        ),
        isA<Err<DocumentRequest>>(),
      );
      final other =
          await (db.select(db.appointments)
                ..where((a) => a.patientId.equals(visit.patientId).not())
                ..limit(1))
              .getSingle();
      expect(
        await service.prepare(
          PrepareDocument(
            patientId: visit.patientId,
            appointmentId: other.id,
            templateId: 'sick-leave-v1-en-employer',
            content: {'leaveStart': '2026-10-08', 'leaveEnd': '2026-10-10'},
            idempotencyKey: 'mismatch',
          ),
        ),
        isA<Err<DocumentRequest>>(),
      );
    },
  );

  for (final language in ['en', 'ar']) {
    test('real $language renderer produces A4 draft and issued PDFs', () async {
      const renderer = IssuedSickLeavePdf();
      for (final draft in [true, false]) {
        final bytes = await renderer.render(
          wording: language == 'ar'
              ? 'إجازة مرضية\nالمريض: أحمد. الطبيب: سارة.'
              : 'Sick leave\nPatient: Jane. Clinician: Sam.',
          language: language,
          reference: draft ? 'DRAFT' : 'ABC23-DEF45',
          issuedAt: DateTime(2026, 10, 8),
          draft: draft,
        );
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        expect(bytes.length, greaterThan(1000));
        final document = sf.PdfDocument(inputBytes: bytes);
        try {
          expect(document.pages[0].size.width, closeTo(595.28, 1));
          expect(document.pages[0].size.height, closeTo(841.89, 1));
          final text = sf.PdfTextExtractor(document).extractText();
          expect(text.contains('DRAFT'), draft);
          if (language == 'en') {
            expect(
              text.replaceAll(RegExp(r'\s+'), ' '),
              contains('Patient: Jane'),
            );
          }
          if (language == 'ar') {
            expect(
              RegExp(
                r'[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]',
              ).hasMatch(text),
              isTrue,
            );
          }
        } finally {
          document.dispose();
        }
      }
    });
  }
}
