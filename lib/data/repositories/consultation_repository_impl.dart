/// Drift-backed [WalkInTicketRepository] and [ReferralRequestRepository].
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/ticketing.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/consultation_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class WalkInTicketRepositoryImpl implements WalkInTicketRepository {
  WalkInTicketRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<WalkInTicket>> create(NewWalkInTicket r) {
    return Result.guardAsync(() async {
      final dept = await (_db.select(
        _db.departments,
      )..where((d) => d.id.equals(r.departmentId))).getSingleOrNull();
      if (dept == null) {
        throw NotFoundFailure('No department ${r.departmentId}.');
      }

      final id = newId('walkin');
      final tag = await _issueTag(r.departmentId, dept.name);
      await _db
          .into(_db.walkInTickets)
          .insert(
            WalkInTicketsCompanion.insert(
              id: id,
              patientId: r.patientId,
              departmentId: r.departmentId,
              ticketTag: tag,
              reason: Value(r.reason),
              sourceAppointmentId: Value(r.sourceAppointmentId),
              createdByStaffId: r.createdByStaffId,
            ),
          );
      return _require(id);
    });
  }

  /// `[department letter]-[count of that department's walk-ins today, + 1]`.
  Future<String> _issueTag(String departmentId, String departmentName) async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final todays =
        await (_db.select(_db.walkInTickets)..where(
              (t) =>
                  t.departmentId.equals(departmentId) &
                  t.createdAt.isBiggerOrEqualValue(dayStart),
            ))
            .get();
    return '${departmentLetterFor(departmentName)}-${todays.length + 1}';
  }

  @override
  Future<Result<List<WalkInTicket>>> forDepartment(
    String departmentId, {
    bool openOnly = false,
  }) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.walkInTickets)
        ..where((t) => t.departmentId.equals(departmentId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
      if (openOnly) {
        q.where(
          (t) =>
              t.status.equalsValue(WalkInStatus.waiting) |
              t.status.equalsValue(WalkInStatus.called),
        );
      }
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<WalkInTicket>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.walkInTickets)
                ..where((t) => t.patientId.equals(patientId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<WalkInTicket>> byId(String id) =>
      Result.guardAsync(() => _require(id));

  @override
  Future<Result<WalkInTicket>> claim({
    required String id,
    required String doctorId,
    required String resultAppointmentId,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(
        _db.walkInTickets,
      )..where((t) => t.id.equals(id))).write(
        WalkInTicketsCompanion(
          status: const Value(WalkInStatus.inProgress),
          claimedByStaffId: Value(doctorId),
          resultAppointmentId: Value(resultAppointmentId),
        ),
      );
      return _require(id);
    });
  }

  @override
  Future<Result<WalkInTicket>> resolve(String id) {
    return Result.guardAsync(() async {
      await (_db.update(
        _db.walkInTickets,
      )..where((t) => t.id.equals(id))).write(
        WalkInTicketsCompanion(
          status: const Value(WalkInStatus.done),
          resolvedAt: Value(DateTime.now()),
        ),
      );
      return _require(id);
    });
  }

  @override
  Future<Result<void>> resolveByAppointment(String appointmentId) {
    return Result.guardAsync(() async {
      await (_db.update(
        _db.walkInTickets,
      )..where((t) => t.resultAppointmentId.equals(appointmentId))).write(
        WalkInTicketsCompanion(
          status: const Value(WalkInStatus.done),
          resolvedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<Result<WalkInTicket>> cancel(String id) {
    return Result.guardAsync(() async {
      await (_db.update(
        _db.walkInTickets,
      )..where((t) => t.id.equals(id))).write(
        WalkInTicketsCompanion(
          status: const Value(WalkInStatus.cancelled),
          resolvedAt: Value(DateTime.now()),
        ),
      );
      return _require(id);
    });
  }

  Future<WalkInTicket> _require(String id) async {
    final row = await (_db.select(
      _db.walkInTickets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundFailure('No walk-in ticket $id.');
    return row.toEntity();
  }
}

class ReferralRequestRepositoryImpl implements ReferralRequestRepository {
  ReferralRequestRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<ReferralRequest>> create(NewReferralRequest r) {
    return Result.guardAsync(() async {
      if (r.reason.trim().isEmpty) {
        throw const ValidationFailure('A reason for the referral is required.');
      }
      final id = newId('refreq');
      await _db
          .into(_db.referralRequests)
          .insert(
            ReferralRequestsCompanion.insert(
              id: id,
              patientId: r.patientId,
              appointmentId: Value(r.appointmentId),
              requestedByStaffId: r.requestedByStaffId,
              reason: r.reason.trim(),
            ),
          );
      return _require(id);
    });
  }

  @override
  Future<Result<List<ReferralRequest>>> pending() {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.referralRequests)
                ..where(
                  (t) => t.status.equalsValue(ReferralRequestStatus.pending),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<ReferralRequest>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.referralRequests)
                ..where((t) => t.patientId.equals(patientId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<ReferralRequest?>> pendingForAppointment(String appointmentId) {
    return Result.guardAsync(() async {
      final row =
          await (_db.select(_db.referralRequests)..where(
                (t) =>
                    t.appointmentId.equals(appointmentId) &
                    t.status.equalsValue(ReferralRequestStatus.pending),
              ))
              .getSingleOrNull();
      return row?.toEntity();
    });
  }

  @override
  Future<Result<ReferralRequest>> decide({
    required String id,
    required ReferralRequestStatus status,
    required String adminId,
    String? note,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(
        _db.referralRequests,
      )..where((t) => t.id.equals(id))).write(
        ReferralRequestsCompanion(
          status: Value(status),
          decidedByAdminId: Value(adminId),
          decisionNote: note == null
              ? const Value.absent()
              : Value(note.trim()),
          decidedAt: Value(DateTime.now()),
        ),
      );
      return _require(id);
    });
  }

  Future<ReferralRequest> _require(String id) async {
    final row = await (_db.select(
      _db.referralRequests,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundFailure('No referral request $id.');
    return row.toEntity();
  }
}
