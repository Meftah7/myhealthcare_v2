// Booking wizard UI: with department/doctor/date chosen, the slot list runs
// the full clinic day (opening → closing) with a recommended slot on top, and
// tapping a time books it and returns to Appointments (P4-13, P4-14, P8-10).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/booking/presentation/booking_screen.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('booking: full-day slot list + book a time', (tester) async {
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
      'patient3@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _settle(tester);

    // Appointments tab → Book.
    await tester.tap(find.text('Appointments').last);
    await _settle(tester);
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Book'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Book an appointment'), findsOneWidget);

    // Fill the draft (dept + doctor + a near clinic day) via the provider —
    // the wizard reacts and shows the slot list.
    final depts = await container.read(departmentsProvider.future);
    final staff = await container.read(
      departmentStaffProvider(depts.first.id).future,
    );
    var date = DateTime.now().add(const Duration(days: 3));
    while (date.weekday == DateTime.friday ||
        date.weekday == DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    container.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
      departmentId: depts.first.id,
      staffId: staff.first.id,
      date: DateTime(date.year, date.month, date.day),
    );
    await _settle(tester);

    // Opening → closing list is present with a recommended slot on top.
    expect(find.text('Available times'), findsOneWidget);
    expect(find.textContaining('recommended'), findsOneWidget);
    expect(find.text('ALL OPEN TIMES'), findsOneWidget);

    // A fresh future clinic day opens the whole 08:00–13:40 span (18 × 20-min).
    expect(find.text('08:00'), findsWidgets);
    final tiles = find.descendant(
      of: find.byType(BookingScreen),
      matching: find.byType(ListTile),
    );
    expect(tiles.evaluate().length, greaterThanOrEqualTo(12));

    final before =
        (await container.read(patientAppointmentsProvider.future)).length;

    // Book the recommended slot (first tile).
    await tester.ensureVisible(tiles.first);
    await _settle(tester);
    await tester.tap(tiles.first);
    await _settle(tester);
    expect(find.text('Confirm booking'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Book'));
    await _settle(tester);

    // Landed back on Appointments with the new booking.
    expect(find.widgetWithText(AppBar, 'My appointments'), findsOneWidget);
    final after =
        (await container.read(patientAppointmentsProvider.future)).length;
    expect(after, before + 1);
  });
}
