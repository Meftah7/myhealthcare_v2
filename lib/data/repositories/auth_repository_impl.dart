/// Drift-backed [AuthRepository] + [UserRepository] (P1-12).
library;

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/identity/principal.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/auth/access_policy.dart';
import '../../services/auth/auth_context.dart';
import '../../services/auth/password_hasher.dart';
import '../../services/auth/recovery_delivery.dart';
import '../db/app_database.dart';
import 'booking_safety.dart';
import 'mappers.dart';

/// Builds the principal for a proven account: role grants, narrowed for
/// nurses.
Future<Principal> principalFor(AppDatabase db, UserRow row) async {
  var isNurse = false;
  if (row.role == UserRole.staff) {
    final profile = await (db.select(
      db.staffProfiles,
    )..where((p) => p.userId.equals(row.id))).getSingleOrNull();
    isNurse = profile?.jobTitle == kNurseJobTitle;
  }
  return Principal(
    accountId: row.id,
    role: row.role,
    permissions: RolePermissions.forRole(row.role, isNurse: isNurse),
    sessionId: newId('sess'),
    authenticatedAt: DateTime.now(),
  );
}

/// Masks an email or national ID for display (`p***@myhealth.demo`,
/// `*****1234`).
String maskIdentifier(String identifier) {
  final value = identifier.trim();
  final at = value.indexOf('@');
  if (at > 0) {
    return '${value[0]}***${value.substring(at).toLowerCase()}';
  }
  if (value.length <= 4) return '****';
  return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._db, {
    PasswordHasher? hasher,
    AuthContext? context,
    RecoveryDelivery? recovery,
    this.allowDemoSignIn = false,
    DateTime Function()? now,
  }) : _hasher = hasher ?? const PasswordHasher(),
       _context = context, // ignore: prefer_initializing_formals
       _recovery = recovery ?? const UnavailableRecoveryDelivery(),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final PasswordHasher _hasher;
  final AuthContext? _context;
  final RecoveryDelivery _recovery;
  final DateTime Function() _now;

  /// Demo builds only — the account switcher signs in without a password.
  final bool allowDemoSignIn;

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
  static const _dummyHash = '120000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
  static const _dummySalt = 'AAAAAAAAAAAAAAAAAAAAAA==';

  // --- Recovery policy -----------------------------------------------------

  /// How long an emailed code stays valid.
  static const recoveryCodeLifetime = Duration(minutes: 10);

  /// Wrong guesses allowed against one code before it is burnt.
  static const maxRecoveryCodeAttempts = 5;

  /// Codes one account can be sent per hour.
  static const maxRecoveryCodesPerHour = 3;

  /// Recovery requests this device can make per window, whatever the
  /// identifier (stops cycling through identifiers to dodge the per-account
  /// limit).
  static const maxRecoveryStartsPerWindow = 5;
  static const recoveryStartWindow = Duration(minutes: 15);

  /// Codes are short-lived and attempt-limited; a lighter work factor than
  /// passwords keeps the flow responsive.
  static const _codeHasher = PasswordHasher(iterations: 20000);
  static const _invalidCode = AuthFailure(
    'That code is invalid or has expired. Request a new one.',
  );
  static final _random = Random.secure();
  final List<DateTime> _recoveryStarts = [];

  /// The account behind an "email or national ID" identifier.
  Future<UserRow?> _rowForIdentifier(String identifier) {
    final id = identifier.trim();
    return (_db.select(_db.users)..where(
          (u) => u.email.equals(id.toLowerCase()) | u.nationalId.equals(id),
        ))
        .getSingleOrNull();
  }

  Future<void> _audit(
    String action, {
    String? actor,
    String? userId,
    String? detail,
  }) async {
    try {
      await _db
          .into(_db.auditLog)
          .insert(
            AuditLogCompanion.insert(
              id: newId('aud'),
              action: action,
              entityType: 'account',
              entityId: Value(userId),
              actorUserId: Value(actor),
              detail: Value(detail),
            ),
          );
    } on Object {
      // Auditing must never turn a sign-in outcome into a different one.
    }
  }

  Future<void> _establish(UserRow row) async {
    final context = _context;
    if (context == null) return;
    context.establish(await principalFor(_db, row));
  }

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) {
    return Result.guardAsync(() async {
      if (!_passwordFits(password)) throw _badCredentials;
      final row = await _rowForIdentifier(email);

      // A dependent's record has no login, whatever its password column
      // holds.
      if (row == null || !row.hasLogin) {
        // Still do the expensive hash work, so the response time doesn't
        // give away that this identifier has no account.
        _hasher.verify(password, hash: _dummyHash, salt: _dummySalt);
        throw _badCredentials;
      }

      final lockedUntil = row.lockedUntil;
      if (lockedUntil != null && lockedUntil.isAfter(_now())) {
        await _audit('auth.login_locked', userId: row.id);
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
        await _recordFailedAttempt(row.id);
        await _audit('auth.login_failed', userId: row.id);
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
      await _establish(row);
      await _audit('auth.login', actor: row.id, userId: row.id);
      return row.toEntity();
    });
  }

  @override
  Future<Result<User>> demoSignIn(String userId) {
    return Result.guardAsync(() async {
      if (!allowDemoSignIn) {
        throw const AccessDeniedFailure(
          'Switching accounts without a password is only available in demo '
          'builds.',
        );
      }
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingleOrNull();
      if (row == null || !row.isActive || !row.hasLogin) {
        throw const AuthFailure('That account is not available.');
      }
      await _establish(row);
      await _audit('auth.demo_sign_in', actor: row.id, userId: row.id);
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> reauthenticate(String password) {
    return Result.guardAsync(() async {
      final context = _context;
      final principal = context?.principal;
      if (context == null || principal == null) {
        throw const SessionExpiredFailure();
      }
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(principal.accountId))).getSingleOrNull();
      if (row == null || !row.isActive) {
        context.clear();
        throw const SessionExpiredFailure();
      }
      if (!_passwordFits(password) ||
          !_hasher.verify(
            password,
            hash: row.passwordHash,
            salt: row.passwordSalt,
          )) {
        await _recordFailedAttempt(row.id);
        await _audit('auth.reauth_failed', actor: row.id, userId: row.id);
        throw const AuthFailure('That password is incorrect.');
      }
      context.markReauthenticated();
      await _audit('auth.reauthenticated', actor: row.id, userId: row.id);
    });
  }

  @override
  Future<void> signOut({String reason = 'signed_out'}) async {
    final accountId = _context?.principal?.accountId;
    _context?.clear();
    if (accountId != null) {
      await _audit(
        'auth.session_ended',
        actor: accountId,
        userId: accountId,
        detail: reason,
      );
    }
  }

  Future<void> _recordFailedAttempt(String userId) {
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingle();
      final attempts = current.failedLoginAttempts + 1;
      final locked = attempts >= _maxFailedAttempts;
      await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(
          failedLoginAttempts: Value(locked ? 0 : attempts),
          lockedUntil: Value(locked ? _now().add(_lockoutDuration) : null),
        ),
      );
    });
  }

  static bool _passwordFits(String password) =>
      utf8.encode(password).length <= PasswordHasher.maxPasswordBytes;

  static void _requireNewPassword(String password) {
    if (password.length < 8 || !_passwordFits(password)) {
      throw const ValidationFailure(
        'Choose a password between 8 characters and 1 KiB.',
      );
    }
  }

  @override
  Future<Result<Patient>> registerPatient(PatientRegistration reg) {
    return Result.guardAsync(() async {
      // Signed out: self-registration, which signs the new account in.
      // Signed in: an administrator creating an account for someone else —
      // their own session must stay theirs.
      final creator = _context?.principal;
      if (creator != null) {
        _context!.requireActive();
        if (!creator.isAdmin || !creator.can(Permission.manageUsers)) {
          throw const AccessDeniedFailure();
        }
      }
      _requireNewPassword(reg.password);
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
      final now = _now();

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
      if (creator == null) {
        await _establish(userRow);
        await _audit('auth.registered', actor: id, userId: id);
      } else {
        await _audit(
          'account.patient_created',
          actor: creator.accountId,
          userId: id,
        );
      }
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
      // Only for the signed-in account itself — the current password below
      // is the re-authentication.
      final principal = _context?.requireActive();
      if (principal != null && principal.accountId != userId) {
        throw const AccessDeniedFailure();
      }
      _requireNewPassword(newPassword);
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Account not found.');
      if (!_hasher.verify(
        currentPassword,
        hash: row.passwordHash,
        salt: row.passwordSalt,
      )) {
        await _audit(
          'auth.password_change_failed',
          actor: userId,
          userId: userId,
        );
        throw const AuthFailure('Current password is incorrect.');
      }
      final pw = _hasher.hashNew(newPassword);
      await _db.transaction(() async {
        await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
          UsersCompanion(
            passwordHash: Value(pw.hash),
            passwordSalt: Value(pw.salt),
          ),
        );
        await invalidateRecoveryCodes(_db, userId, _now());
      });
      _context?.markReauthenticated();
      await _audit('auth.password_changed', actor: userId, userId: userId);
    });
  }

  // --- Verified self-service recovery -------------------------------------

  void _throttleDevice() {
    final now = _now();
    _recoveryStarts.removeWhere((t) => now.difference(t) > recoveryStartWindow);
    if (_recoveryStarts.length >= maxRecoveryStartsPerWindow) {
      throw const ValidationFailure(
        'Too many recovery requests. Try again in a few minutes.',
      );
    }
    _recoveryStarts.add(now);
  }

  static String _newCode() =>
      List.generate(6, (_) => _random.nextInt(10)).join();

  @override
  Future<Result<RecoveryChallenge>> startRecovery(String identifier) {
    return Result.guardAsync(() async {
      if (identifier.trim().isEmpty) {
        throw const ValidationFailure('Enter your email or national ID.');
      }
      _throttleDevice();
      final now = _now();
      final challengeId = newId('rcv');
      final expiresAt = now.add(recoveryCodeLifetime);

      if (!_recovery.isAvailable) {
        await _queueAdminRequest(identifier);
        return RecoveryChallenge(
          challengeId: challengeId,
          expiresAt: expiresAt,
          selfService: false,
        );
      }
      final challenge = RecoveryChallenge(
        challengeId: challengeId,
        expiresAt: expiresAt,
        selfService: true,
      );

      final row = await _rowForIdentifier(identifier);
      if (row == null || !row.isActive || !row.hasLogin) {
        // Same work and the same answer as a real account: nothing here may
        // reveal whether the identifier is registered.
        _codeHasher.hashNew(_newCode());
        await _audit(
          'recovery.unmatched_identifier',
          detail: maskIdentifier(identifier),
        );
        return challenge;
      }

      final sentLastHour =
          await (_db.select(_db.accountRecoveryTokens)..where(
                (t) =>
                    t.userId.equals(row.id) &
                    t.createdAt.isBiggerThanValue(
                      now.subtract(const Duration(hours: 1)),
                    ),
              ))
              .get();
      if (sentLastHour.length >= maxRecoveryCodesPerHour) {
        _codeHasher.hashNew(_newCode());
        await _audit('recovery.rate_limited', userId: row.id);
        return challenge;
      }

      final code = _newCode();
      final hashed = _codeHasher.hashNew(code);
      final sentTo = maskIdentifier(row.email);
      await _db.transaction(() async {
        // Only the newest code works.
        await invalidateRecoveryCodes(_db, row.id, now);
        await _db
            .into(_db.accountRecoveryTokens)
            .insert(
              AccountRecoveryTokensCompanion.insert(
                id: challengeId,
                userId: row.id,
                codeHash: hashed.hash,
                codeSalt: hashed.salt,
                sentTo: sentTo,
                createdAt: now,
                expiresAt: expiresAt,
              ),
            );
      });
      await _recovery.send(
        account: row.toEntity(),
        sentTo: sentTo,
        code: code,
        expiresAt: expiresAt,
      );
      await _audit('recovery.code_sent', userId: row.id, detail: sentTo);
      return challenge;
    });
  }

  @override
  Future<Result<void>> completeRecovery({
    required String challengeId,
    required String code,
    required String newPassword,
  }) {
    return Result.guardAsync(() async {
      _requireNewPassword(newPassword);
      final now = _now();
      final token = await (_db.select(
        _db.accountRecoveryTokens,
      )..where((t) => t.id.equals(challengeId))).getSingleOrNull();

      if (token == null) {
        _codeHasher.verify(code, hash: _dummyHash, salt: _dummySalt);
        await _audit('recovery.rejected', detail: 'unknown challenge');
        throw _invalidCode;
      }
      final reason = token.consumedAt != null
          ? 'already used'
          : token.invalidatedAt != null
          ? 'superseded or revoked'
          : !token.expiresAt.isAfter(now)
          ? 'expired'
          : token.failedAttempts >= maxRecoveryCodeAttempts
          ? 'too many attempts'
          : null;
      if (reason != null) {
        await _audit('recovery.rejected', userId: token.userId, detail: reason);
        throw _invalidCode;
      }

      final ok =
          RegExp(r'^\d{6}$').hasMatch(code.trim()) &&
          _codeHasher.verify(
            code.trim(),
            hash: token.codeHash,
            salt: token.codeSalt,
          );
      if (!ok) {
        final attempts = token.failedAttempts + 1;
        await (_db.update(
          _db.accountRecoveryTokens,
        )..where((t) => t.id.equals(token.id))).write(
          AccountRecoveryTokensCompanion(
            failedAttempts: Value(attempts),
            invalidatedAt: Value(
              attempts >= maxRecoveryCodeAttempts ? now : null,
            ),
          ),
        );
        await _audit(
          'recovery.rejected',
          userId: token.userId,
          detail: 'wrong code ($attempts/$maxRecoveryCodeAttempts)',
        );
        throw _invalidCode;
      }

      final account = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(token.userId))).getSingleOrNull();
      if (account == null || !account.isActive || !account.hasLogin) {
        await _audit(
          'recovery.rejected',
          userId: token.userId,
          detail: 'account unavailable',
        );
        throw _invalidCode;
      }

      final pw = _hasher.hashNew(newPassword);
      await _db.transaction(() async {
        // Single use, even against a concurrent redemption.
        final claimed =
            await (_db.update(_db.accountRecoveryTokens)..where(
                  (t) =>
                      t.id.equals(token.id) &
                      t.consumedAt.isNull() &
                      t.invalidatedAt.isNull(),
                ))
                .write(AccountRecoveryTokensCompanion(consumedAt: Value(now)));
        if (claimed != 1) throw _invalidCode;
        await invalidateRecoveryCodes(_db, token.userId, now);
        await (_db.update(
          _db.users,
        )..where((u) => u.id.equals(token.userId))).write(
          UsersCompanion(
            passwordHash: Value(pw.hash),
            passwordSalt: Value(pw.salt),
            failedLoginAttempts: const Value(0),
            lockedUntil: const Value(null),
          ),
        );
        await (_db.update(_db.passwordResetRequests)..where(
              (r) => r.userId.equals(token.userId) & r.resolved.equals(false),
            ))
            .write(
              PasswordResetRequestsCompanion(
                resolved: const Value(true),
                resolvedAt: Value(now),
              ),
            );
      });
      if (_recovery case final DemoRecoveryOutbox outbox) {
        outbox.clearFor(token.userId);
      }
      await _audit('recovery.completed', userId: token.userId);
    });
  }

  @override
  Future<Result<void>> requestPasswordReset(String identifier) {
    return Result.guardAsync(() => _queueAdminRequest(identifier));
  }

  Future<void> _queueAdminRequest(String identifier) async {
    final row = await _rowForIdentifier(identifier);
    // Deliberately no NotFoundFailure/deactivated distinction here: this
    // always reports success to the caller so it can never be used to test
    // whether an identifier has an account. Nothing is queued for a
    // deactivated account, but that's invisible to the caller too.
    if (row == null || !row.isActive || !row.hasLogin) return;
    final existing =
        await (_db.select(
              _db.passwordResetRequests,
            )..where((r) => r.userId.equals(row.id) & r.resolved.equals(false)))
            .getSingleOrNull();
    if (existing != null) return;
    await _db
        .into(_db.passwordResetRequests)
        .insert(
          PasswordResetRequestsCompanion.insert(
            id: newId('prr'),
            userId: row.id,
            identifierEntered: maskIdentifier(identifier),
          ),
        );
    await _audit('recovery.admin_request_queued', userId: row.id);
  }
}

