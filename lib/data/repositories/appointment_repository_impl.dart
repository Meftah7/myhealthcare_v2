/// Drift-backed [AppointmentRepository] (P1-13).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/appointment_repository.dart';
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
      final weekday = day.weekday;
      final templates =
          await (_db.select(_db.scheduleTemplates)..where(
                (t) => t.staffId.equals(staffId) & t.weekday.equals(weekday),
              ))
              .get();
      if (templates.isEmpty) return const <OpenSlot>[];

      final booked = await _forStaffOnDayQuery(staffId, day).get();
      final bookedStarts = booked
          .where((a) => a.status != AppointmentStatus.cancelled)
          .map((a) => a.slotStart)
          .toSet();

      final dayStart = _dayStart(day);
      final slots = <OpenSlot>[];
      for (final t in templates) {
        var cursor = t.startMinutes;
        while (cursor + t.slotMinutes <= t.endMinutes) {
          final start = dayStart.add(Duration(minutes: cursor));
          final end = start.add(Duration(minutes: t.slotMinutes));
          if (start.isAfter(DateTime.now()) && !bookedStarts.contains(start)) {
            slots.add(OpenSlot(staffId: staffId, start: start, end: end));
          }
          cursor += t.slotMinutes;
        }
      }
      slots.sort((a, b) => a.start.compareTo(b.start));
      return slots;
    });
  }

  @override
  Future<Result<Appointment>> book(BookingRequest r) {
    return Result.guardAsync(() async {
      final clash =
          await (_db.select(_db.appointments)..where(
                (a) =>
                    a.staffId.equals(r.staffId) &
                    a.slotStart.equals(r.start) &
                    a.status.equalsValue(AppointmentStatus.cancelled).not(),
              ))
              .getSingleOrNull();
      if (clash != null) {
        throw const ValidationFailure('That slot was just taken.');
      }

      final id = newId('appt');
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
              departmentId: Value(r.departmentId),
              reasonText: Value(r.reasonText),
              noShowRisk: Value(r.noShowRisk),
              riskBand: Value(r.riskBand),
            ),
          );
      final row = await (_db.select(
        _db.appointments,
      )..where((a) => a.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<Appointment>> reschedule({
    required String id,
    required DateTime newStart,
    required DateTime newEnd,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(
          slotStart: Value(newStart),
          slotEnd: Value(newEnd),
          status: const Value(AppointmentStatus.booked),
        ),
      );
      final row = await (_db.select(
        _db.appointments,
      )..where((a) => a.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> cancel(String id) {
    return Result.guardAsync(() async {
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        const AppointmentsCompanion(status: Value(AppointmentStatus.cancelled)),
      );
    });
  }

  @override
  Future<Result<void>> updateStatus({
    required String id,
    required AppointmentStatus status,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(status: Value(status)),
      );
    });
  }

  @override
  Future<Result<void>> markCheckedIn(String id, DateTime at) {
    return Result.guardAsync(() async {
      await (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(
          checkedInAt: Value(at),
          status: const Value(AppointmentStatus.confirmed),
        ),
      );
    });
  }
}
