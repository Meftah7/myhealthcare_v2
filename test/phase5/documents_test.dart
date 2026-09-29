// Phase 5 gate: an imported document keeps its source file, issuer, patient
// and review status through storage, review and export; exports are
// authorized, audited, selectable text, and say where they came from.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';
import 'package:myhealthcare/services/pdf/clinic_pdf.dart';
import 'package:myhealthcare/services/pdf/reports.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../support/sessions.dart';

const _patient = 'patient3@myhealth.demo';
const _patientId = 'patient_003';

Matcher _fails<T extends Failure>() =>
    isA<Err<dynamic>>().having((e) => e.failure, 'failure', isA<T>());

Matcher get _denied => _fails<AccessDeniedFailure>();

/// A small, real PDF — what a patient would pick.
Future<Uint8List> _outsidePdf() {
  final doc = pw.Document()
    ..addPage(pw.Page(build: (_) => pw.Text('Ferritin 9 ug/L  (ref 15-150)')));
  return doc.save();
}

/// Text a reader (or screen reader) can select in [pdf].
String _text(Uint8List pdf) {
  final doc = PdfDocument(inputBytes: pdf);
  try {
    // Line by line: plain extractText() puts every word on its own line.
    return PdfTextExtractor(
      doc,
    ).extractTextLines().map((l) => l.text).join('\n');
  } finally {
    doc.dispose();
  }
}

/// Email of a clinician with a care relationship to the patient.
Future<String> _treatingClinicianEmail(AppDatabase db) async {
  final appt =
      await (db.select(db.appointments)
            ..where((a) => a.patientId.equals(_patientId))
            ..limit(1))
          .getSingle();
  final user = await (db.select(
    db.users,
  )..where((u) => u.id.equals(appt.staffId))).getSingle();
  return user.email;
}

