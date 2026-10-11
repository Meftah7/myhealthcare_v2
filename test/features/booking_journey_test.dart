// Booking journey guarantees (local Drift environment): draft invalidation,
// account-scoped intent, one confirmation at a time, slot conflicts,
// revoked dependent access at confirmation, and the bounded availability
// summary used by doctor search. Uses the seeded synthetic test data.

import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/family_link_repository_impl.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';

import '../support/sessions.dart';

Future<String> _idOf(AppDatabase db, String email) async => (await (db.select(
  db.users,
)..where((u) => u.email.equals(email))).getSingle()).id;

/// A clinician with a schedule and the first future day with open slots.
Future<(String staffId, String departmentId, List<OpenSlot> slots)> _openDay(
  ProviderContainer c,
  AppDatabase db,
) async {
  final templates = await (db.select(
    db.scheduleTemplates,
  )..orderBy([(t) => OrderingTerm(expression: t.staffId)])).get();
  final repo = c.read(appointmentRepositoryProvider);
  final today = DateTime.now();
  for (final staffId in templates.map((t) => t.staffId).toSet()) {
    final profile = await (db.select(
      db.staffProfiles,
    )..where((p) => p.userId.equals(staffId))).getSingleOrNull();
    if (profile?.departmentId == null) continue;
    for (var i = 1; i < 21; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final slots = (await repo.openSlots(staffId, day)).valueOrNull ?? [];
      if (slots.length >= 2) return (staffId, profile!.departmentId!, slots);
    }
  }
  throw StateError('Seed has no clinician with two open slots on one day.');
}

RankedSlot _ranked(OpenSlot s) => RankedSlot(
  slot: s,
  probability: 0,
  band: RiskBand.low,
  reason: 'test',
  hasRiskEstimate: false,
);

Future<int> _bookedCount(
  AppDatabase db,
  String patientId,
  DateTime start,
) async =>
    (await (db.select(db.appointments)..where(
              (a) => a.patientId.equals(patientId) & a.slotStart.equals(start),
            ))
            .get())
        .length;

