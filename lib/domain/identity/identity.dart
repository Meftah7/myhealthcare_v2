/// Identity and relationship concepts, kept apart so each can change on its
/// own:
///
/// * **Account** — a login identity (credentials, role, active flag). This is
///   the existing `User` entity.
/// * **Patient** — a person who receives care. Usually backed by the account
///   of the same id, but a *dependent* (a child, or an adult someone cares
///   for) is a patient with no login of their own.
/// * **ProxyGrant** — one account's permission to see, or act for, another
///   patient. Persisted in the `family_links` table.
/// * **StaffCredential** — a clinician's licence or registration.
/// * **CareTeamAssignment** — a clinician formally assigned to a patient.
/// * **Role / Permission** — what kind of action an account may attempt
///   (see `permissions.dart`).
library;

import 'package:flutter/foundation.dart';

import '../entities/family_link.dart';
import '../entities/user.dart';
import '../enums.dart';

/// A login identity. An alias today; the separate name marks code that is
/// about credentials and sign-in rather than about a patient's care.
typedef Account = User;

enum ProxyAccess { view, manage }

/// Access that [proxyAccountId] holds to [patientId]'s data.
@immutable
class ProxyGrant {
  const ProxyGrant({
    required this.id,
    required this.patientId,
    required this.proxyAccountId,
    required this.access,
    required this.grantedAt,
  });

  /// Only an accepted family link is a grant; a pending request grants
  /// nothing.
  static ProxyGrant? fromFamilyLink(FamilyLink link) {
    if (!link.isAccepted) return null;
    return ProxyGrant(
      id: link.id,
      patientId: link.ownerPatientId,
      proxyAccountId: link.viewerPatientId,
      access: link.permission == FamilyLinkPermission.manage
          ? ProxyAccess.manage
          : ProxyAccess.view,
      grantedAt: link.respondedAt ?? link.createdAt,
    );
  }

  final String id;
  final String patientId;
  final String proxyAccountId;
  final ProxyAccess access;
  final DateTime grantedAt;

  bool get canAct => access == ProxyAccess.manage;
}

/// The two identities every patient-facing action carries: who is acting,
/// and whose record it lands on. They differ when a guardian books for a
/// dependent or a proxy pays a linked account's invoice.
@immutable
class PatientSubject {
  const PatientSubject({
    required this.actingAccountId,
    required this.patientId,
    this.grantId,
  });

  final String actingAccountId;
  final String patientId;

  /// The proxy grant that authorised acting for someone else, if any.
  final String? grantId;

  bool get isSelf => actingAccountId == patientId;

  @override
  bool operator ==(Object other) =>
      other is PatientSubject &&
      other.actingAccountId == actingAccountId &&
      other.patientId == patientId &&
      other.grantId == grantId;

  @override
  int get hashCode => Object.hash(actingAccountId, patientId, grantId);
}

enum CareTeamRole { primaryClinician, consultant, nurse, other }

@immutable
class CareTeamAssignment {
  const CareTeamAssignment({
    required this.id,
    required this.patientId,
    required this.staffId,
    required this.role,
    required this.assignedAt,
    this.assignedBy,
    this.endedAt,
  });

  final String id;
  final String patientId;
  final String staffId;
  final CareTeamRole role;
  final DateTime assignedAt;
  final String? assignedBy;
  final DateTime? endedAt;

  bool isActiveAt(DateTime at) =>
      !assignedAt.isAfter(at) && (endedAt == null || endedAt!.isAfter(at));
}

enum CredentialKind { medicalLicense, nursingLicense, other }

@immutable
class StaffCredential {
  const StaffCredential({
    required this.id,
    required this.staffId,
    required this.kind,
    required this.identifier,
    required this.recordedAt,
    this.issuer,
    this.validUntil,
    this.verifiedAt,
    this.revokedAt,
  });

  final String id;
  final String staffId;
  final CredentialKind kind;
  final String identifier;
  final DateTime recordedAt;
  final String? issuer;
  final DateTime? validUntil;
  final DateTime? verifiedAt;
  final DateTime? revokedAt;

  bool isValidAt(DateTime at) =>
      revokedAt == null && (validUntil == null || validUntil!.isAfter(at));
}
