/// Patient document plumbing (P10-01, Phase 5): the identity block every
/// generated PDF carries, plus one-call builders the screens hand to a
/// download button.
///
/// Every builder first asks the export repository to authorize and audit the
/// export — a denial means nothing is built — and produces the document in
/// the app's language (Arabic documents are right-to-left).
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/export_repository.dart';
import '../../../domain/repositories/record_repository.dart';
import '../../../services/pdf/clinic_pdf.dart';
import '../../../services/pdf/reports.dart';
import '../../appointments/application/appointment_records_provider.dart';
import 'patient_data_providers.dart';

bool get _ar => Intl.getCurrentLocale().startsWith('ar');

/// The signed-in patient's identity, shaped for [ClinicPdf].
final pdfIdentityProvider = FutureProvider<PdfIdentity>((ref) async {
  final p = await ref.watch(patientProfileProvider.future);
  // Medications are context, not the document's subject — a failed read
  // must not stop the export.
  final meds = await ref
      .watch(patientMedicationsProvider.future)
      .catchError((Object _) => <Medication>[]);
  return PdfIdentity(
    name: p.fullName,
    patientId: p.id,
    bloodType: p.bloodType,
    dob: p.user.dob,
    allergies: p.allergies,
    conditions: p.chronicConditions,
    medications: [
      for (final m in meds)
        if (m.isActive) [m.name, ?m.dose, ?m.frequency].join(' · '),
    ],
  );
});

/// A clinician's licence number, or null when unknown or unreadable.
Future<String?> _licence(WidgetRef ref, String? staffId) async {
  if (staffId == null) return null;
  final r = await ref.read(userRepositoryProvider).staffById(staffId);
  return r.valueOrNull?.licenseNo;
}

/// For each analyte in [record], its most recent value from an earlier
/// record — so the patient can see the direction of change.
Future<Map<String, PreviousLab>> _previousLabs(
  WidgetRef ref,
  MedicalRecord record,
) async {
  if (record.labValues.isEmpty) return const {};
  final wanted = {for (final v in record.labValues) v.analyte.toLowerCase()};
  final history = await ref
      .read(patientTimelineProvider.future)
      .catchError((Object _) => <MedicalRecord>[]);
  final earlier =
      history
          .where(
            (r) =>
                r.id != record.id &&
                r.labValues.isNotEmpty &&
                r.occurredAt.isBefore(record.occurredAt),
          )
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final out = <String, PreviousLab>{};
  for (final r in earlier) {
    for (final v in r.labValues) {
      final key = v.analyte.toLowerCase();
      if (wanted.contains(key) && !out.containsKey(key)) {
        out[key] = (value: v.value, unit: v.unit, at: r.occurredAt);
      }
    }
  }
  return out;
}

/// The document's identity strip is the signed-in patient, so it may only
/// carry that patient's records.
void _samePatient(PdfIdentity identity, String patientId) {
  if (identity.patientId != patientId) {
    throw const AccessDeniedFailure(
      'This document belongs to another patient.',
    );
  }
}

/// Authorize and audit before building anything; throws the denial.
Future<void> _authorize(
  WidgetRef ref,
  String patientId,
  ExportDocument document, {
  String? entityId,
}) async {
  final r = await ref
      .read(exportRepositoryProvider)
      .authorizeExport(
        patientId: patientId,
        document: document,
        entityId: entityId,
      );
  if (r case Err(:final failure)) throw failure;
}

/// Builds the patient's vital-signs report from live data.
Future<Uint8List> buildVitalsReport(WidgetRef ref) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  await _authorize(ref, identity.patientId, ExportDocument.vitalsReport);
  final readings = await ref.read(patientVitalsProvider.future);
  return vitalsReportPdf(patient: identity, readings: readings, arabic: _ar);
}

/// Builds a radiology report for one imaging [record].
Future<Uint8List> buildRadiologyReport(
  WidgetRef ref,
  MedicalRecord record,
) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  _samePatient(identity, record.patientId);
  await _authorize(
    ref,
    record.patientId,
    ExportDocument.radiologyReport,
    entityId: record.id,
  );
  final doctors = await ref.read(doctorDirectoryProvider.future);
  return radiologyReportPdf(
    patient: identity,
    record: record,
    reportingClinician: doctors[record.authorStaffId]?.name,
    clinicianLicence: await _licence(ref, record.authorStaffId),
    arabic: _ar,
  );
}

