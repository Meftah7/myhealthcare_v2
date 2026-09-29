/// Drift-backed [WalkInTicketRepository] and [ReferralRequestRepository].
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/ticketing.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/repositories/consultation_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import '../sync/idempotency.dart';
import '../sync/outbox.dart';
import 'mappers.dart';

class EncounterDraftRepositoryImpl implements EncounterDraftRepository {
  EncounterDraftRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<EncounterDraftData?>> forAppointment(String appointmentId) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(
        entityType: 'encounter_draft',
        entityId: appointmentId,
      );
      final row = await (_db.select(
        _db.encounterDrafts,
      )..where((d) => d.appointmentId.equals(appointmentId))).getSingleOrNull();
      return row == null ? null : _toDraft(row);
    });
  }

  @override
  Future<Result<EncounterDraftData>> save(
    EncounterDraftData draft, {
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        draft.authorStaffId,
        Permission.runConsultation,
        entityType: 'encounter_draft',
        entityId: draft.appointmentId,
      );
      if (_access.isEnforced) {
        final appt = await (_db.select(
          _db.appointments,
        )..where((a) => a.id.equals(draft.appointmentId))).getSingleOrNull();
        if (appt == null || appt.staffId != draft.authorStaffId) {
          throw const AccessDeniedFailure(
            'This consultation is assigned to another clinician.',
          );
        }
      }
      final existing =
          await (_db.select(_db.encounterDrafts)
                ..where((d) => d.appointmentId.equals(draft.appointmentId)))
              .getSingleOrNull();
      if (existing == null) {
        await _db
            .into(_db.encounterDrafts)
            .insert(
              EncounterDraftsCompanion.insert(
                appointmentId: draft.appointmentId,
                patientId: draft.patientId,
                authorStaffId: draft.authorStaffId,
                note: Value(draft.note),
                medicationsJson: Value(_encodeMedications(draft.medications)),
                referralRequested: Value(draft.referralRequested),
              ),
            );
      } else {
        if (existing.authorStaffId != draft.authorStaffId) {
          throw const AccessDeniedFailure(
            'This encounter draft belongs to another clinician.',
          );
        }
        if (expectedVersion != null && existing.version != expectedVersion) {
          throw ConflictFailure(
            'This draft changed elsewhere. Reload before saving.',
            currentVersion: existing.version,
          );
        }
        final changed =
            await (_db.update(_db.encounterDrafts)..where(
                  (d) =>
                      d.appointmentId.equals(draft.appointmentId) &
                      d.version.equals(existing.version),
                ))
                .write(
                  EncounterDraftsCompanion(
                    note: Value(draft.note),
                    medicationsJson: Value(
                      _encodeMedications(draft.medications),
                    ),
                    referralRequested: Value(draft.referralRequested),
                    version: Value(existing.version + 1),
                    updatedAt: Value(DateTime.now()),
                  ),
                );
        if (changed != 1) {
          throw const ConflictFailure(
            'This draft changed elsewhere. Reload before saving.',
          );
        }
      }
      final saved = await (_db.select(
        _db.encounterDrafts,
      )..where((d) => d.appointmentId.equals(draft.appointmentId))).getSingle();
      return _toDraft(saved);
    });
  }

  @override
  Future<Result<void>> discard(String appointmentId) {
    return Result.guardAsync(() async {
      final actor = await _access.requireStaffOrAdmin(
        entityType: 'encounter_draft',
        entityId: appointmentId,
      );
      final draft = await (_db.select(
        _db.encounterDrafts,
      )..where((d) => d.appointmentId.equals(appointmentId))).getSingleOrNull();
      if (actor != null &&
          draft != null &&
          !actor.isAdmin &&
          draft.authorStaffId != actor.accountId) {
        throw const AccessDeniedFailure(
          'This encounter draft belongs to another clinician.',
        );
      }
      await (_db.delete(
        _db.encounterDrafts,
      )..where((d) => d.appointmentId.equals(appointmentId))).go();
    });
  }

  static String _encodeMedications(List<DraftMedicationData> medications) =>
      jsonEncode([
        for (final medication in medications)
          {
            'name': medication.name,
            'dose': medication.dose,
            'frequency': medication.frequency,
          },
      ]);

  static EncounterDraftData _toDraft(EncounterDraftRow row) {
    final raw = jsonDecode(row.medicationsJson) as List<dynamic>;
    return EncounterDraftData(
      appointmentId: row.appointmentId,
      patientId: row.patientId,
      authorStaffId: row.authorStaffId,
      note: row.note,
      medications: [
        for (final value in raw.cast<Map<String, dynamic>>())
          DraftMedicationData(
            name: value['name'] as String,
            dose: value['dose'] as String?,
            frequency: value['frequency'] as String?,
          ),
      ],
      referralRequested: row.referralRequested,
      version: row.version,
      updatedAt: row.updatedAt,
    );
  }
}

