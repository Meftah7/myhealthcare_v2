/// Drift-backed [PatientRepository] + [DepartmentRepository] (P1-12).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/patient_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._db);

  final AppDatabase _db;

  Future<Patient> _load(String id) async {
    final user = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    if (user == null || user.role != UserRole.patient) {
      throw NotFoundFailure('No patient $id.');
    }
    final profile = await (_db.select(
      _db.patientProfiles,
    )..where((p) => p.userId.equals(id))).getSingleOrNull();
    return patientFrom(user, profile);
  }

  @override
  Future<Result<Patient>> byId(String id) => Result.guardAsync(() => _load(id));

  @override
  Future<Result<List<Patient>>> search(String query, {int limit = 50}) {
    return Result.guardAsync(() async {
      final q = '%${query.trim()}%';
      final users =
          await (_db.select(_db.users)
                ..where(
                  (u) =>
                      u.role.equalsValue(UserRole.patient) &
                      (u.fullName.like(q) | u.nationalId.like(q)),
                )
                ..orderBy([(u) => OrderingTerm(expression: u.fullName)])
                ..limit(limit))
              .get();
      return _attachProfiles(users);
    });
  }

  @override
  Future<Result<List<Patient>>> all({int limit = 100, int offset = 0}) {
    return Result.guardAsync(() async {
      final users =
          await (_db.select(_db.users)
                ..where((u) => u.role.equalsValue(UserRole.patient))
                ..orderBy([(u) => OrderingTerm(expression: u.fullName)])
                ..limit(limit, offset: offset))
              .get();
      return _attachProfiles(users);
    });
  }

  Future<List<Patient>> _attachProfiles(List<UserRow> users) async {
    if (users.isEmpty) return const [];
    final ids = users.map((u) => u.id).toList();
    final profiles = await (_db.select(
      _db.patientProfiles,
    )..where((p) => p.userId.isIn(ids))).get();
    final byId = {for (final p in profiles) p.userId: p};
    return users.map((u) => patientFrom(u, byId[u.id])).toList();
  }

  @override
  Future<Result<void>> updateProfile(Patient patient) {
    return Result.guardAsync(() async {
      await (_db.update(
        _db.patientProfiles,
      )..where((p) => p.userId.equals(patient.id))).write(
        PatientProfilesCompanion(
          bloodType: Value(patient.bloodType),
          allergies: Value(patient.allergies),
          chronicConditions: Value(patient.chronicConditions),
          emergencyContact: Value(patient.emergencyContact),
        ),
      );
      await (_db.update(
        _db.users,
      )..where((u) => u.id.equals(patient.id))).write(
        UsersCompanion(
          fullName: Value(patient.user.fullName),
          phone: Value(patient.user.phone),
          dob: Value(patient.user.dob),
          gender: Value(patient.user.gender),
          nationalId: Value(patient.user.nationalId),
        ),
      );
    });
  }
}

class DepartmentRepositoryImpl implements DepartmentRepository {
  DepartmentRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<Department>>> all() {
    return Result.guardAsync(() async {
      final rows = await (_db.select(
        _db.departments,
      )..orderBy([(d) => OrderingTerm(expression: d.name)])).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<Department>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.departments,
      )..where((d) => d.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No department $id.');
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> upsert(Department department) {
    return Result.guardAsync(() async {
      await _db
          .into(_db.departments)
          .insertOnConflictUpdate(
            DepartmentsCompanion.insert(
              id: department.id,
              name: department.name,
              description: Value(department.description),
            ),
          );
    });
  }

  @override
  Future<Result<void>> delete(String id) {
    return Result.guardAsync(() async {
      final staff = await (_db.select(
        _db.staffProfiles,
      )..where((p) => p.departmentId.equals(id))).get();
      final appts = await (_db.select(
        _db.appointments,
      )..where((a) => a.departmentId.equals(id))).get();
      if (staff.isNotEmpty || appts.isNotEmpty) {
        throw ValidationFailure(
          'Still in use: ${staff.length} staff and ${appts.length} '
          'appointment(s) are assigned to this department. '
          'Reassign them first.',
        );
      }
      await (_db.delete(_db.departments)..where((d) => d.id.equals(id))).go();
    });
  }
}
