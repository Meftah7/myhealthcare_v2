// Every appointment — past, present and future — carries a ticket tag and a
// room number, both from the seed and from a fresh booking.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seeded appointments all have a ticket tag and room number', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final rows = await db.select(db.appointments).get();
    expect(rows, isNotEmpty);

    for (final a in rows) {
      expect(
        a.ticketTag,
        isNotNull,
        reason: 'appointment ${a.id} (${a.status}) has no ticket tag',
      );
      expect(a.ticketTag, matches(RegExp(r'^[A-X]-\d+$')));
      expect(
        a.roomNumber,
        isNotNull,
        reason: 'appointment ${a.id} (${a.status}) has no room number',
      );
      expect(a.roomNumber, matches(RegExp(r'^[A-Z?]-\d+$')));
    }
  });

  test('ticket numbers are unique within an hour bucket', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final rows = await db.select(db.appointments).get();
    final byBucket = <String, List<String>>{};
    for (final a in rows) {
      final b = '${a.slotStart.year}-${a.slotStart.month}-'
          '${a.slotStart.day}-${a.slotStart.hour}';
      (byBucket[b] ??= []).add(a.ticketTag!);
    }
    for (final entry in byBucket.entries) {
      expect(
        entry.value.toSet().length,
        entry.value.length,
        reason: 'duplicate ticket in bucket ${entry.key}: ${entry.value}',
      );
    }
  });

  test('a freshly booked appointment gets a ticket and room', () async {
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

    await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);

    final depts = await container.read(departmentsProvider.future);
    final staff = await container.read(
      departmentStaffProvider(depts.first.id).future,
    );
    var date = DateTime.now().add(const Duration(days: 2));
    while (date.weekday == DateTime.friday ||
        date.weekday == DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    container.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
      departmentId: depts.first.id,
      staffId: staff.first.id,
      date: DateTime(date.year, date.month, date.day),
    );

    final ranked = await container.read(rankedSlotsProvider.future);
    final booked = await container
        .read(bookingControllerProvider)
        .confirm(ranked.first);

    expect(booked.isOk, isTrue);
    expect(booked.valueOrNull!.ticketTag, matches(RegExp(r'^[A-X]-\d+$')));
    expect(booked.valueOrNull!.roomNumber, matches(RegExp(r'^[A-Z?]-\d+$')));
  });
}