/// Burn every outstanding recovery code for [userId] — on a new code, a
/// password change by any route, or deactivation.
Future<void> invalidateRecoveryCodes(
  AppDatabase db,
  String userId,
  DateTime at,
) {
  return (db.update(db.accountRecoveryTokens)..where(
        (t) =>
            t.userId.equals(userId) &
            t.consumedAt.isNull() &
            t.invalidatedAt.isNull(),
      ))
      .write(AccountRecoveryTokensCompanion(invalidatedAt: Value(at)));
}

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._db, {PasswordHasher? hasher, AccessPolicy? access})
    : _hasher = hasher ?? const PasswordHasher(),
      _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final PasswordHasher _hasher;
  final AccessPolicy _access;

  /// Account administration: the permission, plus a recently proven
  /// password for anything that changes who can sign in.
  Future<void> _admin({bool sensitive = false, String? entityId}) async {
    await _access.require(
      Permission.manageUsers,
      entityType: 'account',
      entityId: entityId,
    );
    if (sensitive) await _access.requireRecentAuthentication();
  }

  /// A patient may look up clinicians and themselves, and other patients
  /// only through a proxy grant.
  Future<void> _canSeeAccount(UserRow row) async {
    final actor = await _access.principal();
    if (actor == null || !actor.isPatient) return;
    if (row.role != UserRole.patient || row.id == actor.accountId) return;
    await _access.readPatient(
      row.id,
      scope: PatientDataScope.administrative,
      entityType: 'account',
      entityId: row.id,
    );
  }

  static void _requireNewPassword(String password) {
    if (password.length < 8 ||
        utf8.encode(password).length > PasswordHasher.maxPasswordBytes) {
      throw const ValidationFailure(
        'Choose a password between 8 characters and 1 KiB.',
      );
    }
  }

  @override
  Future<Result<User>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No user $id.');
      await _canSeeAccount(row);
      return row.toEntity();
    });
  }

  @override
  Future<Result<List<User>>> byRole(UserRole role) {
    return Result.guardAsync(() async {
      switch (role) {
        case UserRole.patient:
          await _access.requireStaffOrAdmin(entityType: 'account');
        case UserRole.admin:
          await _admin();
        case UserRole.staff:
          await _access.principal();
      }
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
    final rows = (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).watchSingleOrNull();
    return authorizedStream(() async {
      final row = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(id))).getSingleOrNull();
      if (row != null) await _canSeeAccount(row);
    }, () => rows.map((r) => r?.toEntity()));
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
      await _access.assertActor(id, entityType: 'presence');
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
      await _admin();
      _requireNewPassword(temporaryPassword);
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
        final licence = licenseNo?.trim();
        if (licence != null && licence.isNotEmpty) {
          await _db
              .into(_db.staffCredentials)
              .insert(
                StaffCredentialsCompanion.insert(
                  id: newId('cred'),
                  staffId: id,
                  kind: jobTitle == kNurseJobTitle
                      ? CredentialKind.nursingLicense
                      : CredentialKind.medicalLicense,
                  identifier: licence,
                  recordedAt: DateTime.now(),
                ),
              );
        }
      });
      await _access.audit(
        'account.staff_created',
        entityType: 'account',
        entityId: id,
      );
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
      await _admin(sensitive: true);
      _requireNewPassword(temporaryPassword);
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
    return Result.guardAsync(
      () => _db.transaction(() async {
        await _admin(sensitive: true, entityId: id);
        if (!active && id == _access.actingAccountId) {
          throw const ValidationFailure(
            "You can't deactivate your own account.",
          );
        }
        if (!active) await requireSafeDeactivation(_db, id);
        final updated =
            await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
              UsersCompanion(isActive: Value(active)),
            );
        if (updated != 1) throw NotFoundFailure('No user $id.');
        if (!active) await invalidateRecoveryCodes(_db, id, DateTime.now());
        await _access.audit(
          active ? 'account.activated' : 'account.deactivated',
          entityType: 'account',
          entityId: id,
        );
      }),
    );
  }

  @override
  Future<Result<void>> setAvatarPath({required String id, String? avatarPath}) {
    return Result.guardAsync(() async {
      // Your own photo, or an administrator managing accounts.
      await _access.selfOrAdmin(
        id,
        Permission.manageUsers,
        entityType: 'account',
        entityId: id,
      );
      await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(avatarPath: Value(avatarPath)),
      );
    });
  }

  @override
  Future<Result<void>> resetPassword({
    required String id,
    required String newPassword,
  }) {
    return Result.guardAsync(() async {
      await _admin(sensitive: true, entityId: id);
      _requireNewPassword(newPassword);
      final pw = _hasher.hashNew(newPassword);
      final updated =
          await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
            UsersCompanion(
              passwordHash: Value(pw.hash),
              passwordSalt: Value(pw.salt),
            ),
          );
      if (updated != 1) throw NotFoundFailure('No user $id.');
      await invalidateRecoveryCodes(_db, id, DateTime.now());
      await _access.audit(
        'account.password_reset_by_admin',
        entityType: 'account',
        entityId: id,
      );
    });
  }

  @override
  Future<Result<void>> resetPasswordAndResolve({
    required String id,
    required String newPassword,
    required String adminId,
  }) async {
    try {
      await _admin(sensitive: true, entityId: id);
      await _access.assertActor(adminId, entityType: 'account', entityId: id);
    } on Failure catch (f) {
      return Err(f);
    }
    final result = await Result.guardAsync(
      () => _db.transaction(() async {
        _requireNewPassword(newPassword);
        final admin =
            await (_db.select(_db.users)..where(
                  (u) =>
                      u.id.equals(adminId) &
                      u.role.equalsValue(UserRole.admin) &
                      u.isActive.equals(true),
                ))
                .getSingleOrNull();
        if (admin == null) {
          throw const AuthFailure('Administrator access is required.');
        }
        final pw = _hasher.hashNew(newPassword);
        final updated =
            await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
              UsersCompanion(
                passwordHash: Value(pw.hash),
                passwordSalt: Value(pw.salt),
              ),
            );
        if (updated != 1) throw NotFoundFailure('No user $id.');
        await (_db.update(
          _db.passwordResetRequests,
        )..where((r) => r.userId.equals(id) & r.resolved.equals(false))).write(
          PasswordResetRequestsCompanion(
            resolved: const Value(true),
            resolvedByStaffId: Value(adminId),
            resolvedAt: Value(DateTime.now()),
          ),
        );
        await invalidateRecoveryCodes(_db, id, DateTime.now());
      }),
    );
    if (result.isOk) {
      await _access.audit(
        'account.password_reset_by_admin',
        entityType: 'account',
        entityId: id,
        detail: 'resolved queued request',
      );
    }
    return result;
  }

  @override
  Future<Result<Set<String>>> userIdsWithPendingPasswordResetRequests() {
    return Result.guardAsync(() async {
      await _admin();
      final rows = await (_db.select(
        _db.passwordResetRequests,
      )..where((r) => r.resolved.equals(false))).get();
      return rows.map((r) => r.userId).toSet();
    });
  }

  @override
  Future<Result<void>> resolvePasswordResetRequests({
    required String userId,
    required String staffId,
  }) {
    return Result.guardAsync(() async {
      await _admin(entityId: userId);
      await _access.assertActor(staffId, entityType: 'account');
      await (_db.update(_db.passwordResetRequests)
            ..where((r) => r.userId.equals(userId) & r.resolved.equals(false)))
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
