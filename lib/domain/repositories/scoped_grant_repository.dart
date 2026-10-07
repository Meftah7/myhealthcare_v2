import '../../core/result.dart';
import '../identity/operational_roles.dart';
import '../identity/permissions.dart';

class ScopedGrant {
  const ScopedGrant({
    required this.id,
    required this.accountId,
    required this.permission,
    required this.scope,
    required this.scopeId,
    required this.startsAt,
    this.expiresAt,
    this.revokedAt,
  });
  final String id, accountId, scopeId;
  final Permission permission;
  final GrantScope scope;
  final DateTime startsAt;
  final DateTime? expiresAt, revokedAt;
}

abstract interface class ScopedGrantRepository {
  Future<Result<List<ScopedGrant>>> forAccount(String accountId);

  /// Admin + recent authentication. Grant and audit commit together.
  Future<Result<ScopedGrant>> grant({
    required String accountId,
    required Permission permission,
    required GrantScope scope,
    required String scopeId,
    required String reason,
    DateTime? startsAt,
    DateTime? expiresAt,
  });
  Future<Result<void>> revoke(String id, {required String reason});
}
