// Issued documents carry a verification code staff can look up, and referral
// letters carry their urgency.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/repositories/document_verification_repository_impl.dart';
import 'package:myhealthcare/data/repositories/record_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/export_repository.dart';
import 'package:myhealthcare/domain/repositories/record_repository.dart';
import 'package:myhealthcare/services/pdf/clinic_pdf.dart';
import 'package:myhealthcare/services/pdf/reports.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../support/test_database.dart';

String _text(Uint8List pdf) {
  final doc = PdfDocument(inputBytes: pdf);
  try {
    return PdfTextExtractor(
      doc,
    ).extractTextLines().map((l) => l.text).join('\n');
  } finally {
    doc.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a code is stable per document and looks up what it states', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final patient = (await (db.select(
      db.users,
    )..where((u) => u.role.equalsValue(UserRole.patient))).get()).first;
    final repo = DocumentVerificationRepositoryImpl(db);

    Future<String> issue(List<String> summary) async => (await repo.issue(
      document: ExportDocument.sickLeaveCertificate,
      entityId: 'sl_test',
      patientId: patient.id,
      issuer: 'Dr Test',
      summary: summary,
    )).valueOrNull!;

    final code = await issue(['Reason: Influenza']);
    expect(code, matches(RegExp(r'^[A-Z2-9]{5}-[A-Z2-9]{5}$')));
    // Exporting again keeps the code; a changed document updates the record.
    expect(await issue(['Reason: Influenza (amended)']), code);

    final found = (await repo.verify(code.toLowerCase())).valueOrNull!;
    expect(found.patientName, patient.fullName);
    expect(found.issuer, 'Dr Test');
    expect(found.summary, ['Reason: Influenza (amended)']);
    expect((await repo.verify('ZZZZZ-ZZZZZ')).valueOrNull, isNull);
  });

  test('referral urgency is stored and printed with the code', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final patient = (await (db.select(
      db.users,
    )..where((u) => u.role.equalsValue(UserRole.patient))).get()).first;
    final saved = (await RecordRepositoryImpl(db).add(
      NewRecord(
        patientId: patient.id,
        recordType: RecordType.referral,
        title: 'Referral — City Hospital',
        occurredAt: DateTime(2026, 9, 1),
        body: 'Chest pain on exertion',
        sourceFacility: 'City Hospital',
        referralUrgency: ReferralUrgency.emergency,
      ),
    )).valueOrNull!;
    expect(saved.referralUrgency, ReferralUrgency.emergency);

    final text = _text(
      await referralLetterPdf(
        patient: PdfIdentity(name: patient.fullName, patientId: patient.id),
        destination: 'City Hospital',
        reason: 'Chest pain on exertion',
        referringClinic: 'Dr Test',
        urgency: saved.referralUrgency,
        verificationCode: 'ABCDE-FGHJK',
      ),
    );
    expect(text, contains('Emergency'));
    expect(text, contains('ABCDE-FGHJK'));
  });
}
