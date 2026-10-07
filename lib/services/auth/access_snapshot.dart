import '../../domain/identity/permissions.dart';

/// Only authorization metadata; never clinical content.
class AccessSnapshot {
  const AccessSnapshot({
    required this.sessionId,
    required this.patients,
    required this.permissions,
    required this.manageProxies,
    required this.credentials,
    this.scopedGrants = const {},
    this.signingPatients = const {},
    this.nextExpiry,
  });
  final String sessionId;
  final Set<String> patients;
  final Set<Permission> permissions;
  final Set<String> manageProxies;
  final Set<String> credentials;
  final Set<String> scopedGrants;
  final Set<String> signingPatients;
  final DateTime? nextExpiry;

  bool losesAccessFrom(AccessSnapshot previous) =>
      sessionId != previous.sessionId ||
      !patients.containsAll(previous.patients) ||
      !permissions.containsAll(previous.permissions) ||
      !manageProxies.containsAll(previous.manageProxies) ||
      !credentials.containsAll(previous.credentials) ||
      !scopedGrants.containsAll(previous.scopedGrants) ||
      !signingPatients.containsAll(previous.signingPatients);
}
