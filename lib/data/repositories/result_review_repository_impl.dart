/// Drift-backed [ResultReviewRepository] (Phase 4).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/clinical/lab_rules.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/result_review_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import 'task_cover.dart';

/// Opens a review for a just-filed result when any of its [flags] needs one.
/// Call inside the transaction that files the result, so a result never
/// exists without its owned review. Returns the review id, or null.
Future<String?> openResultReviewIfNeeded(
  AppDatabase db, {
  required String recordId,
  required List<AbnormalFlag> flags,
  String? ownerStaffId,
  DateTime? now,
}) async {
  if (!flags.any(LabRules.needsReview)) return null;
  final at = now ?? DateTime.now();
  final priority = LabRules.priorityFor(flags);
  final id = newId('rrv');
  await db
      .into(db.resultReviews)
      .insert(
        ResultReviewsCompanion.insert(
          id: id,
          recordId: recordId,
          ownerStaffId: Value(ownerStaffId),
          dueAt: at.add(LabRules.reviewWindow(priority)),
          priority: Value(priority),
          status: Value(
            ownerStaffId == null
                ? ResultReviewStatus.unassigned
                : ResultReviewStatus.assigned,
          ),
          createdAt: Value(at),
        ),
      );
  return id;
}

class ResultReviewRepositoryImpl implements ResultReviewRepository {
  ResultReviewRepositoryImpl(
    this._db, {
    AccessPolicy? access,
    DateTime Function()? now,
  }) : _access = access ?? AccessPolicy.unenforced(_db),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final AccessPolicy _access;
  final DateTime Function() _now;

  /// Which status changes are allowed. A handover keeps `assigned` and
  /// changes only the owner.
  static const _allowed = <ResultReviewStatus, Set<ResultReviewStatus>>{
    ResultReviewStatus.unassigned: {
      ResultReviewStatus.assigned,
      ResultReviewStatus.escalated,
    },
    ResultReviewStatus.assigned: {
      ResultReviewStatus.assigned,
      ResultReviewStatus.inReview,
      ResultReviewStatus.escalated,
      ResultReviewStatus.resolved,
    },
    ResultReviewStatus.inReview: {
      ResultReviewStatus.assigned,
      ResultReviewStatus.escalated,
      ResultReviewStatus.resolved,
    },
    ResultReviewStatus.escalated: {
      ResultReviewStatus.assigned,
      ResultReviewStatus.inReview,
      ResultReviewStatus.resolved,
    },
  };

  JoinedSelectStatement<HasResultSet, dynamic> _joined() =>
      _db.select(_db.resultReviews).join([
        innerJoin(
          _db.medicalRecords,
          _db.medicalRecords.id.equalsExp(_db.resultReviews.recordId),
        ),
      ]);

