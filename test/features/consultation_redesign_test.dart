// The doctor's in-progress consultation screen: patient info, then "Open
// chart" (no completion steps or visit documents), "Doctor's notes" (no AI
// Scribe), medications with dose and frequency required, referral, and a
// sick-leave request that an administrator approves before the patient
// ever sees it. No visit summary.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _login(ProviderContainer c, String email) => c
    .read(sessionProvider.notifier)
    .login(email: email, password: Seeder.demoPassword);

void main() {
  testWidgets('in-progress consultation layout and sick leave approval', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
    final db = newTestDatabase();
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(c.dispose);

    // A visit under way right now: staff_01 with patient_001.
    final now = DateTime.now();
    await db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: 'visit-now',
            patientId: 'patient_001',
            staffId: 'staff_01',
            slotStart: now.subtract(const Duration(minutes: 10)),
            slotEnd: now.add(const Duration(minutes: 10)),
            visitType: VisitType.followUp,
            status: const Value(AppointmentStatus.inProgress),
            checkedInAt: Value(now.subtract(const Duration(minutes: 5))),
          ),
        );
    // The patient's certificates before this visit (signed in as them).
    await _login(c, 'patient1@myhealth.demo');
    final before =
        (await c.read(sickLeaveRepositoryProvider).forPatient('patient_001'))
            .valueOrNull!
            .length;

    await _login(c, 'staff1@myhealth.demo');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
    );
    await _settle(tester);
    c.read(routerProvider).go(AppRoutes.staffConsultation('visit-now'));
    await _settle(tester);

    // Layout.
    expect(
      find.byKey(const ValueKey('consultation-open-chart')),
      findsOneWidget,
    );
    expect(find.text('Visit completion steps'), findsNothing);
    expect(find.text('Documents for this visit'), findsNothing);
    expect(find.text("Doctor's notes"), findsOneWidget);
    expect(find.text('Clinical note'), findsNothing);
    expect(find.text('Open AI Scribe'), findsNothing);
    expect(find.textContaining('Visit summary'), findsNothing);
    expect(find.text('Referral'), findsOneWidget);
    expect(find.text('Sick leave'), findsOneWidget);

    // Medications: dose and frequency are required; "Quantity".
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add medication'));
    await _settle(tester);
    final add = find.widgetWithText(FilledButton, 'Add');
    await tester.enterText(
      find.widgetWithText(TextField, 'Medication name'),
      'Paracetamol',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    expect(find.widgetWithText(TextField, 'Quantity'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('med-dose')), '500 mg');
    await tester.pump();
    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('med-frequency')),
      'every 6 hours',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
    await tester.tap(add);
    await _settle(tester);
    expect(find.text('500 mg · every 6 hours'), findsOneWidget);

    // Sick leave: the doctor requests it from the visit.
    await tester.tap(
      find.byKey(const ValueKey('consultation-request-sick-leave')),
    );
    await _settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Reason / diagnosis'),
      'Acute viral illness',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);
    expect(find.textContaining('waiting for admin approval'), findsOneWidget);
    // One at a time: no second request while it waits.
    expect(
      find.byKey(const ValueKey('consultation-request-sick-leave')),
      findsNothing,
    );

    // The patient can't see it yet.
    final pending = await db.select(db.sickLeaveCertificates).get();
    final request = pending.singleWhere((r) => r.appointmentId == 'visit-now');
    expect(request.status, SickLeaveStatus.requested);
    await _login(c, 'patient1@myhealth.demo');
    expect(
      (await c.read(sickLeaveRepositoryProvider).forPatient('patient_001'))
          .valueOrNull,
      hasLength(before),
    );

    // An administrator approves it.
    await _login(c, 'admin@myhealth.demo');
    c.read(routerProvider).go(AppRoutes.adminSickLeaveRequests);
    await _settle(tester);
    expect(find.text('Acute viral illness'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('approve-sick-${request.id}')));
    await _settle(tester);
    expect(find.text('No sick leave requests are waiting.'), findsOneWidget);

    // Now it is the patient's certificate.
    await _login(c, 'patient1@myhealth.demo');
    expect(
      (await c.read(sickLeaveRepositoryProvider).forPatient('patient_001'))
          .valueOrNull,
      hasLength(before + 1),
    );

    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
