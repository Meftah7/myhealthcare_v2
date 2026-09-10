/// Drift row → domain entity mappers (P1-12…P1-17).
///
/// One direction only: rows come from the database as generated `*Row` classes
/// and are converted to `lib/domain/entities` types here. Writes build drift
/// `Companion`s inline in each repository.
library;

import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../db/app_database.dart';

extension UserRowX on UserRow {
  User toEntity() => User(
    id: id,
    role: role,
    fullName: fullName,
    email: email,
    isActive: isActive,
    createdAt: createdAt,
    phone: phone,
    dob: dob,
    gender: gender,
    nationalId: nationalId,
  );
}

extension DepartmentRowX on DepartmentRow {
  Department toEntity() =>
      Department(id: id, name: name, description: description);
}

Patient patientFrom(UserRow user, PatientProfileRow? profile) => Patient(
  user: user.toEntity(),
  bloodType: profile?.bloodType,
  allergies: profile?.allergies ?? const [],
  chronicConditions: profile?.chronicConditions ?? const [],
  emergencyContact: profile?.emergencyContact,
);

Staff staffFrom(UserRow user, StaffProfileRow? profile) => Staff(
  user: user.toEntity(),
  specialty: profile?.specialty,
  departmentId: profile?.departmentId,
  licenseNo: profile?.licenseNo,
  jobTitle: profile?.jobTitle,
  presence: profile?.presence ?? PresenceStatus.offShift,
);

extension AppointmentRowX on AppointmentRow {
  Appointment toEntity() => Appointment(
    id: id,
    patientId: patientId,
    staffId: staffId,
    slotStart: slotStart,
    slotEnd: slotEnd,
    visitType: visitType,
    status: status,
    bookedAt: bookedAt,
    remindersSent: remindersSent,
    departmentId: departmentId,
    reasonText: reasonText,
    noShowRisk: noShowRisk,
    riskBand: riskBand,
    calledInAt: calledInAt,
    checkedInAt: checkedInAt,
    outcomeNote: outcomeNote,
    ticketTag: ticketTag,
    roomNumber: roomNumber,
    bookedForName: bookedForName,
  );
}

extension WalkInRowX on WalkInRow {
  WalkInTicket toEntity() => WalkInTicket(
    id: id,
    patientId: patientId,
    departmentId: departmentId,
    ticketTag: ticketTag,
    status: status,
    reason: reason,
    sourceAppointmentId: sourceAppointmentId,
    createdByStaffId: createdByStaffId,
    claimedByStaffId: claimedByStaffId,
    resultAppointmentId: resultAppointmentId,
    createdAt: createdAt,
    resolvedAt: resolvedAt,
  );
}

extension ReferralRequestRowX on ReferralRequestRow {
  ReferralRequest toEntity() => ReferralRequest(
    id: id,
    patientId: patientId,
    appointmentId: appointmentId,
    requestedByStaffId: requestedByStaffId,
    reason: reason,
    status: status,
    decidedByAdminId: decidedByAdminId,
    decisionNote: decisionNote,
    decidedAt: decidedAt,
    createdAt: createdAt,
  );
}

extension InvoiceRowX on InvoiceRow {
  Invoice toEntity() => Invoice(
    id: id,
    patientId: patientId,
    subtotal: subtotal,
    taxRate: taxRate,
    taxAmount: taxAmount,
    totalAmount: totalAmount,
    status: status,
    issuedAt: issuedAt,
    appointmentId: appointmentId,
    dueDate: dueDate,
    paidAt: paidAt,
    paymentMethod: paymentMethod,
    notes: notes,
  );
}

extension PaymentMethodRowX on PaymentMethodRow {
  PaymentMethod toEntity() => PaymentMethod(
    id: id,
    patientId: patientId,
    brand: brand,
    last4: last4,
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
    holderName: holderName,
    addedAt: addedAt,
    isDefault: isDefault,
  );
}

extension NotificationRowX on NotificationRow {
  AppNotification toEntity() => AppNotification(
    id: id,
    recipientId: recipientId,
    category: category,
    title: title,
    body: body,
    createdAt: createdAt,
    deepLink: deepLink,
    readAt: readAt,
  );
}

extension LabValueRowX on LabValueRow {
  LabValue toEntity() => LabValue(
    id: id,
    recordId: recordId,
    analyte: analyte,
    value: value,
    abnormalFlag: abnormalFlag,
    unit: unit,
    refLow: refLow,
    refHigh: refHigh,
  );
}

