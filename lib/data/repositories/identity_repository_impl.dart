/// Drift-backed [CareTeamRepository] + [StaffCredentialRepository].
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/identity_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

extension on CareTeamAssignmentRow {
  CareTeamAssignment toEntity() => CareTeamAssignment(
    id: id,
    patientId: patientId,
    staffId: staffId,
    role: role,
    assignedAt: assignedAt,
    assignedBy: assignedBy,
    endedAt: endedAt,
  );
}

extension on StaffCredentialRow {
  StaffCredential toEntity() => StaffCredential(
    id: id,
    staffId: staffId,
    kind: kind,
    identifier: identifier,
    recordedAt: recordedAt,
    issuer: issuer,
    validUntil: validUntil,
    verifiedAt: verifiedAt,
    revokedAt: revokedAt,
  );
}

class CareTeamRepositoryImpl implements CareTeamRepository {
  CareTeamRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<CareTeamAssignment>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      await _access.readPatient(
        patientId,
        scope: PatientDataScope.administrative,
        entityType: 'care_team',
      );
      final rows =
          await (_db.select(_db.careTeamAssignments)
                ..where((c) => c.patientId.equals(patientId))
                ..orderBy([(c) => OrderingTerm.desc(c.assignedAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<CareTeamAssignment>>> activeForStaff(String staffId) {
    return Result.guardAsync(() async {
      await _access.selfOrAdmin(
        staffId,
        Permission.manageCareTeams,
        entityType: 'care_team',
      );
      final now = DateTime.now();
      final rows =
          await (_db.select(_db.careTeamAssignments)..where(
                (c) =>
                    c.staffId.equals(staffId) &
                    (c.endedAt.isNull() | c.endedAt.isBiggerThanValue(now)),
              ))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<CareTeamAssignment>> assign({
    required String patientId,
    required String staffId,
    required CareTeamRole role,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageCareTeams,
        entityType: 'care_team',
      );
      final users = await (_db.select(
        _db.users,
      )..where((u) => u.id.isIn([patientId, staffId]))).get();
      final patient = users.where((u) => u.id == patientId).firstOrNull;
      final staff = users.where((u) => u.id == staffId).firstOrNull;
      if (patient == null || patient.role != UserRole.patient) {
        throw NotFoundFailure('No patient $patientId.');
      }
      if (staff == null || staff.role != UserRole.staff || !staff.isActive) {
        throw NotFoundFailure('No active clinician $staffId.');
      }
      final id = newId('care');
      await _db
          .into(_db.careTeamAssignments)
          .insert(
            CareTeamAssignmentsCompanion.insert(
              id: id,
              patientId: patientId,
              staffId: staffId,
              role: role,
              assignedAt: DateTime.now(),
              assignedBy: Value(_access.actingAccountId),
            ),
          );
      await _access.audit(
        'care_team.assigned',
        entityType: 'care_team',
        entityId: id,
        subjectPatientId: patientId,
        detail: '$staffId as ${role.name}',
      );
      final row = await (_db.select(
        _db.careTeamAssignments,
      )..where((c) => c.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> end(String assignmentId) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageCareTeams,
        entityType: 'care_team',
        entityId: assignmentId,
      );
      final row = await (_db.select(
        _db.careTeamAssignments,
      )..where((c) => c.id.equals(assignmentId))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Assignment not found.');
      if (row.endedAt != null) return;
      await (_db.update(_db.careTeamAssignments)
            ..where((c) => c.id.equals(assignmentId)))
          .write(CareTeamAssignmentsCompanion(endedAt: Value(DateTime.now())));
      await _access.audit(
        'care_team.ended',
        entityType: 'care_team',
        entityId: assignmentId,
        subjectPatientId: row.patientId,
      );
    });
  }
}

class StaffCredentialRepositoryImpl implements StaffCredentialRepository {
  StaffCredentialRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<StaffCredential>>> forStaff(String staffId) {
    return Result.guardAsync(() async {
      await _access.selfOrAdmin(
        staffId,
        Permission.manageUsers,
        entityType: 'staff_credential',
      );
      final rows =
          await (_db.select(_db.staffCredentials)
                ..where((c) => c.staffId.equals(staffId))
                ..orderBy([(c) => OrderingTerm.desc(c.recordedAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<StaffCredential>> record({
    required String staffId,
    required CredentialKind kind,
    required String identifier,
    String? issuer,
    DateTime? validUntil,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageUsers,
        entityType: 'staff_credential',
      );
      if (identifier.trim().isEmpty) {
        throw const ValidationFailure('Enter the licence or registration.');
      }
      final id = newId('cred');
      final now = DateTime.now();
      await _db
          .into(_db.staffCredentials)
          .insert(
            StaffCredentialsCompanion.insert(
              id: id,
              staffId: staffId,
              kind: kind,
              identifier: identifier.trim(),
              recordedAt: now,
              issuer: Value(issuer?.trim()),
              validUntil: Value(validUntil),
              verifiedAt: Value(now),
            ),
          );
      await _access.audit(
        'staff_credential.recorded',
        entityType: 'staff_credential',
        entityId: id,
        detail: staffId,
      );
      final row = await (_db.select(
        _db.staffCredentials,
      )..where((c) => c.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> revoke(String credentialId) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageUsers,
        entityType: 'staff_credential',
        entityId: credentialId,
      );
      await (_db.update(_db.staffCredentials)
            ..where((c) => c.id.equals(credentialId) & c.revokedAt.isNull()))
          .write(StaffCredentialsCompanion(revokedAt: Value(DateTime.now())));
      await _access.audit(
        'staff_credential.revoked',
        entityType: 'staff_credential',
        entityId: credentialId,
      );
    });
  }
}
