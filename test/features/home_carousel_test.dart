// Home restructure: sections in the new order, and the Upcoming appointments
// carousel shows a ticket number, a room, a "N of M" count and advances.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sessions.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('home carousel: ticket number, room, count, auto-slide', (
    tester,
  ) async {
    // A compact width on purpose: this test is about the *reading order* of
    // the sections, which is a vertical stack on a phone. From `expanded` up
    // the same sections deliberately split into two columns, so `dy` no longer
    // encodes the order there — that layout is covered in responsive_test.dart.
    tester.view.physicalSize = const Size(420, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = newTestDatabase();
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        patientAppointmentsProvider.overrideWith(
          (ref) async => [
            for (var i = 1; i <= 3; i++)
              Appointment(
                id: 'carousel-visit-$i',
                patientId: 'patient',
                staffId: 'staff',
                slotStart: DateTime.now().add(Duration(days: i)),
                slotEnd: DateTime.now().add(Duration(days: i, minutes: 20)),
                visitType: VisitType.followUp,
                status: AppointmentStatus.confirmed,
                bookedAt: DateTime.now(),
                remindersSent: 0,
                ticketTag: 'K-$i',
                roomNumber: 'A-$i',
              ),
          ],
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);

    await signInAs(container, 'patient3@myhealth.demo');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyHealthCareApp(),
      ),
    );
    await _settle(tester);

    // Phase 6 priority order: the next appointment is the anchor, above the
    // health figures and the quick actions.
    final health = tester.getTopLeft(find.text('Your health')).dy;
    final upcoming = tester.getTopLeft(find.text('Upcoming appointments')).dy;
    final quick = tester.getTopLeft(find.text('Quick actions')).dy;
    expect(upcoming, lessThan(health));
    expect(upcoming, lessThan(quick));

    // The carousel shows a well-formed ticket number and a room.
    expect(find.text('TICKET'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith(RegExp(r'[A-X]-')),
      ),
      findsWidgets,
    );
    expect(find.textContaining('Room '), findsWidgets);

    // The count is visible.
    expect(find.textContaining(RegExp(r'^\d+ of \d+$')), findsOneWidget);

    // Every four seconds the next card slides in; manual controls remain available.
    await tester.ensureVisible(find.byTooltip('Pause appointment slideshow'));
    await tester.tap(find.byTooltip('Pause appointment slideshow'));
    final firstCount = tester
        .widget<Text>(find.textContaining(RegExp(r'^\d+ of \d+$')))
        .data!;
    await tester.pump(const Duration(seconds: 10));
    expect(find.text(firstCount), findsOneWidget);
    await tester.tap(find.byTooltip('Resume appointment slideshow'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(firstCount), findsNothing);
    await tester.tap(find.byTooltip('Previous appointment'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(firstCount), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
