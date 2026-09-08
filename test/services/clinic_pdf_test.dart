// Patient document builders produce a valid PDF from any input (P10-01..03).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/services/pdf/clinic_pdf.dart';
import 'package:myhealthcare/services/pdf/reports.dart';

bool _isPdf(Uint8List b) =>
    b.length > 800 &&
    b[0] == 0x25 && // %
    b[1] == 0x50 && // P
    b[2] == 0x44 && // D
    b[3] == 0x46; // F

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const identity = PdfIdentity(
    name: 'Sara Ahmed',
    patientId: 'patient_003',
    bloodType: 'O+',
    allergies: ['Penicillin', 'Peanuts'],
  );

  final now = DateTime(2026, 3, 1, 9);

  test('vitals report renders — with readings', () async {
    final readings = [
      Vitals(
        id: 'v1',
        patientId: 'p',
        recordedAt: now,
        systolic: 128,
        diastolic: 82,
        heartRate: 74,
        spo2: 98,
        weightKg: 80,
        heightCm: 175,
        glucose: 5.4,
      ),
      Vitals(
        id: 'v2',
        patientId: 'p',
        recordedAt: now.subtract(const Duration(days: 30)),
        systolic: 134,
        diastolic: 86,
      ),
    ];
    final bytes = await vitalsReportPdf(patient: identity, readings: readings);
    expect(_isPdf(bytes), isTrue);
  });

  test('vitals report renders — empty history', () async {
    final bytes = await vitalsReportPdf(patient: identity, readings: const []);
    expect(_isPdf(bytes), isTrue);
  });

  test('radiology report renders', () async {
    final rec = MedicalRecord(
      id: 'r1',
      patientId: 'p',
      recordType: RecordType.imaging,
      title: 'Chest X-ray (PA and lateral)',
      occurredAt: DateTime(2026, 2, 2),
      createdAt: DateTime(2026, 2, 2),
      body: 'Lungs clear. No acute cardiopulmonary abnormality.',
      sourceFacility: 'BDF Hospital',
    );
    final bytes = await radiologyReportPdf(
      patient: identity,
      record: rec,
      reportingClinician: 'Dr Noor Salem',
    );
    expect(_isPdf(bytes), isTrue);
  });

  test('renders for a patient with no allergies / no blood type', () async {
    const bare = PdfIdentity(name: 'A B', patientId: 'p');
    final bytes = await vitalsReportPdf(patient: bare, readings: const []);
    expect(_isPdf(bytes), isTrue);
  });
}
