/// Drift-backed [FamilyLinkRepository].
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/family_link_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class FamilyLinkRepositoryImpl implements FamilyLinkRepository {
  FamilyLinkRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  /// Every call names the account it is made for; it must be the signed-in
  /// patient's own.
  Future<void> _asSelf(String accountId, {String? entityId}) async {
    final p = await _access.assertActor(
      accountId,
      entityType: 'family_link',
      entityId: entityId,
    );
    if (p != null) {
      await _access.require(
        Permission.manageProxyGrants,
        entityType: 'family_link',
        entityId: entityId,
      );
    }
  }

  @override
  Future<Result<List<FamilyLink>>> incomingRequests(String ownerPatientId) {
    return Result.guardAsync(() async {
      await _asSelf(ownerPatientId);
      final rows =
          await (_db.select(_db.familyLinks)..where(
                (l) =>
                    l.ownerPatientId.equals(ownerPatientId) &
                    l.status.equalsValue(FamilyLinkStatus.pending),
              ))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<FamilyLink>>> outgoingRequests(String viewerPatientId) {
    return Result.guardAsync(() async {
      await _asSelf(viewerPatientId);
      final rows =
          await (_db.select(_db.familyLinks)..where(
                (l) =>
                    l.viewerPatientId.equals(viewerPatientId) &
                    l.status.equalsValue(FamilyLinkStatus.pending),
              ))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<FamilyLink>>> linkedAccounts(String viewerPatientId) {
    return Result.guardAsync(() async {
      await _asSelf(viewerPatientId);
      final rows =
          await (_db.select(_db.familyLinks)..where(
                (l) =>
                    l.viewerPatientId.equals(viewerPatientId) &
                    l.status.equalsValue(FamilyLinkStatus.accepted),
              ))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<FamilyLink>>> viewersOfMe(String ownerPatientId) {
    return Result.guardAsync(() async {
      await _asSelf(ownerPatientId);
      final rows =
          await (_db.select(_db.familyLinks)..where(
                (l) =>
                    l.ownerPatientId.equals(ownerPatientId) &
                    l.status.equalsValue(FamilyLinkStatus.accepted),
              ))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<FamilyLink?>> activeLink({
    required String viewerPatientId,
    required String ownerPatientId,
  }) {
    return Result.guardAsync(() async {
      await _asSelf(viewerPatientId);
      final row =
          await (_db.select(_db.familyLinks)..where(
                (l) =>
                    l.viewerPatientId.equals(viewerPatientId) &
                    l.ownerPatientId.equals(ownerPatientId) &
                    l.status.equalsValue(FamilyLinkStatus.accepted),
              ))
              .getSingleOrNull();
      return row?.toEntity();
    });
  }

  static const maxRequestsPerDay = 10;

  @override
  Future<Result<FamilyLink>> request({
    required String ownerPatientId,
    required String viewerPatientId,
    required FamilyLinkPermission permission,
  }) {
    return Result.guardAsync(() async {
      await _asSelf(viewerPatientId);
      if (ownerPatientId == viewerPatientId) {
        throw const ValidationFailure("You can't link to your own account.");
      }
      // A dependent has no login to accept with; their guardian's grant is
      // created when the dependent is added, not requested.
      final owner = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(ownerPatientId))).getSingleOrNull();
      if (owner == null || !owner.hasLogin || !owner.isActive) {
        throw const NotFoundFailure('No account to link with.');
      }
      final existing =
          await (_db.select(_db.familyLinks)..where(
                (l) =>
                    l.ownerPatientId.equals(ownerPatientId) &
                    l.viewerPatientId.equals(viewerPatientId),
              ))
              .getSingleOrNull();
      if (existing != null) {
        throw ValidationFailure(
          existing.status == FamilyLinkStatus.accepted
              ? 'Already linked to this account.'
              : 'A request is already pending with this account.',
        );
      }

      // Anti-spam: cap how many requests one account can send per day
      // (SEC-PAT-11). Durable per-device throttling needs a backend.
      final since = DateTime.now().subtract(const Duration(days: 1));
      final recent = _db.familyLinks.id.count();
      final sentToday =
          await (_db.selectOnly(_db.familyLinks)
                ..addColumns([recent])
                ..where(
                  _db.familyLinks.viewerPatientId.equals(viewerPatientId) &
                      _db.familyLinks.createdAt.isBiggerOrEqualValue(since),
                ))
              .map((r) => r.read(recent) ?? 0)
              .getSingle();
      if (sentToday >= maxRequestsPerDay) {
        throw const ValidationFailure(
          'Too many link requests today. Try again tomorrow.',
        );
      }

      final id = newId('flink');
      await _db
          .into(_db.familyLinks)
          .insert(
            FamilyLinksCompanion.insert(
              id: id,
              ownerPatientId: ownerPatientId,
              viewerPatientId: viewerPatientId,
              permission: permission,
            ),
          );
      final row = await (_db.select(
        _db.familyLinks,
      )..where((l) => l.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<FamilyLink>> accept({
    required String linkId,
    required String actingPatientId,
  }) {
    return Result.guardAsync(() async {
      await _asSelf(actingPatientId, entityId: linkId);
      final row = await (_db.select(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Request not found.');
      if (row.ownerPatientId != actingPatientId) {
        throw const NotFoundFailure('Request not found.');
      }
      if (row.status != FamilyLinkStatus.pending) {
        throw const ValidationFailure('This request was already handled.');
      }

      await (_db.update(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).write(
        FamilyLinksCompanion(
          status: const Value(FamilyLinkStatus.accepted),
          respondedAt: Value(DateTime.now()),
        ),
      );
      await _access.audit(
        'proxy.grant.accepted',
        entityType: 'family_link',
        entityId: linkId,
        subjectPatientId: row.ownerPatientId,
        detail: row.permission.name,
      );
      final updated = await (_db.select(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).getSingle();
      return updated.toEntity();
    });
  }

  @override
  Future<Result<void>> decline({
    required String linkId,
    required String actingPatientId,
  }) {
    return Result.guardAsync(() async {
      await _asSelf(actingPatientId, entityId: linkId);
      final row = await (_db.select(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Request not found.');
      if (row.ownerPatientId != actingPatientId &&
          row.viewerPatientId != actingPatientId) {
        throw const NotFoundFailure('Request not found.');
      }
      await (_db.delete(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).go();
    });
  }

  @override
  Future<Result<void>> unlink({
    required String linkId,
    required String actingPatientId,
  }) {
    return Result.guardAsync(() async {
      await _asSelf(actingPatientId, entityId: linkId);
      final row = await (_db.select(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Link not found.');
      if (row.ownerPatientId != actingPatientId &&
          row.viewerPatientId != actingPatientId) {
        throw const NotFoundFailure('Link not found.');
      }
      final owner = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(row.ownerPatientId))).getSingleOrNull();
      if (owner != null && !owner.hasLogin) {
        throw const ValidationFailure(
          'A dependent stays linked to their guardian. Remove them from your '
          'family list instead.',
        );
      }
      await (_db.delete(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).go();
      // Revocation takes effect on the next repository call: every read and
      // write re-checks the grant.
      await _access.audit(
        'proxy.grant.revoked',
        entityType: 'family_link',
        entityId: linkId,
        subjectPatientId: row.ownerPatientId,
      );
    });
  }
}
