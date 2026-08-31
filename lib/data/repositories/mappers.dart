/// Drift row → domain entity mappers (P1-12…P1-17).
///
/// One direction only: rows come from the database as generated `*Row` classes
/// and are converted to `lib/domain/entities` types here. Writes build drift
/// `Companion`s inline in each repository.
library;

import '../../domain/entities/entities.dart';
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
    checkedInAt: checkedInAt,
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
