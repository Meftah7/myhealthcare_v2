// Suggested booking times (Phase 3): ranked from aggregate clinic history and
// the patient's own visits, never forced, and never exposing other patients.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/services/scheduling/slot_recommender.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 4, 7);
  OpenSlot slot(int hour) => OpenSlot(
    staffId: 'doc',
    start: DateTime(2026, 10, 5, hour),
    end: DateTime(2026, 10, 5, hour, 20),
  );
  SlotDemandStat stat(
    int hour, {
    required int attended,
    required int noShows,
    double? wait,
  }) => SlotDemandStat(
    weekday: DateTime(2026, 10, 5).weekday,
    hour: hour,
    booked: attended + noShows,
    attended: attended,
    noShows: noShows,
    avgWaitMinutes: wait,
  );
  Appointment visit(int hour) => Appointment(
    id: 'a$hour',
    patientId: 'p',
    staffId: 'doc',
    slotStart: DateTime(2026, 9, 1, hour),
    slotEnd: DateTime(2026, 9, 1, hour, 20),
    visitType: VisitType.followUp,
    status: AppointmentStatus.completed,
    bookedAt: DateTime(2026, 8, 25),
    remindersSent: 1,
  );

  group('recommendSlots', () {
    test('with no history it suggests the earliest times', () {
      final recs = recommendSlots(
        slots: [slot(15), slot(9), slot(12), slot(10)],
        staffStats: const [],
        clinicStats: const [],
        patientHistory: const [],
        now: now,
      );
      expect(recs.map((r) => r.slot.start.hour), [9, 10, 12]);
      expect(
        recs.every((r) => r.reasons.single == SlotReason.earliest),
        isTrue,
      );
    });

    test('prefers well-attended, short-wait hours and says why', () {
      final recs = recommendSlots(
        slots: [slot(8), slot(11), slot(16)],
        staffStats: [
          stat(8, attended: 4, noShows: 6, wait: 5),
          stat(11, attended: 9, noShows: 1, wait: 35),
          stat(16, attended: 19, noShows: 1, wait: 6),
        ],
        clinicStats: const [],
        patientHistory: const [],
        now: now,
      );
      expect(recs.first.slot.start.hour, 16);
      expect(recs.first.reasons, contains(SlotReason.reliableHour));
      expect(recs.first.reasons, contains(SlotReason.shortWait));
      expect(recs.first.avgWaitMinutes, 6);
      expect(recs.last.slot.start.hour, 8);
    });

    test("leans towards the patient's usual time", () {
      final recs = recommendSlots(
        slots: [slot(9), slot(17)],
        staffStats: [
          stat(9, attended: 8, noShows: 2),
          stat(17, attended: 8, noShows: 2),
        ],
        clinicStats: const [],
        patientHistory: [visit(17), visit(17), visit(18)],
        now: now,
      );
      expect(recs.first.slot.start.hour, 17);
      expect(recs.first.reasons, contains(SlotReason.yourUsualTime));
    });

    test('falls back to clinic-wide history for a new clinician', () {
      final recs = recommendSlots(
        slots: [slot(8), slot(10)],
        staffStats: const [],
        clinicStats: [
          stat(8, attended: 2, noShows: 8),
          stat(10, attended: 18, noShows: 2, wait: 8),
        ],
        patientHistory: const [],
        now: now,
      );
      expect(recs.first.slot.start.hour, 10);
    });

    test('never drops or invents slots', () {
      final slots = [slot(9), slot(10)];
      final recs = recommendSlots(
        slots: slots,
        staffStats: [stat(10, attended: 9, noShows: 1)],
        clinicStats: const [],
        patientHistory: const [],
        now: now,
        limit: 5,
      );
      expect(recs.map((r) => r.slot).toSet(), slots.toSet());
    });
  });

  group('with seeded data', () {
    late ProviderContainer container;

    setUp(() async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      final login = await container
          .read(sessionProvider.notifier)
          .login(
            email: 'patient3@myhealth.demo',
            password: Seeder.demoPassword,
          );
      expect(login.isOk, isTrue);
    });

    test(
      'a patient reads aggregates only, with small cells left out',
      () async {
        final stats =
            (await container
                    .read(appointmentRepositoryProvider)
                    .slotDemandStats(minSample: 5))
                .valueOrNull!;
        expect(stats, isNotEmpty);
        for (final s in stats) {
          expect(s.booked, greaterThanOrEqualTo(5));
          expect(s.attended + s.noShows, lessThanOrEqualTo(s.booked));
        }
        // The demo pattern: late mornings run behind early afternoons.
        final waits = {
          for (final s in stats)
            if (s.avgWaitMinutes != null) s.hour: s.avgWaitMinutes!,
        };
        if (waits.containsKey(10) && waits.containsKey(14)) {
          expect(waits[10]!, greaterThan(waits[14]!));
        }
      },
    );

    test('suggestions are a subset of the bookable slots', () async {
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

      final all = await container.read(rankedSlotsProvider.future);
      final recs = await container.read(slotRecommendationsProvider.future);
      expect(recs, isNotEmpty);
      expect(recs.length, lessThanOrEqualTo(3));
      for (final r in recs) {
        expect(all.any((s) => identical(s.slot, r.slot)), isTrue);
        expect(r.reasons, isNotEmpty);
      }
      // The full list is unchanged: still every slot, in time order.
      expect(!all.first.slot.start.isAfter(all.last.slot.start), isTrue);
    });
  });
}
