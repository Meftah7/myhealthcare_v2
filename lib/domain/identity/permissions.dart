/// Least-privilege permissions and the role → permission grant table.
///
/// A permission says what *kind* of action a principal may attempt. It never
/// says which object: object-level checks (is this my patient, my proxy, my
/// care relationship, my appointment) are made separately by `AccessPolicy`
/// in the repositories, which stay the authoritative enforcement point. The
/// UI reads the same table only to decide what to offer.
library;

import '../enums.dart';

enum Permission {
  // --- Patient self-service (own record, or a proxy grant's patient) -------
  viewOwnHealthData,
  updateProfile,
  bookAppointments,
  payBills,
  messageCareTeam,
  manageProxyGrants,
  uploadDocuments,
  requestHomeVisit,

  // --- Clinical ------------------------------------------------------------
  readPatientChart,
  writeClinicalRecord,
  prescribe,
  issueSickLeave,
  runConsultation,
  manageOwnSchedule,
  manageWalkInQueue,
  acknowledgeRiskFlags,
  useClinicalScribe,
  requestReferral,

  /// Sign (finalize) an encounter note. Nurses draft; doctors sign.
  signEncounter,

  /// Take ownership of and resolve abnormal/unknown result reviews.
  reviewResults,

  /// Work the staff task list (update status, escalate to cover).
  manageTasks,

  // --- Administration ------------------------------------------------------
  manageUsers,
  manageDepartments,
  manageBilling,

  /// Return money from a settled payment. Separate from [manageBilling] so a
  /// clinic can give invoicing to more people than refunds.
  refundPayments,
  manageSettings,
  readAuditLog,
  broadcastNotifications,
  decideReferrals,
  decideHomeVisits,
  manageCareTeams,
  manageClinicSchedules,
  viewOperationalReports,
}

/// Grants per role. Staff grants depend on the clinical job title: a nurse
/// works the chart and the queue but does not prescribe or certify leave.
abstract final class RolePermissions {
  static const patient = <Permission>{
    Permission.viewOwnHealthData,
    Permission.updateProfile,
    Permission.bookAppointments,
    Permission.payBills,
    Permission.messageCareTeam,
    Permission.manageProxyGrants,
    Permission.uploadDocuments,
    Permission.requestHomeVisit,
  };

  static const nurse = <Permission>{
    Permission.readPatientChart,
    Permission.writeClinicalRecord,
    Permission.runConsultation,
    Permission.manageOwnSchedule,
    Permission.manageWalkInQueue,
    Permission.acknowledgeRiskFlags,
    Permission.messageCareTeam,
    Permission.manageTasks,
  };

  static const doctor = <Permission>{
    ...nurse,
    Permission.prescribe,
    Permission.issueSickLeave,
    Permission.useClinicalScribe,
    Permission.requestReferral,
    Permission.signEncounter,
    Permission.reviewResults,
  };

  static const admin = <Permission>{
    Permission.manageUsers,
    Permission.manageDepartments,
    Permission.manageBilling,
    Permission.refundPayments,
    Permission.manageSettings,
    Permission.readAuditLog,
    Permission.broadcastNotifications,
    Permission.decideReferrals,
    Permission.decideHomeVisits,
    Permission.manageCareTeams,
    Permission.manageClinicSchedules,
    Permission.viewOperationalReports,
  };

  /// The grant for an account of [role]. [isNurse] only matters for staff.
  static Set<Permission> forRole(UserRole role, {bool isNurse = false}) =>
      switch (role) {
        UserRole.patient => patient,
        UserRole.staff => isNurse ? nurse : doctor,
        UserRole.admin => admin,
      };
}
