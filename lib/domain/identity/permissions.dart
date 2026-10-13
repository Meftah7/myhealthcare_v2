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
  requestRecordCorrection,
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

  // Explicit scoped grants; account roles do not grant these automatically.
  prepareDocument,
  issueAdministrativeDocument,
  reprintApprovedDocument,
  manageDocumentTemplates,
  assignOperationalWork,
  revokeDocument,
  signClinicalDocument,

  // --- Front desk and pharmacy ---------------------------------------------
  /// Book, reschedule or cancel appointments on a patient's behalf.
  bookForPatients,

  /// Confirm arrival / check a booked patient in.
  checkInPatients,

  /// Administratively confirm an already issued document copy. Never a
  /// clinical signature.
  confirmDocumentCopy,

  /// Review signed prescriptions and record dispensing outcomes.
  dispenseMedication,

  /// Append FDI dental chart entries (dentists only).
  recordDentalChart,
}

/// Grants per role. Staff grants depend on the validated [StaffRole]: a nurse
/// works the chart and the queue but does not prescribe or certify leave;
/// reception and pharmacy never read the clinical chart.
abstract final class RolePermissions {
  static const patient = <Permission>{
    Permission.viewOwnHealthData,
    Permission.updateProfile,
    Permission.bookAppointments,
    Permission.payBills,
    Permission.messageCareTeam,
    Permission.manageProxyGrants,
    Permission.uploadDocuments,
    Permission.requestRecordCorrection,
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

  /// Dental scope: chart, notes, scoped prescribing and signing within care
  /// relationships; no general result-review queue.
  static const dentist = <Permission>{
    ...nurse,
    Permission.prescribe,
    Permission.issueSickLeave,
    Permission.useClinicalScribe,
    Permission.requestReferral,
    Permission.signEncounter,
    Permission.recordDentalChart,
  };

  static const receptionist = <Permission>{
    Permission.bookForPatients,
    Permission.checkInPatients,
    Permission.confirmDocumentCopy,
    Permission.messageCareTeam,
    Permission.manageTasks,
  };

  static const pharmacist = <Permission>{
    Permission.dispenseMedication,
    Permission.messageCareTeam,
    Permission.manageTasks,
  };

  /// A staff account whose role is missing or unrecognised: nothing.
  static const unassignedStaff = <Permission>{};

  static Set<Permission> forStaff(StaffRole? role) => switch (role) {
    StaffRole.doctor => doctor,
    StaffRole.nurse => nurse,
    StaffRole.dentist => dentist,
    StaffRole.receptionist => receptionist,
    StaffRole.pharmacist => pharmacist,
    null => unassignedStaff,
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

  /// The grant for an account of [role]. [staffRole] only matters for staff.
  static Set<Permission> forRole(UserRole role, {StaffRole? staffRole}) =>
      switch (role) {
        UserRole.patient => patient,
        UserRole.staff => forStaff(staffRole),
        UserRole.admin => admin,
      };
}
