// "Open chart" on an in-progress consultation shows the patient's chart —
// name, details and the chart sections — not an empty page.

import 'dart:async';

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
import 'package:myhealthcare/features/care/presentation/document_workspace_screen.dart';
import 'package:myhealthcare/features/consultation/presentation/consultation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('Open chart from a consultation shows the chart', (tester) async {
    tester.view.physicalSize = const Size(1366, 900);
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

    await c
        .read(sessionProvider.notifier)
        .login(email: 'staff1@myhealth.demo', password: Seeder.demoPassword);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
    );
    await _settle(tester);
    // As a doctor does it: from the dashboard, into the consultation.
    final router = c.read(routerProvider);
    router.go(AppRoutes.staffDashboard);
    await _settle(tester);
    unawaited(router.push(AppRoutes.staffConsultation('visit-now')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('consultation-open-chart')));
    await _settle(tester);
    expect(tester.takeException(), isNull);

    // The chart: the patient's header card and the chart's sections.
    expect(find.text('Aisha Smith'), findsWidgets);
    expect(find.text('Recent vitals'), findsOneWidget);
    expect(find.byKey(const ValueKey('consultation-open-chart')), findsNothing);
    // The chart sits on the visit — the visit isn't opened a second time.
    expect(
      find.byType(ConsultationScreen, skipOffstage: false),
      findsOneWidget,
    );

    // The chart's own pages open from here too.
    await tester.tap(find.byTooltip('Documents'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(DocumentWorkspaceScreen), findsOneWidget);
    await tester.pageBack();
    await _settle(tester);
    expect(find.text('Recent vitals'), findsOneWidget);

    // Back returns to the consultation, notes and all.
    await tester.pageBack();
    await _settle(tester);
    expect(
      find.byKey(const ValueKey('consultation-open-chart')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
