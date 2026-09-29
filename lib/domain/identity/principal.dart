/// The authenticated acting identity.
///
/// Created only by a successful sign-in (password check) and held by
/// `AuthContext`. Repositories take "who is acting" from here — never from an
/// ID a caller passes in — and treat caller-supplied patient/staff IDs as the
/// *object* being acted on, which they then authorize against this.
library;

import 'package:flutter/foundation.dart';

import '../enums.dart';
import 'permissions.dart';

@immutable
class Principal {
  const Principal({
    required this.accountId,
    required this.role,
    required this.permissions,
    required this.sessionId,
    required this.authenticatedAt,
  });

  final String accountId;
  final UserRole role;
  final Set<Permission> permissions;

  /// Fresh per sign-in, so state from one session can be told apart from the
  /// next even when the same account signs in again.
  final String sessionId;

  /// When the password was last proven (sign-in or re-authentication).
  final DateTime authenticatedAt;

  bool get isPatient => role == UserRole.patient;
  bool get isStaff => role == UserRole.staff;
  bool get isAdmin => role == UserRole.admin;

  bool can(Permission permission) => permissions.contains(permission);

  Principal reauthenticated(DateTime at) => Principal(
    accountId: accountId,
    role: role,
    permissions: permissions,
    sessionId: sessionId,
    authenticatedAt: at,
  );

  @override
  String toString() => 'Principal($accountId, ${role.name}, $sessionId)';
}
