import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import '../db/tables/sync.dart';
import 'booking_safety.dart';

enum AdminQueue {
  referral,
  homeVisit,
  review,
  reply,
  document,
  delivery,
  feedback,
}

class AdminWork {
  const AdminWork({
    required this.type,
    required this.sourceId,
    required this.created,
    required this.route,
    required this.nextAction,
    this.owner,
    this.due,
    this.state = 'open',
    this.version = 0,
    this.urgent = false,
  });
  final AdminQueue type;
  final String sourceId, route, nextAction, state;
  final String? owner;
  final DateTime created;
  final DateTime? due;
  final int version;
  final bool urgent;
  String get id => '${type.name}:$sourceId';
  bool get overdue =>
      state != 'resolved' && due != null && due!.isBefore(DateTime.now());
}

class AdminSearchHit {
  const AdminSearchHit(this.label, this.detail, this.route);
  final String label, detail, route;
}

final adminWorkspaceProvider = Provider(
  (ref) => AdminWorkspace(
    ref.watch(appDatabaseProvider),
    ref.watch(accessPolicyProvider),
  ),
);

/// Administrative metadata only. Clinical decisions stay in source repositories.
class AdminWorkspace {
  AdminWorkspace(this.db, this.access);
  final AppDatabase db;
  final AccessPolicy access;
  static Permission permission(AdminQueue type) => switch (type) {
    AdminQueue.referral => Permission.decideReferrals,
    AdminQueue.homeVisit => Permission.decideHomeVisits,
    AdminQueue.review || AdminQueue.reply => Permission.manageCareTeams,
    AdminQueue.document => Permission.manageSettings,
    AdminQueue.delivery => Permission.broadcastNotifications,
    AdminQueue.feedback => Permission.viewOperationalReports,
  };
  Future<void> authorize(Permission p) async {
    final actor = await access.principal();
    if (actor == null || !actor.isAdmin) {
      throw const AccessDeniedFailure('Administrator access required.');
    }
    await access.require(p, entityType: 'admin_workspace');
  }