/// Builds a referral letter from an external `referral` record — the one the
/// admin created when referring the patient to another hospital
/// (`sourceFacility` = the hospital, `body` = the reason).
Future<Uint8List> buildReferralLetter(
  WidgetRef ref,
  MedicalRecord record,
) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  _samePatient(identity, record.patientId);
  await _authorize(
    ref,
    record.patientId,
    ExportDocument.referralLetter,
    entityId: record.id,
  );
  final doctors = await ref.read(doctorDirectoryProvider.future);
  final clinician = doctors[record.authorStaffId]?.name;
  return referralLetterPdf(
    patient: identity,
    destination:
        record.sourceFacility ?? (_ar ? 'جهة خارجية' : 'External service'),
    reason: (record.body ?? '').trim().isEmpty
        ? (_ar ? 'راجع سجل المريض.' : 'See patient record.')
        : record.body!.trim(),
    referringClinic: clinician ?? ClinicPdf.clinicName,
    date: record.occurredAt,
    reference: record.id,
    clinicianLicence: await _licence(ref, record.authorStaffId),
    arabic: _ar,
  );
}

/// Builds a sick-leave certificate PDF.
Future<Uint8List> buildSickLeave(
  WidgetRef ref,
  SickLeaveCertificate certificate,
) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  _samePatient(identity, certificate.patientId);
  await _authorize(
    ref,
    certificate.patientId,
    ExportDocument.sickLeaveCertificate,
    entityId: certificate.id,
  );
  final doctors = await ref.read(doctorDirectoryProvider.future);
  return sickLeavePdf(
    patient: identity,
    certificate: certificate,
    issuingClinician:
        doctors[certificate.issuedByStaffId]?.name ??
        (_ar ? 'الطبيب المعالج' : 'Attending clinician'),
    clinicianLicence: await _licence(ref, certificate.issuedByStaffId),
    arabic: _ar,
  );
}

/// Builds a summary of any stored record — including a patient import, with
/// its issuer, original file fingerprint and review status.
Future<Uint8List> buildRecordSummary(
  WidgetRef ref,
  MedicalRecord record, {
  required String recordTypeLabel,
}) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  _samePatient(identity, record.patientId);
  await _authorize(
    ref,
    record.patientId,
    ExportDocument.recordSummary,
    entityId: record.id,
  );
  final doctors = await ref.read(doctorDirectoryProvider.future);
  return recordSummaryPdf(
    patient: identity,
    record: record,
    recordTypeLabel: recordTypeLabel,
    authorName: doctors[record.authorStaffId]?.name,
    reviewerName: doctors[record.reviewedByStaffId]?.name,
    previousLabs: await _previousLabs(ref, record),
    arabic: _ar,
  );
}

/// The original file behind an imported record, exactly as imported.
Future<Uint8List> openOriginalFile(WidgetRef ref, MedicalRecord record) async {
  await _authorize(
    ref,
    record.patientId,
    ExportDocument.originalFile,
    entityId: record.id,
  );
  final r = await ref.read(recordRepositoryProvider).sourceFile(record.id);
  return switch (r) {
    Ok(:final SourceFile value) => value.bytes,
    Err(:final failure) => throw failure,
  };
}

/// Builds a summary of one completed [appointment]: vitals, notes, results
/// and medications linked to it, plus the next booked visit.
Future<Uint8List> buildVisitSummary(
  WidgetRef ref,
  Appointment appointment,
) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  _samePatient(identity, appointment.patientId);
  await _authorize(
    ref,
    appointment.patientId,
    ExportDocument.visitSummary,
    entityId: appointment.id,
  );
  final bundle = await ref.read(
    appointmentRecordsProvider(appointment.id).future,
  );
  final doctors = await ref.read(doctorDirectoryProvider.future);
  final departments = await ref.read(departmentDirectoryProvider.future);
  final next = await ref
      .read(nextAppointmentProvider.future)
      .catchError((Object _) => null);
  return visitSummaryPdf(
    patient: identity,
    appointment: appointment,
    records: bundle.records,
    vitals: bundle.vitals,
    medications: bundle.medications,
    clinicianName: doctors[appointment.staffId]?.name,
    clinicianLicence: await _licence(ref, appointment.staffId),
    departmentName: departments[appointment.departmentId],
    nextAppointment: next,
    arabic: _ar,
  );
}
