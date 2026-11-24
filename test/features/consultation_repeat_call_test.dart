// On the doctor's "Open consultation" screen the patient can be called as
// many times as needed — the button stays, each press pages the patient
// again, and the screen shows how many calls and when the last one was —
// until they arrive or are marked not shown.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
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

/// A fresh booked visit for staff_01 + patient_001 on a clear slot ahead,
/// booked by the patient; then the doctor is signed in.
Future<String> _bookAsPatientThenSignInDoctor(ProviderContainer c) async {
  await _login(c, 'patient1@myhealth.demo');
  final now = DateTime.now();
  var start = DateTime(now.year, now.month, now.day + 2, 10);
  while (start.weekday == DateTime.friday ||
      start.weekday == DateTime.saturday) {
    start = start.add(const Duration(days: 1));
  }
  final slots =
      (await c.read(appointmentRepositoryProvider).openSlots('staff_01', start))
          .valueOrNull!;
  final booked = await c
      .read(appointmentRepositoryProvider)
      .book(
        BookingRequest(
          patientId: 'patient_001',
          staffId: 'staff_01',
          start: slots.first.start,
          end: slots.first.end,
          visitType: VisitType.followUp,
        ),
      );
  await _login(c, 'staff1@myhealth.demo');
  return booked.valueOrNull!.id;
}

void main() {
  testWidgets('the doctor can call the patient again and again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
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

    final id = await _bookAsPatientThenSignInDoctor(c);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
    );
    await _settle(tester);
    c.read(routerProvider).go(AppRoutes.staffConsultation(id));
    await _settle(tester);

    final call = find.byKey(const ValueKey('consultation-call-patient'));
    final status = find.byKey(const ValueKey('consultation-call-status'));
    expect(find.widgetWithText(FilledButton, 'Call patient'), findsOneWidget);
    expect(status, findsNothing);

    // First call.
    await tester.tap(call);
    await _settle(tester);
    expect(tester.widget<Text>(status).data, startsWith('Patient called at'));
    expect(find.widgetWithText(FilledButton, 'Call again'), findsOneWidget);

    // The button stays: call twice more.
    for (var i = 0; i < 2; i++) {
      await tester.tap(call);
      await _settle(tester);
    }
    expect(
      tester.widget<Text>(status).data,
      startsWith('Patient called 3 times · last at'),
    );
    expect(c.read(scheduleCallLogProvider)[id]?.count, 3);
    // Still waiting for the patient: arrival / not shown remain available.
    expect(find.text('Patient arrived'), findsOneWidget);
    expect(find.text('Patient not shown'), findsOneWidget);

    // Every call paged the patient.
    final pages =
        (await (db.select(
          db.notifications,
        )..where((n) => n.recipientId.equals('patient_001'))).get()).where(
          (n) => n.title == 'You have been called in',
        );
    expect(pages, hasLength(3));

    await tester.pumpWidget(const SizedBox());
    // Stops the reminder dispatcher the booking started (it arms a timer).
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
