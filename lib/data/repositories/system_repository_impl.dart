/// Drift-backed [AuditRepository] + [SettingsRepository] + [FeedbackRepository]
/// + [AiUsageRepository] (P1-17).
library;

import 'package:drift/drift.dart';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/system_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<void>> record({
    required String action,
    required String entityType,
    String? entityId,
    String? actorUserId,
    String? detail,
  }) {
    return Result.guardAsync(() async {
      // When enforced, the actor is whoever is signed in — a caller-supplied
      // actor is kept only as a note if it disagrees.
      var actor = actorUserId;
      var note = detail;
      if (_access.isEnforced) {
        actor = _access.actingAccountId;
        if (actorUserId != null && actorUserId != actor) {
          note = [?detail, 'claimed actor: $actorUserId'].join(' · ');
        }
      }
      await _db
          .into(_db.auditLog)
          .insert(
            AuditLogCompanion.insert(
              id: newId('aud'),
              action: action,
              entityType: entityType,
              entityId: Value(entityId),
              actorUserId: Value(actor),
              detail: Value(note),
            ),
          );
    });
  }

  @override
  Future<Result<List<AuditEntry>>> query(AuditQuery query) async =>
      (await queryPage(
        query,
        page: PageRequest(size: query.limit.clamp(1, PageLimits.maxSize)),
      )).map((p) => p.items);

  @override
  Future<Result<Page<AuditEntry>>> queryPage(
    AuditQuery query, {
    PageRequest page = const PageRequest(),
  }) {
    return Result.guardAsync(() async {
      // Anyone may read their own trail; the whole log is for auditors —
      // and reading it is itself recorded (protected access log).
      final own = query.actorUserId;
      if (own != null) {
        await _access.selfOrAdmin(
          own,
          Permission.readAuditLog,
          entityType: 'audit',
        );
      } else {
        await _access.require(Permission.readAuditLog, entityType: 'audit');
        if (page.offset == 0 && _access.isEnforced) {
          await _access.audit('audit.viewed', entityType: 'audit');
        }
      }
      final q = _db.select(_db.auditLog)
        ..orderBy([
          (a) => OrderingTerm.desc(a.at),
          (a) => OrderingTerm.desc(a.id),
        ])
        ..limit(page.size + 1, offset: page.offset);
      if (query.actorUserId != null) {
        q.where((a) => a.actorUserId.equals(query.actorUserId!));
      }
      if (query.entityType != null) {
        q.where((a) => a.entityType.equals(query.entityType!));
      }
      if (query.entityId != null) {
        q.where((a) => a.entityId.equals(query.entityId!));
      }
      if (query.from != null) {
        q.where((a) => a.at.isBiggerOrEqualValue(query.from!));
      }
      if (query.to != null) {
        q.where((a) => a.at.isSmallerOrEqualValue(query.to!));
      }
      final rows = await q.get();
      final hasMore = rows.length > page.size;
      return Page(
        items: [
          for (final r in hasMore ? rows.sublist(0, page.size) : rows)
            r.toEntity(),
        ],
        offset: page.offset,
        hasMore: hasMore,
      );
    });
  }
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  static const _defaults = AppSettingsCompanion(id: Value(1));

  Future<AppSettingsRow> _ensureRow() async {
    final existing = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;
    await _db.into(_db.appSettings).insert(_defaults);
    return (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(1))).getSingle();
  }

  @override
  Future<Result<AppSettings>> get() {
    return Result.guardAsync(() async => (await _ensureRow()).toEntity());
  }

  @override
  Stream<AppSettings> watch() {
    return (_db.select(_db.appSettings)..where((s) => s.id.equals(1)))
        .watchSingleOrNull()
        .asyncMap((row) async => (row ?? await _ensureRow()).toEntity());
  }

  @override
  Future<Result<({Set<int> openDays, int openHour, int closeHour})?>>
  clinicSchedule() {
    return Result.guardAsync(() async {
      final row = await _ensureRow();
      final days = row.clinicOpenDays;
      final open = row.clinicOpenHour;
      final close = row.clinicCloseHour;
      if (days == null || open == null || close == null) return null;
      return (
        openDays: days.isEmpty
            ? <int>{}
            : days.split(',').map(int.parse).toSet(),
        openHour: open,
        closeHour: close,
      );
    });
  }

  @override
  Future<Result<void>> setClinicSchedule({
    required Set<int> openDays,
    required int openHour,
    required int closeHour,
  }) {
    return Result.guardAsync(
      () => _db.transaction(() async {
        await _access.require(
          Permission.manageSettings,
          entityType: 'settings',
        );
        if (openHour < 0 || closeHour > 24 || openHour >= closeHour) {
          throw const ValidationFailure(
            'Opening time must be before closing time.',
          );
        }
        if (openDays.any((d) => d < 1 || d > 7))
          throw const ValidationFailure('Use weekdays 1 through 7.');
        final bookings =
            await (_db.select(_db.appointments)..where(
                  (a) =>
                      a.slotEnd.isBiggerThanValue(DateTime.now()) &
                      a.status.isInValues([
                        AppointmentStatus.booked,
                        AppointmentStatus.confirmed,
                        AppointmentStatus.inProgress,
                      ]),
                ))
                .get();
        if (bookings.any(
          (a) =>
              !openDays.contains(a.slotStart.weekday) ||
              a.slotStart.hour * 60 + a.slotStart.minute < openHour * 60 ||
              a.slotEnd.hour * 60 + a.slotEnd.minute > closeHour * 60,
        )) {
          throw const ValidationFailure(
            'Preview and replace or reschedule affected bookings before reducing service hours.',
          );
        }
        await _ensureRow();
        await (_db.update(_db.appSettings)..where((r) => r.id.equals(1))).write(
          AppSettingsCompanion(
            clinicOpenDays: Value((openDays.toList()..sort()).join(',')),
            clinicOpenHour: Value(openHour),
            clinicCloseHour: Value(closeHour),
          ),
        );
      }),
    );
  }

  @override
  Future<Result<void>> update(AppSettings s) {
    return Result.guardAsync(() async {
      await _access.require(Permission.manageSettings, entityType: 'settings');
      await _ensureRow();
      await (_db.update(_db.appSettings)..where((r) => r.id.equals(1))).write(
        AppSettingsCompanion(
          aiEnabled: Value(s.aiEnabled),
          mockMode: Value(s.mockMode),
          modelId: Value(s.modelId),
          aiTaskWeight: Value(s.aiTaskWeight),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}

class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<void>> submit({
    required FeedbackCategory category,
    required String message,
    String? reporterId,
  }) {
    return Result.guardAsync(() async {
      if (reporterId != null) {
        await _access.assertActor(reporterId, entityType: 'feedback');
      }
      await _db
          .into(_db.feedbacks)
          .insert(
            FeedbacksCompanion.insert(
              id: newId('fbk'),
              category: category,
              message: message.trim(),
              reporterId: Value(reporterId),
            ),
          );
    });
  }

  @override
  Future<Result<List<UserFeedback>>> all({FeedbackStatus? status}) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.viewOperationalReports,
        entityType: 'feedback',
      );
      final q = _db.select(_db.feedbacks)
        ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]);
      if (status != null) q.where((f) => f.status.equalsValue(status));
      final rows = await q.get();
      if (rows.isEmpty) return const <UserFeedback>[];

      final ids = rows.map((r) => r.reporterId).whereType<String>().toSet();
      final users = ids.isEmpty
          ? const <UserRow>[]
          : await (_db.select(_db.users)..where((u) => u.id.isIn(ids))).get();
      final byId = {for (final u in users) u.id: u};

      return rows
          .map(
            (r) => feedbackFrom(
              r,
              name: byId[r.reporterId]?.fullName,
              email: byId[r.reporterId]?.email,
            ),
          )
          .toList();
    });
  }

  @override
  Future<Result<void>> setStatus({
    required String id,
    required FeedbackStatus status,
    String? adminId,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.viewOperationalReports,
        entityType: 'feedback',
        entityId: id,
      );
      if (adminId != null) {
        await _access.assertActor(
          adminId,
          entityType: 'feedback',
          entityId: id,
        );
      }
      final resolving = status == FeedbackStatus.resolved;
      await (_db.update(_db.feedbacks)..where((f) => f.id.equals(id))).write(
        FeedbacksCompanion(
          status: Value(status),
          handledByAdminId: Value(resolving ? adminId : null),
          handledAt: Value(resolving ? DateTime.now() : null),
        ),
      );
    });
  }
}

