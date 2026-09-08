// Radiology results + visited doctors are derived from seeded data and the
// document builders wire to live patient data (P10-03, P10-04).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_documents.dart';
import 'package:myhealthcare/features/patient/application/visited_doctors_provider.dart';
import 'package:myhealthcare/services/pdf/reports.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<ProviderContainer> _signedInPatient() async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
  addTearDown(db.close);
  addTearDown(container.dispose);

  final login = await container
      .read(sessionProvider.notifier)
      .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
  expect(login.isOk, isTrue);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('imaging results are seeded, imaging-only and newest first', () async {
    final container = await _signedInPatient();

    final imaging = await container.read(patientImagingProvider.future);
    expect(imaging, isNotEmpty);
    expect(imaging.every((r) => r.recordType == RecordType.imaging), isTrue);
    for (var i = 1; i < imaging.length; i++) {
      expect(
        imaging[i - 1].occurredAt.isBefore(imaging[i].occurredAt),
        isFalse,
        reason: 'imaging list is newest-first',
      );
    }
  });

  test('a radiology report builds from a seeded imaging record', () async {
    final container = await _signedInPatient();
    final identity = await container.read(pdfIdentityProvider.future);
    final imaging = await container.read(patientImagingProvider.future);

    final bytes = await radiologyReportPdf(
      patient: identity,
      record: imaging.first,
    );
    expect(bytes.length, greaterThan(800));
  });

  test('the vitals report builds from seeded readings', () async {
    final container = await _signedInPatient();
    final identity = await container.read(pdfIdentityProvider.future);
    final readings = await container.read(patientVitalsProvider.future);
    expect(readings, isNotEmpty);

    final bytes = await vitalsReportPdf(patient: identity, readings: readings);
    expect(bytes.length, greaterThan(800));
  });

  test('visited doctors group past appointments, newest visit first', () async {
    final container = await _signedInPatient();

    final doctors = await container.read(visitedDoctorsProvider.future);
    expect(doctors, isNotEmpty);
    for (final d in doctors) {
      expect(d.visitCount, greaterThanOrEqualTo(1));
      expect(d.lastVisit.isBefore(DateTime.now()), isTrue);
    }
    for (var i = 1; i < doctors.length; i++) {
      expect(
        doctors[i - 1].lastVisit.isBefore(doctors[i].lastVisit),
        isFalse,
        reason: 'care team is ordered by most-recent visit',
      );
    }
  });
}
