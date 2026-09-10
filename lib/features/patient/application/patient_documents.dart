/// Patient document plumbing (P10-01): the identity block every generated PDF
/// carries, plus one-call builders the screens hand to a download button.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/entities.dart';
import '../../../services/pdf/clinic_pdf.dart';
import '../../../services/pdf/reports.dart';
import 'patient_data_providers.dart';

/// The signed-in patient's identity, shaped for [ClinicPdf].
final pdfIdentityProvider = FutureProvider<PdfIdentity>((ref) async {
  final p = await ref.watch(patientProfileProvider.future);
  return PdfIdentity(
    name: p.fullName,
    patientId: p.id,
    bloodType: p.bloodType,
    dob: p.user.dob,
    allergies: p.allergies,
  );
});

/// Builds the patient's vital-signs report from live data.
Future<Uint8List> buildVitalsReport(WidgetRef ref) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  final readings = await ref.read(patientVitalsProvider.future);
  return vitalsReportPdf(patient: identity, readings: readings);
}

/// Builds a radiology report for one imaging [record].
Future<Uint8List> buildRadiologyReport(
  WidgetRef ref,
  MedicalRecord record,
) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  final doctors = await ref.read(doctorDirectoryProvider.future);
  return radiologyReportPdf(
    patient: identity,
    record: record,
    reportingClinician: doctors[record.authorStaffId]?.name,
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
  final doctors = await ref.read(doctorDirectoryProvider.future);
  final clinician = doctors[record.authorStaffId]?.name;
  return referralLetterPdf(
    patient: identity,
    destination: record.sourceFacility ?? 'External service',
    reason: (record.body ?? '').trim().isEmpty
        ? 'See patient record.'
        : record.body!.trim(),
    referringClinic: clinician ?? 'MyHealth Care',
    date: record.occurredAt,
  );
}

/// Builds a sick-leave certificate PDF.
Future<Uint8List> buildSickLeave(
  WidgetRef ref,
  SickLeaveCertificate certificate,
) async {
  final identity = await ref.read(pdfIdentityProvider.future);
  final doctors = await ref.read(doctorDirectoryProvider.future);
  return sickLeavePdf(
    patient: identity,
    certificate: certificate,
    issuingClinician:
        doctors[certificate.issuedByStaffId]?.name ?? 'Attending clinician',
  );
}