  ResultReview _toEntity(TypedResult row) {
    final r = row.readTable(_db.resultReviews);
    final record = row.readTable(_db.medicalRecords);
    return ResultReview(
      id: r.id,
      recordId: r.recordId,
      patientId: record.patientId,
      recordTitle: record.title,
      ownerStaffId: r.ownerStaffId,
      coverageStaffId: r.coverageStaffId,
      dueAt: r.dueAt,
      priority: r.priority,
      status: r.status,
      escalationNote: r.escalationNote,
      resolvedAt: r.resolvedAt,
      resolvedByStaffId: r.resolvedByStaffId,
      resolutionNote: r.resolutionNote,
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  /// Urgent first, then earliest due.
  static int _byUrgency(ResultReview a, ResultReview b) {
    final p = b.priority.index.compareTo(a.priority.index);
    return p != 0 ? p : a.dueAt.compareTo(b.dueAt);
  }

  Future<ResultReview> _require(String id) async {
    final row = await (_joined()..where(_db.resultReviews.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw const NotFoundFailure('Result review not found.');
    return _toEntity(row);
  }

  @override
  Future<Result<ResultReview?>> forRecord(String recordId) {
    return Result.guardAsync(() async {
      final record = await (_db.select(
        _db.medicalRecords,
      )..where((r) => r.id.equals(recordId))).getSingleOrNull();
      if (record == null) throw const NotFoundFailure('Record not found.');
      await _access.readPatient(
        record.patientId,
        entityType: 'result_review',
        entityId: recordId,
      );
      final row =
          await (_joined()..where(_db.resultReviews.recordId.equals(recordId)))
              .getSingleOrNull();
      return row == null ? null : _toEntity(row);
    });
  }

  @override
  Future<Result<List<ResultReview>>> queueFor(String staffId) {
    return Result.guardAsync(() async {
      await _access.selfOrAdmin(
        staffId,
        Permission.manageCareTeams,
        entityType: 'result_review',
      );
      final rows =
          await (_joined()..where(
                (_db.resultReviews.ownerStaffId.equals(staffId) |
                        _db.resultReviews.coverageStaffId.equals(staffId)) &
                    _db.resultReviews.status
                        .equalsValue(ResultReviewStatus.resolved)
                        .not(),
              ))
              .get();
      return rows.map(_toEntity).toList()..sort(_byUrgency);
    });
  }

  @override
  Future<Result<List<ResultReview>>> openReviews({
    bool needsAttentionOnly = false,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageCareTeams,
        entityType: 'result_review',
      );
      final rows =
          await (_joined()..where(
                _db.resultReviews.status
                    .equalsValue(ResultReviewStatus.resolved)
                    .not(),
              ))
              .get();
      final now = _now();
      return rows
          .map(_toEntity)
          .where(
            (r) =>
                !needsAttentionOnly ||
                r.ownerStaffId == null ||
                r.isOverdueAt(now) ||
                r.status == ResultReviewStatus.escalated,
          )
          .toList()
        ..sort(_byUrgency);
    });
  }

  @override
  Future<Result<ResultReview>> assign({
    required String id,
    required String ownerStaffId,
    String? note,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      if (ownerStaffId.trim().isEmpty) {
        throw const ValidationFailure('A review must always have an owner.');
      }
      final current = await _require(id);
      final actor = await _access.principal();
      if (actor != null) {
        final isHolderHandingOver =
            actor.isStaff &&
            actor.can(Permission.reviewResults) &&
            current.isHeldBy(actor.accountId);
        if (!isHolderHandingOver) {
          await _access.require(
            Permission.manageCareTeams,
            entityType: 'result_review',
            entityId: id,
          );
        } else if (note == null || note.trim().isEmpty) {
          throw const ValidationFailure(
            'Add a handover note for the next clinician.',
          );
        }
      }
      await _requireReviewer(ownerStaffId);
      final updated = await _move(
        current,
        ResultReviewStatus.assigned,
        expectedVersion,
        ResultReviewsCompanion(
          ownerStaffId: Value(ownerStaffId),
          escalationNote: note == null || note.trim().isEmpty
              ? const Value.absent()
              : Value(note.trim()),
        ),
      );
      await _access.audit(
        current.ownerStaffId == null
            ? 'result_review.assign'
            : 'result_review.handover',
        entityType: 'result_review',
        entityId: id,
        subjectPatientId: current.patientId,
        detail: '${current.ownerStaffId ?? '-'} -> $ownerStaffId',
      );
      return updated;
    });
  }

  @override
  Future<Result<ResultReview>> startReview({
    required String id,
    required String staffId,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        staffId,
        Permission.reviewResults,
        entityType: 'result_review',
        entityId: id,
      );
      final current = await _require(id);
      await _requireHolder(current, staffId);
      final updated = await _move(
        current,
        ResultReviewStatus.inReview,
        expectedVersion,
        // Whoever picks up an escalated review now owns it.
        ResultReviewsCompanion(ownerStaffId: Value(staffId)),
      );
      await _access.audit(
        'result_review.start',
        entityType: 'result_review',
        entityId: id,
        subjectPatientId: current.patientId,
      );
      return updated;
    });
  }

  @override
  Future<Result<ResultReview>> escalate({
    required String id,
    required String staffId,
    required String coverageStaffId,
    required String note,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      // A nurse holding a result may escalate it; only a doctor resolves.
      await _access.actAsStaff(
        staffId,
        Permission.readPatientChart,
        entityType: 'result_review',
        entityId: id,
      );
      if (note.trim().isEmpty) {
        throw const ValidationFailure('Say why this needs escalating.');
      }
      if (coverageStaffId == staffId) {
        throw const ValidationFailure('Escalate to a different clinician.');
      }
      final current = await _require(id);
      if (current.ownerStaffId != null) await _requireHolder(current, staffId);
      await _requireReviewer(coverageStaffId);
      final updated = await _move(
        current,
        ResultReviewStatus.escalated,
        expectedVersion,
        ResultReviewsCompanion(
          coverageStaffId: Value(coverageStaffId),
          // An unowned result becomes owned by whoever escalated it, so it
          // is never left without an owner.
          ownerStaffId: current.ownerStaffId == null
              ? Value(staffId)
              : const Value.absent(),
          escalationNote: Value(note.trim()),
          priority: const Value(WorkPriority.urgent),
          dueAt: Value(_now().add(LabRules.reviewWindow(WorkPriority.urgent))),
        ),
      );
      await _access.audit(
        'result_review.escalate',
        entityType: 'result_review',
        entityId: id,
        subjectPatientId: current.patientId,
        detail: 'to $coverageStaffId',
      );
      return updated;
    });
  }

  @override
  Future<Result<ResultReview>> resolve({
    required String id,
    required String staffId,
    required String note,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        staffId,
        Permission.reviewResults,
        entityType: 'result_review',
        entityId: id,
      );
      if (note.trim().isEmpty) {
        throw const ValidationFailure(
          'Record what was decided about this result.',
        );
      }
      final current = await _require(id);
      await _requireHolder(current, staffId);
      final now = _now();
      return _db.transaction(() async {
        final updated = await _move(
          current,
          ResultReviewStatus.resolved,
          expectedVersion,
          ResultReviewsCompanion(
            resolvedAt: Value(now),
            resolvedByStaffId: Value(staffId),
            resolutionNote: Value(note.trim()),
          ),
        );
        await (_db.update(_db.labValues)..where(
              (l) =>
                  l.recordId.equals(current.recordId) &
                  l.verificationStatus.equalsValue(
                    VerificationStatus.unverified,
                  ),
            ))
            .write(
              LabValuesCompanion(
                verificationStatus: const Value(VerificationStatus.verified),
                verifiedByStaffId: Value(staffId),
                verifiedAt: Value(now),
              ),
            );
        await _access.audit(
          'result_review.resolve',
          entityType: 'result_review',
          entityId: id,
          subjectPatientId: current.patientId,
        );
        return updated;
      });
    });
  }

  // --- helpers -------------------------------------------------------------

  Future<void> _requireHolder(ResultReview review, String staffId) async {
    if (!_access.isEnforced) return;
    if (!review.isHeldBy(staffId)) {
      throw const AccessDeniedFailure(
        'This result is held by another clinician.',
      );
    }
    if (review.ownerStaffId != staffId && review.coverageStaffId == staffId) {
      final sources =
          await (_db.select(_db.taskSources)..where(
                (s) =>
                    s.sourceType.equals('result') &
                    s.sourceId.equals(review.id),
              ))
              .get();
      for (final source in sources) {
        if (!await activeTaskCover(_db, source.taskId, staffId)) {
          throw const AccessDeniedFailure('Result cover has expired.');
        }
      }
    }
  }

  /// The target must be an active doctor — a review cannot go to a patient,
  /// an admin, an inactive account, or a clinician who cannot resolve it.
  Future<void> _requireReviewer(String staffId) async {
    final user = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(staffId))).getSingleOrNull();
    final profile = await (_db.select(
      _db.staffProfiles,
    )..where((s) => s.userId.equals(staffId))).getSingleOrNull();
    if (user == null ||
        !user.isActive ||
        user.role != UserRole.staff ||
        profile?.jobTitle == kNurseJobTitle) {
      throw const ValidationFailure(
        'Choose an active doctor who can review results.',
      );
    }
  }

  Future<ResultReview> _move(
    ResultReview current,
    ResultReviewStatus to,
    int? expectedVersion,
    ResultReviewsCompanion changes,
  ) async {
    if (!(_allowed[current.status]?.contains(to) ?? false)) {
      throw ValidationFailure(
        current.status == ResultReviewStatus.resolved
            ? 'This result review is already resolved.'
            : 'A review cannot move from ${current.status.name} to '
                  '${to.name}.',
      );
    }
    final version = expectedVersion ?? current.version;
    final changed =
        await (_db.update(_db.resultReviews)..where(
              (r) => r.id.equals(current.id) & r.version.equals(version),
            ))
            .write(changes.copyWith(status: Value(to)));
    if (changed != 1) {
      final latest = await _require(current.id);
      throw ConflictFailure(
        'This result review changed. Reload to see the latest.',
        currentVersion: latest.version,
      );
    }
    return _require(current.id);
  }
}
