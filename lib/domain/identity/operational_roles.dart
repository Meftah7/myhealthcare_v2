import 'permissions.dart';

enum OperationalRole {
  clinicAdministrator,
  reception,
  billing,
  documentDesk,
  clinicalSupervisor,
}

enum GrantScope { clinic, patient, department }

/// Presets are grant suggestions, never automatic account privileges.
abstract final class OperationalRoles {
  static const permissions = <OperationalRole, Set<Permission>>{
    OperationalRole.clinicAdministrator: {
      Permission.prepareDocument,
      Permission.issueAdministrativeDocument,
      Permission.reprintApprovedDocument,
      Permission.manageDocumentTemplates,
      Permission.assignOperationalWork,
      Permission.revokeDocument,
    },
    OperationalRole.reception: {
      Permission.prepareDocument,
      Permission.assignOperationalWork,
    },
    OperationalRole.billing: {Permission.issueAdministrativeDocument},
    OperationalRole.documentDesk: {
      Permission.prepareDocument,
      Permission.reprintApprovedDocument,
    },
    OperationalRole.clinicalSupervisor: {
      Permission.prepareDocument,
      Permission.reprintApprovedDocument,
      Permission.assignOperationalWork,
      Permission.revokeDocument,
    },
  };

  static const scopedPermissions = {
    Permission.prepareDocument,
    Permission.issueAdministrativeDocument,
    Permission.reprintApprovedDocument,
    Permission.manageDocumentTemplates,
    Permission.assignOperationalWork,
    Permission.revokeDocument,
    Permission.signClinicalDocument,
  };
}
