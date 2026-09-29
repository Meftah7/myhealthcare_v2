/// Object-level authorization, enforced inside the repositories.
///
/// Every repository method that reads or changes patient, clinical, billing
/// or administrative data asks this policy first. It takes the acting
/// identity from [AuthContext] (set only by a real sign-in) and re-checks the
/// account against the database on every call, so a deactivated account,
/// changed role, expired session or revoked proxy grant stops working
/// immediately — whatever the UI still has cached. Caller-supplied patient
/// and staff IDs are treated as the *target* of the action and authorized
/// against the principal, never trusted as the actor.
///
/// Denials throw [AccessDeniedFailure] and leave an `access.denied` audit
/// entry. Checks run before any transaction opens, so a rollback can never
/// swallow the audit row.
library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';
import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/identity/principal.dart';
import 'auth_context.dart';

/// A live query gated on [authorize]: nothing reaches a listener until the
/// check passes, and a denial arrives as the stream's error (then the stream
/// closes).
///
/// Broadcast, like drift's own query streams: the query subscription opens
/// in the same call as the first listen and is cancelled with the last one,
/// and the check runs again for every new first listener. (A
/// single-subscription wrapper can be left paused by Riverpod with the query
/// still attached, and drift then waits on it forever when it closes.)
Stream<T> authorizedStream<T>(
  Future<void> Function() authorize,
  Stream<T> Function() open,
) {
  late final StreamController<T> controller;
  StreamSubscription<T>? inner;
  var authorized = false;
  final held = <T>[];

  controller = StreamController<T>.broadcast(
    onListen: () {
      authorized = false;
      held.clear();
      final subscription = open().listen(
        (event) => authorized ? controller.add(event) : held.add(event),
        onError: controller.addError,
        onDone: () => unawaited(controller.close()),
      );
      inner = subscription;
      unawaited(
        authorize().then(
          (_) {
            if (!identical(inner, subscription) || controller.isClosed) return;
            authorized = true;
            held.forEach(controller.add);
            held.clear();
          },
          onError: (Object error, StackTrace stack) {
            if (!identical(inner, subscription) || controller.isClosed) return;
            inner = null;
            unawaited(subscription.cancel());
            controller.addError(error, stack);
            unawaited(controller.close());
          },
        ),
      );
    },
    onCancel: () {
      final subscription = inner;
      inner = null;
      unawaited(subscription?.cancel());
    },
  );
  return controller.stream;
}

/// Which kind of patient data a read touches.
///
/// * [clinical] — records, vitals, medications, certificates, AI summaries.
///   Staff need a care relationship; administrators get none.
/// * [administrative] — demographics and bookings. Clinic-wide for staff
///   (queues, search, schedules) and administrators.
/// * [financial] — invoices, wallet, saved cards. Administrators only, on
///   the clinic side.
enum PatientDataScope { clinical, administrative, financial }

class AccessPolicy {
  AccessPolicy(this._db, AuthContext context) : _context = context;

  /// A policy that allows everything. Only for the seeder, migrations and
  /// repository unit tests that exercise storage rules in isolation — the
  /// app's providers always inject an enforcing policy (see `di.dart` and
  /// `test/services/access_policy_test.dart`).
  AccessPolicy.unenforced(this._db) : _context = null;

  final AppDatabase _db;
  final AuthContext? _context;

  bool get isEnforced => _context != null;

  /// The acting account, for stamping `...ByAccountId` columns. Null when
  /// unenforced.
  String? get actingAccountId => _context?.principal?.accountId;

