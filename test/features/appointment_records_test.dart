import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/appointments/application/appointment_records_provider.dart';
import 'package:myhealthcare/features/appointments/presentation/appointment_records_section.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/features/patient/application/visited_doctors_provider.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/test_database.dart';

Future<ProviderContainer> patientContainer() async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(db.close);
  addTearDown(c.dispose);
  await c
      .read(sessionProvider.notifier)
      .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'old encounters include all linked records and stopped medication, excluding other encounters',
    () async {
      final c = await patientContainer();
      final db = c.read(appDatabaseProvider);
      final appointments = await c.read(ownAppointmentsProvider.future);
      final completed =
          appointments
              .where((a) => a.status == AppointmentStatus.completed)
              .toList()
            ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
      final a = completed.first;
      for (final type in RecordType.values) {
        await db
            .into(db.medicalRecords)
            .insert(
              MedicalRecordsCompanion.insert(
                id: 'test-${type.name}',
                patientId: a.patientId,
                appointmentId: Value(a.id),
                recordType: type,
                title: type.name,
                occurredAt: a.slotStart,
              ),
            );
      }
      await db
          .into(db.medicalRecords)
          .insert(
            MedicalRecordsCompanion.insert(
              id: 'unlinked-same-date',
              patientId: a.patientId,
              recordType: RecordType.visitNote,
              title: 'Unrelated',
              occurredAt: a.slotStart,
            ),
          );
      await db
          .into(db.medications)
          .insert(
            MedicationsCompanion.insert(
              id: 'stopped-encounter-med',
              patientId: a.patientId,
              appointmentId: Value(a.id),
              name: 'Historical prescription',
              startDate: a.slotStart,
              isActive: const Value(false),
            ),
          );
      for (var i = 0; i < 40; i++) {
        await db
            .into(db.medicalRecords)
            .insert(
              MedicalRecordsCompanion.insert(
                id: 'newer-$i',
                patientId: a.patientId,
                recordType: RecordType.visitNote,
                title: 'Newer visit',
                occurredAt: a.slotStart.add(Duration(days: i + 1)),
              ),
            );
      }
      final bundle = await c.read(appointmentRecordsProvider(a.id).future);
      expect(
        bundle.records.map((r) => r.recordType).toSet(),
        RecordType.values.toSet(),
      );
      expect(bundle.records.any((r) => r.id == 'unlinked-same-date'), isFalse);
      expect(bundle.records.every((r) => r.appointmentId == a.id), isTrue);
      expect(bundle.vitals, isNotEmpty);
      expect(bundle.vitals.every((v) => v.appointmentId == a.id), isTrue);
      expect(bundle.medications.single.isActive, isFalse);
      final timeline = await c
          .read(recordRepositoryProvider)
          .timeline(a.patientId, limit: 30);
      expect(
        timeline.valueOrNull!.any((r) => r.id == 'test-discharge'),
        isFalse,
      );
    },
  );

  test(
    'unknown and unfinished appointments cannot expose encounter records',
    () async {
      final c = await patientContainer();
      await expectLater(
        c.read(appointmentRecordsProvider('someone-elses-visit').future),
        throwsA(isA<AccessDeniedFailure>()),
      );
      final appts = await c.read(ownAppointmentsProvider.future);
      final unfinished = appts.firstWhere(
        (a) => a.status != AppointmentStatus.completed,
      );
      await expectLater(
        c.read(appointmentRecordsProvider(unfinished.id).future),
        throwsA(isA<AccessDeniedFailure>()),
      );
    },
  );

  test(
    'missed visits and a dependent\'s completed visits do not qualify the account holder for doctor chat',
    () async {
      final c = await patientContainer();
      final appts = await c.read(ownAppointmentsProvider.future);
      final a = appts.first;
      final scoped = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(c.read(appDatabaseProvider)),
          sharedPreferencesProvider.overrideWithValue(
            c.read(sharedPreferencesProvider),
          ),
          patientAppointmentsProvider.overrideWith(
            (ref) async => [
              a.copyWith(
                status: AppointmentStatus.noShow,
                slotStart: DateTime(2020),
                slotEnd: DateTime(2020, 1, 1, 1),
              ),
              a.copyWith(
                id: 'dependent',
                patientId: 'other-patient',
                status: AppointmentStatus.completed,
              ),
            ],
          ),
        ],
      );
      addTearDown(scoped.dispose);
      await scoped
          .read(sessionProvider.notifier)
          .login(
            email: 'patient3@myhealth.demo',
            password: Seeder.demoPassword,
          );
      expect(await scoped.read(visitedDoctorsProvider.future), isEmpty);
    },
  );

  testWidgets(
    'encounter UI hides absent categories and displays linked vitals',
    (tester) async {
      final c = await patientContainer();
      final appts = await c.read(ownAppointmentsProvider.future);
      final a = appts.firstWhere(
        (a) => a.status == AppointmentStatus.completed,
      );
      final bundle = await c.read(appointmentRecordsProvider(a.id).future);
      final scoped = ProviderContainer(
        parent: c,
        overrides: [
          appointmentRecordsProvider(a.id).overrideWith(
            (ref) async => AppointmentRecords(
              records: [],
              vitals: bundle.vitals,
              medications: [],
            ),
          ),
        ],
      );
      addTearDown(scoped.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scoped,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AppointmentRecordsSection(appointmentId: a.id),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vitals recorded'), findsOneWidget);
      expect(find.text('Laboratory panel'), findsNothing);
      expect(find.text('Vaccinations'), findsNothing);
      expect(find.textContaining('mmHg'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
