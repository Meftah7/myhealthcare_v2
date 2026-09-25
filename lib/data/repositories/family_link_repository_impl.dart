/// Drift-backed [FamilyLinkRepository].
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/family_link_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class FamilyLinkRepositoryImpl implements FamilyLinkRepository {
  FamilyLinkRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<FamilyLink>>> incomingRequests(String ownerPatientId) {
    return Result.guardAsync(() async {
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

  @override
  Future<Result<FamilyLink>> request({
    required String ownerPatientId,
    required String viewerPatientId,
    required FamilyLinkPermission permission,
  }) {
    return Result.guardAsync(() async {
      if (ownerPatientId == viewerPatientId) {
        throw const ValidationFailure("You can't link to your own account.");
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
      final row = await (_db.select(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Link not found.');
      if (row.ownerPatientId != actingPatientId &&
          row.viewerPatientId != actingPatientId) {
        throw const NotFoundFailure('Link not found.');
      }
      await (_db.delete(
        _db.familyLinks,
      )..where((l) => l.id.equals(linkId))).go();
    });
  }
}
