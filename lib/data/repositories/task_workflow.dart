/// Human-owned work, canonical source links and explicit handover acceptance.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../domain/identity/operational_roles.dart';
import '../../domain/identity/permissions.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'task_cover.dart';

final taskWorkflowProvider = Provider<TaskWorkflow>(
  (ref) => TaskWorkflow(
    ref.watch(appDatabaseProvider),
    ref.watch(accessPolicyProvider),
  ),
);

class TaskContext {
  const TaskContext(
    this.task,
    this.sources,
    this.history,
    this.owner,
    this.cover,
    this.reason,
  );
  final StaffTask task;
  final List<TaskSourceRow> sources;
  final List<TaskHistoryRow> history;
  final String owner;
  final String? cover;
  final String reason;
}

class TaskWorkflow {
  TaskWorkflow(this.db, this.access);
  final AppDatabase db;
  final AccessPolicy access;

  Future<bool> _assignmentGrant(String actor, String? patient) async {
    if (!access.isEnforced) return true;
    final now = DateTime.now();
    final grants =
        await (db.select(db.scopedGrants)..where(
              (g) =>
                  g.accountId.equals(actor) &
                  g.permission.equals(Permission.assignOperationalWork.name) &
                  g.revokedAt.isNull() &
                  g.startsAt.isSmallerOrEqualValue(now) &
                  (g.expiresAt.isNull() | g.expiresAt.isBiggerThanValue(now)),
            ))
            .get();
    return grants.any(
      (g) =>
          g.scope == GrantScope.clinic.name && g.scopeId.isEmpty ||
          g.scope == GrantScope.patient.name && g.scopeId == patient,
    );
  }

