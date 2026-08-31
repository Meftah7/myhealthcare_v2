// End-to-end integration (P6-05): seed → patient logs in and books an
// AI-ranked slot → the assigned staff member logs in and sees that appointment
// on their week and the patient in their panel.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

/// Seeded staff ids are `staff_01`…`staff_12`; the matching demo email is
/// `staff<n>@myhealth.demo` with no leading zero.
String _staffEmail(String staffId) {
  final n = int.parse(staffId.substring('staff_'.length));
  return 'staff$n@myhealth.demo';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('patient books a slot and the assigned staff member sees it', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    // --- patient books -------------------------------------------------
    final login = await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
    expect(login.isOk, isTrue);
    final patientId = container.read(currentUserProvider)!.id;

    final depts = await container.read(departmentsProvider.future);
    final deptStaff = await container.read(
      departmentStaffProvider(depts.first.id).future,
    );
    final chosenStaff = deptStaff.first;

    var date = DateTime.now().add(const Duration(days: 2));
    while (date.weekday > 5) {
      date = date.add(const Duration(days: 1));
    }
    container.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
      departmentId: depts.first.id,
      staffId: chosenStaff.id,
      date: DateTime(date.year, date.month, date.day),
    );

    final ranked = await container.read(rankedSlotsProvider.future);
    expect(ranked, isNotEmpty);
    final booked = await container
        .read(bookingControllerProvider)
        .confirm(ranked.first);
    expect(booked.isOk, isTrue);
    final apptId = booked.valueOrNull!.id;

    // --- assigned staff signs in and sees it ------------------------
    final staffLogin = await container
        .read(sessionProvider.notifier)
        .login(
          email: _staffEmail(chosenStaff.id),
          password: Seeder.demoPassword,
        );
    expect(staffLogin.isOk, isTrue);
    expect(container.read(currentUserProvider)!.id, chosenStaff.id);

    final weekStart = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    final staffWeek = await container
        .read(appointmentRepositoryProvider)
        .forStaffInRange(
          chosenStaff.id,
          weekStart,
          weekStart.add(const Duration(days: 7)),
        );
    expect(
      staffWeek.valueOrNull!.map((a) => a.id),
      contains(apptId),
      reason: 'the booked appointment shows on the staff week grid',
    );

    final panel = await container.read(staffPanelProvider.future);
    expect(
      panel.map((p) => p.id),
      contains(patientId),
      reason: 'the booking patient is in the staff panel',
    );
  });
}