  /// The current principal after confirming the session is live and the
  /// account behind it is still active with the same role. Null when
  /// unenforced.
  Future<Principal?> principal() async {
    final context = _context;
    if (context == null) return null;
    final principal = context.requireActive();
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(principal.accountId))).getSingleOrNull();
    if (row == null ||
        !row.isActive ||
        !row.hasLogin ||
        row.role != principal.role) {
      context.clear();
      throw const SessionExpiredFailure(
        'Your account is no longer available. Please sign in again.',
      );
    }
    return principal;
  }

  /// Require [permission] of the signed-in principal.
  Future<Principal?> require(
    Permission permission, {
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) return null;
    if (!p.can(permission)) {
      await _deny(
        p,
        'missing permission ${permission.name}',
        entityType: entityType,
        entityId: entityId,
      );
    }
    return p;
  }

  /// A sensitive action: the password must have been proven recently.
  Future<Principal?> requireRecentAuthentication() async {
    final p = await principal();
    if (p == null) return null;
    if (!_context!.recentlyAuthenticated) throw const ReauthRequiredFailure();
    return p;
  }

  /// Read access to [patientId]'s data: the patient themself or an accepted
  /// proxy, plus clinic roles as [PatientDataScope] describes.
  Future<void> readPatient(
    String patientId, {
    PatientDataScope scope = PatientDataScope.clinical,
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) return;
    final allowed = switch (p.role) {
      UserRole.patient =>
        p.accountId == patientId ||
            await _proxyGrant(patientId, p.accountId) != null,
      UserRole.staff => switch (scope) {
        PatientDataScope.clinical =>
          p.can(Permission.readPatientChart) &&
              await hasCareRelationship(
                staffId: p.accountId,
                patientId: patientId,
              ),
        PatientDataScope.administrative => true,
        PatientDataScope.financial => false,
      },
      UserRole.admin => scope != PatientDataScope.clinical,
    };
    if (!allowed) {
      await _deny(
        p,
        'no read access to patient',
        entityType: entityType,
        entityId: entityId,
        subjectPatientId: patientId,
      );
    }
  }

  /// Whether the principal may read [patientId]'s [scope] data — the same
  /// rule as [readPatient], without denying (for redacting a field rather
  /// than refusing the whole response). Always true when unenforced.
  Future<bool> canRead(
    String patientId, {
    PatientDataScope scope = PatientDataScope.clinical,
  }) async {
    final p = await principal();
    if (p == null) return true;
    return switch (p.role) {
      UserRole.patient =>
        p.accountId == patientId ||
            await _proxyGrant(patientId, p.accountId) != null,
      UserRole.staff => switch (scope) {
        PatientDataScope.clinical =>
          p.can(Permission.readPatientChart) &&
              await hasCareRelationship(
                staffId: p.accountId,
                patientId: patientId,
              ),
        PatientDataScope.administrative => true,
        PatientDataScope.financial => false,
      },
      UserRole.admin => scope != PatientDataScope.clinical,
    };
  }

  /// Patients the signed-in clinician has a care relationship with — one
  /// query set for redacting a whole list. Null means "no restriction"
  /// (unenforced); empty for non-clinicians.
  Future<Set<String>?> clinicallyVisiblePatientIds() async {
    final p = await principal();
    if (p == null) return null;
    if (p.isPatient) {
      final grants =
          await (_db.select(_db.familyLinks)..where(
                (l) =>
                    l.viewerPatientId.equals(p.accountId) &
                    l.status.equalsValue(FamilyLinkStatus.accepted),
              ))
              .get();
      return {p.accountId, for (final g in grants) g.ownerPatientId};
    }
    if (!p.isStaff || !p.can(Permission.readPatientChart)) return {};
    final now = DateTime.now();
    final appts =
        await (_db.selectOnly(_db.appointments, distinct: true)
              ..addColumns([_db.appointments.patientId])
              ..where(_db.appointments.staffId.equals(p.accountId)))
            .map((r) => r.read(_db.appointments.patientId)!)
            .get();
    final assigned =
        await (_db.select(_db.careTeamAssignments)..where(
              (c) =>
                  c.staffId.equals(p.accountId) &
                  c.assignedAt.isSmallerOrEqualValue(now) &
                  (c.endedAt.isNull() | c.endedAt.isBiggerThanValue(now)),
            ))
            .get();
    final walkIns =
        await (_db.select(_db.walkInTickets)..where(
              (w) =>
                  w.claimedByStaffId.equals(p.accountId) |
                  w.createdByStaffId.equals(p.accountId),
            ))
            .get();
    return {
      ...appts,
      for (final a in assigned) a.patientId,
      for (final w in walkIns) w.patientId,
    };
  }

  /// A patient-side action on [patientId]'s record, made by the patient or a
  /// proxy holding a *manage* grant. Returns both identities so the write can
  /// record who acted and for whom. Unenforced: the patient acts for self.
  Future<PatientSubject> actForPatient(
    String patientId,
    Permission permission, {
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) {
      return PatientSubject(actingAccountId: patientId, patientId: patientId);
    }
    if (!p.isPatient || !p.can(permission)) {
      await _deny(
        p,
        'role cannot ${permission.name}',
        entityType: entityType,
        entityId: entityId,
        subjectPatientId: patientId,
      );
    }
    if (p.accountId == patientId) {
      return PatientSubject(actingAccountId: patientId, patientId: patientId);
    }
    final grant = await _proxyGrant(patientId, p.accountId);
    if (grant == null || !grant.canAct) {
      await _deny(
        p,
        grant == null ? 'no proxy grant' : 'proxy grant is view-only',
        entityType: entityType,
        entityId: entityId,
        subjectPatientId: patientId,
      );
    }
    return PatientSubject(
      actingAccountId: p.accountId,
      patientId: patientId,
      grantId: grant.id,
    );
  }

  /// A staff action performed as [staffId]: the principal must *be* that
  /// clinician and hold [permission].
  Future<Principal?> actAsStaff(
    String staffId,
    Permission permission, {
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) return null;
    if (!p.isStaff || p.accountId != staffId || !p.can(permission)) {
      await _deny(
        p,
        p.accountId != staffId
            ? 'acting as another clinician'
            : 'missing permission ${permission.name}',
        entityType: entityType,
        entityId: entityId,
      );
    }
    return p;
  }

  /// A clinical write by [staffId] about [patientId]: [actAsStaff] plus a
  /// care relationship between them.
  Future<void> clinicalWrite({
    required String staffId,
    required String patientId,
    required Permission permission,
    String? entityType,
    String? entityId,
  }) async {
    final p = await actAsStaff(
      staffId,
      permission,
      entityType: entityType,
      entityId: entityId,
    );
    if (p == null) return;
    if (!await hasCareRelationship(staffId: staffId, patientId: patientId)) {
      await _deny(
        p,
        'no care relationship with patient',
        entityType: entityType,
        entityId: entityId,
        subjectPatientId: patientId,
      );
    }
  }

  /// A clinical write about [patientId] by whichever clinician is signed in
  /// — for operations that do not name a clinician themselves.
  Future<Principal?> clinicalWriteAsCurrentStaff(
    String patientId,
    Permission permission, {
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) return null;
    await clinicalWrite(
      staffId: p.isStaff ? p.accountId : '',
      patientId: patientId,
      permission: permission,
      entityType: entityType,
      entityId: entityId,
    );
    return p;
  }

  /// A caller-supplied "done by" ID (e.g. `adminId`, `createdByStaffId`)
  /// must name the signed-in principal — it is recorded, never trusted.
  Future<Principal?> assertActor(
    String claimedAccountId, {
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) return null;
    if (p.accountId != claimedAccountId) {
      await _deny(
        p,
        'claimed to act as another account',
        entityType: entityType,
        entityId: entityId,
      );
    }
    return p;
  }

  /// The principal is [accountId] itself, or an administrator holding
  /// [adminPermission].
  Future<Principal?> selfOrAdmin(
    String accountId,
    Permission adminPermission, {
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) return null;
    if (p.accountId == accountId) return p;
    if (!p.isAdmin || !p.can(adminPermission)) {
      await _deny(
        p,
        'not own account',
        entityType: entityType,
        entityId: entityId,
      );
    }
    return p;
  }

  /// Staff (any clinician) or admin — shared operational queues.
  Future<Principal?> requireStaffOrAdmin({
    String? entityType,
    String? entityId,
  }) async {
    final p = await principal();
    if (p == null) return null;
    if (p.isPatient) {
      await _deny(
        p,
        'staff or admin only',
        entityType: entityType,
        entityId: entityId,
      );
    }
    return p;
  }

  /// A clinician has a care relationship with a patient when they share an
  /// appointment, an active care-team assignment, or a walk-in the clinician
  /// raised or claimed. (A message thread is not one: threads may only open
  /// on top of an existing relationship.)
  Future<bool> hasCareRelationship({
    required String staffId,
    required String patientId,
  }) async {
    final appointment =
        await (_db.select(_db.appointments)
              ..where(
                (a) =>
                    a.staffId.equals(staffId) & a.patientId.equals(patientId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (appointment != null) return true;

    final now = DateTime.now();
    final assignment =
        await (_db.select(_db.careTeamAssignments)
              ..where(
                (c) =>
                    c.staffId.equals(staffId) &
                    c.patientId.equals(patientId) &
                    c.assignedAt.isSmallerOrEqualValue(now) &
                    (c.endedAt.isNull() | c.endedAt.isBiggerThanValue(now)),
              )
              ..limit(1))
            .getSingleOrNull();
    if (assignment != null) return true;

    final walkIn =
        await (_db.select(_db.walkInTickets)
              ..where(
                (w) =>
                    w.patientId.equals(patientId) &
                    (w.claimedByStaffId.equals(staffId) |
                        w.createdByStaffId.equals(staffId)),
              )
              ..limit(1))
            .getSingleOrNull();
    return walkIn != null;
  }

  /// The accepted proxy grant giving [accountId] access to [patientId].
  Future<ProxyGrant?> _proxyGrant(String patientId, String accountId) async {
    final row =
        await (_db.select(_db.familyLinks)..where(
              (l) =>
                  l.ownerPatientId.equals(patientId) &
                  l.viewerPatientId.equals(accountId) &
                  l.status.equalsValue(FamilyLinkStatus.accepted),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return ProxyGrant(
      id: row.id,
      patientId: row.ownerPatientId,
      proxyAccountId: row.viewerPatientId,
      access: row.permission == FamilyLinkPermission.manage
          ? ProxyAccess.manage
          : ProxyAccess.view,
      grantedAt: row.respondedAt ?? row.createdAt,
    );
  }

  /// Record a successful security-relevant action. Stamps the acting
  /// account; [subjectPatientId] records whose data it touched.
  Future<void> audit(
    String action, {
    required String entityType,
    String? entityId,
    String? subjectPatientId,
    String? detail,
  }) {
    return _db
        .into(_db.auditLog)
        .insert(
          AuditLogCompanion.insert(
            id: newId('aud'),
            action: action,
            entityType: entityType,
            entityId: Value(entityId),
            actorUserId: Value(actingAccountId),
            subjectPatientId: Value(subjectPatientId),
            detail: Value(detail),
          ),
        );
  }

  Future<Never> _deny(
    Principal principal,
    String reason, {
    String? entityType,
    String? entityId,
    String? subjectPatientId,
  }) async {
    try {
      await _db
          .into(_db.auditLog)
          .insert(
            AuditLogCompanion.insert(
              id: newId('aud'),
              action: 'access.denied',
              entityType: entityType ?? 'unknown',
              entityId: Value(entityId),
              actorUserId: Value(principal.accountId),
              subjectPatientId: Value(subjectPatientId),
              detail: Value(reason),
            ),
          );
    } on Object {
      // The denial stands even if the audit write fails.
    }
    throw const AccessDeniedFailure();
  }
}
