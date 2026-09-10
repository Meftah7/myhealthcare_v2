// Admin → Users: the expanding directory rows and their account actions —
// deactivate/reactivate + reset password (existing), and, for a patient,
// book-an-appointment and refer (new).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/entities/staff.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/admin/application/admin_providers.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _headless() async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
  await container
      .read(sessionProvider.notifier)
      .login(email: 'admin@myhealth.demo', password: Seeder.demoPassword);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  test(
    'bookForPatient adds a booked appointment and notifies the patient',
    () async {
      final container = await _headless();
      addTearDown(container.dispose);

      const patientId = 'patient_004';
      final depts = await container.read(departmentsProvider.future);
      final doctors = await container.read(
        adminDepartmentDoctorsProvider(depts.first.id).future,
      );
      // Next clinic-hours slot: 10:00 two days out.
      final now = DateTime.now();
      var start = DateTime(now.year, now.month, now.day + 2, 10);
      while (start.weekday == DateTime.friday ||
          start.weekday == DateTime.saturday) {
        start = start.add(const Duration(days: 1));
      }

      final before = await container
          .read(appointmentRepositoryProvider)
          .forPatient(patientId);

      final r = await container
          .read(adminActionsProvider)
          .bookForPatient(
            patientId: patientId,
            staffId: doctors.first.id,
            start: start,
            duration: const Duration(minutes: 20),
            visitType: VisitType.followUp,
            departmentId: depts.first.id,
          );
      expect(r.isOk, isTrue, reason: r.toString());

      final after = await container
          .read(appointmentRepositoryProvider)
          .forPatient(patientId);
      expect(after.valueOrNull!.length, before.valueOrNull!.length + 1);
      final appt = after.valueOrNull!.firstWhere((a) => a.slotStart == start);
      expect(appt.status, AppointmentStatus.booked);
      expect(appt.staffId, doctors.first.id);

      final notes = await container
          .read(notificationRepositoryProvider)
          .forRecipient(patientId);
      expect(
        notes.valueOrNull!.any((n) => n.title.contains('Appointment booked')),
        isTrue,
      );
    },
  );

  test(
    'referPatient writes a referral record to the patient history',
    () async {
      final container = await _headless();
      addTearDown(container.dispose);

      const patientId = 'patient_006';
      final depts = await container.read(departmentsProvider.future);

      // Internal referral.
      final r1 = await container
          .read(adminActionsProvider)
          .referPatient(
            patientId: patientId,
            destination: depts.last.name,
            external: false,
            reason: 'Second opinion on ECG changes.',
          );
      expect(r1.isOk, isTrue, reason: r1.toString());

      // External referral.
      final r2 = await container
          .read(adminActionsProvider)
          .referPatient(
            patientId: patientId,
            destination: 'Salmaniya Medical Complex',
            external: true,
            reason: 'Requires cardiac catheterisation lab.',
          );
      expect(r2.isOk, isTrue, reason: r2.toString());

      final timeline = await container
          .read(recordRepositoryProvider)
          .timeline(patientId, limit: 500);
      final referrals = timeline.valueOrNull!
          .where((rec) => rec.recordType == RecordType.referral)
          .toList();
      expect(referrals.length, greaterThanOrEqualTo(2));
      // The external referral names the hospital in the title + sourceFacility;
      // its body is the clinical reason (so the letter PDF can use them apart).
      final external = referrals.firstWhere(
        (rec) => rec.sourceFacility == 'Salmaniya Medical Complex',
      );
      expect(external.title, contains('Salmaniya'));
      expect(external.body, 'Requires cardiac catheterisation lab.');
    },
  );

  test('createStaff persists the chosen role as the job title', () async {
    final container = await _headless();
    addTearDown(container.dispose);

    final r = await container
        .read(adminActionsProvider)
        .createStaff(
          fullName: 'Layla Nurse',
          email: 'nurse.test@myhealth.demo',
          temporaryPassword: 'password123',
          jobTitle: kNurseJobTitle,
        );
    expect(r.isOk, isTrue, reason: r.toString());
    expect(r.valueOrNull!.jobTitle, kNurseJobTitle);
    expect(r.valueOrNull!.isNurse, isTrue);
    expect(r.valueOrNull!.isDoctor, isFalse);
  });

  testWidgets('a user row expands to show the account actions', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = newTestDatabase();
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyHealthCareApp(),
      ),
    );
    await _settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'admin@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await passMfa(tester);
    await _settle(tester);

    await tester.tap(find.text('Users').last);
    await _settle(tester);

    // Patients tab is first. Collapsed rows hide the actions.
    expect(find.text('Reset password'), findsNothing);

    await tester.tap(find.byType(ExpansionTile).first);
    await _settle(tester);

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Deactivate'), findsOneWidget);
    // Patient-only actions.
    expect(find.text('Book appointment'), findsOneWidget);
    expect(find.text('Refer'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
