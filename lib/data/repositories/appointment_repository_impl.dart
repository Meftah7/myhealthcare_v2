/// Drift-backed [AppointmentRepository] (P1-13).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/ticketing.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../services/auth/access_policy.dart';
import '../../services/notifications/reminder_scheduler.dart';
import '../db/app_database.dart';
import '../sync/idempotency.dart';
import '../sync/outbox.dart';
import 'mappers.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(
    this._db, {
    AccessPolicy? access,
    this.changePolicy = const AppointmentChangePolicy(),
  }) : _access = access ?? AccessPolicy.unenforced(_db),
       _idempotency = IdempotencyGuard(_db),
       _outbox = Outbox(_db);

  final AppDatabase _db;
  final AppointmentChangePolicy changePolicy;
  final AccessPolicy _access;
  final IdempotencyGuard _idempotency;
  final Outbox _outbox;

  static const _bookScope = 'appointment.book';

  /// Optimistic concurrency: refuse a change based on a stale copy.
  static void _requireVersion(AppointmentRow row, int? expected) {
    if (expected != null && row.version != expected) {
      throw ConflictFailure(
        'This appointment was changed by someone else. Reload to see the '
        'latest before trying again.',
        currentVersion: row.version,
      );
    }
  }

  Future<void> _enqueue(List<NewNotification> notify) async {
    for (final n in notify) {
      await _outbox.enqueueNotification(n);
    }
  }

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<Result<Appointment>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.appointments,
      )..where((a) => a.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No appointment $id.');
      await _access.readPatient(
        row.patientId,
        scope: PatientDataScope.administrative,
        entityType: 'appointment',
        entityId: id,
      );
      return row.toEntity();
    });
  }

  @override
  Future<Result<bool>> hasCareRelationship({
    required String staffId,
    required String patientId,
  }) {
    return Result.guardAsync(() async {
      await _access.principal();
      return _access.hasCareRelationship(
        staffId: staffId,
        patientId: patientId,
      );
    });
  }

  @override
  Future<Result<List<Appointment>>> forPatient(
    String patientId, {
    bool upcomingOnly = false,
  }) {
    return Result.guardAsync(() async {
      await _access.readPatient(
        patientId,
        scope: PatientDataScope.administrative,
        entityType: 'appointment',
      );
      final q = _db.select(_db.appointments)
        ..where((a) => a.patientId.equals(patientId))
        ..orderBy([(a) => OrderingTerm.desc(a.slotStart)]);
      if (upcomingOnly) {
        q.where((a) => a.slotStart.isBiggerThanValue(DateTime.now()));
      }
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  SimpleSelectStatement<$AppointmentsTable, AppointmentRow> _forStaffOnDayQuery(
    String staffId,
    DateTime day,
  ) {
    final start = _dayStart(day);
    final end = start.add(const Duration(days: 1));
    return _db.select(_db.appointments)
      ..where(
        (a) =>
            a.staffId.equals(staffId) &
            a.slotStart.isBiggerOrEqualValue(start) &
            a.slotStart.isSmallerThanValue(end),
      )
      ..orderBy([(a) => OrderingTerm(expression: a.slotStart)]);
  }

  @override
  Future<Result<List<Appointment>>> forStaffOnDay(
    String staffId,
    DateTime day,
  ) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'appointment');
      final rows = await _forStaffOnDayQuery(staffId, day).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<Appointment>>> forStaffInRange(
    String staffId,
    DateTime from,
    DateTime to,
  ) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'appointment');
      final rows =
          await (_db.select(_db.appointments)
                ..where(
                  (a) =>
                      a.staffId.equals(staffId) &
                      a.slotStart.isBiggerOrEqualValue(from) &
                      a.slotStart.isSmallerThanValue(to),
                )
                ..orderBy([(a) => OrderingTerm(expression: a.slotStart)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<Appointment>>> inRange(DateTime from, DateTime to) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'appointment');
      final rows =
          await (_db.select(_db.appointments)
                ..where(
                  (a) =>
                      a.slotStart.isBiggerOrEqualValue(from) &
                      a.slotStart.isSmallerThanValue(to),
                )
                ..orderBy([(a) => OrderingTerm(expression: a.slotStart)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<Appointment>> watchForStaffOnDay(String staffId, DateTime day) {
    return authorizedStream(
      () => _access.requireStaffOrAdmin(entityType: 'appointment'),
      () => _forStaffOnDayQuery(
        staffId,
        day,
      ).watch().map((rows) => rows.map((r) => r.toEntity()).toList()),
    );
  }

  @override
  Future<Result<List<SlotDemandStat>>> slotDemandStats({
    String? staffId,
    Duration lookback = const Duration(days: 365),
    int minSample = 5,
  }) {
    return Result.guardAsync(() async {
      await _access.principal();
      final now = DateTime.now();
      final query = _db.select(_db.appointments)
        ..where(
          (a) =>
              a.slotStart.isBiggerOrEqualValue(now.subtract(lookback)) &
              a.slotStart.isSmallerThanValue(now) &
              a.status.isInValues(const [
                AppointmentStatus.completed,
                AppointmentStatus.noShow,
                AppointmentStatus.cancelled,
              ]),
        );
      if (staffId != null) query.where((a) => a.staffId.equals(staffId));
      final rows = await query.get();

      // Aggregate here so no individual visit leaves the data layer.
      final cells = <(int, int), List<AppointmentRow>>{};
      for (final r in rows) {
        cells
            .putIfAbsent((r.slotStart.weekday, r.slotStart.hour), () => [])
            .add(r);
      }
      return [
        for (final MapEntry(key: (weekday, hour), value: visits)
            in cells.entries)
          if (visits.length >= minSample) _statFor(weekday, hour, visits),
      ];
    });
  }

  static SlotDemandStat _statFor(
    int weekday,
    int hour,
    List<AppointmentRow> visits,
  ) {
    final waits = [
      for (final v in visits)
        if (v.status == AppointmentStatus.completed && v.calledInAt != null)
          v.calledInAt!.difference(v.slotStart).inMinutes.clamp(0, 240),
    ];
    return SlotDemandStat(
      weekday: weekday,
      hour: hour,
      booked: visits.length,
      attended: visits
          .where((v) => v.status == AppointmentStatus.completed)
          .length,
      noShows: visits.where((v) => v.status == AppointmentStatus.noShow).length,
      avgWaitMinutes: waits.isEmpty
          ? null
          : waits.reduce((a, b) => a + b) / waits.length,
    );
  }

  @override
  Future<Result<int>> markOverdueNoShows({
    Duration grace = const Duration(minutes: 30),
    DateTime? now,
  }) {
    return Result.guardAsync(() async {
      final cutoff = (now ?? DateTime.now()).subtract(grace);
      return _db.transaction(() async {
        final overdue =
            await (_db.select(_db.appointments)..where(
                  (a) =>
                      a.status.isInValues(const [
                        AppointmentStatus.booked,
                        AppointmentStatus.confirmed,
                      ]) &
                      a.checkedInAt.isNull() &
                      a.calledInAt.isNull() &
                      a.slotStart.isSmallerThanValue(cutoff),
                ))
                .get();
        for (final row in overdue) {
          await (_db.update(
            _db.appointments,
          )..where((a) => a.id.equals(row.id))).write(
            const AppointmentsCompanion(
              status: Value(AppointmentStatus.noShow),
            ),
          );
          await _access.audit(
            'appointment.auto_no_show',
            entityType: 'appointment',
            entityId: row.id,
            subjectPatientId: row.patientId,
            detail: 'Not arrived ${grace.inMinutes} min after the start time',
          );
        }
        return overdue.length;
      });
    });
  }

  @override
  Future<Result<List<OpenSlot>>> openSlots(String staffId, DateTime day) {
    return Result.guardAsync(() async {
      await _access.principal();
      final raw = await _templateSlotsFor(staffId, day);
      if (raw.isEmpty) return const <OpenSlot>[];

      final booked = await _forStaffOnDayQuery(staffId, day).get();
      final dayStart = _dayStart(day);
      final exceptions =
          await (_db.select(_db.availabilityExceptions)..where(
                (e) =>
                    e.staffId.equals(staffId) &
                    e.startsAt.isSmallerThanValue(
                      dayStart.add(const Duration(days: 1)),
                    ) &
                    e.endsAt.isBiggerThanValue(dayStart),
              ))
              .get();
      final active = booked
          .where((a) => a.status != AppointmentStatus.cancelled)
          .toList();

      final slots =
          raw
              .where(
                (s) =>
                    s.start.isAfter(DateTime.now()) &&
                    !active.any(
                      (a) =>
                          a.slotStart.isBefore(s.end) &&
                          a.slotEnd.isAfter(s.start),
                    ) &&
                    !exceptions.any(
                      (e) =>
                          e.startsAt.isBefore(s.end) &&
                          e.endsAt.isAfter(s.start),
                    ),
              )
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));
      return slots;
    });
  }

  /// Every slot boundary [staffId]'s schedule templates generate for [day],
  /// ignoring whether it's already booked or in the past — the raw grid, not
  /// what's actually available. Shared by [openSlots] (which filters it) and
  /// [_isOnScheduleGrid] (which just needs to know a boundary is legitimate).
  Future<List<OpenSlot>> _templateSlotsFor(String staffId, DateTime day) async {
    final settings = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    final openDays = settings?.clinicOpenDays
        ?.split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    if (openDays != null && !openDays.contains(day.weekday)) {
      return const [];
    }
    final clinicOpenMinutes = (settings?.clinicOpenHour ?? 8) * 60;
    final clinicCloseMinutes = (settings?.clinicCloseHour ?? 20) * 60;
    final templates =
        await (_db.select(_db.scheduleTemplates)..where(
              (t) => t.staffId.equals(staffId) & t.weekday.equals(day.weekday),
            ))
            .get();
    final dayStart = _dayStart(day);
    final slots = <OpenSlot>[];
    for (final t in templates) {
      var cursor = t.startMinutes;
      while (cursor < clinicOpenMinutes) {
        cursor += t.slotMinutes;
      }
      final closingBoundary = t.endMinutes < clinicCloseMinutes
          ? t.endMinutes
          : clinicCloseMinutes;
      while (cursor + t.slotMinutes <= closingBoundary) {
        final start = dayStart.add(Duration(minutes: cursor));
        final end = start.add(Duration(minutes: t.slotMinutes));
        slots.add(
          OpenSlot(staffId: staffId, start: start, end: end, resourceId: t.id),
        );
        cursor += t.slotMinutes;
      }
    }
    return slots;
  }

  /// True when `[start, end)` exactly matches one of [staffId]'s real
  /// schedule-template slot boundaries — independent of whether it's booked
  /// (that's [_hasOverlap]'s job) or in the past (checked separately), this
  /// just asks "is this a legitimate slot on the grid at all."
  Future<bool> _isOnScheduleGrid({
    required String staffId,
    required DateTime start,
    required DateTime end,
  }) async {
    final raw = await _templateSlotsFor(staffId, start);
    return raw.any((s) => s.start == start && s.end == end);
  }

  Future<bool> _hasAvailabilityException({
    required String staffId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows =
        await (_db.select(_db.availabilityExceptions)..where(
              (e) =>
                  e.staffId.equals(staffId) &
                  e.startsAt.isSmallerThanValue(end) &
                  e.endsAt.isBiggerThanValue(start),
            ))
            .get();
    return rows.isNotEmpty;
  }

  @override
  Future<Result<List<ScheduleTemplate>>> templatesFor(String staffId) {
    return Result.guardAsync(() async {
      await _access.principal();
      final rows =
          await (_db.select(_db.scheduleTemplates)
                ..where((t) => t.staffId.equals(staffId))
                ..orderBy([(t) => OrderingTerm(expression: t.weekday)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<ScheduleTemplate>>> setTemplates({
    required String staffId,
    required List<NewScheduleTemplate> templates,
  }) {
    return Result.guardAsync(() async {
      // A clinician edits their own schedule; an administrator anyone's.
      final actor = await _access.principal();
      if (actor != null && actor.isStaff) {
        await _access.actAsStaff(
          staffId,
          Permission.manageOwnSchedule,
          entityType: 'schedule',
          entityId: staffId,
        );
      } else if (actor != null) {
        await _access.require(
          Permission.manageClinicSchedules,
          entityType: 'schedule',
          entityId: staffId,
        );
      }
      for (final t in templates) {
        if (t.startMinutes >= t.endMinutes) {
          throw const ValidationFailure('Start time must be before end time.');
        }
        if (t.slotMinutes <= 0) {
          throw const ValidationFailure(
            'Slot length must be greater than zero.',
          );
        }
      }
      // Two templates for the same weekday that overlap in time would make
      // `openSlots` generate the same wall-clock slot twice from different
      // sources — reject that combination outright.
      final byWeekday = <int, List<NewScheduleTemplate>>{};
      for (final t in templates) {
        byWeekday.putIfAbsent(t.weekday, () => []).add(t);
      }
      for (final group in byWeekday.values) {
        for (var i = 0; i < group.length; i++) {
          for (var j = i + 1; j < group.length; j++) {
            final a = group[i];
            final b = group[j];
            if (a.startMinutes < b.endMinutes &&
                a.endMinutes > b.startMinutes) {
              throw const ValidationFailure(
                'Two schedules for the same day overlap. Adjust the times.',
              );
            }
          }
        }
      }
      final existingAppointments =
          await (_db.select(_db.appointments)..where(
                (a) =>
                    a.staffId.equals(staffId) &
                    a.slotStart.isBiggerThanValue(DateTime.now()) &
                    a.status.isInValues([
                      AppointmentStatus.booked,
                      AppointmentStatus.confirmed,
                    ]),
              ))
              .get();
      for (final appointment in existingAppointments) {
        final startMinutes =
            appointment.slotStart.hour * 60 + appointment.slotStart.minute;
        final endMinutes =
            appointment.slotEnd.hour * 60 + appointment.slotEnd.minute;
        final covered = templates.any(
          (template) =>
              template.weekday == appointment.slotStart.weekday &&
              startMinutes >= template.startMinutes &&
              endMinutes <= template.endMinutes &&
              endMinutes - startMinutes == template.slotMinutes &&
              (startMinutes - template.startMinutes) % template.slotMinutes ==
                  0,
        );
        if (!covered) {
          throw const ValidationFailure(
            'The new schedule conflicts with an existing appointment.',
          );
        }
      }
      await _db.transaction(() async {
        await (_db.delete(
          _db.scheduleTemplates,
        )..where((t) => t.staffId.equals(staffId))).go();
        for (final t in templates) {
          await _db
              .into(_db.scheduleTemplates)
              .insert(
                ScheduleTemplatesCompanion.insert(
                  id: newId('sched'),
                  staffId: staffId,
                  weekday: t.weekday,
                  startMinutes: t.startMinutes,
                  endMinutes: t.endMinutes,
                  slotMinutes: Value(t.slotMinutes),
                ),
              );
        }
      });
      final rows =
          await (_db.select(_db.scheduleTemplates)
                ..where((t) => t.staffId.equals(staffId))
                ..orderBy([(t) => OrderingTerm(expression: t.weekday)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<AvailabilityException>> addAvailabilityException({
    required String staffId,
    required DateTime start,
    required DateTime end,
    String? reason,
  }) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'availability_exception');
      final actor = await _access.principal();
      if (actor?.isStaff == true) {
        await _access.actAsStaff(
          staffId,
          Permission.manageOwnSchedule,
          entityType: 'availability_exception',
        );
      } else if (actor?.isAdmin == true) {
        await _access.require(
          Permission.manageClinicSchedules,
          entityType: 'availability_exception',
        );
      }
      await _access.selfOrAdmin(
        staffId,
        Permission.manageClinicSchedules,
        entityType: 'availability_exception',
      );
      if (reason == null || reason.trim().isEmpty) {
        throw const ValidationFailure('Record a time-off reason.');
      }
      if (!end.isAfter(start)) {
        throw const ValidationFailure('Exception end must be after its start.');
      }
      var id = newId('availability');
      await _db.transaction(() async {
        final existing =
            await (_db.select(_db.availabilityExceptions)..where(
                  (e) =>
                      e.staffId.equals(staffId) &
                      e.startsAt.equals(start) &
                      e.endsAt.equals(end) &
                      e.reason.equals(reason.trim()),
                ))
                .get();
        if (existing.isNotEmpty) {
          id = existing.first.id;
          return;
        }
        await _db
            .into(_db.availabilityExceptions)
            .insert(
              AvailabilityExceptionsCompanion.insert(
                id: id,
                staffId: staffId,
                startsAt: start,
                endsAt: end,
                reason: Value(reason.trim()),
              ),
            );
        final affected =
            await (_db.select(_db.appointments)..where(
                  (a) =>
                      a.staffId.equals(staffId) &
                      a.slotStart.isSmallerThanValue(end) &
                      a.slotEnd.isBiggerThanValue(start) &
                      a.status.isNotIn([
                        AppointmentStatus.cancelled.name,
                        AppointmentStatus.noShow.name,
                        AppointmentStatus.completed.name,
                      ]),
                ))
                .get();
        if (actor?.isAdmin == true && affected.isNotEmpty) {
          throw const ValidationFailure(
            'Preview affected bookings and assign a replacement before changing availability.',
          );
        }
        for (final visit in affected) {
          await _db
              .into(_db.notifications)
              .insert(
                NotificationsCompanion.insert(
                  id: newId('notice'),
                  recipientId: visit.patientId,
                  category: NotificationCategory.appointment,
                  title: 'Your appointment needs schedule review',
                  body:
                      'The clinic is reviewing staff availability for your booking. Your booking remains assigned; contact the clinic for confirmation.',
                  deepLink: const Value('/patient/appointments'),
                  sourceEventId: Value('availability:$id:${visit.id}'),
                ),
              );
        }
        await _access.audit(
          'schedule.timeoff.recorded',
          entityType: 'availability_exception',
          entityId: id,
          detail:
              '${affected.length} affected bookings; in-app notices delivered; ownership retained.',
        );
      });
      return AvailabilityException(
        id: id,
        staffId: staffId,
        start: start,
        end: end,
        reason: reason.trim(),
      );
    });
  }

  @override
  Future<Result<List<AvailabilityException>>> availabilityExceptions(
    String staffId,
    DateTime from,
    DateTime to,
  ) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'availability_exception');
      await _access.selfOrAdmin(
        staffId,
        Permission.manageClinicSchedules,
        entityType: 'availability_exception',
      );
      final rows =
          await (_db.select(_db.availabilityExceptions)..where(
                (e) =>
                    e.staffId.equals(staffId) &
                    e.startsAt.isSmallerThanValue(to) &
                    e.endsAt.isBiggerThanValue(from),
              ))
              .get();
      return [
        for (final row in rows)
          AvailabilityException(
            id: row.id,
            staffId: row.staffId,
            start: row.startsAt,
            end: row.endsAt,
            reason: row.reason,
            version: row.version,
          ),
      ];
    });
  }

  @override
  Future<Result<Appointment>> book(BookingRequest r) async {
    // Authorize before the transaction so a denial's audit row survives.
    final String? bookedBy;
    try {
      bookedBy = await _authorizeBooking(r.patientId);
    } on Failure catch (f) {
      return Err(f);
    }
    // A visit for someone else must be booked on *their* record. A name
    // stamped on the booker's own record would put the visit — and every
    // note and invoice after it — on the wrong patient's chart.
    if (r.bookedForName != null &&
        bookedBy != null &&
        bookedBy == r.patientId) {
      return const Err(
        ValidationFailure(
          'Choose the family member so the visit is booked on their record.',
        ),
      );
    }
    // The whole thing — the overlap check, the ticket-count read, and the
    // insert — runs as one transaction. SQLite serializes writers, so two
    // concurrent bookings can no longer both pass the check (a stale read
    // racing an insert) and no longer both land on the same ticket count.
    return Result.guardAsync(
      () => _db.transaction(() async {
        // A retry of a booking that already committed gets that booking
        // back — it never books (or notifies) twice.
        final prior = await _idempotency.prior(
          r.idempotencyKey,
          scope: _bookScope,
          actorAccountId: bookedBy,
        );
        if (prior != null) {
          final existing = await (_db.select(
            _db.appointments,
          )..where((a) => a.id.equals(prior))).getSingle();
          return existing.toEntity();
        }
        if (r.end.isBefore(r.start) || r.end.isAtSameMomentAs(r.start)) {
          throw const ValidationFailure('The visit must end after it starts.');
        }
        if (!r.start.isAfter(DateTime.now())) {
          throw const ValidationFailure(
            'That time has already passed. Choose a later slot.',
          );
        }
        if (!await _isOnScheduleGrid(
          staffId: r.staffId,
          start: r.start,
          end: r.end,
        )) {
          throw const ValidationFailure(
            "That time isn't on this clinician's schedule. Choose a listed slot.",
          );
        }
        if (await _hasAvailabilityException(
          staffId: r.staffId,
          start: r.start,
          end: r.end,
        )) {
          throw const ConflictFailure(
            'That clinician is unavailable at this time.',
          );
        }
        if (await _hasOverlap(staffId: r.staffId, start: r.start, end: r.end)) {
          throw const ConflictFailure('That slot was just taken.');
        }
        final slot = (await _templateSlotsFor(r.staffId, r.start)).firstWhere(
          (candidate) => candidate.start == r.start && candidate.end == r.end,
        );
        final reservation = BookingReservation(
          resourceId: slot.resourceId ?? r.staffId,
          start: r.start,
          end: r.end,
          capacity: slot.capacity,
          resourceVersion: slot.version,
        );
        if (reservation.capacity < 1) {
          throw const ConflictFailure('That slot has no remaining capacity.');
        }

        final id = newId('appt');
        final ticketTag = await _issueTicketTag(r.start);
        // Every appointment gets a room. If the request didn't name a
        // department, fall back to the doctor's own.
        final departmentId = r.departmentId ?? await _departmentOf(r.staffId);
        final roomNumber = departmentId == null
            ? null
            : await _assignRoomNumber(departmentId, r.staffId);
        await _db
            .into(_db.appointments)
            .insert(
              AppointmentsCompanion.insert(
                id: id,
                patientId: r.patientId,
                staffId: r.staffId,
                slotStart: r.start,
                slotEnd: r.end,
                visitType: r.visitType,
                departmentId: Value(departmentId),
                reasonText: Value(r.reasonText),
                noShowRisk: Value(r.noShowRisk),
                riskBand: Value(r.riskBand),
                ticketTag: Value(ticketTag),
                roomNumber: Value(roomNumber),
                bookedForName: Value(r.bookedForName),
                bookedByAccountId: Value(bookedBy),
              ),
            );

        await _idempotency.remember(
          r.idempotencyKey,
          scope: _bookScope,
          actorAccountId: bookedBy,
          resultRef: id,
        );
        await _enqueue(r.notify);
        await _rebuildReminders(
          appointmentId: id,
          slotStart: r.start,
          band: r.riskBand ?? RiskBand.low,
          enabledChannels: r.enabledReminderChannels,
        );
        // Reminder scheduling for a fresh booking stays with the caller
        // (`booking_providers.dart`/`quick_appointment_providers.dart`),
        // which already calls `ReminderScheduler.scheduleFor` right after —
        // duplicating that here would just make it run twice. `reschedule`
        // and `cancel` below use `_rebuildReminders` directly because,
        // unlike booking, nothing else currently handles it for them.
        final row = await (_db.select(
          _db.appointments,
        )..where((a) => a.id.equals(id))).getSingle();
        return row.toEntity();
      }),
    );
  }

  /// A patient (or a proxy with a manage grant) books for that patient; an
  /// administrator books on a patient's behalf. Returns the acting account.
  Future<String?> _authorizeBooking(String patientId) async {
    final actor = await _access.principal();
    if (actor == null) return null;
    if (actor.isAdmin) {
      await _access.require(
        Permission.manageClinicSchedules,
        entityType: 'appointment',
      );
      await _access.audit(
        'appointment.book_on_behalf',
        entityType: 'appointment',
        subjectPatientId: patientId,
      );
      return actor.accountId;
    }
    final subject = await _access.actForPatient(
      patientId,
      Permission.bookAppointments,
      entityType: 'appointment',
    );
    if (!subject.isSelf) {
      await _access.audit(
        'proxy.appointment.book',
        entityType: 'appointment',
        subjectPatientId: patientId,
      );
    }
    return subject.actingAccountId;
  }

  /// A patient-side change to an existing appointment. Authorizes against
  /// the appointment's *stored* patient, so a caller cannot reach another
  /// patient's visit by passing a patient ID it does control.
  Future<void> _authorizePatientChange(
    String id,
    String patientId,
    String action,
  ) async {
    final row = await (_db.select(
      _db.appointments,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundFailure('No appointment $id.');
    if (row.patientId != patientId) {
      throw const AccessDeniedFailure(
        'You do not have permission to change this appointment.',
      );
    }
    final subject = await _access.actForPatient(
      row.patientId,
      Permission.bookAppointments,
      entityType: 'appointment',
      entityId: id,
    );
    if (!subject.isSelf) {
      await _access.audit(
        'proxy.appointment.$action',
        entityType: 'appointment',
        entityId: id,
        subjectPatientId: row.patientId,
      );
    }
  }

  /// True when [staffId] already has an active (non-cancelled) appointment
  /// whose interval overlaps `[start, end)` — the standard
  /// `existing.start < end && existing.end > start` test, not just an
  /// exact-start-time match, so two differently-aligned bookings (e.g. from
  /// two schedule templates, or a free-form admin time entry) can't overlap.
  Future<bool> _hasOverlap({
    required String staffId,
    required DateTime start,
    required DateTime end,
    String? excludingAppointmentId,
  }) async {
    var q = _db.select(_db.appointments)
      ..where(
        (a) =>
            a.staffId.equals(staffId) &
            a.status.equalsValue(AppointmentStatus.cancelled).not() &
            a.slotStart.isSmallerThanValue(end) &
            a.slotEnd.isBiggerThanValue(start),
      );
    if (excludingAppointmentId != null) {
      q = q..where((a) => a.id.equals(excludingAppointmentId).not());
    }
    return (await q.get()).isNotEmpty;
  }

  Future<void> _rebuildReminders({
    required String appointmentId,
    required DateTime slotStart,
    required RiskBand band,
    Set<ReminderChannel>? enabledChannels,
  }) async {
    await (_db.update(_db.reminders)..where(
          (r) =>
              r.appointmentId.equals(appointmentId) &
              r.deliveryStatus.equalsValue(ReminderDeliveryStatus.queued),
        ))
        .write(
          const RemindersCompanion(
            deliveryStatus: Value(ReminderDeliveryStatus.suppressed),
          ),
        );
    final now = DateTime.now();
    final channels = reminderChannelsFor(enabledChannels);
    for (final plan in reminderPlanFor(band)) {
      final at = slotStart.subtract(plan.offsetBeforeSlot);
      if (at.isBefore(now)) continue; // no point scheduling the past
      for (final channel in channels) {
        await _db
            .into(_db.reminders)
            .insert(
              RemindersCompanion.insert(
                id: newId('rem'),
                appointmentId: appointmentId,
                scheduledFor: at,
                channel: channel,
                kind: Value(plan.kind),
              ),
            );
      }
    }
  }

  /// `[hour letter]-[facility-wide count of tickets already issued for that
  /// local hour bucket, plus one]` — a fresh count per calendar day since the
  /// bucket is the exact hour of [slotStart] (P8-xx redesign v2).
  Future<String> _issueTicketTag(DateTime slotStart) async {
    final bucketStart = DateTime(
      slotStart.year,
      slotStart.month,
      slotStart.day,
      slotStart.hour,
    );
    final bucketEnd = bucketStart.add(const Duration(hours: 1));
    final existing =
        await (_db.select(_db.appointments)..where(
              (a) =>
                  a.slotStart.isBiggerOrEqualValue(bucketStart) &
                  a.slotStart.isSmallerThanValue(bucketEnd),
            ))
            .get();
    return '${hourLetterFor(slotStart)}-${existing.length + 1}';
  }

  /// `[department letter]-[this doctor's 1-based position among that
  /// department's staff, ordered by join date]`.
  Future<String?> _departmentOf(String staffId) async {
    final profile = await (_db.select(
      _db.staffProfiles,
    )..where((p) => p.userId.equals(staffId))).getSingleOrNull();
    return profile?.departmentId;
  }

  Future<String?> _assignRoomNumber(String departmentId, String staffId) async {
    final department = await (_db.select(
      _db.departments,
    )..where((d) => d.id.equals(departmentId))).getSingleOrNull();
    if (department == null) return null;

    final profiles = await (_db.select(
      _db.staffProfiles,
    )..where((p) => p.departmentId.equals(departmentId))).get();
    final ids = profiles.map((p) => p.userId).toList();
    if (ids.isEmpty) return null;
    // `createdAt` then `id` as a stable tiebreaker — seeded demo staff all
    // share one backdated `createdAt`, so `id` (assigned in listing order)
    // is what actually orders them.
    final staffByJoinDate =
        await (_db.select(_db.users)
              ..where((u) => u.id.isIn(ids))
              ..orderBy([
                (u) => OrderingTerm(expression: u.createdAt),
                (u) => OrderingTerm(expression: u.id),
              ]))
            .get();
    final sequence = staffByJoinDate.indexWhere((u) => u.id == staffId) + 1;
    if (sequence <= 0) return null;
    return '${departmentLetterFor(department.name)}-$sequence';
  }

  static const _reschedulableStatuses = {
    AppointmentStatus.booked,
    AppointmentStatus.confirmed,
  };

  @override
  Future<Result<Appointment>> reschedule({
    required String id,
    required String patientId,
    required DateTime newStart,
    required DateTime newEnd,
    Set<ReminderChannel>? enabledChannels,
    int? expectedVersion,
  }) async {
    try {
      await _authorizePatientChange(id, patientId, 'reschedule');
    } on Failure catch (f) {
      return Err(f);
    }
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await (_db.select(
          _db.appointments,
        )..where((a) => a.id.equals(id))).getSingleOrNull();
        if (row == null) throw NotFoundFailure('No appointment $id.');
        // A caller with permission over one patient's appointments (e.g. a
        // family "manage" link) must not be able to reach a *different*
        // patient's appointment just by knowing/guessing its ID.
        if (row.patientId != patientId) {
          throw const AuthFailure(
            'You do not have permission to change this appointment.',
          );
        }
        _requireVersion(row, expectedVersion);
        if (!_reschedulableStatuses.contains(row.status)) {
          throw const ValidationFailure(
            'This appointment can no longer be rescheduled.',
          );
        }
        if (newEnd.isBefore(newStart) || newEnd.isAtSameMomentAs(newStart)) {
          throw const ValidationFailure('The visit must end after it starts.');
        }
        if (!newStart.isAfter(DateTime.now())) {
          throw const ValidationFailure(
            'That time has already passed. Choose a later slot.',
          );
        }
        if (newStart.difference(DateTime.now()) < changePolicy.minimumNotice) {
          throw const ValidationFailure(
            'This appointment is inside the change cutoff window.',
          );
        }
        if (!await _isOnScheduleGrid(
          staffId: row.staffId,
          start: newStart,
          end: newEnd,
        )) {
          throw const ValidationFailure(
            "That time isn't on this clinician's schedule. Choose a listed slot.",
          );
        }
        if (await _hasAvailabilityException(
          staffId: row.staffId,
          start: newStart,
          end: newEnd,
        )) {
          throw const ConflictFailure(
            'That clinician is unavailable at this time.',
          );
        }
        if (await _hasOverlap(
          staffId: row.staffId,
          start: newStart,
          end: newEnd,
          excludingAppointmentId: id,
        )) {
          throw const ConflictFailure(
            'That slot is no longer available. Choose another.',
          );
        }

        await (_db.update(
          _db.appointments,
        )..where((a) => a.id.equals(id))).write(
          AppointmentsCompanion(
            slotStart: Value(newStart),
            slotEnd: Value(newEnd),
            status: const Value(AppointmentStatus.booked),
          ),
        );
        await _rebuildReminders(
          appointmentId: id,
          slotStart: newStart,
          band: row.riskBand ?? RiskBand.low,
          enabledChannels: enabledChannels,
        );

        final updated = await (_db.select(
          _db.appointments,
        )..where((a) => a.id.equals(id))).getSingle();
        await _access.audit(
          'appointment.reschedule',
          entityType: 'appointment',
          entityId: id,
          subjectPatientId: row.patientId,
        );
        return updated.toEntity();
      }),
    );
  }

  @override
  Future<Result<void>> cancel(
    String id, {
    required String patientId,
    int? expectedVersion,
  }) async {
    try {
      await _authorizePatientChange(id, patientId, 'cancel');
    } on Failure catch (f) {
      return Err(f);
    }
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await (_db.select(
          _db.appointments,
        )..where((a) => a.id.equals(id))).getSingleOrNull();
        if (row == null) throw NotFoundFailure('No appointment $id.');
        if (row.patientId != patientId) {
          throw const AuthFailure(
            'You do not have permission to cancel this appointment.',
          );
        }
        _requireVersion(row, expectedVersion);
        if (!_reschedulableStatuses.contains(row.status) ||
            row.checkedInAt != null) {
          throw const ValidationFailure(
            'This appointment can no longer be cancelled.',
          );
        }
        if (row.slotStart.difference(DateTime.now()) <
            changePolicy.minimumNotice) {
          throw const ValidationFailure(
            'This appointment is inside the cancellation cutoff window.',
          );
        }
        await (_db.update(
          _db.appointments,
        )..where((a) => a.id.equals(id))).write(
          const AppointmentsCompanion(
            status: Value(AppointmentStatus.cancelled),
          ),
        );
        await (_db.update(_db.reminders)..where(
              (r) =>
                  r.appointmentId.equals(id) &
                  r.deliveryStatus.equalsValue(ReminderDeliveryStatus.queued),
            ))
            .write(
              const RemindersCompanion(
                deliveryStatus: Value(ReminderDeliveryStatus.suppressed),
              ),
            );
        await _access.audit(
          'appointment.cancel',
          entityType: 'appointment',
          entityId: id,
          subjectPatientId: row.patientId,
        );
      }),
    );
  }

  /// Loads the appointment and verifies [staffId] matches its current
  /// clinician — every staff-side mutation below goes through this so a
  /// clinician can't act on a colleague's visit just by knowing its ID.
  /// The principal must *be* [staffId] (checked before any transaction so a
  /// denial's audit row is kept).
  Future<Failure?> _staffDenial(String id, String staffId) async {
    try {
      await _access.actAsStaff(
        staffId,
        Permission.runConsultation,
        entityType: 'appointment',
        entityId: id,
      );
      return null;
    } on Failure catch (f) {
      return f;
    }
  }

  Future<AppointmentRow> _ownedByStaff(
    String id,
    String staffId, [
    int? expectedVersion,
  ]) async {
    final row = await (_db.select(
      _db.appointments,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundFailure('No appointment $id.');
    if (row.staffId != staffId) {
      throw const AuthFailure(
        'This appointment is assigned to a different clinician.',
      );
    }
    _requireVersion(row, expectedVersion);
    return row;
  }

  bool _canTransition(AppointmentStatus from, AppointmentStatus to) =>
      switch (from) {
        AppointmentStatus.booked =>
          to == AppointmentStatus.confirmed ||
              to == AppointmentStatus.cancelled ||
              to == AppointmentStatus.noShow,
        AppointmentStatus.confirmed =>
          to == AppointmentStatus.inProgress ||
              to == AppointmentStatus.cancelled ||
              to == AppointmentStatus.noShow,
        AppointmentStatus.inProgress =>
          to == AppointmentStatus.completed ||
              to == AppointmentStatus.cancelled ||
              to == AppointmentStatus.noShow,
        AppointmentStatus.completed ||
        AppointmentStatus.cancelled ||
        AppointmentStatus.noShow => false,
      };

  void _requireTransition(AppointmentStatus from, AppointmentStatus to) {
    if (!_canTransition(from, to)) {
      throw ValidationFailure(
        'Cannot change an appointment from ${from.name} to ${to.name}.',
      );
    }
  }

  @override
  Future<Result<void>> updateStatus({
    required String id,
    required String staffId,
    required AppointmentStatus status,
    int? expectedVersion,
  }) async {
    final denied = await _staffDenial(id, staffId);
    if (denied != null) return Err(denied);
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await _ownedByStaff(id, staffId, expectedVersion);
        _requireTransition(row.status, status);
        await (_db.update(_db.appointments)..where((a) => a.id.equals(id)))
            .write(AppointmentsCompanion(status: Value(status)));
      }),
    );
  }

  @override
  Future<Result<void>> updateRiskBand({
    required String id,
    required String staffId,
    required RiskBand riskBand,
    Set<ReminderChannel>? enabledChannels,
    int? expectedVersion,
  }) async {
    final denied = await _staffDenial(id, staffId);
    if (denied != null) return Err(denied);
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await _ownedByStaff(id, staffId, expectedVersion);
        if (!_reschedulableStatuses.contains(row.status)) {
          throw const ValidationFailure(
            'A closed or active appointment cannot change reminder risk.',
          );
        }
        await (_db.update(_db.appointments)..where((a) => a.id.equals(id)))
            .write(AppointmentsCompanion(riskBand: Value(riskBand)));
        await _rebuildReminders(
          appointmentId: id,
          slotStart: row.slotStart,
          band: riskBand,
          enabledChannels: enabledChannels,
        );
        await _access.audit(
          'appointment.risk_band.update',
          entityType: 'appointment',
          entityId: id,
          subjectPatientId: row.patientId,
          detail: riskBand.name,
        );
      }),
    );
  }

  @override
  Future<Result<void>> markCheckedIn(
    String id, {
    required String staffId,
    required DateTime at,
    int? expectedVersion,
  }) async {
    final denied = await _staffDenial(id, staffId);
    if (denied != null) return Err(denied);
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await _ownedByStaff(id, staffId, expectedVersion);
        _requireTransition(row.status, AppointmentStatus.confirmed);
        await (_db.update(
          _db.appointments,
        )..where((a) => a.id.equals(id))).write(
          AppointmentsCompanion(
            checkedInAt: Value(at),
            status: const Value(AppointmentStatus.confirmed),
          ),
        );
      }),
    );
  }

  @override
  Future<Result<void>> markCalledIn(
    String id, {
    required String staffId,
    required DateTime at,
    int? expectedVersion,
    List<NewNotification> notify = const [],
  }) async {
    final denied = await _staffDenial(id, staffId);
    if (denied != null) return Err(denied);
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await _ownedByStaff(id, staffId, expectedVersion);
        if (row.status == AppointmentStatus.completed ||
            row.status == AppointmentStatus.cancelled ||
            row.status == AppointmentStatus.noShow) {
          throw const ValidationFailure(
            'A closed appointment cannot be called in.',
          );
        }
        await (_db.update(_db.appointments)..where((a) => a.id.equals(id)))
            .write(AppointmentsCompanion(calledInAt: Value(at)));
        await _enqueue(notify);
      }),
    );
  }

  @override
  Future<Result<void>> markArrived(
    String id, {
    required String staffId,
    required DateTime at,
    int? expectedVersion,
  }) async {
    final denied = await _staffDenial(id, staffId);
    if (denied != null) return Err(denied);
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await _ownedByStaff(id, staffId, expectedVersion);
        var currentStatus = row.status;
        if (currentStatus == AppointmentStatus.booked) {
          _requireTransition(currentStatus, AppointmentStatus.confirmed);
          await (_db.update(
            _db.appointments,
          )..where((a) => a.id.equals(id))).write(
            const AppointmentsCompanion(
              status: Value(AppointmentStatus.confirmed),
            ),
          );
          currentStatus = AppointmentStatus.confirmed;
        }
        if (currentStatus != AppointmentStatus.inProgress) {
          _requireTransition(currentStatus, AppointmentStatus.inProgress);
        }
        await (_db.update(
          _db.appointments,
        )..where((a) => a.id.equals(id))).write(
          AppointmentsCompanion(
            checkedInAt: Value(at),
            status: const Value(AppointmentStatus.inProgress),
          ),
        );
      }),
    );
  }

  @override
  Future<Result<void>> completeVisit({
    required String id,
    required String staffId,
    String? outcomeNote,
    int? expectedVersion,
  }) async {
    final denied = await _staffDenial(id, staffId);
    if (denied != null) return Err(denied);
    return Result.guardAsync(
      () => _db.transaction(() async {
        final row = await _ownedByStaff(id, staffId, expectedVersion);
        _requireTransition(row.status, AppointmentStatus.completed);
        await (_db.update(
          _db.appointments,
        )..where((a) => a.id.equals(id))).write(
          AppointmentsCompanion(
            status: const Value(AppointmentStatus.completed),
            outcomeNote: outcomeNote == null
                ? const Value.absent()
                : Value(outcomeNote.trim()),
          ),
        );
      }),
    );
  }

  @override
  Future<Result<Appointment>> openWalkInVisit({
    required String patientId,
    required String staffId,
    required String departmentId,
    required String ticketTag,
    String? reasonText,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        staffId,
        Permission.manageWalkInQueue,
        entityType: 'appointment',
      );
      final now = DateTime.now();
      final id = newId('appt');
      final roomNumber = await _assignRoomNumber(departmentId, staffId);
      await _db
          .into(_db.appointments)
          .insert(
            AppointmentsCompanion.insert(
              id: id,
              patientId: patientId,
              staffId: staffId,
              slotStart: now,
              slotEnd: now.add(const Duration(minutes: 20)),
              visitType: VisitType.urgentCare,
              departmentId: Value(departmentId),
              status: const Value(AppointmentStatus.inProgress),
              checkedInAt: Value(now),
              calledInAt: Value(now),
              reasonText: Value(reasonText),
              ticketTag: Value(ticketTag),
              roomNumber: Value(roomNumber),
            ),
          );
      final row = await (_db.select(
        _db.appointments,
      )..where((a) => a.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<Appointment>> transfer({
    required String id,
    required String fromStaffId,
    required String toStaffId,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        fromStaffId,
        Permission.runConsultation,
        entityType: 'appointment',
        entityId: id,
      );
      final current = await _ownedByStaff(id, fromStaffId, expectedVersion);
      if (current.staffId == toStaffId) {
        throw const ValidationFailure(
          'That appointment is already with this clinician.',
        );
      }
      final target = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(toStaffId))).getSingleOrNull();
      if (target == null || target.role != UserRole.staff) {
        throw NotFoundFailure('No staff member $toStaffId.');
      }

      final departmentId = await _departmentOf(toStaffId);
      final roomNumber = departmentId == null
          ? null
          : await _assignRoomNumber(departmentId, toStaffId);

      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(
          staffId: Value(toStaffId),
          departmentId: Value(departmentId),
          roomNumber: Value(roomNumber),
          checkedInAt: const Value(null),
          status: const Value(AppointmentStatus.booked),
        ),
      );
      final row = await (_db.select(
        _db.appointments,
      )..where((a) => a.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }
}