  Future<List<AdminWork>> queue() async {
    await authorize(Permission.viewOperationalReports);
    final actor = (await access.principal())!;
    final work = <AdminWork>[];
    final now = DateTime.now();
    if (actor.permissions.contains(Permission.decideReferrals)) {
      for (final r in await db.select(db.referralRequests).get()) {
        if ({
          ReferralRequestStatus.actioned,
          ReferralRequestStatus.rejected,
          ReferralRequestStatus.closed,
        }.contains(r.status)) {
          continue;
        }
        work.add(
          AdminWork(
            type: AdminQueue.referral,
            sourceId: r.id,
            created: r.createdAt,
            owner: r.ownerStaffId,
            due: r.dueAt,
            urgent: r.priority == WorkPriority.urgent,
            route:
                '/admin/dashboard/referral-requests?source=${Uri.encodeComponent(r.id)}',
            nextAction: 'Arrange referral or request clarification',
          ),
        );
      }
    }
    if (actor.permissions.contains(Permission.decideHomeVisits)) {
      for (final r in await db.select(db.homeVisitRequests).get()) {
        if (r.status != HomeVisitStatus.requested &&
            r.status != HomeVisitStatus.scheduled) {
          continue;
        }
        work.add(
          AdminWork(
            type: AdminQueue.homeVisit,
            sourceId: r.id,
            created: r.createdAt,
            owner: r.assignedStaffId,
            due: r.preferredDate,
            route:
                '/admin/dashboard/home-visits?source=${Uri.encodeComponent(r.id)}',
            nextAction: 'Triage or arrange home visit',
          ),
        );
      }
    }
    if (actor.permissions.contains(Permission.manageCareTeams)) {
      for (final r in await db.select(db.resultReviews).get()) {
        if (r.status == ResultReviewStatus.resolved) continue;
        work.add(
          AdminWork(
            type: AdminQueue.review,
            sourceId: r.id,
            created: r.createdAt,
            owner: r.ownerStaffId,
            due: r.dueAt,
            urgent: r.priority == WorkPriority.urgent,
            route: '/admin/dashboard/work?review=${Uri.encodeComponent(r.id)}',
            nextAction:
                'Assign a qualified clinician; clinical review remains separate',
          ),
        );
      }
      final messages = await db.select(db.careMessages).get();
      for (final m in messages) {
        if (m.fromStaff ||
            m.responseDueAt == null ||
            messages.any(
              (r) =>
                  r.fromStaff &&
                  r.patientId == m.patientId &&
                  r.staffId == m.staffId &&
                  r.sentAt.isAfter(m.sentAt),
            )) {
          continue;
        }
        work.add(
          AdminWork(
            type: AdminQueue.reply,
            sourceId: m.id,
            created: m.sentAt,
            owner: m.queueOwnerStaffId ?? m.staffId,
            due: m.responseDueAt,
            route: '/admin/dashboard/work?reply=${Uri.encodeComponent(m.id)}',
            nextAction:
                'Coordinate clinician response; message content remains clinical',
          ),
        );
      }
    }
    if (actor.permissions.contains(Permission.manageSettings)) {
      for (final r in await db.select(db.documentRequests).get()) {
        if (!{'draft', 'submitted', 'approved'}.contains(r.status)) continue;
        work.add(
          AdminWork(
            type: AdminQueue.document,
            sourceId: r.id,
            created: r.createdAt,
            owner: r.requestedBy,
            due: r.createdAt.add(const Duration(days: 1)),
            route:
                '/admin/profile/document-workspace?patientId=${Uri.encodeComponent(r.patientId)}',
            nextAction: 'Prepare or route for authorized approval and issuance',
          ),
        );
      }
    }
    if (actor.permissions.contains(Permission.broadcastNotifications)) {
      for (final r in await db.select(db.reminders).get()) {
        if (r.deliveryStatus != ReminderDeliveryStatus.failed) continue;
        work.add(
          AdminWork(
            type: AdminQueue.delivery,
            sourceId: 'reminder:${r.id}',
            created: r.scheduledFor,
            due: r.nextAttemptAt ?? r.scheduledFor,
            route: '/admin/dashboard/work',
            nextAction: 'Review reminder failure and retry',
          ),
        );
      }
      for (final r in await db.select(db.outboxEvents).get()) {
        if (r.status != OutboxStatus.failed) continue;
        work.add(
          AdminWork(
            type: AdminQueue.delivery,
            sourceId: r.id,
            created: r.createdAt,
            due: r.nextAttemptAt,
            route:
                '/admin/dashboard/work?delivery=${Uri.encodeComponent(r.id)}',
            nextAction: 'Review delivery failure and retry',
          ),
        );
      }
      for (final r in await db.select(db.documentDeliveryEvents).get()) {
        if (r.status != 'failed') continue;
        work.add(
          AdminWork(
            type: AdminQueue.delivery,
            sourceId: 'document:${r.id}',
            created: r.createdAt,
            due: r.createdAt,
            route: '/admin/documents',
            nextAction: 'Retry document delivery in its authorized workspace',
          ),
        );
      }
    }
    for (final r in await db.select(db.feedbacks).get()) {
      if (r.status == FeedbackStatus.resolved) continue;
      work.add(
        AdminWork(
          type: AdminQueue.feedback,
          sourceId: r.id,
          created: r.createdAt,
          owner: r.handledByAdminId,
          due: r.createdAt.add(const Duration(days: 3)),
          route: '/admin/feedback?source=${Uri.encodeComponent(r.id)}',
          nextAction: 'Investigate feedback and record resolution',
        ),
      );
    }
    final stored = {
      for (final r in await db.select(db.adminWorkItems).get()) r.id: r,
    };
    final merged = [
      for (final w in work)
        if (stored[w.id] case final r?)
          AdminWork(
            type: w.type,
            sourceId: w.sourceId,
            created: w.created,
            route: w.route,
            nextAction: w.nextAction,
            owner: r.ownerId,
            due: r.dueAt,
            state: r.status,
            version: r.version,
            urgent: w.urgent,
          )
        else
          w,
    ];
    merged.sort((a, b) {
      if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
      final date = (a.due ?? now.add(const Duration(days: 365))).compareTo(
        b.due ?? now.add(const Duration(days: 365)),
      );
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
    await access.assertActor(actor.accountId, entityType: 'admin_workspace');
    await authorize(Permission.viewOperationalReports);
    return merged;
  }

  Future<List<UserRow>> owners() async {
    await authorize(Permission.viewOperationalReports);
    return (db.select(db.users)..where(
          (u) => u.role.equalsValue(UserRole.admin) & u.isActive.equals(true),
        ))
        .get();
  }

  Future<void> updateWork(
    AdminWork item, {
    required String owner,
    required DateTime due,
    required String status,
    required String reason,
  }) async {
    await authorize(permission(item.type));
    if (!{'open', 'waiting', 'resolved'}.contains(status) ||
        reason.trim().isEmpty ||
        reason.length > 2000) {
      throw const ValidationFailure(
        'Record a reason or outcome (up to 2000 characters).',
      );
    }
    if (status == 'waiting' && !due.isAfter(DateTime.now())) {
      throw const ValidationFailure('Waiting work needs a future review time.');
    }
    await db.transaction(() async {
      await authorize(permission(item.type));
      final source = (await queue()).where((w) => w.id == item.id).firstOrNull;
      if (source == null) {
        throw const ConflictFailure('Source work is no longer pending.');
      }
      if (source.version != item.version) {
        throw const ConflictFailure('Work changed. Reload before saving.');
      }
      final holder = await (db.select(
        db.users,
      )..where((u) => u.id.equals(owner))).getSingleOrNull();
      if (holder == null || !holder.isActive || holder.role != UserRole.admin) {
        throw const ValidationFailure(
          'Choose an active operational administrator.',
        );
      }
      final row = await (db.select(
        db.adminWorkItems,
      )..where((w) => w.id.equals(item.id))).getSingleOrNull();
      final actor = (await access.principal())!.accountId;
      final next = {
        'owner': owner,
        'due': due.toIso8601String(),
        'status': status,
      };
      await db
          .into(db.adminWorkItems)
          .insertOnConflictUpdate(
            AdminWorkItemsCompanion.insert(
              id: item.id,
              sourceType: item.type.name,
              sourceId: item.sourceId,
              ownerId: Value(owner),
              dueAt: Value(due),
              status: Value(status),
              outcome: Value(reason.trim()),
              version: Value((row?.version ?? 0) + 1),
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.adminWorkHistory)
          .insert(
            AdminWorkHistoryCompanion.insert(
              id: const Uuid().v4(),
              workId: item.id,
              actorId: actor,
              beforeJson: jsonEncode({
                'owner': source.owner,
                'due': source.due?.toIso8601String(),
                'status': source.state,
              }),
              afterJson: jsonEncode(next),
              reason: reason.trim(),
              at: DateTime.now(),
            ),
          );
      await access.audit(
        'admin.work.$status',
        entityType: 'admin_work',
        entityId: item.id,
        detail: jsonEncode(next),
      );
      if (row?.ownerId != owner || status == 'waiting') {
        await db
            .into(db.notifications)
            .insert(
              NotificationsCompanion.insert(
                id: const Uuid().v4(),
                recipientId: owner,
                category: NotificationCategory.system,
                title: 'Operational work assigned',
                body: 'Review your assigned work and deadline.',
                deepLink: Value(
                  '/admin/work?item=${Uri.encodeComponent(item.id)}',
                ),
              ),
            );
      }
      if (status == 'waiting') {
        final recipient = await _informationRecipient(item);
        if (recipient != null && recipient != owner) {
          final user = await (db.select(
            db.users,
          )..where((u) => u.id.equals(recipient))).getSingleOrNull();
          if (user != null && user.isActive && user.hasLogin) {
            await db
                .into(db.notifications)
                .insert(
                  NotificationsCompanion.insert(
                    id: const Uuid().v4(),
                    recipientId: recipient,
                    category: NotificationCategory.system,
                    title: 'Clinic information request',
                    body:
                        'Please contact the clinic coordinator about reference ${item.sourceId}.',
                    deepLink: Value(
                      user.role == UserRole.admin
                          ? '/admin/work?item=${Uri.encodeComponent(item.id)}'
                          : user.role == UserRole.staff
                          ? '/staff/inbox'
                          : '/patient/notifications',
                    ),
                  ),
                );
          }
        }
      }
    });
  }

  Future<String?> _informationRecipient(AdminWork item) async {
    switch (item.type) {
      case AdminQueue.referral:
        return (await (db.select(
              db.referralRequests,
            )..where((r) => r.id.equals(item.sourceId))).getSingle())
            .requestedByStaffId;
      case AdminQueue.homeVisit:
        return (await (db.select(
          db.homeVisitRequests,
        )..where((r) => r.id.equals(item.sourceId))).getSingle()).patientId;
      case AdminQueue.review:
        return (await (db.select(
          db.resultReviews,
        )..where((r) => r.id.equals(item.sourceId))).getSingle()).ownerStaffId;
      case AdminQueue.reply:
        return (await (db.select(
          db.careMessages,
        )..where((r) => r.id.equals(item.sourceId))).getSingle()).staffId;
      case AdminQueue.document:
        return (await (db.select(
          db.documentRequests,
        )..where((r) => r.id.equals(item.sourceId))).getSingle()).requestedBy;
      case AdminQueue.feedback:
        return (await (db.select(
          db.feedbacks,
        )..where((r) => r.id.equals(item.sourceId))).getSingle()).reporterId;
      case AdminQueue.delivery:
        return null;
    }
  }

  Future<List<AdminWorkHistoryRow>> history(AdminWork item) async {
    await authorize(permission(item.type));
    return (db.select(db.adminWorkHistory)
          ..where((h) => h.workId.equals(item.id))
          ..orderBy([(h) => OrderingTerm.desc(h.at)]))
        .get();
  }

  Future<List<AdminSearchHit>> search(String query) async {
    await authorize(Permission.viewOperationalReports);
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    final actor = (await access.principal())!;
    final hits = <AdminSearchHit>[];
    if (actor.permissions.contains(Permission.manageUsers)) {
      for (final u in await db.select(db.users).get()) {
        if ('${u.fullName} ${u.email} ${u.id}'.toLowerCase().contains(q)) {
          hits.add(
            AdminSearchHit(
              u.fullName,
              u.role.name,
              '/admin/users/${Uri.encodeComponent(u.id)}',
            ),
          );
        }
      }
    }
    if (actor.permissions.contains(Permission.manageClinicSchedules)) {
      final names = {
        for (final u in await db.select(db.users).get()) u.id: u.fullName,
      };
      for (final a in await db.select(db.appointments).get()) {
        if ('${a.id} ${names[a.patientId]} ${names[a.staffId]}'
            .toLowerCase()
            .contains(q)) {
          hits.add(
            AdminSearchHit(
              a.id,
              '${names[a.patientId]} · ${a.slotStart}',
              '/admin/appointments?appointment=${Uri.encodeComponent(a.id)}',
            ),
          );
        }
      }
    }
    if (actor.permissions.contains(Permission.manageSettings)) {
      for (final d in await db.select(db.issuedDocumentVersions).get()) {
        if ('${d.id} ${d.requestId} ${d.documentType}'.toLowerCase().contains(
          q,
        )) {
          hits.add(
            AdminSearchHit(
              d.id,
              d.documentType,
              '/admin/profile/document-workspace?patientId=${Uri.encodeComponent(d.patientId)}',
            ),
          );
        }
      }
    }
    await access.assertActor(actor.accountId, entityType: 'admin_workspace');
    await authorize(Permission.viewOperationalReports);
    return hits;
  }

  Future<Map<String, dynamic>> configuration(String key) async {
    await authorize(Permission.manageSettings);
    if (!{'clinic', 'integrations', 'backup'}.contains(key) &&
        key != 'actions:${access.actingAccountId}') {
      throw const AccessDeniedFailure(
        'Configuration belongs to another account.',
      );
    }
    final r = await (db.select(
      db.clinicConfigurations,
    )..where((c) => c.id.equals(key))).getSingleOrNull();
    return r == null ? {} : jsonDecode(r.valueJson) as Map<String, dynamic>;
  }

  Future<void> saveConfiguration(
    String key,
    Map<String, dynamic> values,
  ) async {
    await authorize(Permission.manageSettings);
    if (!{'clinic', 'integrations', 'backup'}.contains(key) &&
        key != 'actions:${access.actingAccountId}') {
      throw const ValidationFailure('Unknown configuration.');
    }
    final allowed = switch (key) {
      'clinic' => {'name', 'address', 'contact'},
      'integrations' => {'apiOrigin', 'verificationOrigin'},
      'backup' => {'recoveryOwner', 'recoveryHours', 'retentionDays'},
      _ => {'visible'},
    };
    if (values.keys.any((k) => !allowed.contains(k))) {
      throw const ValidationFailure('Unknown configuration field.');
    }
    if (key == 'backup' &&
        ([
          'recoveryHours',
          'retentionDays',
        ].any((k) => (int.tryParse('${values[k] ?? ''}') ?? 0) <= 0))) {
      throw const ValidationFailure(
        'Recovery and retention targets must be positive.',
      );
    }
    if (key == 'clinic' &&
        (values['name'] is! String ||
            (values['name'] as String).trim().isEmpty)) {
      throw const ValidationFailure('Clinic name is required.');
    }
    if (key == 'integrations') {
      for (final name in ['verificationOrigin', 'apiOrigin']) {
        final value = values[name] as String? ?? '';
        final uri = Uri.tryParse(value);
        if (value.isNotEmpty &&
            (uri == null ||
                uri.scheme != 'https' ||
                uri.host.isEmpty ||
                uri.userInfo.isNotEmpty ||
                uri.hasQuery ||
                uri.hasFragment ||
                (uri.path.isNotEmpty && uri.path != '/'))) {
          throw const ValidationFailure(
            'Use an HTTPS origin without credentials, query or fragment.',
          );
        }
      }
    }
    await db.transaction(() async {
      await authorize(Permission.manageSettings);
      await db
          .into(db.clinicConfigurations)
          .insertOnConflictUpdate(
            ClinicConfigurationsCompanion.insert(
              id: key,
              valueJson: jsonEncode(values),
              updatedAt: DateTime.now(),
            ),
          );
      await access.audit(
        'clinic.configuration.updated',
        entityType: 'clinic_configuration',
        entityId: key,
      );
    });
  }

  Future<List<AppointmentRow>> affectedBookings(String staff) async {
    await authorize(Permission.manageClinicSchedules);
    return (db.select(db.appointments)..where(
          (a) =>
              a.staffId.equals(staff) &
              a.status.isInValues(activeBookingStates),
        ))
        .get();
  }

  Future<void> moveBookings(
    String from,
    String to,
    List<AppointmentRow> preview,
    String reason,
  ) async {
    await authorize(Permission.manageClinicSchedules);
    if (from == to || reason.trim().isEmpty || preview.isEmpty) {
      throw const ValidationFailure(
        'Choose a replacement and record a reason.',
      );
    }
    await db.transaction(() async {
      await authorize(Permission.manageClinicSchedules);
      final replacement = await (db.select(
        db.users,
      )..where((u) => u.id.equals(to))).getSingleOrNull();
      final profile = await (db.select(
        db.staffProfiles,
      )..where((s) => s.userId.equals(to))).getSingleOrNull();
      final original = await (db.select(
        db.staffProfiles,
      )..where((s) => s.userId.equals(from))).getSingle();
      if (replacement == null ||
          !replacement.isActive ||
          replacement.role != UserRole.staff ||
          profile == null ||
          profile.departmentId != original.departmentId ||
          profile.jobTitle == 'Nurse') {
        throw const ValidationFailure(
          'Choose an active doctor in the same department.',
        );
      }
      final templates = await (db.select(
        db.scheduleTemplates,
      )..where((s) => s.staffId.equals(to))).get();
      final exceptions = await (db.select(
        db.availabilityExceptions,
      )..where((e) => e.staffId.equals(to))).get();
      for (final old in preview) {
        final current = await (db.select(
          db.appointments,
        )..where((a) => a.id.equals(old.id))).getSingle();
        if (current.version != old.version ||
            current.staffId != from ||
            current.status == AppointmentStatus.inProgress ||
            !activeBookingStates.contains(current.status)) {
          throw const ConflictFailure(
            'Bookings changed or a consultation already started. Reload the preview.',
          );
        }
        final start = current.slotStart.hour * 60 + current.slotStart.minute;
        final end =
            start + current.slotEnd.difference(current.slotStart).inMinutes;
        if (!templates.any(
              (s) =>
                  s.weekday == current.slotStart.weekday &&
                  s.startMinutes <= start &&
                  s.endMinutes >= end &&
                  s.slotMinutes == end - start &&
                  (start - s.startMinutes) % s.slotMinutes == 0,
            ) ||
            exceptions.any(
              (e) =>
                  e.startsAt.isBefore(current.slotEnd) &&
                  e.endsAt.isAfter(current.slotStart),
            )) {
          throw const ValidationFailure(
            'Replacement availability does not cover all previewed bookings.',
          );
        }
        final clashes =
            await (db.select(db.appointments)..where(
                  (a) =>
                      a.staffId.equals(to) &
                      a.status.isInValues(activeBookingStates) &
                      a.slotStart.isSmallerThanValue(current.slotEnd) &
                      a.slotEnd.isBiggerThanValue(current.slotStart),
                ))
                .get();
        if (clashes.isNotEmpty) {
          throw const ConflictFailure('Replacement has a conflicting booking.');
        }
        await (db.update(db.appointments)..where(
              (a) => a.id.equals(current.id) & a.version.equals(old.version),
            ))
            .write(AppointmentsCompanion(staffId: Value(to)));
        await db
            .into(db.notifications)
            .insert(
              NotificationsCompanion.insert(
                id: const Uuid().v4(),
                recipientId: current.patientId,
                category: NotificationCategory.appointment,
                title: 'Appointment clinician changed',
                body:
                    'Your appointment time is unchanged. Please review the updated clinician.',
                deepLink: const Value('/patient/visits'),
              ),
            );
        await access.audit(
          'appointment.replacement_assigned',
          entityType: 'appointment',
          entityId: current.id,
          detail: jsonEncode({'from': from, 'to': to, 'reason': reason.trim()}),
        );
      }
    });
  }
}
