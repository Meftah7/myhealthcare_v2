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

  /// One message for "no such account" and "wrong password" alike, so a
  /// login attempt can never be used to test whether an email or national ID
  /// has an account (OWASP account-enumeration guidance).
  static const _badCredentials = AuthFailure('Incorrect email or password.');

  /// Consecutive failures allowed before a temporary lockout.
  static const _maxFailedAttempts = 5;

  /// How long an account stays locked after crossing [_maxFailedAttempts].
  static const _lockoutDuration = Duration(minutes: 5);

  /// A hash/salt pair verify() always fails against — run when no account
  /// matches, so a login attempt takes about as long whether or not the
  /// identifier exists (a real difference here is a timing side-channel for
  /// account enumeration).
  static const _dummyHash = '20000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
  static const _dummySalt = 'AAAAAAAAAAAAAAAAAAAAAA==';

  /// The account behind an "email or national ID" identifier.
  Future<UserRow?> _rowForIdentifier(String identifier) {
    final id = identifier.trim();
    return (_db.select(_db.users)..where(
          (u) => u.email.equals(id.toLowerCase()) | u.nationalId.equals(id),
        ))
        .getSingleOrNull();
  }

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) {
    return Result.guardAsync(() async {
      final row = await _rowForIdentifier(email);

      if (row == null) {
        // Still do the expensive hash work, so the response time doesn't
        // give away that this identifier has no account.
        _hasher.verify(password, hash: _dummyHash, salt: _dummySalt);
        throw _badCredentials;
      }

      final lockedUntil = row.lockedUntil;
      if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
        throw const AuthFailure(
          'Too many attempts. Try again in a few minutes.',
        );
      }

      final ok = _hasher.verify(
        password,
        hash: row.passwordHash,
        salt: row.passwordSalt,
      );
      if (!ok) {
        await _recordFailedAttempt(row);
        throw _badCredentials;
      }

      // Only reveal deactivation once the password has actually been proven
      // correct — otherwise anyone who merely knows the identifier could
      // learn an account's status without ever guessing the password.
      if (!row.isActive) {
        throw const AuthFailure('This account has been deactivated.');
      }

      if (row.failedLoginAttempts > 0 || row.lockedUntil != null) {
        await (_db.update(_db.users)..where((u) => u.id.equals(row.id))).write(
          const UsersCompanion(
            failedLoginAttempts: Value(0),
            lockedUntil: Value(null),
          ),
        );
      }
      return row.toEntity();
    });
  }

  Future<void> _recordFailedAttempt(UserRow row) async {
    final attempts = row.failedLoginAttempts + 1;
    final locked = attempts >= _maxFailedAttempts;
    await (_db.update(_db.users)..where((u) => u.id.equals(row.id))).write(
      UsersCompanion(
        failedLoginAttempts: Value(locked ? 0 : attempts),
        lockedUntil: Value(locked ? DateTime.now().add(_lockoutDuration) : null),
      ),
    );
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
      final nationalId = reg.nationalId?.trim();
      if (nationalId != null && nationalId.isNotEmpty) {
        final existingNationalId = await (_db.select(
          _db.users,
        )..where((u) => u.nationalId.equals(nationalId))).getSingleOrNull();
        if (existingNationalId != null) {
          throw const ValidationFailure(
            'An account with that national ID already exists.',
          );
        }
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
      if (newPassword.trim().length < 8) {
        throw const ValidationFailure(
          'Choose a password of at least 8 characters.',
        );
      }
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

  @override
  Future<Result<User>> accountForIdentifier(String identifier) {
    return Result.guardAsync(() async {
      final row = await _rowForIdentifier(identifier);
      if (row == null) {
        throw const NotFoundFailure(
          'No account matches that email or national ID.',
        );
      }
      if (!row.isActive) {
        throw const AuthFailure('This account has been deactivated.');
      }
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> requestPasswordReset(String identifier) {
    return Result.guardAsync(() async {
      final row = await _rowForIdentifier(identifier);
      // Deliberately no NotFoundFailure/deactivated distinction here: this
      // always reports success to the caller so it can never be used to
      // test whether an identifier has an account. Nothing is queued for a
      // deactivated account, but that's invisible to the caller too.
      if (row != null && row.isActive) {
        await _db
            .into(_db.passwordResetRequests)
            .insert(
              PasswordResetRequestsCompanion.insert(
                id: newId('prr'),
                userId: row.id,
                identifierEntered: identifier.trim(),
              ),
            );
      }
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
  Future<Result<List<Staff>>> allStaff() {
    return Result.guardAsync(() async {
      final users =
          await (_db.select(_db.users)
                ..where((u) => u.role.equalsValue(UserRole.staff))
                ..orderBy([(u) => OrderingTerm(expression: u.fullName)]))
              .get();
      if (users.isEmpty) return const <Staff>[];
      final profiles = await _db.select(_db.staffProfiles).get();
      final byId = {for (final p in profiles) p.userId: p};
      return users.map((u) => staffFrom(u, byId[u.id])).toList();
    });
  }

  @override
  Future<Result<void>> setPresence({
    required String id,
    required PresenceStatus status,
  }) {
    return Result.guardAsync(() async {
      final updated =
          await (_db.update(_db.staffProfiles)
                ..where((p) => p.userId.equals(id)))
              .write(StaffProfilesCompanion(presence: Value(status)));
      if (updated == 0) throw NotFoundFailure('No staff profile for $id.');
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
  Future<Result<User>> createAdmin({
    required String fullName,
    required String email,
    required String temporaryPassword,
  }) {
    return Result.guardAsync(() async {
      final normalized = email.trim().toLowerCase();
      final existing = await (_db.select(
        _db.users,
      )..where((u) => u.email.equals(normalized))).getSingleOrNull();
      if (existing != null) {
        throw const ValidationFailure('An account with that email exists.');
      }
      final id = newId('user');
      final pw = _hasher.hashNew(temporaryPassword);
      await _db
          .into(_db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              role: UserRole.admin,
              fullName: fullName.trim(),
              email: normalized,
              passwordHash: pw.hash,
              passwordSalt: pw.salt,
            ),
          );
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(id))).getSingle();
      return row.toEntity();
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
      if (newPassword.trim().length < 8) {
        throw const ValidationFailure(
          'Choose a password of at least 8 characters.',
        );
      }
      final pw = _hasher.hashNew(newPassword);
      await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(
          passwordHash: Value(pw.hash),
          passwordSalt: Value(pw.salt),
        ),
      );
    });
  }

  @override
  Future<Result<Set<String>>> userIdsWithPendingPasswordResetRequests() {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.passwordResetRequests)
                ..where((r) => r.resolved.equals(false)))
              .get();
      return rows.map((r) => r.userId).toSet();
    });
  }

  @override
  Future<Result<void>> resolvePasswordResetRequests({
    required String userId,
    required String staffId,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.passwordResetRequests)..where(
            (r) => r.userId.equals(userId) & r.resolved.equals(false),
          ))
          .write(
            PasswordResetRequestsCompanion(
              resolved: const Value(true),
              resolvedByStaffId: Value(staffId),
              resolvedAt: Value(DateTime.now()),
            ),
          );
    });
  }
}