MedicalRecord recordFrom(MedicalRecordRow row, List<LabValueRow> labs) =>
    MedicalRecord(
      id: row.id,
      patientId: row.patientId,
      recordType: row.recordType,
      title: row.title,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
      labValues: labs.map((l) => l.toEntity()).toList(),
      authorStaffId: row.authorStaffId,
      appointmentId: row.appointmentId,
      body: row.body,
      sourceFacility: row.sourceFacility,
      attachmentPath: row.attachmentPath,
      extractedText: row.extractedText,
    );

extension VitalsRowX on VitalsRow {
  Vitals toEntity() => Vitals(
    id: id,
    patientId: patientId,
    recordedAt: recordedAt,
    systolic: systolic,
    diastolic: diastolic,
    heartRate: heartRate,
    tempC: tempC,
    weightKg: weightKg,
    heightCm: heightCm,
    spo2: spo2,
    glucose: glucose,
    recordedByStaffId: recordedByStaffId,
  );
}

extension MedicationRowX on MedicationRow {
  Medication toEntity() => Medication(
    id: id,
    patientId: patientId,
    name: name,
    startDate: startDate,
    isActive: isActive,
    prescriberId: prescriberId,
    appointmentId: appointmentId,
    dose: dose,
    frequency: frequency,
    endDate: endDate,
  );
}

extension StaffTaskRowX on StaffTaskRow {
  StaffTask toEntity() => StaffTask(
    id: id,
    staffId: staffId,
    title: title,
    kind: kind,
    status: status,
    ruleScore: ruleScore,
    createdAt: createdAt,
    patientId: patientId,
    dueAt: dueAt,
    aiPriorityScore: aiPriorityScore,
    aiRationale: aiRationale,
  );
}

extension RiskFlagRowX on RiskFlagRow {
  RiskFlag toEntity() => RiskFlag(
    id: id,
    patientId: patientId,
    kind: kind,
    severity: severity,
    rationale: rationale,
    detectedAt: detectedAt,
    source: source,
    dedupeKey: dedupeKey,
    acknowledgedBy: acknowledgedBy,
    acknowledgedAt: acknowledgedAt,
  );
}

extension AuditLogRowX on AuditLogRow {
  AuditEntry toEntity() => AuditEntry(
    id: id,
    action: action,
    entityType: entityType,
    at: at,
    actorUserId: actorUserId,
    entityId: entityId,
    detail: detail,
  );
}

extension AppSettingsRowX on AppSettingsRow {
  AppSettings toEntity() => AppSettings(
    aiEnabled: aiEnabled,
    mockMode: mockMode,
    modelId: modelId,
    aiTaskWeight: aiTaskWeight,
    seedVersion: seedVersion,
    updatedAt: updatedAt,
  );
}

UserFeedback feedbackFrom(FeedbackRow row, {String? name, String? email}) =>
    UserFeedback(
      id: row.id,
      category: row.category,
      message: row.message,
      status: row.status,
      createdAt: row.createdAt,
      reporterId: row.reporterId,
      reporterName: name,
      reporterEmail: email,
      handledByAdminId: row.handledByAdminId,
      handledAt: row.handledAt,
    );

extension AiUsageRowX on AiUsageRow {
  AiUsageEntry toEntity() => AiUsageEntry(
    id: id,
    feature: feature,
    at: at,
    usedLiveModel: usedLiveModel,
    userId: userId,
    summary: summary,
  );
}

extension SickLeaveRowX on SickLeaveRow {
  SickLeaveCertificate toEntity() => SickLeaveCertificate(
    id: id,
    patientId: patientId,
    issuedByStaffId: issuedByStaffId,
    diagnosis: diagnosis,
    fromDate: fromDate,
    toDate: toDate,
    issuedAt: issuedAt,
    appointmentId: appointmentId,
    notes: notes,
  );
}

extension CareMessageRowX on CareMessageRow {
  CareMessage toEntity() => CareMessage(
    id: id,
    patientId: patientId,
    staffId: staffId,
    fromStaff: fromStaff,
    body: body,
    sentAt: sentAt,
    readAt: readAt,
  );
}

extension HomeVisitRowX on HomeVisitRow {
  HomeVisitRequest toEntity() => HomeVisitRequest(
    id: id,
    patientId: patientId,
    addressText: addressText,
    preferredDate: preferredDate,
    reasonText: reasonText,
    status: status,
    createdAt: createdAt,
    departmentId: departmentId,
    assignedStaffId: assignedStaffId,
    decisionNote: decisionNote,
    decidedAt: decidedAt,
  );
}
