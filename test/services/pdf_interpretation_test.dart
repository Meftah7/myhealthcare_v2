// Patient-facing interpretation in exported documents (Phase 2): flags in
// the document's language, out-of-range explanations, previous values,
// patient context, licence numbers and the visit summary.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/services/pdf/clinic_pdf.dart';
import 'package:myhealthcare/services/pdf/reports.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

  final at = DateTime(2026, 3, 1, 9);
  final identity = PdfIdentity(
    name: 'Sara Ahmed',
    patientId: 'patient_003',
    dob: DateTime(1990, 1, 1),
    conditions: const ['Type 2 diabetes'],
    medications: const ['Metformin · 500 mg · twice daily'],
  );

  MedicalRecord labRecord(List<LabValue> values) => MedicalRecord(
    id: 'r1',
    patientId: 'patient_003',
    recordType: RecordType.labResult,
    title: 'Blood panel',
    occurredAt: at,
    createdAt: at,
    labValues: values,
  );

  LabValue lab(String analyte, double value, AbnormalFlag flag) => LabValue(
    id: analyte,
    recordId: 'r1',
    analyte: analyte,
    value: value,
    unit: 'mmol/L',
    refLow: 3.9,
    refHigh: 5.5,
    abnormalFlag: flag,
  );

  test('lab flags are translated and abnormal results explained', () async {
    final record = labRecord([
      lab('Glucose', 7.2, AbnormalFlag.high),
      lab('Potassium', 4.1, AbnormalFlag.normal),
    ]);
    final en = _text(
      await recordSummaryPdf(
        patient: identity,
        record: record,
        recordTypeLabel: 'Lab result',
        previousLabs: {
          'glucose': (value: 6.1, unit: 'mmol/L', at: DateTime(2025, 12, 1)),
        },
      ),
    );
    expect(en, contains('High'));
    expect(en, contains('outside the reference range'));
    expect(en, contains('Previous'));
    expect(en, contains('6.1 mmol/L'));
    expect(en, contains('Type 2 diabetes'));
    expect(en, contains('Metformin'));
    expect(en, isNot(contains('high\n')));

    final ar = _text(
      await recordSummaryPdf(
        patient: identity,
        record: record,
        recordTypeLabel: 'نتيجة مختبر',
        arabic: true,
      ),
    );
    expect(ar, isNot(contains('high')));
  });

  test('a critical result tells the patient to contact the clinic', () async {
    final text = _text(
      await recordSummaryPdf(
        patient: identity,
        record: labRecord([lab('Potassium', 6.9, AbnormalFlag.critical)]),
        recordTypeLabel: 'Lab result',
      ),
    );
    expect(text, contains('Critical'));
    expect(text, contains('contact the clinic today'));
  });

  test('vitals show the typical range and flag high readings', () async {
    final text = _text(
      await vitalsReportPdf(
        patient: identity,
        readings: [
          Vitals(
            id: 'v1',
            patientId: 'patient_003',
            recordedAt: at,
            systolic: 150,
            diastolic: 95,
            heartRate: 72,
          ),
        ],
      ),
    );
    expect(text, contains('Typical adult range'));
    expect(text, contains('High'));
    expect(text, contains('Normal'));
  });

  test('sick leave prints the clinician licence number', () async {
    final text = _text(
      await sickLeavePdf(
        patient: identity,
        certificate: SickLeaveCertificate(
          id: 'sl1',
          patientId: 'patient_003',
          issuedByStaffId: 'staff_1',
          diagnosis: 'Influenza',
          fromDate: at,
          toDate: at.add(const Duration(days: 2)),
          issuedAt: at,
        ),
        issuingClinician: 'Dr Hassan',
        clinicianLicence: 'BH-12345',
      ),
    );
    expect(text, contains('BH-12345'));
  });

  test(
    'visit summary lists vitals, results, medications and follow-up',
    () async {
      final appointment = Appointment(
        id: 'a1',
        patientId: 'patient_003',
        staffId: 'staff_1',
        slotStart: at,
        slotEnd: at.add(const Duration(minutes: 20)),
        visitType: VisitType.followUp,
        status: AppointmentStatus.completed,
        bookedAt: at.subtract(const Duration(days: 3)),
        remindersSent: 1,
        outcomeNote: 'Recheck glucose in three months.',
      );
      final text = _text(
        await visitSummaryPdf(
          patient: identity,
          appointment: appointment,
          records: [
            labRecord([lab('Glucose', 7.2, AbnormalFlag.high)]),
          ],
          vitals: [
            Vitals(
              id: 'v1',
              patientId: 'patient_003',
              recordedAt: at,
              systolic: 120,
              diastolic: 80,
              appointmentId: 'a1',
            ),
          ],
          medications: [
            Medication(
              id: 'm1',
              patientId: 'patient_003',
              name: 'Atorvastatin',
              startDate: at,
              isActive: true,
              dose: '20 mg',
            ),
          ],
          clinicianName: 'Dr Hassan',
          departmentName: 'Internal Medicine',
        ),
      );
      expect(text, contains('Visit summary'));
      expect(text, contains('Internal Medicine'));
      expect(text, contains('BLOOD PANEL'));
      expect(text, contains('Atorvastatin'));
      expect(text, contains('Recheck glucose'));
      expect(text, contains('No upcoming appointment'));
    },
  );
}