  Future<StaffTaskRow> _task(
    String id,
    String actor, {
    bool team = false,
  }) async {
    await access.actAsStaff(actor, Permission.manageTasks);
    final row = await (db.select(
      db.staffTasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundFailure('Task not found.');
    if (row.coverageStaffId == actor &&
        row.staffId != actor &&
        !await activeTaskCover(db, id, actor)) {
      throw const AccessDeniedFailure('Cover has expired.');
    }
    if (row.patientId != null) await access.readPatient(row.patientId!);
    if (row.staffId != actor && row.coverageStaffId != actor) {
      if (!team) throw const AccessDeniedFailure();
      await access.requireScoped(
        Permission.assignOperationalWork,
        patientId: row.patientId,
      );
    }
    return row;
  }

  Future<TaskContext> context(String id, String actor) async {
    final row = await _task(id, actor, team: true);
    final sources = await (db.select(
      db.taskSources,
    )..where((s) => s.taskId.equals(id))).get();
    final history =
        await (db.select(db.taskHistory)
              ..where((h) => h.taskId.equals(id))
              ..orderBy([(h) => OrderingTerm.desc(h.at)]))
            .get();
    final owner = await (db.select(
      db.users,
    )..where((u) => u.id.equals(row.staffId))).getSingle();
    final cover = row.coverageStaffId == null
        ? null
        : await (db.select(
            db.users,
          )..where((u) => u.id.equals(row.coverageStaffId!))).getSingleOrNull();
    var reason = row.title;
    for (final source in sources.where((s) => s.sourceType == 'risk')) {
      final flag = await (db.select(
        db.riskFlags,
      )..where((f) => f.id.equals(source.sourceId))).getSingleOrNull();
      if (flag != null) {
        if (flag.patientId != row.patientId) {
          throw const AccessDeniedFailure(
            'Source patient does not match this work.',
          );
        }
        reason = flag.rationale;
      }
    }
    return TaskContext(
      row.toEntity(),
      sources,
      history,
      owner.fullName,
      cover?.fullName,
      reason,
    );
  }

  Future<List<StaffTask>> team(String actor) async {
    await access.actAsStaff(actor, Permission.manageTasks);
    final visible = await access.clinicallyVisiblePatientIds();
    final rows = await (db.select(
      db.staffTasks,
    )..where((t) => t.patientId.isNotNull())).get();
    final result = <StaffTask>[];
    for (final row in rows) {
      if (visible != null && !visible.contains(row.patientId)) continue;
      try {
        await access.requireScoped(
          Permission.assignOperationalWork,
          patientId: row.patientId,
        );
        result.add(row.toEntity());
      } on AccessDeniedFailure {
        /* A clinical relationship alone grants no team assignment. */
      }
    }
    return result;
  }

  Future<List<UserRow>> recipients(String actor) async {
    await access.actAsStaff(actor, Permission.manageTasks);
    return (db.select(db.users)..where(
          (u) =>
              u.role.equalsValue(UserRole.staff) &
              u.isActive.equals(true) &
              u.id.equals(actor).not(),
        ))
        .get();
  }

  Future<void> _event(
    String task,
    String actor,
    String action,
    Map<String, Object?> after, {
    String? reason,
    String? id,
    Map<String, Object?> before = const {},
  }) async {
    await db
        .into(db.taskHistory)
        .insert(
          TaskHistoryCompanion.insert(
            id: id ?? const Uuid().v4(),
            taskId: task,
            actorAccountId: Value(actor),
            action: action,
            beforeJson: jsonEncode(before),
            afterJson: jsonEncode(after),
            outcome: Value(reason),
            at: DateTime.now(),
          ),
        );
    await access.audit(
      action,
      entityType: 'staff_task',
      entityId: task,
      detail: jsonEncode(after),
    );
  }

  Future<void> _notify(String recipient, String title, String body) async {
    await db
        .into(db.notifications)
        .insert(
          NotificationsCompanion.insert(
            id: const Uuid().v4(),
            recipientId: recipient,
            category: NotificationCategory.system,
            title: title,
            body: body,
            deepLink: const Value('/staff/tasks/handover'),
          ),
        );
  }

  /// Clinical responsibility stays with the current owner until all work in
  /// this bundle is accepted. No patient details are sent in an offer notice.
  Future<void> offer({
    required String actor,
    required Map<String, int> tasks,
    required String recipient,
    required String reason,
    required DateTime expires,
    bool reassign = false,
    bool urgent = false,
  }) async {
    if (tasks.isEmpty ||
        reason.trim().isEmpty ||
        reason.length > 2000 ||
        !expires.isAfter(DateTime.now()) ||
        expires.isAfter(DateTime.now().add(const Duration(hours: 72)))) {
      throw const ValidationFailure(
        'Select work, a reason and a cover period of up to 72 hours.',
      );
    }
    final people = await recipients(actor);
    if (!people.any((p) => p.id == recipient)) {
      throw const ValidationFailure('Choose an active colleague.');
    }
    await db.transaction(() async {
      final bundle = const Uuid().v4();
      for (final entry in tasks.entries) {
        final row = await _task(entry.key, actor, team: reassign);
        if (reassign) {
          await access.requireScoped(
            Permission.assignOperationalWork,
            patientId: row.patientId,
          );
        }
        if (row.version != entry.value) {
          throw const ConflictFailure('Work changed. Reload before handover.');
        }
        if (row.status == TaskStatus.done ||
            row.status == TaskStatus.dismissed) {
          throw const ValidationFailure('Closed work cannot be handed over.');
        }
        await _event(
          row.id,
          actor,
          'task.offer',
          {
            'bundle': bundle,
            'recipient': recipient,
            'owner': row.staffId,
            'version': row.version,
            'expires': expires.toUtc().toIso8601String(),
            'reassign': reassign,
            'urgent': urgent,
          },
          reason: reason.trim(),
          before: {
            'owner': row.staffId,
            'cover': row.coverageStaffId,
            'version': row.version,
          },
        );
        if (urgent) {
          await (db.update(
            db.staffTasks,
          )..where((t) => t.id.equals(row.id))).write(
            StaffTasksCompanion(
              priority: const Value(WorkPriority.urgent),
              escalatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
      await _notify(
        recipient,
        'Responsibility acceptance requested',
        '${tasks.length} work items await your decision.',
      );
    });
  }

  /// Only sender/count/expiry are returned before acceptance: no patient data.
  Future<List<({String bundle, String sender, int count, DateTime expires})>>
  pending(String actor) async {
    await access.actAsStaff(actor, Permission.manageTasks);
    final rows =
        await (db.select(db.taskHistory)..where(
              (h) =>
                  h.action.equals('task.offer') |
                  h.action.equals('task.offer.accepted') |
                  h.action.equals('task.offer.declined'),
            ))
            .get();
    final finished = rows
        .where((h) => h.action != 'task.offer')
        .map((h) => (jsonDecode(h.afterJson) as Map<String, dynamic>)['bundle'])
        .toSet();
    final groups = <String, List<TaskHistoryRow>>{};
    for (final row in rows.where((h) => h.action == 'task.offer')) {
      final data = jsonDecode(row.afterJson) as Map<String, dynamic>;
      if (data['recipient'] != actor ||
          finished.contains(data['bundle']) ||
          !DateTime.parse(data['expires'] as String).isAfter(DateTime.now())) {
        continue;
      }
      groups.putIfAbsent(data['bundle'] as String, () => []).add(row);
    }
    return [
      for (final group in groups.entries)
        (
          bundle: group.key,
          sender: group.value.first.actorAccountId ?? '',
          count: group.value.length,
          expires: DateTime.parse(
            (jsonDecode(group.value.first.afterJson)
                    as Map<String, dynamic>)['expires']
                as String,
          ),
        ),
    ];
  }

  Future<void> decide(
    String actor,
    String bundle, {
    required bool accept,
  }) async {
    await access.actAsStaff(actor, Permission.manageTasks);
    await db.transaction(() async {
      if (!(await pending(actor)).any((p) => p.bundle == bundle)) {
        throw const ConflictFailure('Offer expired or was already answered.');
      }
      final offers =
          (await (db.select(
                db.taskHistory,
              )..where((h) => h.action.equals('task.offer'))).get())
              .where(
                (h) =>
                    (jsonDecode(h.afterJson)
                        as Map<String, dynamic>)['bundle'] ==
                    bundle,
              )
              .toList();
      for (final offer in offers) {
        final data = jsonDecode(offer.afterJson) as Map<String, dynamic>;
        final row = await (db.select(
          db.staffTasks,
        )..where((t) => t.id.equals(offer.taskId))).getSingle();
        if (accept) {
          final sender = offer.actorAccountId!;
          final senderAccount = await (db.select(
            db.users,
          )..where((u) => u.id.equals(sender))).getSingle();
          if (!senderAccount.isActive || senderAccount.role != UserRole.staff) {
            throw const AccessDeniedFailure(
              'Sender no longer has clinical authority.',
            );
          }
          final delegated =
              data['reassign'] == true &&
              await _assignmentGrant(sender, row.patientId);
          if (data['reassign'] == true && !delegated) {
            throw const AccessDeniedFailure(
              'Assignment authority was revoked.',
            );
          }
          if (row.version !=
              (data['version'] as int) + (data['urgent'] == true ? 1 : 0)) {
            throw const ConflictFailure('Work changed; request a fresh offer.');
          }
          // Revalidate the sender's existing relationship and current ownership;
          // never resurrect revoked access through an old invitation.
          if (row.staffId != data['owner'] ||
              (row.staffId != sender &&
                  row.coverageStaffId != sender &&
                  !delegated)) {
            throw const ConflictFailure(
              'Assignment changed; request a fresh offer.',
            );
          }
          if (row.status == TaskStatus.done ||
              row.status == TaskStatus.dismissed) {
            throw const ConflictFailure(
              'Work was closed; request a fresh handover.',
            );
          }
          final expires = DateTime.parse(data['expires'] as String);
          if (row.patientId != null) {
            final senderCare =
                await (db.select(db.careTeamAssignments)..where(
                      (c) =>
                          c.patientId.equals(row.patientId!) &
                          c.staffId.equals(sender) &
                          c.assignedAt.isSmallerOrEqualValue(DateTime.now()) &
                          (c.endedAt.isNull() |
                              c.endedAt.isBiggerOrEqualValue(expires)),
                    ))
                    .get();
            final visits =
                await (db.select(db.appointments)..where(
                      (a) =>
                          a.patientId.equals(row.patientId!) &
                          a.staffId.equals(sender),
                    ))
                    .get();
            if (senderCare.isEmpty && visits.isEmpty) {
              throw const AccessDeniedFailure(
                'Sender no longer has a care relationship.',
              );
            }
            final prior = await db.select(db.careTeamAssignments).get();
            for (final c in prior.where(
              (c) => c.id.startsWith('task-cover-${row.id}-'),
            )) {
              await (db.update(
                db.careTeamAssignments,
              )..where((a) => a.id.equals(c.id))).write(
                CareTeamAssignmentsCompanion(endedAt: Value(DateTime.now())),
              );
            }
            await db
                .into(db.careTeamAssignments)
                .insert(
                  CareTeamAssignmentsCompanion.insert(
                    id: 'task-cover-${row.id}-${offer.id}',
                    patientId: row.patientId!,
                    staffId: actor,
                    role: CareTeamRole.consultant,
                    assignedAt: DateTime.now(),
                    assignedBy: Value(sender),
                    endedAt: Value(data['reassign'] == true ? null : expires),
                  ),
                );
          }
          await (db.update(db.staffTasks)..where(
                (t) => t.id.equals(row.id) & t.version.equals(row.version),
              ))
              .write(
                data['reassign'] == true
                    ? StaffTasksCompanion(
                        staffId: Value(actor),
                        coverageStaffId: const Value(null),
                      )
                    : StaffTasksCompanion(coverageStaffId: Value(actor)),
              );
          final sources = await (db.select(
            db.taskSources,
          )..where((s) => s.taskId.equals(row.id))).get();
          for (final source in sources) {
            void validateSubject(String? patient) {
              if (patient != row.patientId) {
                throw const AccessDeniedFailure(
                  'Source patient does not match this work.',
                );
              }
            }

            if (source.sourceType == 'result') {
              final review = await (db.select(
                db.resultReviews,
              )..where((r) => r.id.equals(source.sourceId))).getSingle();
              final record = await (db.select(
                db.medicalRecords,
              )..where((r) => r.id.equals(review.recordId))).getSingle();
              validateSubject(record.patientId);
              await (db.update(db.resultReviews)
                    ..where((r) => r.id.equals(source.sourceId)))
                  .write(ResultReviewsCompanion(coverageStaffId: Value(actor)));
            }
            if (source.sourceType == 'reply') {
              final message = await (db.select(
                db.careMessages,
              )..where((m) => m.id.equals(source.sourceId))).getSingle();
              validateSubject(message.patientId);
              await (db.update(db.careMessages)
                    ..where((m) => m.id.equals(source.sourceId)))
                  .write(CareMessagesCompanion(coverageStaffId: Value(actor)));
            }
            if (source.sourceType == 'referral_request') {
              final referral = await (db.select(
                db.referralRequests,
              )..where((r) => r.id.equals(source.sourceId))).getSingle();
              validateSubject(referral.patientId);
              await (db.update(
                db.referralRequests,
              )..where((r) => r.id.equals(source.sourceId))).write(
                ReferralRequestsCompanion(coverageStaffId: Value(actor)),
              );
            }
          }
        }
        await _event(
          row.id,
          actor,
          accept ? 'task.offer.accepted' : 'task.offer.declined',
          {
            'bundle': bundle,
            'owner': accept && data['reassign'] == true ? actor : row.staffId,
            'cover': accept && data['reassign'] != true
                ? actor
                : row.coverageStaffId,
            'recipient': actor,
            'assignmentVersion': row.version + (accept ? 1 : 0),
          },
          before: {'owner': row.staffId, 'cover': row.coverageStaffId},
        );
      }
      await _notify(
        offers.first.actorAccountId!,
        accept ? 'Handover accepted' : 'Handover declined',
        '${offers.length} work items.',
      );
    });
  }

  /// Owner-independent source IDs make regeneration safe after reassignment.
  /// Existing work is never reopened or automatically completed.
  Future<int> generate(String actor) async {
    await access.actAsStaff(actor, Permission.manageTasks);
    var added = 0;
    Future<void> add(
      String type,
      String source,
      String owner,
      String patient,
      String title,
      TaskKind kind,
      DateTime due, {
      WorkPriority priority = WorkPriority.routine,
    }) async {
      if (owner != actor || !await access.canRead(patient)) return;
      final id = 'source-${sha256.convert(utf8.encode('$type:$source'))}';
      await db.transaction(() async {
        final existing = await (db.select(
          db.staffTasks,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (existing != null) {
          if (priority.index > existing.priority.index) {
            await (db.update(db.staffTasks)..where((t) => t.id.equals(id)))
                .write(StaffTasksCompanion(priority: Value(priority)));
          }
          return;
        }
        if (type == 'result') {
          final review = await (db.select(
            db.resultReviews,
          )..where((r) => r.id.equals(source))).getSingle();
          final flags =
              await (db.select(db.riskFlags)..where(
                    (f) =>
                        f.patientId.equals(patient) &
                        f.kind.equalsValue(RiskFlagKind.abnormalLab),
                  ))
                  .get();
          for (final flag in flags.where(
            (f) => f.dedupeKey.endsWith(
              ':source:${Uri.encodeComponent(review.recordId)}',
            ),
          )) {
            final linked =
                await (db.select(db.taskSources)..where(
                      (s) =>
                          s.sourceType.equals('risk') &
                          s.sourceId.equals(flag.id),
                    ))
                    .get();
            if (linked.isEmpty) continue;
            await db
                .into(db.taskSources)
                .insertOnConflictUpdate(
                  TaskSourcesCompanion.insert(
                    taskId: linked.first.taskId,
                    sourceType: type,
                    sourceId: source,
                    episodeKey: source,
                    recordedAt: DateTime.now(),
                  ),
                );
            return;
          }
        }
        await db
            .into(db.staffTasks)
            .insert(
              StaffTasksCompanion.insert(
                id: id,
                staffId: owner,
                patientId: Value(patient),
                title: title.length > 200 ? title.substring(0, 200) : title,
                kind: kind,
                dueAt: Value(due),
                priority: Value(priority),
                ruleScore: Value(priority == WorkPriority.urgent ? 1.0 : .6),
              ),
            );
        await db
            .into(db.taskSources)
            .insert(
              TaskSourcesCompanion.insert(
                taskId: id,
                sourceType: type,
                sourceId: source,
                episodeKey: source,
                recordedAt: DateTime.now(),
              ),
            );
        await _event(id, actor, 'task.generated', {
          'sourceType': type,
          'sourceId': source,
          'owner': owner,
        });
        added++;
      });
    }

    for (final r in await db.select(db.resultReviews).get()) {
      if (r.status == ResultReviewStatus.resolved || r.ownerStaffId == null) {
        continue;
      }
      final record = await (db.select(
        db.medicalRecords,
      )..where((m) => m.id.equals(r.recordId))).getSingleOrNull();
      if (record != null) {
        await add(
          'result',
          r.id,
          r.ownerStaffId!,
          record.patientId,
          'Review result: ${record.title}',
          TaskKind.unreviewedAbnormalLab,
          r.dueAt,
          priority: r.priority,
        );
      }
    }
    for (final d in await db.select(db.encounterDrafts).get()) {
      if (await (db.select(db.signedNotes)
                ..where((n) => n.appointmentId.equals(d.appointmentId)))
              .getSingleOrNull() !=
          null) {
        continue;
      }
      await add(
        'visit',
        d.appointmentId,
        d.authorStaffId,
        d.patientId,
        'Review and sign consultation draft',
        TaskKind.unsignedNote,
        d.updatedAt.add(const Duration(hours: 24)),
      );
    }
    for (final r in await db.select(db.referralRequests).get()) {
      if ({
        ReferralRequestStatus.closed,
        ReferralRequestStatus.rejected,
        ReferralRequestStatus.actioned,
      }.contains(r.status)) {
        continue;
      }
      final title = 'Follow through referral: ${r.reason}';
      await add(
        'referral_request',
        r.id,
        r.ownerStaffId ?? r.requestedByStaffId,
        r.patientId,
        title.length > 200 ? title.substring(0, 200) : title,
        TaskKind.referralAction,
        r.dueAt ?? r.createdAt.add(const Duration(days: 2)),
        priority: r.priority,
      );
    }
    for (final r in await db.select(db.medicalRecords).get()) {
      if (r.recordType != RecordType.referral ||
          r.authorStaffId == null ||
          r.uploadedByPatient) {
        continue;
      }
      if (r.appointmentId != null &&
          (await (db.select(db.referralRequests)..where(
                    (q) =>
                        q.patientId.equals(r.patientId) &
                        q.appointmentId.equals(r.appointmentId!),
                  ))
                  .get())
              .isNotEmpty) {
        continue;
      }
      await add(
        'referral',
        r.id,
        r.authorStaffId!,
        r.patientId,
        'Follow through referral: ${r.title}',
        TaskKind.referralAction,
        r.occurredAt.add(const Duration(days: 2)),
      );
    }
    for (final d in await db.select(db.documentRequests).get()) {
      if (!{'submitted', 'approved'}.contains(d.status) ||
          d.appointmentId == null) {
        continue;
      }
      final visit = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(d.appointmentId!))).getSingleOrNull();
      if (visit != null) {
        await add(
          'document',
          d.id,
          visit.staffId,
          d.patientId,
          'Review document request',
          TaskKind.other,
          d.createdAt.add(const Duration(hours: 24)),
        );
      }
    }
    final messages = await db.select(db.careMessages).get();
    for (final m in messages) {
      if (m.fromStaff ||
          m.responseDueAt == null ||
          m.responseDueAt!.isAfter(DateTime.now())) {
        continue;
      }
      if (messages.any(
        (reply) =>
            reply.patientId == m.patientId &&
            reply.staffId == m.staffId &&
            reply.fromStaff &&
            !reply.sentAt.isBefore(m.sentAt),
      )) {
        continue;
      }
      // One task per unanswered message episode, independent of current cover.
      await add(
        'reply',
        m.id,
        m.queueOwnerStaffId ?? m.staffId,
        m.patientId,
        'Reply to overdue patient message',
        TaskKind.other,
        m.responseDueAt!,
      );
    }
    return added;
  }

  Future<String> replyTask(String actor, String messageId) async {
    await access.actAsStaff(actor, Permission.manageTasks);
    return db.transaction(() async {
      final m = await (db.select(
        db.careMessages,
      )..where((m) => m.id.equals(messageId))).getSingle();
      await access.readPatient(m.patientId);
      final owner = m.queueOwnerStaffId ?? m.staffId;
      if (m.fromStaff || (owner != actor && m.coverageStaffId != actor)) {
        throw const AccessDeniedFailure();
      }
      final id = 'source-${sha256.convert(utf8.encode('reply:${m.id}'))}';
      if (await (db.select(
            db.staffTasks,
          )..where((t) => t.id.equals(id))).getSingleOrNull() ==
          null) {
        await db
            .into(db.staffTasks)
            .insert(
              StaffTasksCompanion.insert(
                id: id,
                staffId: owner,
                patientId: Value(m.patientId),
                title: 'Reply to patient message',
                kind: TaskKind.other,
                coverageStaffId: Value(m.coverageStaffId),
                dueAt: Value(m.responseDueAt),
              ),
            );
        await db
            .into(db.taskSources)
            .insert(
              TaskSourcesCompanion.insert(
                taskId: id,
                sourceType: 'reply',
                sourceId: m.id,
                episodeKey: m.id,
                recordedAt: DateTime.now(),
              ),
            );
        await _event(id, actor, 'task.created.from_reply', {
          'owner': owner,
          'sourceId': m.id,
        });
      }
      return id;
    });
  }
}