Future<MedicalRecord> _import(
  ProviderContainer c, {
  required Uint8List bytes,
  String issuer = 'Gulf Diagnostics Lab',
}) async {
  final r = await c
      .read(recordRepositoryProvider)
      .add(
        NewRecord(
          patientId: _patientId,
          recordType: RecordType.labResult,
          title: 'Outside ferritin',
          occurredAt: DateTime(2026, 8, 20),
          sourceFacility: issuer,
          extractedText: 'Ferritin 9 ug/L',
          uploadedByPatient: true,
          sourceFile: NewSourceFile(
            fileName: 'ferritin.pdf',
            mimeType: 'application/pdf',
            bytes: bytes,
          ),
        ),
      );
  return r.valueOrNull!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('import journey', () {
    test('source file, issuer and review status survive storage, review and '
        'export', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _patient);
      final bytes = await _outsidePdf();
      final record = await _import(c, bytes: bytes);

      expect(record.reviewStatus, ImportReviewStatus.pendingReview);
      expect(record.sourceFacility, 'Gulf Diagnostics Lab');
      final doc = record.sourceDocument!;
      expect(doc.fileName, 'ferritin.pdf');
      expect(doc.sizeBytes, bytes.length);
      expect(doc.sha256, hasLength(64));

      // Read back exactly as imported, and the read is audited.
      final original =
          (await c.read(recordRepositoryProvider).sourceFile(record.id))
              .valueOrNull!;
      expect(original.bytes, bytes);
      final audits = await (db.select(
        db.auditLog,
      )..where((a) => a.action.equals('record.source.download'))).get();
      expect(audits, isNotEmpty);

      // The export says what it is: issuer, import, not reviewed, file.
      const identity = PdfIdentity(name: 'Test Patient', patientId: _patientId);
      final before = _text(
        await recordSummaryPdf(
          patient: identity,
          record: record,
          recordTypeLabel: 'Lab result',
        ),
      );
      expect(before, contains('Gulf Diagnostics Lab'));
      expect(before, contains('Not reviewed by a clinician'));
      expect(before, contains('ferritin.pdf'));
      expect(before, contains(doc.sha256));

      // A treating clinician accepts it; the status travels with it.
      await signInAs(c, await _treatingClinicianEmail(db));
      final staffId = c.read(accessPolicyProvider).actingAccountId!;
      final reviewed = await c
          .read(recordRepositoryProvider)
          .reviewImport(
            recordId: record.id,
            staffId: staffId,
            decision: ImportReviewStatus.reviewed,
          );
      expect(reviewed.valueOrNull?.reviewStatus, ImportReviewStatus.reviewed);
      expect(reviewed.valueOrNull?.sourceDocument?.sha256, doc.sha256);
      final after = _text(
        await recordSummaryPdf(
          patient: identity,
          record: reviewed.valueOrNull!,
          recordTypeLabel: 'Lab result',
          reviewerName: 'Dr Reviewer',
        ),
      );
      expect(after, contains('Reviewed by Dr Reviewer'));

      // Reviewed once only.
      expect(
        await c
            .read(recordRepositoryProvider)
            .reviewImport(
              recordId: record.id,
              staffId: staffId,
              decision: ImportReviewStatus.rejected,
              note: 'x',
            ),
        _fails<ConflictFailure>(),
      );
    });

    test('an import needs an issuer and a real, bounded file', () async {
      final (c, _) = await seededContainer();
      await signInAs(c, _patient);
      final repo = c.read(recordRepositoryProvider);
      NewRecord draft({required Uint8List bytes, String? issuer}) => NewRecord(
        patientId: _patientId,
        recordType: RecordType.labResult,
        title: 'x',
        occurredAt: DateTime(2026, 8, 20),
        sourceFacility: issuer,
        uploadedByPatient: true,
        sourceFile: NewSourceFile(
          fileName: 'x.pdf',
          mimeType: 'application/pdf',
          bytes: bytes,
        ),
      );
      final pdf = await _outsidePdf();
      expect(await repo.add(draft(bytes: pdf)), _fails<ValidationFailure>());
      expect(
        await repo.add(
          draft(issuer: 'Lab', bytes: Uint8List.fromList([1, 2, 3, 4, 5, 6])),
        ),
        _fails<FileFailure>(),
      );
      expect(
        await repo.add(
          draft(
            issuer: 'Lab',
            bytes: Uint8List(NewSourceFile.maxBytes + 1)
              ..setAll(0, [0x25, 0x50, 0x44, 0x46, 0x2D]),
          ),
        ),
        _fails<FileFailure>(),
      );
    });

    test('rejecting an import needs a reason', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _patient);
      final record = await _import(c, bytes: await _outsidePdf());
      await signInAs(c, await _treatingClinicianEmail(db));
      final staffId = c.read(accessPolicyProvider).actingAccountId!;
      expect(
        await c
            .read(recordRepositoryProvider)
            .reviewImport(
              recordId: record.id,
              staffId: staffId,
              decision: ImportReviewStatus.rejected,
            ),
        _fails<ValidationFailure>(),
      );
    });
  });

  group('export and document authorization', () {
    test(
      'another patient cannot open the original or export the record',
      () async {
        final (c, _) = await seededContainer();
        await signInAs(c, _patient);
        final record = await _import(c, bytes: await _outsidePdf());
        await signInAs(c, 'patient1@myhealth.demo');
        expect(
          await c.read(recordRepositoryProvider).sourceFile(record.id),
          _denied,
        );
        expect(
          await c
              .read(exportRepositoryProvider)
              .authorizeExport(
                patientId: _patientId,
                document: ExportDocument.recordSummary,
                entityId: record.id,
              ),
          _denied,
        );
      },
    );

    test(
      'a clinician without a care relationship cannot review or open it',
      () async {
        final (c, db) = await seededContainer();
        await signInAs(c, _patient);
        final record = await _import(c, bytes: await _outsidePdf());
        final treating = await (db.select(
          db.appointments,
        )..where((a) => a.patientId.equals(_patientId))).get();
        final treatingIds = treating.map((a) => a.staffId).toSet();
        final stranger =
            await (db.select(db.users)
                  ..where(
                    (u) =>
                        u.role.equalsValue(UserRole.staff) &
                        u.id.isNotIn(treatingIds),
                  )
                  ..limit(1))
                .getSingle();
        await signInAs(c, stranger.email);
        expect(
          await c
              .read(recordRepositoryProvider)
              .reviewImport(
                recordId: record.id,
                staffId: stranger.id,
                decision: ImportReviewStatus.reviewed,
              ),
          _denied,
        );
        expect(
          await c.read(recordRepositoryProvider).sourceFile(record.id),
          _denied,
        );
      },
    );

    test('an authorized export is audited', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _patient);
      expect(
        (await c
                .read(exportRepositoryProvider)
                .authorizeExport(
                  patientId: _patientId,
                  document: ExportDocument.vitalsReport,
                ))
            .isOk,
        isTrue,
      );
      final audit =
          await (db.select(db.auditLog)..where(
                (a) =>
                    a.action.equals('document.export') &
                    a.subjectPatientId.equals(_patientId),
              ))
              .get();
      expect(audit.single.detail, 'vitalsReport');
    });
  });

  group('exported documents', () {
    const identity = PdfIdentity(
      name: 'Sara Ahmed',
      patientId: _patientId,
      allergies: ['Penicillin'],
    );
    final readings = [
      Vitals(
        id: 'v1',
        patientId: _patientId,
        recordedAt: DateTime(2026, 8, 1, 9),
        systolic: 128,
        diastolic: 82,
        heartRate: 74,
        recordedByStaffId: 'staff_01',
      ),
      Vitals(
        id: 'v2',
        patientId: _patientId,
        recordedAt: DateTime(2026, 8, 15, 9),
        systolic: 138,
        diastolic: 88,
        heartRate: 80,
      ),
    ];

    test('are selectable text naming issuer, source, date, status and '
        'reference, with a text summary of trend data', () async {
      final text = _text(
        await vitalsReportPdf(patient: identity, readings: readings),
      );
      for (final expected in [
        'Issued by',
        'Source',
        'Document date',
        'Status',
        'Reference',
        'Record extract',
        'SUMMARY',
        '2 readings, from 128/82 to 138/88 mmHg; latest 138/88 mmHg.',
        'Sara Ahmed',
      ]) {
        expect(text, contains(expected));
      }
    });

    test('Arabic documents build right-to-left with Arabic text', () async {
      final bytes = await vitalsReportPdf(
        patient: identity,
        readings: readings,
        arabic: true,
      );
      final text = _text(bytes);
      // Latin names are kept as recorded (right-to-left extraction reverses
      // word order, so check the words).
      expect(text, contains('Sara'));
      expect(text, contains('Ahmed'));
      // Arabic glyphs were embedded, not dropped.
      expect(RegExp('[؀-ۿﹰ-﻿]').hasMatch(text), isTrue);
    });

    test('a certificate says who issued it and its status', () async {
      final text = _text(
        await sickLeavePdf(
          patient: identity,
          certificate: SickLeaveCertificate(
            id: 'sl_1',
            patientId: _patientId,
            issuedByStaffId: 'staff_01',
            diagnosis: 'Viral illness',
            fromDate: DateTime(2026, 8, 2),
            toDate: DateTime(2026, 8, 4),
            issuedAt: DateTime(2026, 8, 2),
          ),
          issuingClinician: 'Dr Noor Salem',
        ),
      );
      expect(text, contains('Dr Noor Salem'));
      expect(text, contains('Issued'));
      expect(text, contains('sl_1'));
    });
  });
}
