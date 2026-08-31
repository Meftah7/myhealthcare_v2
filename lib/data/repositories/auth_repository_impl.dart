/// Drift-backed [AuthRepository] + [UserRepository] (P1-12).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/auth/password_hasher.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._db, {PasswordHasher? hasher})
    : _hasher = hasher ?? const PasswordHasher();

  final AppDatabase _db;
  final PasswordHasher _hasher;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) {
    return Result.guardAsync(() async {
      final row =
          await (_db.select(_db.users)
                ..where((u) => u.email.equals(email.trim().toLowerCase())))
              .getSingleOrNull();

      if (row == null) {
        throw const AuthFailure('No account found for that email.');
      }
      if (!row.isActive) {
        throw const AuthFailure('This account has been deactivated.');
      }
      final ok = _hasher.verify(
        password,
        hash: row.passwordHash,
        salt: row.passwordSalt,
      );
      if (!ok) {
        throw const AuthFailure('Incorrect email or password.');
      }
      return row.toEntity();
    });
  }

  @override
  Future<Result<Patient>> registerPatient(PatientRegistration reg) {
    return Result.guardAsync(() async {
      final email = reg.email.trim().toLowerCase();
      final existing = await (_db.select(
        _db.users,
      )..where((u) => u.email.equals(email))).getSingleOrNull();
      if (existing != null) {
        throw const ValidationFailure('An account with that email exists.');
      }

      final id = newId('user');
      final pw = _hasher.hashNew(reg.password);
      final now = DateTime.now();

      await _db.transaction(() async {
        await _db
            .into(_db.users)
            .insert(
              UsersCompanion.insert(
                id: id,
                role: UserRole.patient,
                fullName: reg.fullName.trim(),
                email: email,
                passwordHash: pw.hash,
                passwordSalt: pw.salt,
                phone: Value(reg.phone),
                dob: Value(reg.dob),
                gender: Value(reg.gender),
                nationalId: Value(reg.nationalId),
                isActive: const Value(true),
                createdAt: Value(now),
              ),
            );
        await _db
            .into(_db.patientProfiles)
            .insert(
              PatientProfilesCompanion.insert(
                userId: id,
                bloodType: Value(reg.bloodType),
                allergies: Value(reg.allergies),
                chronicConditions: Value(reg.chronicConditions),
                emergencyContact: Value(reg.emergencyContact),
              ),
            );
      });

      final userRow = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(id))).getSingle();
      final profileRow = await (_db.select(
        _db.patientProfiles,
      )..where((p) => p.userId.equals(id))).getSingle();
      return patientFrom(userRow, profileRow);
    });
  }

  @override
  Future<Result<void>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Account not found.');
      if (!_hasher.verify(
        currentPassword,
        hash: row.passwordHash,
        salt: row.passwordSalt,
      )) {
        throw const AuthFailure('Current password is incorrect.');
      }
      final pw = _hasher.hashNew(newPassword);
      await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(
          passwordHash: Value(pw.hash),
          passwordSalt: Value(pw.salt),
        ),
      );
    });
  }
}

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._db, {PasswordHasher? hasher})
    : _hasher = hasher ?? const PasswordHasher();

  final AppDatabase _db;
  final PasswordHasher _hasher;

  @override
  Future<Result<User>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No user $id.');
      return row.toEntity();
    });
  }

  @override
  Future<Result<List<User>>> byRole(UserRole role) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.users)
                ..where((u) => u.role.equalsValue(role))
                ..orderBy([(u) => OrderingTerm(expression: u.fullName)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<User?> watchById(String id) {
    return (_db.select(_db.users)..where((u) => u.id.equals(id)))
        .watchSingleOrNull()
        .map((r) => r?.toEntity());
  }

  @override
  Future<Result<Staff>> staffById(String id) {
    return Result.guardAsync(() async {
      final user = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(id))).getSingleOrNull();
      if (user == null || user.role != UserRole.staff) {
        throw NotFoundFailure('No staff $id.');
      }
      final profile = await (_db.select(
        _db.staffProfiles,
      )..where((p) => p.userId.equals(id))).getSingleOrNull();
      return staffFrom(user, profile);
    });
  }

  @override
  Future<Result<List<Staff>>> staffInDepartment(String departmentId) {
    return Result.guardAsync(() async {
      final profiles = await (_db.select(
        _db.staffProfiles,
      )..where((p) => p.departmentId.equals(departmentId))).get();
      if (profiles.isEmpty) return const <Staff>[];
      final ids = profiles.map((p) => p.userId).toList();
      final users =
          await (_db.select(_db.users)
                ..where((u) => u.id.isIn(ids))
                ..orderBy([(u) => OrderingTerm(expression: u.fullName)]))
              .get();
      final byId = {for (final p in profiles) p.userId: p};
      return users.map((u) => staffFrom(u, byId[u.id])).toList();
    });
  }

  @override
  Future<Result<Staff>> createStaff({
    required String fullName,
    required String email,
    required String temporaryPassword,
    String? specialty,
    String? departmentId,
    String? licenseNo,
    String? jobTitle,
  }) {
    return Result.guardAsync(() async {
      final id = newId('user');
      final pw = _hasher.hashNew(temporaryPassword);
      await _db.transaction(() async {
        await _db
            .into(_db.users)
            .insert(
              UsersCompanion.insert(
                id: id,
                role: UserRole.staff,
                fullName: fullName.trim(),
                email: email.trim().toLowerCase(),
                passwordHash: pw.hash,
                passwordSalt: pw.salt,
              ),
            );
        await _db
            .into(_db.staffProfiles)
            .insert(
              StaffProfilesCompanion.insert(
                userId: id,
                specialty: Value(specialty),
                departmentId: Value(departmentId),
                licenseNo: Value(licenseNo),
                jobTitle: Value(jobTitle),
              ),
            );
      });
      final userRow = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(id))).getSingle();
      final profileRow = await (_db.select(
        _db.staffProfiles,
      )..where((p) => p.userId.equals(id))).getSingle();
      return staffFrom(userRow, profileRow);
    });
  }

  @override
  Future<Result<void>> setActive({required String id, required bool active}) {
    return Result.guardAsync(() async {
      await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(isActive: Value(active)),
      );
    });
  }

  @override
  Future<Result<void>> resetPassword({
    required String id,
    required String newPassword,
  }) {
    return Result.guardAsync(() async {
      final pw = _hasher.hashNew(newPassword);
      await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(
          passwordHash: Value(pw.hash),
          passwordSalt: Value(pw.salt),
        ),
      );
    });
  }
}
