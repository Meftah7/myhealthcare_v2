// Patient <-> doctor chat is live on both sides: with a patient and their
// doctor signed in separately on the same database (two browser tabs on the
// web), a message from one appears on the other's open screen straight away
// — conversation, inbox and unread count — with no refresh. On the
// patient's Messages the Care Navigator steps aside.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/care/application/care_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

const _patient = 'patient_001';
const _doctor = 'staff_01'; // A doctor Aisha has seen.

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _signedIn(
  AppDatabase db,
  SharedPreferences prefs,
  String email,
) async {
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
  addTearDown(c.dispose);
  final r = await c
      .read(sessionProvider.notifier)
      .login(email: email, password: Seeder.demoPassword);
  expect(r.isOk, isTrue, reason: email);
  return c;
}

Future<void> _send(
  WidgetTester tester,
  ProviderContainer from,
  String to,
  String text,
) async {
  final r = await from
      .read(messageActionsProvider)
      .sendAsCurrentUser(counterpartId: to, body: text);
  expect(r.isOk, isTrue, reason: '${r.failureOrNull}');
}

Future<(AppDatabase, SharedPreferences)> _setUp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );
  final db = newTestDatabase();
  addTearDown(db.close);
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
  final prefs = await SharedPreferences.getInstance();
  return (db, prefs);
}

void main() {
  testWidgets('the doctor sees a patient message arrive live', (tester) async {
    final (db, prefs) = await _setUp(tester);
    final patient = await _signedIn(db, prefs, 'patient1@myhealth.demo');
    final doctor = await _signedIn(db, prefs, 'staff1@myhealth.demo');

    // The doctor's tab: the inbox, then the conversation with Aisha.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: doctor,
        child: const MyHealthCareApp(),
      ),
    );
    await _settle(tester);
    doctor.read(routerProvider).go(AppRoutes.staffInbox);
    await _settle(tester);
    expect(find.text('Aisha Smith'), findsNothing);

    // The patient's tab sends — the inbox lists it with no refresh.
    await _send(tester, patient, _doctor, 'Hello doctor, a quick question');
    await _settle(tester);
    expect(find.text('Aisha Smith'), findsWidgets);
    expect(doctor.read(staffUnreadCountProvider), 1);

    doctor
        .read(routerProvider)
        .go(AppRoutes.staffInboxThread(_patient, name: 'Aisha Smith'));
    await _settle(tester);
    expect(find.text('Hello doctor, a quick question'), findsOneWidget);

    // A second message while the conversation is open appears in it, and
    // counts as read — it is on screen.
    await _send(tester, patient, _doctor, 'Can I take it with food?');
    await _settle(tester);
    expect(find.text('Can I take it with food?'), findsOneWidget);
    await _settle(tester);
    expect(doctor.read(staffUnreadCountProvider), 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the patient sees the doctor reply arrive live', (tester) async {
    final (db, prefs) = await _setUp(tester);
    final patient = await _signedIn(db, prefs, 'patient1@myhealth.demo');
    final doctor = await _signedIn(db, prefs, 'staff1@myhealth.demo');
    await _send(tester, patient, _doctor, 'Is my result back?');

    // The patient's tab: the conversation with the doctor, open.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: patient,
        child: const MyHealthCareApp(),
      ),
    );
    await _settle(tester);
    patient
        .read(routerProvider)
        .go('${AppRoutes.patientMessages}/$_doctor?name=Dr%20Wadha%20Smith');
    await _settle(tester);
    expect(find.text('Is my result back?'), findsOneWidget);
    // The Care Navigator steps aside so it can't cover the Send button.
    expect(find.bySemanticsLabel('Open Care Navigator'), findsNothing);

    // The doctor's tab replies — it shows up for the patient straight away.
    await _send(tester, doctor, _patient, 'Yes, it is normal.');
    await _settle(tester);
    expect(find.text('Yes, it is normal.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
