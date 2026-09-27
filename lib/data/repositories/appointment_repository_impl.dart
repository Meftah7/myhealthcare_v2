/// Drift-backed [AppointmentRepository] (P1-13).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/ticketing.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../services/notifications/reminder_scheduler.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._db);

  final AppDatabase _db;

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<Result<Appointment>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.appointments,
      )..where((a) => a.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No appointment $id.');
      return row.toEntity();
    });
  }

  @override
  Future<Result<List<Appointment>>> forPatient(
    String patientId, {
    bool upcomingOnly = false,
  }) {
    return Result.guardAsync(() async {
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
    return _forStaffOnDayQuery(
      staffId,
      day,
    ).watch().map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  @override
  Future<Result<List<OpenSlot>>> openSlots(String staffId, DateTime day) {
    return Result.guardAsync(() async {
      final raw = await _templateSlotsFor(staffId, day);
      if (raw.isEmpty) return const <OpenSlot>[];

      final booked = await _forStaffOnDayQuery(staffId, day).get();
      final bookedStarts = booked
          .where((a) => a.status != AppointmentStatus.cancelled)
          .map((a) => a.slotStart)
          .toSet();

      final slots = raw
          .where(
            (s) => s.start.isAfter(DateTime.now()) &&
                !bookedStarts.contains(s.start),
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
    final templates =
        await (_db.select(_db.scheduleTemplates)..where(
              (t) =>
                  t.staffId.equals(staffId) & t.weekday.equals(day.weekday),
            ))
            .get();
    final dayStart = _dayStart(day);
    final slots = <OpenSlot>[];
    for (final t in templates) {
      var cursor = t.startMinutes;
      while (cursor + t.slotMinutes <= t.endMinutes) {
        final start = dayStart.add(Duration(minutes: cursor));
        final end = start.add(Duration(minutes: t.slotMinutes));
        slots.add(OpenSlot(staffId: staffId, start: start, end: end));
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

  @override
  Future<Result<List<ScheduleTemplate>>> templatesFor(String staffId) {
    return Result.guardAsync(() async {
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
      for (final t in templates) {
        if (t.startMinutes >= t.endMinutes) {
          throw const ValidationFailure('Start time must be before end time.');
        }
        if (t.slotMinutes <= 0) {
          throw const ValidationFailure('Slot length must be greater than zero.');
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
            if (a.startMinutes < b.endMinutes && a.endMinutes > b.startMinutes) {
              throw const ValidationFailure(
                'Two schedules for the same day overlap. Adjust the times.',
              );
            }
          }
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
  Future<Result<Appointment>> book(BookingRequest r) {
    // The whole thing — the overlap check, the ticket-count read, and the
    // insert — runs as one transaction. SQLite serializes writers, so two
    // concurrent bookings can no longer both pass the check (a stale read
    // racing an insert) and no longer both land on the same ticket count.
    return Result.guardAsync(
      () => _db.transaction(() async {
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
        if (await _hasOverlap(staffId: r.staffId, start: r.start, end: r.end)) {
          throw const ValidationFailure('That slot was just taken.');
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
              ),
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
    await (_db.delete(_db.reminders)..where(
          (r) => r.appointmentId.equals(appointmentId) & r.sentAt.isNull(),
        ))
        .go();
    final now = DateTime.now();
    for (final plan in reminderPlanFor(band)) {
      if (enabledChannels != null && !enabledChannels.contains(plan.channel)) {
        continue;
      }
      final at = slotStart.subtract(plan.offsetBeforeSlot);
      if (at.isBefore(now)) continue;
      await _db
          .into(_db.reminders)
          .insert(
            RemindersCompanion.insert(
              id: newId('rem'),
              appointmentId: appointmentId,
              scheduledFor: at,
              channel: plan.channel,
              kind: Value(plan.kind),
            ),
          );
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
  }) {
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
        if (!await _isOnScheduleGrid(
          staffId: row.staffId,
          start: newStart,
          end: newEnd,
        )) {
          throw const ValidationFailure(
            "That time isn't on this clinician's schedule. Choose a listed slot.",
          );
        }
        if (await _hasOverlap(
          staffId: row.staffId,
          start: newStart,
          end: newEnd,
          excludingAppointmentId: id,
        )) {
          throw const ValidationFailure(
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
        return updated.toEntity();
      }),
    );
  }

  @override
  Future<Result<void>> cancel(String id, {required String patientId}) {
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
        if (row.status == AppointmentStatus.cancelled) {
          throw const ValidationFailure('This appointment is already cancelled.');
        }
        if (row.status == AppointmentStatus.completed) {
          throw const ValidationFailure(
            'A completed visit cannot be cancelled.',
          );
        }
        await (_db.update(
          _db.appointments,
        )..where((a) => a.id.equals(id))).write(
          const AppointmentsCompanion(
            status: Value(AppointmentStatus.cancelled),
          ),
        );
        await (_db.delete(_db.reminders)..where(
              (r) => r.appointmentId.equals(id) & r.sentAt.isNull(),
            ))
            .go();
      }),
    );
  }

  /// Loads the appointment and verifies [staffId] matches its current
  /// clinician — every staff-side mutation below goes through this so a
  /// clinician can't act on a colleague's visit just by knowing its ID.
  Future<AppointmentRow> _ownedByStaff(String id, String staffId) async {
    final row = await (_db.select(
      _db.appointments,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundFailure('No appointment $id.');
    if (row.staffId != staffId) {
      throw const AuthFailure(
        'This appointment is assigned to a different clinician.',
      );
    }
    return row;
  }

  @override
  Future<Result<void>> updateStatus({
    required String id,
    required String staffId,
    required AppointmentStatus status,
  }) {
    return Result.guardAsync(() async {
      await _ownedByStaff(id, staffId);
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(status: Value(status)),
      );
    });
  }

  @override
  Future<Result<void>> markCheckedIn(
    String id, {
    required String staffId,
    required DateTime at,
  }) {
    return Result.guardAsync(() async {
      await _ownedByStaff(id, staffId);
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(
          checkedInAt: Value(at),
          status: const Value(AppointmentStatus.confirmed),
        ),
      );
    });
  }

  @override
  Future<Result<void>> markCalledIn(
    String id, {
    required String staffId,
    required DateTime at,
  }) {
    return Result.guardAsync(() async {
      await _ownedByStaff(id, staffId);
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(calledInAt: Value(at)),
      );
    });
  }

  @override
  Future<Result<void>> markArrived(
    String id, {
    required String staffId,
    required DateTime at,
  }) {
    return Result.guardAsync(() async {
      await _ownedByStaff(id, staffId);
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(
          checkedInAt: Value(at),
          status: const Value(AppointmentStatus.inProgress),
        ),
      );
    });
  }

  @override
  Future<Result<void>> completeVisit({
    required String id,
    required String staffId,
    String? outcomeNote,
  }) {
    return Result.guardAsync(() async {
      await _ownedByStaff(id, staffId);
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(
          status: const Value(AppointmentStatus.completed),
          outcomeNote: outcomeNote == null
              ? const Value.absent()
              : Value(outcomeNote.trim()),
        ),
      );
    });
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
  }) {
    return Result.guardAsync(() async {
      final current = await _ownedByStaff(id, fromStaffId);
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
