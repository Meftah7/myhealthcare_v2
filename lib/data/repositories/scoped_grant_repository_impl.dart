import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/enums.dart';
import '../../domain/identity/operational_roles.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/scoped_grant_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class ScopedGrantRepositoryImpl implements ScopedGrantRepository {
  ScopedGrantRepositoryImpl(this._db, this._access);
  final AppDatabase _db;
  final AccessPolicy _access;

  ScopedGrant _from(ScopedGrantRow r) => ScopedGrant(
    id: r.id,
    accountId: r.accountId,
    permission: Permission.values.byName(r.permission),
    scope: GrantScope.values.byName(r.scope),
    scopeId: r.scopeId,
    startsAt: r.startsAt,
    expiresAt: r.expiresAt,
    revokedAt: r.revokedAt,
  );

  @override
  Future<Result<List<ScopedGrant>>> forAccount(String accountId) =>
      Result.guardAsync(() async {
        final actor = await _access.principal();
        if (actor?.accountId != accountId) {
          await _access.require(Permission.manageUsers);
        }
        final rows =
            await (_db.select(_db.scopedGrants)
                  ..where((g) => g.accountId.equals(accountId))
                  ..orderBy([(g) => OrderingTerm.desc(g.startsAt)]))
                .get();
        return rows.map(_from).toList();
      });

  @override
  Future<Result<ScopedGrant>> grant({
    required String accountId,
    required Permission permission,
    required GrantScope scope,
    required String scopeId,
    required String reason,
    DateTime? startsAt,
    DateTime? expiresAt,
  }) => Result.guardAsync(() async {
    final actor = await _access.require(
      Permission.manageUsers,
      entityType: 'scoped_grant',
    );
    await _access.requireRecentAuthentication();
    if (actor == null) throw const AccessDeniedFailure();
    final now = DateTime.now();
    final start = startsAt ?? now;
    if (!OperationalRoles.scopedPermissions.contains(permission) ||
        reason.trim().isEmpty ||
        reason.length > 2000 ||
        (expiresAt != null &&
            (!expiresAt.isAfter(start) || !expiresAt.isAfter(now)))) {
      throw const ValidationFailure(
        'Choose a scoped permission, valid dates and a reason.',
      );
    }
    final recipient = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(accountId))).getSingleOrNull();
    if (recipient == null ||
        !recipient.isActive ||
        !recipient.hasLogin ||
        recipient.role == UserRole.patient) {
      throw const ValidationFailure(
        'Grants require an active staff or administrator account.',
      );
    }
    switch (scope) {
      case GrantScope.clinic:
        if (scopeId.isNotEmpty) {
          throw const ValidationFailure('Clinic scope has no subject id.');
        }
      case GrantScope.patient:
        final patient = await (_db.select(
          _db.users,
        )..where((u) => u.id.equals(scopeId))).getSingleOrNull();
        if (patient?.role != UserRole.patient) {
          throw const ValidationFailure('Choose an existing patient.');
        }
      case GrantScope.department:
        final department = await (_db.select(
          _db.departments,
        )..where((d) => d.id.equals(scopeId))).getSingleOrNull();
        if (department == null) {
          throw const ValidationFailure('Choose an existing department.');
        }
    }
    final id = newId('grant');
    return _db.transaction(() async {
      await _db
          .into(_db.scopedGrants)
          .insert(
            ScopedGrantsCompanion.insert(
              id: id,
              accountId: accountId,
              permission: permission.name,
              scope: scope.name,
              scopeId: scopeId,
              grantedBy: actor.accountId,
              startsAt: start,
              expiresAt: Value(expiresAt),
              reason: reason.trim(),
            ),
          );
      await _access.audit(
        'grant.create',
        entityType: 'scoped_grant',
        entityId: id,
        detail: '${permission.name}/${scope.name}/$scopeId',
      );
      return _from(
        await (_db.select(
          _db.scopedGrants,
        )..where((g) => g.id.equals(id))).getSingle(),
      );
    });
  });

  @override
  Future<Result<void>> revoke(String id, {required String reason}) =>
      Result.guardAsync(() async {
        final actor = await _access.require(
          Permission.manageUsers,
          entityType: 'scoped_grant',
          entityId: id,
        );
        await _access.requireRecentAuthentication();
        if (actor == null) throw const AccessDeniedFailure();
        if (reason.trim().isEmpty || reason.length > 2000) {
          throw const ValidationFailure('Enter a revocation reason.');
        }
        await _db.transaction(() async {
          final grant = await (_db.select(
            _db.scopedGrants,
          )..where((g) => g.id.equals(id))).getSingleOrNull();
          if (grant == null) throw const NotFoundFailure('Grant not found.');
          if (grant.revokedAt != null) return;
          await (_db.update(
            _db.scopedGrants,
          )..where((g) => g.id.equals(id))).write(
            ScopedGrantsCompanion(
              revokedAt: Value(DateTime.now()),
              revokedBy: Value(actor.accountId),
            ),
          );
          await _access.audit(
            'grant.revoke',
            entityType: 'scoped_grant',
            entityId: id,
            detail: reason.trim(),
          );
        });
      });
}