class AiUsageRepositoryImpl implements AiUsageRepository {
  AiUsageRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<void>> log({
    required AiFeature feature,
    required bool usedLiveModel,
    String? userId,
    String? summary,
  }) {
    return Result.guardAsync(() async {
      if (userId != null) {
        await _access.assertActor(userId, entityType: 'ai_usage');
      }
      await _db
          .into(_db.aiUsageLog)
          .insert(
            AiUsageLogCompanion.insert(
              id: newId('ail'),
              feature: feature,
              usedLiveModel: Value(usedLiveModel),
              userId: Value(userId),
              summary: Value(analyticsSummary(feature, summary)),
            ),
          );
    });
  }

  /// The usage log is operational analytics, not a clinical record: it
  /// never stores what was typed or dictated, or whose chart it was — only
  /// the feature and the input size. Enforced here so no caller can leak
  /// health text into it.
  static String analyticsSummary(AiFeature feature, String? input) {
    final label = switch (feature) {
      AiFeature.careNavigator => 'Care Navigator question',
      AiFeature.clinicalScribe => 'Clinical scribe draft',
      AiFeature.patientSummary => 'Record summary',
    };
    final size = input?.length ?? 0;
    return size == 0 ? label : '$label · $size characters';
  }

  @override
  Future<Result<Page<AiUsageEntry>>> recentPage({
    AiFeature? feature,
    PageRequest page = const PageRequest(),
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.viewOperationalReports,
        entityType: 'ai_usage',
      );
      final q = _db.select(_db.aiUsageLog)
        ..orderBy([
          (l) => OrderingTerm.desc(l.at),
          (l) => OrderingTerm.desc(l.id),
        ])
        ..limit(page.size + 1, offset: page.offset);
      if (feature != null) q.where((l) => l.feature.equalsValue(feature));
      final rows = await q.get();
      final hasMore = rows.length > page.size;
      return Page(
        items: [
          for (final r in hasMore ? rows.sublist(0, page.size) : rows)
            r.toEntity(),
        ],
        offset: page.offset,
        hasMore: hasMore,
      );
    });
  }

  @override
  Future<Result<List<AiUsageEntry>>> recent({
    AiFeature? feature,
    int limit = 100,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.viewOperationalReports,
        entityType: 'ai_usage',
      );
      final q = _db.select(_db.aiUsageLog)
        ..orderBy([(l) => OrderingTerm.desc(l.at)])
        ..limit(limit);
      if (feature != null) q.where((l) => l.feature.equalsValue(feature));
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }
}
