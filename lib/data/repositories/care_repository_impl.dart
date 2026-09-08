/// Drift-backed care-services repositories (P10 Batch B).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/care_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class SickLeaveRepositoryImpl implements SickLeaveRepository {
  SickLeaveRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<SickLeaveCertificate>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.sickLeaveCertificates)
                ..where((c) => c.patientId.equals(patientId))
                ..orderBy([(c) => OrderingTerm.desc(c.issuedAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<SickLeaveCertificate>>> issuedBy(String staffId) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.sickLeaveCertificates)
                ..where((c) => c.issuedByStaffId.equals(staffId))
                ..orderBy([(c) => OrderingTerm.desc(c.issuedAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<SickLeaveCertificate>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.sickLeaveCertificates,
      )..where((c) => c.id.equals(id))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Certificate not found.');
      return row.toEntity();
    });
  }

  @override
  Future<Result<SickLeaveCertificate>> issue(NewSickLeave c) {
    return Result.guardAsync(() async {
      if (c.diagnosis.trim().isEmpty) {
        throw const ValidationFailure('A reason for the note is required.');
      }
      if (c.toDate.isBefore(c.fromDate)) {
        throw const ValidationFailure('The end date is before the start date.');
      }
      final id = newId('sick');
      await _db
          .into(_db.sickLeaveCertificates)
          .insert(
            SickLeaveCertificatesCompanion.insert(
              id: id,
              patientId: c.patientId,
              issuedByStaffId: c.issuedByStaffId,
              diagnosis: c.diagnosis.trim(),
              fromDate: _dateOnly(c.fromDate),
              toDate: _dateOnly(c.toDate),
              appointmentId: Value(c.appointmentId),
              notes: Value(c.notes?.trim()),
            ),
          );
      final row = await (_db.select(
        _db.sickLeaveCertificates,
      )..where((r) => r.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class CareMessageRepositoryImpl implements CareMessageRepository {
  CareMessageRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<CareThread>>> threadsForPatient(String patientId) =>
      _threads(byPatient: patientId);

  @override
  Future<Result<List<CareThread>>> threadsForStaff(String staffId) =>
      _threads(byStaff: staffId);

  Future<Result<List<CareThread>>> _threads({
    String? byPatient,
    String? byStaff,
  }) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.careMessages)
        ..orderBy([(m) => OrderingTerm.asc(m.sentAt)]);
      if (byPatient != null) q.where((m) => m.patientId.equals(byPatient));
      if (byStaff != null) q.where((m) => m.staffId.equals(byStaff));
      final rows = await q.get();
      if (rows.isEmpty) return const <CareThread>[];

      // Name lookup for the counterpart shown in the list.
      final names = {
        for (final u in await _db.select(_db.users).get()) u.id: u.fullName,
      };

      final grouped = <String, List<CareMessageRow>>{};
      for (final r in rows) {
        grouped.putIfAbsent('${r.patientId}|${r.staffId}', () => []).add(r);
      }

      final threads = <CareThread>[];
      for (final entry in grouped.entries) {
        final msgs = entry.value;
        final last = msgs.last;
        final staffLed = byStaff != null;
        threads.add(
          CareThread(
            patientId: last.patientId,
            staffId: last.staffId,
            counterpartName: staffLed
                ? (names[last.patientId] ?? 'Patient')
                : 'Dr ${names[last.staffId] ?? 'Clinician'}',
            lastMessage: last.toEntity(),
            unreadForPatient: msgs
                .where((m) => m.fromStaff && m.readAt == null)
                .length,
            unreadForStaff: msgs
                .where((m) => !m.fromStaff && m.readAt == null)
                .length,
          ),
        );
      }
      threads.sort(
        (a, b) => b.lastMessage.sentAt.compareTo(a.lastMessage.sentAt),
      );
      return threads;
    });
  }

  @override
  Future<Result<List<CareMessage>>> thread({
    required String patientId,
    required String staffId,
  }) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.careMessages)
                ..where(
                  (m) =>
                      m.patientId.equals(patientId) & m.staffId.equals(staffId),
                )
                ..orderBy([(m) => OrderingTerm.asc(m.sentAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<CareMessage>> send({
    required String patientId,
    required String staffId,
    required bool fromStaff,
    required String body,
  }) {
    return Result.guardAsync(() async {
      final text = body.trim();
      if (text.isEmpty) throw const ValidationFailure('Write a message first.');
      final id = newId('msg');
      await _db
          .into(_db.careMessages)
          .insert(
            CareMessagesCompanion.insert(
              id: id,
              patientId: patientId,
              staffId: staffId,
              fromStaff: fromStaff,
              body: text,
            ),
          );
      final row = await (_db.select(
        _db.careMessages,
      )..where((m) => m.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> markRead({
    required String patientId,
    required String staffId,
    required bool readerIsStaff,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.careMessages)..where(
            (m) =>
                m.patientId.equals(patientId) &
                m.staffId.equals(staffId) &
                m.fromStaff.equals(!readerIsStaff) &
                m.readAt.isNull(),
          ))
          .write(CareMessagesCompanion(readAt: Value(DateTime.now())));
    });
  }
}

class HomeVisitRepositoryImpl implements HomeVisitRepository {
  HomeVisitRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<HomeVisitRequest>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.homeVisitRequests)
                ..where((r) => r.patientId.equals(patientId))
                ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<HomeVisitRequest>>> all({HomeVisitStatus? status}) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.homeVisitRequests)
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]);
      if (status != null) q.where((r) => r.status.equalsValue(status));
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<HomeVisitRequest>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.homeVisitRequests,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Request not found.');
      return row.toEntity();
    });
  }

  @override
  Future<Result<HomeVisitRequest>> create(NewHomeVisitRequest r) {
    return Result.guardAsync(() async {
      if (r.addressText.trim().isEmpty) {
        throw const ValidationFailure('An address is required.');
      }
      if (r.reasonText.trim().isEmpty) {
        throw const ValidationFailure('Tell us why a home visit is needed.');
      }
      final id = newId('hv');
      await _db
          .into(_db.homeVisitRequests)
          .insert(
            HomeVisitRequestsCompanion.insert(
              id: id,
              patientId: r.patientId,
              addressText: r.addressText.trim(),
              preferredDate: r.preferredDate,
              reasonText: r.reasonText.trim(),
              departmentId: Value(r.departmentId),
            ),
          );
      return _require(id);
    });
  }

  @override
  Future<Result<HomeVisitRequest>> decide({
    required String id,
    required HomeVisitStatus status,
    String? assignedStaffId,
    String? decisionNote,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.homeVisitRequests)..where((r) => r.id.equals(id)))
          .write(
            HomeVisitRequestsCompanion(
              status: Value(status),
              // Only touch the assignment when a value is supplied, so marking
              // a scheduled visit "completed" doesn't wipe the clinician.
              assignedStaffId: assignedStaffId == null
                  ? const Value.absent()
                  : Value(assignedStaffId),
              decisionNote: decisionNote == null
                  ? const Value.absent()
                  : Value(decisionNote.trim()),
              decidedAt: Value(DateTime.now()),
            ),
          );
      return _require(id);
    });
  }

  @override
  Future<Result<HomeVisitRequest>> cancel({
    required String id,
    required String patientId,
  }) {
    return Result.guardAsync(() async {
      final row =
          await (_db.select(_db.homeVisitRequests)..where(
                (r) => r.id.equals(id) & r.patientId.equals(patientId),
              ))
              .getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Request not found.');
      if (!row.toEntity().isOpen) {
        throw const ValidationFailure('This request can no longer be cancelled.');
      }
      await (_db.update(_db.homeVisitRequests)..where((r) => r.id.equals(id)))
          .write(
            HomeVisitRequestsCompanion(
              status: const Value(HomeVisitStatus.cancelled),
              decidedAt: Value(DateTime.now()),
            ),
          );
      return _require(id);
    });
  }

  Future<HomeVisitRequest> _require(String id) async {
    final row = await (_db.select(
      _db.homeVisitRequests,
    )..where((r) => r.id.equals(id))).getSingle();
    return row.toEntity();
  }
}
