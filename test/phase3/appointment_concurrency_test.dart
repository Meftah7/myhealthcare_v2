import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/domain/entities/patient.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late AppointmentRepositoryImpl appointments;
  late AuthRepositoryImpl auth;

  setUp(() {
    db = newTestDatabase();
    appointments = AppointmentRepositoryImpl(db);
    auth = AuthRepositoryImpl(db);
  });

  tearDown(() => db.close());

  Future<Patient> patient(String id) async {
    final result = await auth.registerPatient(
      PatientRegistration(
        fullName: 'Patient $id',
        email: '$id@example.test',
        password: 'Phase3-pass',
      ),
    );
    return result.valueOrNull!;
  }

  Future<void> staffWithSlot(String id, DateTime start) async {
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: id,
            role: UserRole.staff,
            fullName: 'Doctor $id',
            email: '$id@example.test',
            passwordHash: 'test',
            passwordSalt: 'test',
          ),
        );
    await db
        .into(db.scheduleTemplates)
        .insert(
          ScheduleTemplatesCompanion.insert(
            id: 'schedule-$id',
            staffId: id,
            weekday: start.weekday,
            startMinutes: start.hour * 60 + start.minute,
            endMinutes: start.hour * 60 + start.minute + 20,
          ),
        );
  }

  DateTime futureSlot() {
    final day = DateTime.now().add(const Duration(days: 7));
    return DateTime(day.year, day.month, day.day, 10);
  }

  BookingRequest request({
    required String patientId,
    required String staffId,
    required DateTime start,
    IdempotencyKey? key,
  }) => BookingRequest(
    patientId: patientId,
    staffId: staffId,
    start: start,
    end: start.add(const Duration(minutes: 20)),
    visitType: VisitType.followUp,
    idempotencyKey: key,
  );

  test('exactly one concurrent request wins the final slot', () async {
    final first = await patient('phase3-first');
    final second = await patient('phase3-second');
    final start = futureSlot();
    await staffWithSlot('phase3-staff', start);

    final results = await Future.wait([
      appointments.book(
        request(
          patientId: first.id,
          staffId: 'phase3-staff',
          start: start,
          key: const IdempotencyKey('phase3-final-slot-first'),
        ),
      ),
      appointments.book(
        request(
          patientId: second.id,
          staffId: 'phase3-staff',
          start: start,
          key: const IdempotencyKey('phase3-final-slot-second'),
        ),
      ),
    ]);

    expect(results.where((result) => result.isOk), hasLength(1));
    expect(
      results.where((result) => result.failureOrNull is ConflictFailure),
      hasLength(1),
    );
  });

  test(
    'retrying one booking key returns one authoritative appointment',
    () async {
      final owner = await patient('phase3-retry');
      final start = futureSlot();
      await staffWithSlot('phase3-retry-staff', start);
      final booking = request(
        patientId: owner.id,
        staffId: 'phase3-retry-staff',
        start: start,
        key: const IdempotencyKey('phase3-booking-retry'),
      );

      final first = await appointments.book(booking);
      final retry = await appointments.book(booking);
      final rows = await db.select(db.appointments).get();

      expect(first.isOk, isTrue);
      expect(retry.isOk, isTrue);
      expect(retry.valueOrNull!.id, first.valueOrNull!.id);
      expect(rows, hasLength(1));
    },
  );

  test('concurrent bookings issue unique facility tickets', () async {
    final first = await patient('phase3-ticket-first');
    final second = await patient('phase3-ticket-second');
    final start = futureSlot();
    await staffWithSlot('phase3-ticket-staff-a', start);
    await staffWithSlot('phase3-ticket-staff-b', start);

    final results = await Future.wait([
      appointments.book(
        request(
          patientId: first.id,
          staffId: 'phase3-ticket-staff-a',
          start: start,
        ),
      ),
      appointments.book(
        request(
          patientId: second.id,
          staffId: 'phase3-ticket-staff-b',
          start: start,
        ),
      ),
    ]);

    expect(results.every((result) => result.isOk), isTrue);
    expect(
      results.map((result) => result.valueOrNull!.ticketTag).toSet(),
      hasLength(2),
    );
  });

  test('open slots exclude any overlapping active interval', () async {
    final owner = await patient('phase3-overlap');
    final start = futureSlot();
    await staffWithSlot('phase3-overlap-staff', start);
    await db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: 'phase3-overlap-appointment',
            patientId: owner.id,
            staffId: 'phase3-overlap-staff',
            slotStart: start.subtract(const Duration(minutes: 10)),
            slotEnd: start.add(const Duration(minutes: 10)),
            visitType: VisitType.followUp,
          ),
        );

    final slots = await appointments.openSlots('phase3-overlap-staff', start);

    expect(slots.valueOrNull, isEmpty);
  });

  test('booking and reminder plan commit together', () async {
    final owner = await patient('phase3-reminder');
    final start = futureSlot();
    await staffWithSlot('phase3-reminder-staff', start);

    final result = await appointments.book(
      BookingRequest(
        patientId: owner.id,
        staffId: 'phase3-reminder-staff',
        start: start,
        end: start.add(const Duration(minutes: 20)),
        visitType: VisitType.followUp,
        riskBand: RiskBand.low,
        enabledReminderChannels: const {ReminderChannel.push},
      ),
    );

    expect(result.isOk, isTrue);
    final reminders = await db.select(db.reminders).get();
    // One low-risk step, delivered in-app and by browser alert.
    expect(reminders, hasLength(2));
    expect(reminders.map((r) => r.channel).toSet(), {
      ReminderChannel.inApp,
      ReminderChannel.push,
    });
    expect(
      reminders.every((r) => r.appointmentId == result.valueOrNull!.id),
      isTrue,
    );
  });

  test('risk-band change rebuilds queued reminders atomically', () async {
    final owner = await patient('phase3-risk');
    final start = futureSlot();
    await staffWithSlot('phase3-risk-staff', start);
    final booked = await appointments.book(
      request(patientId: owner.id, staffId: 'phase3-risk-staff', start: start),
    );

    final changed = await appointments.updateRiskBand(
      id: booked.valueOrNull!.id,
      staffId: 'phase3-risk-staff',
      riskBand: RiskBand.high,
      expectedVersion: booked.valueOrNull!.version,
    );

    expect(changed.isOk, isTrue);
    final reminders =
        await (db.select(db.reminders)
              ..where((row) => row.appointmentId.equals(booked.valueOrNull!.id))
              ..where(
                (row) => row.deliveryStatus.equalsValue(
                  ReminderDeliveryStatus.queued,
                ),
              ))
            .get();
    // Three high-risk steps; no preference given, so in-app and push.
    expect(reminders, hasLength(6));
  });

  test('availability exception removes and rejects a listed slot', () async {
    final owner = await patient('phase3-exception');
    final start = futureSlot();
    await staffWithSlot('phase3-exception-staff', start);
    final added = await appointments.addAvailabilityException(
      staffId: 'phase3-exception-staff',
      start: start,
      end: start.add(const Duration(minutes: 20)),
      reason: 'Training',
    );
    expect(added.isOk, isTrue);

    final slots = await appointments.openSlots('phase3-exception-staff', start);
    expect(slots.valueOrNull, isEmpty);
    final booking = await appointments.book(
      request(
        patientId: owner.id,
        staffId: 'phase3-exception-staff',
        start: start,
      ),
    );
    expect(booking.failureOrNull, isA<ConflictFailure>());
  });

  test('patient change cutoff preserves the appointment', () async {
    final owner = await patient('phase3-cutoff');
    final day = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(day.year, day.month, day.day, 10);
    await staffWithSlot('phase3-cutoff-staff', start);
    final repo = AppointmentRepositoryImpl(
      db,
      changePolicy: const AppointmentChangePolicy(
        minimumNotice: Duration(days: 2),
      ),
    );
    final booked = await repo.book(
      request(
        patientId: owner.id,
        staffId: 'phase3-cutoff-staff',
        start: start,
      ),
    );
    final cancelled = await repo.cancel(
      booked.valueOrNull!.id,
      patientId: owner.id,
    );
    expect(cancelled.isErr, isTrue);
    expect(
      (await repo.byId(booked.valueOrNull!.id)).valueOrNull!.status,
      AppointmentStatus.booked,
    );
  });

  test('controller restart reuses one authoritative booking outcome', () async {
    final owner = await patient('phase3-restart');
    final start = futureSlot();
    await staffWithSlot('phase3-restart-staff', start);
    const key = IdempotencyKey('phase3-restart-key');
    final booking = request(
      patientId: owner.id,
      staffId: 'phase3-restart-staff',
      start: start,
      key: key,
    );
    final first = await appointments.book(booking);
    final reopenedRepository = AppointmentRepositoryImpl(db);
    final restored = await reopenedRepository.book(booking);

    expect(restored.valueOrNull!.id, first.valueOrNull!.id);
    expect(await db.select(db.appointments).get(), hasLength(1));
  });

  test('patient, staff and admin ranges observe the same state', () async {
    final owner = await patient('phase3-visible');
    final start = futureSlot();
    await staffWithSlot('phase3-visible-staff', start);
    final booked = await appointments.book(
      request(
        patientId: owner.id,
        staffId: 'phase3-visible-staff',
        start: start,
      ),
    );

    final patientView = await appointments.forPatient(owner.id);
    final staffView = await appointments.forStaffOnDay(
      'phase3-visible-staff',
      start,
    );
    final adminView = await appointments.inRange(
      start.subtract(const Duration(hours: 1)),
      start.add(const Duration(hours: 1)),
    );
    expect(
      [
        patientView,
        staffView,
        adminView,
      ].map((result) => result.valueOrNull!.single.id),
      everyElement(booked.valueOrNull!.id),
    );
  });
}
