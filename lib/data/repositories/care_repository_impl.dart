/// Drift-backed care-services repositories (P10 Batch B).
library;

import 'package:drift/drift.dart';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/format.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/care_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import '../sync/idempotency.dart';
import '../sync/outbox.dart';
import 'mappers.dart';

class SickLeaveRepositoryImpl implements SickLeaveRepository {
  SickLeaveRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<SickLeaveCertificate>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      await _access.readPatient(patientId, entityType: 'sick_leave');
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
      await _access.selfOrAdmin(
        staffId,
        Permission.viewOperationalReports,
        entityType: 'sick_leave',
      );
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
      await _access.readPatient(
        row.patientId,
        entityType: 'sick_leave',
        entityId: id,
      );
      return row.toEntity();
    });
  }

  @override
  Future<Result<SickLeaveCertificate>> issue(NewSickLeave c) {
    return Result.guardAsync(() async {
      await _access.clinicalWrite(
        staffId: c.issuedByStaffId,
        patientId: c.patientId,
        permission: Permission.issueSickLeave,
        entityType: 'sick_leave',
      );
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
  CareMessageRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db),
      _idempotency = IdempotencyGuard(_db),
      _outbox = Outbox(_db);

  final AppDatabase _db;
  final AccessPolicy _access;
  final IdempotencyGuard _idempotency;
  final Outbox _outbox;

  /// A thread belongs to its patient (readable by the patient and their
  /// proxies) and to its clinician (readable by that clinician only).
  Future<void> _authorizeThread({
    required String patientId,
    String? staffId,
    bool? asStaff,
  }) async {
    final actor = await _access.principal();
    if (actor == null) return;
    // A clinician covering an unanswered message in someone else's thread
    // may read it (to answer it) — Phase 4 off-duty cover.
    if (actor.isStaff &&
        staffId != null &&
        staffId != actor.accountId &&
        actor.can(Permission.messageCareTeam) &&
        await _covers(patientId, staffId, actor.accountId)) {
      return;
    }
    if (actor.isStaff || (asStaff ?? false)) {
      await _access.actAsStaff(
        staffId ?? '',
        Permission.messageCareTeam,
        entityType: 'care_message',
      );
    } else {
      await _access.readPatient(patientId, entityType: 'care_message');
    }
  }

  @override
  Future<Result<List<CareThread>>> threadsForPatient(String patientId) async {
    try {
      await _authorizeThread(patientId: patientId, asStaff: false);
    } on Failure catch (f) {
      return Err(f);
    }
    return _threads(byPatient: patientId);
  }

  @override
  Future<Result<List<CareThread>>> threadsForStaff(String staffId) async {
    try {
      await _access.actAsStaff(
        staffId,
        Permission.messageCareTeam,
        entityType: 'care_message',
      );
    } on Failure catch (f) {
      return Err(f);
    }
    return _threads(byStaff: staffId);
  }

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
                : clinicianName(names[last.staffId] ?? 'Clinician'),
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
      await _authorizeThread(patientId: patientId, staffId: staffId);
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
    IdempotencyKey? idempotencyKey,
    List<NewNotification> notify = const [],
  }) {
    return Result.guardAsync(() async {
      final sender = await _authorizeSend(
        patientId: patientId,
        staffId: staffId,
        fromStaff: fromStaff,
      );
      final text = body.trim();
      if (text.isEmpty) throw const ValidationFailure('Write a message first.');
      final id = await _db.transaction(() async {
        // A retried send returns the message that already went out.
        final prior = await _idempotency.prior(
          idempotencyKey,
          scope: 'care_message.send',
          actorAccountId: sender,
        );
        if (prior != null) return prior;
        final id = newId('msg');
        final now = DateTime.now();
        // A patient's message is owned work: the thread's clinician must
        // answer it by the promised time, and an on-duty colleague covers it
        // while they are away. A staff reply is not queued.
        await _db
            .into(_db.careMessages)
            .insert(
              CareMessagesCompanion.insert(
                id: id,
                patientId: patientId,
                staffId: staffId,
                fromStaff: fromStaff,
                body: text,
                sentAt: Value(now),
                senderAccountId: Value(sender),
                queueOwnerStaffId: Value(fromStaff ? null : staffId),
                coverageStaffId: Value(
                  fromStaff ? null : await _coverFor(staffId),
                ),
                responseDueAt: Value(
                  fromStaff ? null : now.add(CareMessageQueue.responseWindow),
                ),
              ),
            );
        await _idempotency.remember(
          idempotencyKey,
          scope: 'care_message.send',
          actorAccountId: sender,
          resultRef: id,
        );
        for (final n in notify) {
          await _outbox.enqueueNotification(n);
        }
        return id;
      });
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
      await _authorizeThread(
        patientId: patientId,
        staffId: staffId,
        asStaff: readerIsStaff,
      );
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

  /// Whether [coverId] covers a patient message in this thread.
  Future<bool> _covers(String patientId, String staffId, String coverId) async {
    final row =
        await (_db.select(_db.careMessages)
              ..where(
                (m) =>
                    m.patientId.equals(patientId) &
                    m.staffId.equals(staffId) &
                    m.fromStaff.equals(false) &
                    m.coverageStaffId.equals(coverId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// An on-duty clinician in the same department who covers [ownerId]'s
  /// patient messages while they are off shift or inactive; null when the
  /// owner is working (or nobody else is on duty — the message then stays
  /// with the owner and shows as overdue to administrators).
  Future<String?> _coverFor(String ownerId) async {
    final owner = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(ownerId))).getSingleOrNull();
    final profile = await (_db.select(
      _db.staffProfiles,
    )..where((s) => s.userId.equals(ownerId))).getSingleOrNull();
    if (owner == null || profile == null) return null;
    final away = !owner.isActive || profile.presence == PresenceStatus.offShift;
    if (!away) return null;
    final colleagues =
        await (_db.select(_db.staffProfiles).join([
                innerJoin(
                  _db.users,
                  _db.users.id.equalsExp(_db.staffProfiles.userId),
                ),
              ])
              ..where(
                _db.staffProfiles.departmentId.equalsNullable(
                      profile.departmentId,
                    ) &
                    _db.staffProfiles.userId.equals(ownerId).not() &
                    _db.users.isActive.equals(true) &
                    _db.staffProfiles.presence.isInValues(const [
                      PresenceStatus.onDuty,
                      PresenceStatus.inConsultation,
                    ]),
              )
              ..orderBy([OrderingTerm.asc(_db.staffProfiles.userId)])
              ..limit(1))
            .get();
    return colleagues.isEmpty
        ? null
        : colleagues.first.readTable(_db.staffProfiles).userId;
  }

  @override
  Future<Result<List<CareMessage>>> awaitingReply({String? staffId}) {
    return Result.guardAsync(() async {
      if (staffId == null) {
        await _access.require(
          Permission.manageCareTeams,
          entityType: 'care_message',
        );
      } else {
        await _access.selfOrAdmin(
          staffId,
          Permission.manageCareTeams,
          entityType: 'care_message',
        );
      }
      final q = _db.select(_db.careMessages)
        ..where((m) => m.fromStaff.equals(false) & m.responseDueAt.isNotNull())
        ..orderBy([(m) => OrderingTerm.asc(m.responseDueAt)]);
      if (staffId != null) {
        q.where(
          (m) =>
              m.queueOwnerStaffId.equals(staffId) |
              m.coverageStaffId.equals(staffId),
        );
      }
      final waiting = <CareMessage>[];
      for (final m in await q.get()) {
        // Answered once any clinician replied in the thread afterwards.
        final reply =
            await (_db.select(_db.careMessages)
                  ..where(
                    (r) =>
                        r.patientId.equals(m.patientId) &
                        r.staffId.equals(m.staffId) &
                        r.fromStaff.equals(true) &
                        r.sentAt.isBiggerOrEqualValue(m.sentAt),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (reply == null) waiting.add(m.toEntity());
      }
      return waiting;
    });
  }

  /// The sender must be the side [fromStaff] claims, and the patient and
  /// clinician must already share a care relationship — or, for a staff
  /// reply, the sender covers an unanswered message in this thread. Returns
  /// the sending account.
  Future<String?> _authorizeSend({
    required String patientId,
    required String staffId,
    required bool fromStaff,
  }) async {
    final actor = await _access.principal();
    if (actor == null) return null;
    if (fromStaff && actor.isStaff && actor.accountId != staffId) {
      final covering =
          await (_db.select(_db.careMessages)
                ..where(
                  (m) =>
                      m.patientId.equals(patientId) &
                      m.staffId.equals(staffId) &
                      m.fromStaff.equals(false) &
                      m.coverageStaffId.equals(actor.accountId),
                )
                ..limit(1))
              .getSingleOrNull();
      if (covering != null && actor.can(Permission.messageCareTeam)) {
        await _access.audit(
          'care_message.cover_reply',
          entityType: 'care_message',
          subjectPatientId: patientId,
          detail: 'covering $staffId',
        );
        return actor.accountId;
      }
    }
    if (fromStaff) {
      await _access.clinicalWrite(
        staffId: staffId,
        patientId: patientId,
        permission: Permission.messageCareTeam,
        entityType: 'care_message',
      );
      return actor.accountId;
    }
    final subject = await _access.actForPatient(
      patientId,
      Permission.messageCareTeam,
      entityType: 'care_message',
    );
    if (!await _access.hasCareRelationship(
      staffId: staffId,
      patientId: patientId,
    )) {
      throw const AccessDeniedFailure('You cannot message this clinician.');
    }
    return subject.actingAccountId;
  }
}

class HomeVisitRepositoryImpl implements HomeVisitRepository {
  HomeVisitRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db),
      _idempotency = IdempotencyGuard(_db),
      _outbox = Outbox(_db);

  final AppDatabase _db;
  final AccessPolicy _access;
  final IdempotencyGuard _idempotency;
  final Outbox _outbox;

  static void _requireVersion(HomeVisitRow row, int? expected) {
    if (expected != null && row.version != expected) {
      throw ConflictFailure(
        'This request was updated by someone else. Reload to see the latest.',
        currentVersion: row.version,
      );
    }
  }

  @override
  Future<Result<List<HomeVisitRequest>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      await _access.readPatient(
        patientId,
        scope: PatientDataScope.administrative,
        entityType: 'home_visit',
      );
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
      await _access.require(
        Permission.decideHomeVisits,
        entityType: 'home_visit',
      );
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
      await _access.readPatient(
        row.patientId,
        scope: PatientDataScope.administrative,
        entityType: 'home_visit',
        entityId: id,
      );
      return row.toEntity();
    });
  }

  @override
  Future<Result<HomeVisitRequest>> create(
    NewHomeVisitRequest r, {
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      final subject = await _access.actForPatient(
        r.patientId,
        Permission.requestHomeVisit,
        entityType: 'home_visit',
      );
      if (r.addressText.trim().isEmpty) {
        throw const ValidationFailure('An address is required.');
      }
      if (r.reasonText.trim().isEmpty) {
        throw const ValidationFailure('Tell us why a home visit is needed.');
      }
      final actor = _access.isEnforced ? subject.actingAccountId : null;
      final (id, isRetry) = await _db.transaction(() async {
        final prior = await _idempotency.prior(
          idempotencyKey,
          scope: 'home_visit.create',
          actorAccountId: actor,
        );
        if (prior != null) return (prior, true);
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
                requestedByAccountId: Value(actor),
              ),
            );
        await _idempotency.remember(
          idempotencyKey,
          scope: 'home_visit.create',
          actorAccountId: actor,
          resultRef: id,
        );
        return (id, false);
      });
      if (isRetry) return _require(id);
      if (!subject.isSelf) {
        await _access.audit(
          'proxy.home_visit.request',
          entityType: 'home_visit',
          entityId: id,
          subjectPatientId: r.patientId,
        );
      }
      return _require(id);
    });
  }

  @override
  Future<Result<HomeVisitRequest>> decide({
    required String id,
    required HomeVisitStatus status,
    int? expectedVersion,
    List<NewNotification> notify = const [],
    String? assignedStaffId,
    String? decisionNote,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.decideHomeVisits,
        entityType: 'home_visit',
        entityId: id,
      );
      await _db.transaction(() async {
        final current = await (_db.select(
          _db.homeVisitRequests,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        if (current == null) throw const NotFoundFailure('Request not found.');
        _requireVersion(current, expectedVersion);
        await (_db.update(
          _db.homeVisitRequests,
        )..where((r) => r.id.equals(id))).write(
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
        // Delivered only if the decision commits.
        for (final n in notify) {
          await _outbox.enqueueNotification(n);
        }
      });
      return _require(id);
    });
  }

  @override
  Future<Result<HomeVisitRequest>> cancel({
    required String id,
    required String patientId,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      final row =
          await (_db.select(_db.homeVisitRequests)
                ..where((r) => r.id.equals(id) & r.patientId.equals(patientId)))
              .getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Request not found.');
      await _access.actForPatient(
        row.patientId,
        Permission.requestHomeVisit,
        entityType: 'home_visit',
        entityId: id,
      );
      _requireVersion(row, expectedVersion);
      if (!row.toEntity().isOpen) {
        throw const ValidationFailure(
          'This request can no longer be cancelled.',
        );
      }
      await (_db.update(
        _db.homeVisitRequests,
      )..where((r) => r.id.equals(id))).write(
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