class WalkInTicketRepositoryImpl implements WalkInTicketRepository {
  WalkInTicketRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db),
      _idempotency = IdempotencyGuard(_db);

  final AppDatabase _db;
  final AccessPolicy _access;
  final IdempotencyGuard _idempotency;

  @override
  Future<Result<WalkInTicket>> create(
    NewWalkInTicket r, {
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      // A clinician sends a patient they are seeing to a department desk;
      // an administrator does it when actioning an internal referral.
      final actor = await _access.assertActor(
        r.createdByStaffId,
        entityType: 'walk_in',
      );
      if (actor != null && actor.isAdmin) {
        await _access.require(
          Permission.decideReferrals,
          entityType: 'walk_in',
        );
      } else if (actor != null) {
        await _access.clinicalWrite(
          staffId: r.createdByStaffId,
          patientId: r.patientId,
          permission: Permission.manageWalkInQueue,
          entityType: 'walk_in',
        );
      }
      final dept = await (_db.select(
        _db.departments,
      )..where((d) => d.id.equals(r.departmentId))).getSingleOrNull();
      if (dept == null) {
        throw NotFoundFailure('No department ${r.departmentId}.');
      }

      final id = await _db.transaction(() async {
        final prior = await _idempotency.prior(
          idempotencyKey,
          scope: 'walk_in.create',
          actorAccountId: r.createdByStaffId,
        );
        if (prior != null) return prior;
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
        await _idempotency.remember(
          idempotencyKey,
          scope: 'walk_in.create',
          actorAccountId: r.createdByStaffId,
          resultRef: id,
        );
        return id;
      });
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
      await _access.requireStaffOrAdmin(entityType: 'walk_in');
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
      await _access.readPatient(
        patientId,
        scope: PatientDataScope.administrative,
        entityType: 'walk_in',
      );
      final rows =
          await (_db.select(_db.walkInTickets)
                ..where((t) => t.patientId.equals(patientId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<WalkInTicket>> byId(String id) => Result.guardAsync(() async {
    final ticket = await _require(id);
    await _access.readPatient(
      ticket.patientId,
      scope: PatientDataScope.administrative,
      entityType: 'walk_in',
      entityId: id,
    );
    return ticket;
  });

  @override
  Future<Result<WalkInTicket>> claim({
    required String id,
    required String doctorId,
    required String resultAppointmentId,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        doctorId,
        Permission.manageWalkInQueue,
        entityType: 'walk_in',
        entityId: id,
      );
      // Conditional claim: only an open, unclaimed ticket (at the version the
      // caller saw) changes. When two clinicians race, one write matches and
      // the other matches nothing.
      final claimed =
          await (_db.update(_db.walkInTickets)..where(
                (t) =>
                    t.id.equals(id) &
                    t.claimedByStaffId.isNull() &
                    t.status.isInValues([
                      WalkInStatus.waiting,
                      WalkInStatus.called,
                    ]) &
                    (expectedVersion == null
                        ? const Constant(true)
                        : t.version.equals(expectedVersion)),
              ))
              .write(
                WalkInTicketsCompanion(
                  status: const Value(WalkInStatus.inProgress),
                  claimedByStaffId: Value(doctorId),
                  resultAppointmentId: Value(resultAppointmentId),
                ),
              );
      if (claimed != 1) {
        final current = await _require(id);
        throw ConflictFailure(
          current.claimedByStaffId == null
              ? 'This ticket changed. Reload the queue.'
              : 'Another clinician has already taken this patient.',
          currentVersion: current.version,
        );
      }
      return _require(id);
    });
  }

  @override
  Future<Result<WalkInTicket>> resolve(String id) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'walk_in', entityId: id);
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
      await _access.requireStaffOrAdmin(entityType: 'walk_in');
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
      await _access.requireStaffOrAdmin(entityType: 'walk_in', entityId: id);
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
  ReferralRequestRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db),
      _idempotency = IdempotencyGuard(_db),
      _outbox = Outbox(_db);

  final AppDatabase _db;
  final AccessPolicy _access;
  final IdempotencyGuard _idempotency;
  final Outbox _outbox;

  @override
  Future<Result<ReferralRequest>> create(
    NewReferralRequest r, {
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      await _access.clinicalWrite(
        staffId: r.requestedByStaffId,
        patientId: r.patientId,
        permission: Permission.requestReferral,
        entityType: 'referral_request',
      );
      if (r.reason.trim().isEmpty) {
        throw const ValidationFailure('A reason for the referral is required.');
      }
      final id = await _db.transaction(() async {
        final prior = await _idempotency.prior(
          idempotencyKey,
          scope: 'referral_request.create',
          actorAccountId: r.requestedByStaffId,
        );
        if (prior != null) return prior;
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
        await _idempotency.remember(
          idempotencyKey,
          scope: 'referral_request.create',
          actorAccountId: r.requestedByStaffId,
          resultRef: id,
        );
        return id;
      });
      return _require(id);
    });
  }

  @override
  Future<Result<List<ReferralRequest>>> pending() {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.decideReferrals,
        entityType: 'referral_request',
      );
      final rows =
          await (_db.select(_db.referralRequests)
                ..where(
                  (t) => t.status.isInValues([
                    ReferralRequestStatus.pending,
                    ReferralRequestStatus.clarificationRequested,
                    ReferralRequestStatus.accepted,
                    ReferralRequestStatus.arranged,
                  ]),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<ReferralRequest>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      await _access.readPatient(patientId, entityType: 'referral_request');
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
      await _access.requireStaffOrAdmin(entityType: 'referral_request');
      final row =
          await (_db.select(_db.referralRequests)
                ..where(
                  (t) =>
                      t.appointmentId.equals(appointmentId) &
                      t.status.isInValues(const [
                        ReferralRequestStatus.pending,
                        ReferralRequestStatus.clarificationRequested,
                        ReferralRequestStatus.accepted,
                        ReferralRequestStatus.arranged,
                      ]),
                )
                ..limit(1))
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
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.decideReferrals,
        entityType: 'referral_request',
        entityId: id,
      );
      await _access.assertActor(
        adminId,
        entityType: 'referral_request',
        entityId: id,
      );
      final updated =
          await (_db.update(_db.referralRequests)..where(
                (t) =>
                    t.id.equals(id) &
                    t.status.equalsValue(ReferralRequestStatus.pending) &
                    (expectedVersion == null
                        ? const Constant(true)
                        : t.version.equals(expectedVersion)),
              ))
              .write(
                ReferralRequestsCompanion(
                  status: Value(status),
                  decidedByAdminId: Value(adminId),
                  decisionNote: note == null
                      ? const Value.absent()
                      : Value(note.trim()),
                  decidedAt: Value(DateTime.now()),
                ),
              );
      if (updated != 1) {
        final current = await _require(id);
        throw ConflictFailure(
          current.status == ReferralRequestStatus.pending
              ? 'This referral request changed. Reload to see the latest.'
              : 'This referral request was already decided.',
          currentVersion: current.version,
        );
      }
      return _require(id);
    });
  }

  /// Allowed referral steps. `actioned` (the older one-step "referred out")
  /// is still reachable through [decide].
  static const _referralSteps =
      <ReferralRequestStatus, Set<ReferralRequestStatus>>{
        ReferralRequestStatus.pending: {
          ReferralRequestStatus.clarificationRequested,
          ReferralRequestStatus.accepted,
          ReferralRequestStatus.rejected,
        },
        ReferralRequestStatus.clarificationRequested: {
          ReferralRequestStatus.accepted,
          ReferralRequestStatus.rejected,
        },
        ReferralRequestStatus.accepted: {ReferralRequestStatus.arranged},
        ReferralRequestStatus.arranged: {ReferralRequestStatus.closed},
      };

  @override
  Future<Result<ReferralRequest>> transition({
    required String id,
    required ReferralRequestStatus status,
    required String actorId,
    required String ownerStaffId,
    String? coverageStaffId,
    String? handoverNote,
    DateTime? dueAt,
    WorkPriority? priority,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.decideReferrals,
        entityType: 'referral_request',
        entityId: id,
      );
      await _access.assertActor(
        actorId,
        entityType: 'referral_request',
        entityId: id,
      );
      final current = await _require(id);
      if (!(_referralSteps[current.status]?.contains(status) ?? false)) {
        throw ValidationFailure(
          'Cannot move referral from ${current.status.name} to '
          '${status.name}.',
        );
      }
      await _requireOwner(ownerStaffId);
      if (coverageStaffId != null) await _requireOwner(coverageStaffId);
      final note = handoverNote?.trim() ?? '';
      final ownerChanged =
          current.ownerStaffId != null && current.ownerStaffId != ownerStaffId;
      if (ownerChanged && note.isEmpty) {
        throw const ValidationFailure(
          'Add a handover note when the referral changes owner.',
        );
      }
      if (status == ReferralRequestStatus.clarificationRequested &&
          note.isEmpty) {
        throw const ValidationFailure('Say what needs clarifying.');
      }
      final now = DateTime.now();
      await _db.transaction(() async {
        final updated =
            await (_db.update(_db.referralRequests)..where(
                  (row) =>
                      row.id.equals(id) &
                      row.status.equalsValue(current.status) &
                      row.version.equals(expectedVersion ?? current.version),
                ))
                .write(
                  ReferralRequestsCompanion(
                    status: Value(status),
                    ownerStaffId: Value(ownerStaffId),
                    coverageStaffId: Value(coverageStaffId),
                    handoverNote: note.isEmpty
                        ? const Value.absent()
                        : Value(note),
                    dueAt: dueAt == null ? const Value.absent() : Value(dueAt),
                    priority: priority == null
                        ? const Value.absent()
                        : Value(priority),
                    decidedByAdminId: Value(actorId),
                    decidedAt: Value(now),
                  ),
                );
        if (updated != 1) {
          final latest = await _require(id);
          throw ConflictFailure(
            'This referral changed. Reload before moving it on.',
            currentVersion: latest.version,
          );
        }
        if (status == ReferralRequestStatus.clarificationRequested) {
          // The requesting clinician owes the answer; tell them through the
          // outbox, only if the step commits.
          await _outbox.enqueueNotification(
            NewNotification(
              recipientId: current.requestedByStaffId,
              category: NotificationCategory.message,
              title: 'Referral needs clarification',
              body: note,
              createdAt: now,
            ),
          );
        }
        await _access.audit(
          'referral.${status.name}',
          entityType: 'referral_request',
          entityId: id,
          subjectPatientId: current.patientId,
          detail: ownerChanged
              ? 'owner ${current.ownerStaffId} -> $ownerStaffId'
              : 'owner $ownerStaffId',
        );
      });
      return _require(id);
    });
  }

  @override
  Future<Result<ReferralRequest>> handover({
    required String id,
    required String actorId,
    required String newOwnerId,
    required String note,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.decideReferrals,
        entityType: 'referral_request',
        entityId: id,
      );
      await _access.assertActor(
        actorId,
        entityType: 'referral_request',
        entityId: id,
      );
      if (note.trim().isEmpty) {
        throw const ValidationFailure(
          'Add a handover note for the next owner.',
        );
      }
      final current = await _require(id);
      if (!current.isPending) {
        throw const ValidationFailure(
          'A closed referral cannot be handed over.',
        );
      }
      await _requireOwner(newOwnerId);
      final updated =
          await (_db.update(_db.referralRequests)..where(
                (row) =>
                    row.id.equals(id) &
                    row.version.equals(expectedVersion ?? current.version),
              ))
              .write(
                ReferralRequestsCompanion(
                  ownerStaffId: Value(newOwnerId),
                  handoverNote: Value(note.trim()),
                ),
              );
      if (updated != 1) {
        final latest = await _require(id);
        throw ConflictFailure(
          'This referral changed. Reload before handing it over.',
          currentVersion: latest.version,
        );
      }
      await _access.audit(
        'referral.handover',
        entityType: 'referral_request',
        entityId: id,
        subjectPatientId: current.patientId,
        detail: '${current.ownerStaffId ?? '-'} -> $newOwnerId',
      );
      return _require(id);
    });
  }

  /// A referral's owner must be an active staff member or administrator —
  /// never blank, a patient, or a deactivated account.
  Future<void> _requireOwner(String accountId) async {
    final user = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(accountId))).getSingleOrNull();
    if (accountId.trim().isEmpty ||
        user == null ||
        !user.isActive ||
        user.role == UserRole.patient) {
      throw const ValidationFailure(
        'A referral must be owned by an active staff member.',
      );
    }
  }

  Future<ReferralRequest> _require(String id) async {
    final row = await (_db.select(
      _db.referralRequests,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundFailure('No referral request $id.');
    return row.toEntity();
  }
}

/// Encounter finalization (Phase 4). Owns what used to be written straight
/// from the consultation screen's controller, so the "one transaction, at
/// most once" rule is enforced where the data lives.
class EncounterRepositoryImpl implements EncounterRepository {
  EncounterRepositoryImpl(
    this._db, {
    required AppointmentRepository appointments,
    required WalkInTicketRepository walkIns,
    AccessPolicy? access,
    DateTime Function()? now,
  }) : _access = access ?? AccessPolicy.unenforced(_db),
       _appointments = appointments,
       _walkIns = walkIns,
       _idempotency = IdempotencyGuard(_db),
       _outbox = Outbox(_db),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final AccessPolicy _access;
  final AppointmentRepository _appointments;
  final WalkInTicketRepository _walkIns;
  final IdempotencyGuard _idempotency;
  final Outbox _outbox;
  final DateTime Function() _now;

  static const _scope = 'encounter.finalize';

  /// One signed note per appointment; the id is derived from it so even a
  /// retry with a fresh key after a crash lands on the same row.
  static String signedNoteIdFor(String appointmentId) =>
      'signed_$appointmentId';

  @override
  Future<Result<SignedNote>> finalize(
    FinalizeEncounter request, {
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      final r = request;
      // Nurses draft; only a clinician who may sign finalizes.
      await _access.actAsStaff(
        r.staffId,
        Permission.signEncounter,
        entityType: 'encounter',
        entityId: r.appointmentId,
      );
      final meds = [
        for (final m in r.medications)
          if (m.name.trim().isNotEmpty) m,
      ];
      if (meds.isNotEmpty) {
        await _access.actAsStaff(
          r.staffId,
          Permission.prescribe,
          entityType: 'encounter',
          entityId: r.appointmentId,
        );
      }
      final appt = await (_db.select(
        _db.appointments,
      )..where((a) => a.id.equals(r.appointmentId))).getSingleOrNull();
      if (appt == null) throw const NotFoundFailure('Appointment not found.');
      if (_access.isEnforced && appt.staffId != r.staffId) {
        throw const AccessDeniedFailure(
          'This consultation is assigned to another clinician.',
        );
      }

      final noteId = await _db.transaction(() async {
        final prior = await _idempotency.prior(
          idempotencyKey,
          scope: _scope,
          actorAccountId: r.staffId,
        );
        if (prior != null) return prior;
        final noteId = signedNoteIdFor(r.appointmentId);
        final existing = await (_db.select(
          _db.signedNotes,
        )..where((n) => n.id.equals(noteId))).getSingleOrNull();
        if (existing != null) return noteId;

        final now = _now();
        final body = r.note.trim();
        await _db
            .into(_db.signedNotes)
            .insert(
              SignedNotesCompanion.insert(
                id: noteId,
                appointmentId: r.appointmentId,
                patientId: appt.patientId,
                authorStaffId: r.staffId,
                body: body,
                signedAt: Value(now),
              ),
            );
        if (body.isNotEmpty) {
          await _db
              .into(_db.medicalRecords)
              .insert(
                MedicalRecordsCompanion.insert(
                  id: 'rec_note_${r.appointmentId}',
                  patientId: appt.patientId,
                  recordType: RecordType.visitNote,
                  title: 'Consultation note',
                  occurredAt: now,
                  authorStaffId: Value(r.staffId),
                  appointmentId: Value(r.appointmentId),
                  body: Value(body),
                  createdByAccountId: Value(r.staffId),
                ),
              );
        }
        for (final (i, m) in meds.indexed) {
          await _db
              .into(_db.medications)
              .insert(
                MedicationsCompanion.insert(
                  // Deterministic per encounter + line, so no path can ever
                  // file the same order twice.
                  id: 'med_${r.appointmentId}_$i',
                  patientId: appt.patientId,
                  name: m.name.trim(),
                  dose: Value(m.dose),
                  frequency: Value(m.frequency),
                  prescriberId: Value(r.staffId),
                  appointmentId: Value(r.appointmentId),
                  startDate: now,
                ),
              );
          await _outbox.enqueueNotification(
            NewNotification(
              recipientId: appt.patientId,
              category: NotificationCategory.prescription,
              title: 'New prescription',
              body: [m.name.trim(), ?m.dose, ?m.frequency].join(' · '),
              createdAt: now,
            ),
          );
        }
        _throwIfErr(
          await _appointments.completeVisit(
            id: r.appointmentId,
            staffId: r.staffId,
            outcomeNote: r.outcomeNote,
          ),
        );
        // A walk-in visit closes its ticket too.
        _throwIfErr(await _walkIns.resolveByAppointment(r.appointmentId));
        await (_db.delete(
          _db.encounterDrafts,
        )..where((d) => d.appointmentId.equals(r.appointmentId))).go();
        await _access.audit(
          'encounter.finalize',
          entityType: 'appointment',
          entityId: r.appointmentId,
          subjectPatientId: appt.patientId,
          detail: '${meds.length} medication order(s)',
        );
        await _idempotency.remember(
          idempotencyKey,
          scope: _scope,
          actorAccountId: r.staffId,
          resultRef: noteId,
        );
        return noteId;
      });
      return _load(noteId);
    });
  }

  @override
  Future<Result<SignedNote?>> signedNoteFor(String appointmentId) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.signedNotes,
      )..where((n) => n.appointmentId.equals(appointmentId))).getSingleOrNull();
      if (row == null) {
        await _access.requireStaffOrAdmin(
          entityType: 'encounter',
          entityId: appointmentId,
        );
        return null;
      }
      await _access.readPatient(
        row.patientId,
        entityType: 'encounter',
        entityId: appointmentId,
      );
      return _load(row.id);
    });
  }

  @override
  Future<Result<NoteAmendment>> amend({
    required String signedNoteId,
    required String staffId,
    required String body,
  }) {
    return Result.guardAsync(() async {
      if (body.trim().isEmpty) {
        throw const ValidationFailure('Write the correction to add.');
      }
      final note = await (_db.select(
        _db.signedNotes,
      )..where((n) => n.id.equals(signedNoteId))).getSingleOrNull();
      if (note == null) throw const NotFoundFailure('Signed note not found.');
      await _access.clinicalWrite(
        staffId: staffId,
        patientId: note.patientId,
        permission: Permission.writeClinicalRecord,
        entityType: 'encounter',
        entityId: note.appointmentId,
      );
      final id = newId('amd');
      await _db.transaction(() async {
        await _db
            .into(_db.signedNoteAmendments)
            .insert(
              SignedNoteAmendmentsCompanion.insert(
                id: id,
                signedNoteId: signedNoteId,
                authorStaffId: staffId,
                body: body.trim(),
                amendedAt: Value(_now()),
              ),
            );
        await _access.audit(
          'encounter.amend',
          entityType: 'appointment',
          entityId: note.appointmentId,
          subjectPatientId: note.patientId,
        );
      });
      final row = await (_db.select(
        _db.signedNoteAmendments,
      )..where((a) => a.id.equals(id))).getSingle();
      return _amendment(row);
    });
  }

  Future<SignedNote> _load(String id) async {
    final row = await (_db.select(
      _db.signedNotes,
    )..where((n) => n.id.equals(id))).getSingle();
    final amendments =
        await (_db.select(_db.signedNoteAmendments)
              ..where((a) => a.signedNoteId.equals(id))
              ..orderBy([(a) => OrderingTerm(expression: a.amendedAt)]))
            .get();
    return SignedNote(
      id: row.id,
      appointmentId: row.appointmentId,
      patientId: row.patientId,
      authorStaffId: row.authorStaffId,
      body: row.body,
      signedAt: row.signedAt,
      amendments: amendments.map(_amendment).toList(),
    );
  }

  static NoteAmendment _amendment(SignedNoteAmendmentRow a) => NoteAmendment(
    id: a.id,
    signedNoteId: a.signedNoteId,
    authorStaffId: a.authorStaffId,
    body: a.body,
    amendedAt: a.amendedAt,
  );

  static void _throwIfErr(Result<Object?> r) {
    if (r case Err(:final failure)) throw failure;
  }
}