void main() {
  group('draft invalidation', () {
    final base = BookingRequestDraft(
      departmentId: 'd1',
      staffId: 's1',
      date: DateTime(2030, 1, 2),
      visitType: VisitType.newPatient,
      reason: 'cough',
      bookedForName: 'Sara',
    );

    test('a new department clears only the clinician and date', () {
      final next = base.withDepartment('d2');
      expect(next.departmentId, 'd2');
      expect(next.staffId, isNull);
      expect(next.date, isNull);
      expect(next.visitType, VisitType.newPatient);
      expect(next.reason, 'cough');
      expect(next.bookedForName, 'Sara');
      // Re-selecting the same department changes nothing.
      expect(identical(base.withDepartment('d1'), base), isTrue);
    });

    test('a new clinician keeps the date (re-checked for them)', () {
      final next = base.withStaff('s2');
      expect(next.staffId, 's2');
      expect(next.date, DateTime(2030, 1, 2));
      expect(next.departmentId, 'd1');
    });

    test('booking intent is discarded when the account changes', () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      c.read(bookingDraftProvider.notifier).state = base;
      c.read(bookingTargetPatientIdProvider.notifier).state = 'someone';
      await signInAs(c, 'patient3@myhealth.demo');
      expect(c.read(bookingDraftProvider).departmentId, isNull);
      expect(c.read(bookingTargetPatientIdProvider), isNull);
    });
  });

  group('confirmation', () {
    test('a second confirmation while one is in flight is refused', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      final (staffId, deptId, slots) = await _openDay(c, db);
      c.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
        departmentId: deptId,
        staffId: staffId,
        date: slots.first.start,
      );
      final controller = c.read(bookingControllerProvider);
      final results = await Future.wait([
        controller.confirm(_ranked(slots[0])),
        controller.confirm(_ranked(slots[1])),
      ]);
      expect(results.where((r) => r.isOk), hasLength(1));
      expect(results.last.failureOrNull, isA<ConflictFailure>());
      final me = await _idOf(db, 'patient1@myhealth.demo');
      expect(await _bookedCount(db, me, slots[1].start), 0);
      expect(c.read(bookingInFlightProvider), isFalse);
    });

    test('retrying the same confirmation never books twice', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      final (staffId, deptId, slots) = await _openDay(c, db);
      c.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
        departmentId: deptId,
        staffId: staffId,
      );
      final controller = c.read(bookingControllerProvider);
      final first = await controller.confirm(_ranked(slots[0]));
      expect(first.isOk, isTrue);
      final repo = c.read(appointmentRepositoryProvider);
      final again = await repo.byId(first.valueOrNull!.id);
      expect(again.isOk, isTrue);
      final me = await _idOf(db, 'patient1@myhealth.demo');
      expect(await _bookedCount(db, me, slots[0].start), 1);
    });

    test('a slot taken by someone else is a conflict, never success', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      final (staffId, deptId, slots) = await _openDay(c, db);
      c.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
        departmentId: deptId,
        staffId: staffId,
      );
      expect(
        (await c.read(bookingControllerProvider).confirm(_ranked(slots[0])))
            .isOk,
        isTrue,
      );

      await signInAs(c, 'patient3@myhealth.demo');
      c.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
        departmentId: deptId,
        staffId: staffId,
      );
      final stale = await c
          .read(bookingControllerProvider)
          .confirm(_ranked(slots[0]));
      expect(stale.failureOrNull, isA<ConflictFailure>());
      final other = await _idOf(db, 'patient3@myhealth.demo');
      expect(await _bookedCount(db, other, slots[0].start), 0);
    });

    test(
      'manage access is re-checked at confirmation, not only on entry',
      () async {
        final (c, db) = await seededContainer();
        final viewer = await _idOf(db, 'patient1@myhealth.demo');
        final owner = await _idOf(db, 'patient2@myhealth.demo');
        final links = FamilyLinkRepositoryImpl(db);
        final link = (await links.request(
          ownerPatientId: owner,
          viewerPatientId: viewer,
          permission: FamilyLinkPermission.manage,
        )).valueOrNull!;
        await links.accept(linkId: link.id, actingPatientId: owner);

        await signInAs(c, 'patient1@myhealth.demo');
        final (staffId, deptId, slots) = await _openDay(c, db);
        c.read(bookingTargetPatientIdProvider.notifier).state = owner;
        c.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
          departmentId: deptId,
          staffId: staffId,
        );

        // The owner revokes access after the viewer entered the flow.
        await links.unlink(linkId: link.id, actingPatientId: owner);

        final result = await c
            .read(bookingControllerProvider)
            .confirm(_ranked(slots[0]));
        expect(result.failureOrNull, isA<AuthFailure>());
        expect(await _bookedCount(db, owner, slots[0].start), 0);
      },
    );
  });

  group('availability summary', () {
    test('matches the open-slot rules with a bounded window', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      final (staffId, deptId, slots) = await _openDay(c, db);
      final repo = c.read(appointmentRepositoryProvider);

      final before = (await repo.availabilitySummaries([
        staffId,
      ], days: 21)).valueOrNull![staffId]!;
      expect(before.hasSchedule, isTrue);
      expect(before.windowDays, 21);
      expect(before.openSlotCount, greaterThan(0));
      expect(before.nextSlot, isNotNull);
      // The summary's next slot is a real open slot.
      final day = before.nextSlot!.start;
      final sameDay = (await repo.openSlots(staffId, day)).valueOrNull!;
      expect(sameDay.map((s) => s.start), contains(before.nextSlot!.start));

      // Booking a slot removes it from the summary's count.
      c.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
        departmentId: deptId,
        staffId: staffId,
      );
      final booked = await c
          .read(bookingControllerProvider)
          .confirm(_ranked(slots[0]));
      expect(booked.isOk, isTrue);
      final after = (await repo.availabilitySummaries([
        staffId,
      ], days: 21)).valueOrNull![staffId]!;
      expect(after.openSlotCount, before.openSlotCount - 1);

      // Bounds: window and list size are capped.
      final capped = (await repo.availabilitySummaries([
        staffId,
      ], days: 400)).valueOrNull![staffId]!;
      expect(capped.windowDays, maxSummaryDays);
      final many = (await repo.availabilitySummaries([
        for (var i = 0; i < 80; i++) 'no_such_clinician_$i',
      ])).valueOrNull!;
      expect(many.length, maxSummaryStaff);
      expect(many.values.every((s) => !s.hasSchedule), isTrue);
    });
  });
}
