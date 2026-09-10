/// Patient document builders (P10-02, P10-03). Each returns finished PDF bytes
/// through [ClinicPdf], so callers only deal with `Uint8List` + `present`.
library;

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/entities.dart';
import 'clinic_pdf.dart';

final _dayFmt = DateFormat('d MMM yyyy');
final _dayTimeFmt = DateFormat('d MMM yyyy · HH:mm');

/// Vital signs report — latest snapshot plus the full reading history.
Future<Uint8List> vitalsReportPdf({
  required PdfIdentity patient,
  required List<Vitals> readings,
}) {
  final sorted = [...readings]
    ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  final latest = sorted.firstOrNull;
  final oldest = sorted.lastOrNull;

  final subtitle = sorted.isEmpty
      ? null
      : sorted.length == 1
      ? _dayFmt.format(sorted.first.recordedAt)
      : '${_dayFmt.format(oldest!.recordedAt)} – '
            '${_dayFmt.format(latest!.recordedAt)}  ·  '
            '${sorted.length} readings';

  return ClinicPdf.build(
    title: 'Vital signs report',
    subtitle: subtitle,
    patient: patient,
    body: [
      if (latest != null)
        pdfSection(
          'Most recent reading — ${_dayTimeFmt.format(latest.recordedAt)}',
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (latest.hasBloodPressure)
                pdfKeyValue(
                  'Blood pressure',
                  '${latest.systolic}/${latest.diastolic} mmHg',
                ),
              if (latest.heartRate != null)
                pdfKeyValue('Heart rate', '${latest.heartRate} bpm'),
              if (latest.spo2 != null)
                pdfKeyValue('Oxygen saturation', '${latest.spo2}%'),
              if (latest.tempC != null)
                pdfKeyValue('Temperature', '${latest.tempC} °C'),
              if (latest.weightKg != null)
                pdfKeyValue('Weight', '${latest.weightKg} kg'),
              if (latest.heightCm != null)
                pdfKeyValue('Height', '${latest.heightCm} cm'),
              if (latest.bmi != null)
                pdfKeyValue('BMI', latest.bmi!.toStringAsFixed(1)),
              if (latest.glucose != null)
                pdfKeyValue('Glucose', '${latest.glucose} mmol/L'),
            ],
          ),
        ),
      pdfSection(
        'Reading history',
        sorted.isEmpty
            ? pw.Text(
                'No vitals have been recorded yet.',
                style: const pw.TextStyle(fontSize: 9, color: pdfMuted),
              )
            : _vitalsTable(sorted),
      ),
    ],
  );
}

pw.Widget _vitalsTable(List<Vitals> rows) {
  String cell(Object? v) => v == null ? '—' : '$v';
  return pw.TableHelper.fromTextArray(
    headers: ['Date', 'BP', 'HR', 'SpO₂', 'Temp', 'Weight', 'Glucose'],
    headerStyle: const pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: pdfInk,
    ),
    headerDecoration: const pw.BoxDecoration(color: pdfHeaderFill),
    cellStyle: const pw.TextStyle(fontSize: 8, color: pdfInk),
    columnWidths: {
      0: const pw.FlexColumnWidth(2.2),
      1: const pw.FlexColumnWidth(1.4),
      5: const pw.FlexColumnWidth(1.2),
      6: const pw.FlexColumnWidth(1.3),
    },
    border: pw.TableBorder.symmetric(
      inside: const pw.BorderSide(color: pdfHairline, width: 0.5),
    ),
    data: [
      for (final v in rows)
        [
          _dayFmt.format(v.recordedAt),
          v.hasBloodPressure ? '${v.systolic}/${v.diastolic}' : '—',
          cell(v.heartRate),
          v.spo2 == null ? '—' : '${v.spo2}%',
          v.tempC == null ? '—' : '${v.tempC}',
          v.weightKg == null ? '—' : '${v.weightKg}',
          v.glucose == null ? '—' : '${v.glucose}',
        ],
    ],
  );
}

/// Doctor-issued sick-leave certificate (P10-05).
Future<Uint8List> sickLeavePdf({
  required PdfIdentity patient,
  required SickLeaveCertificate certificate,
  required String issuingClinician,
}) {
  final c = certificate;
  return ClinicPdf.build(
    title: 'Medical certificate',
    subtitle: 'Issued ${_dayFmt.format(c.issuedAt)}',
    patient: patient,
    body: [
      pdfSection(
        'Certificate',
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'This is to certify that the above-named patient was examined '
              'and, in my medical opinion, is unfit for work or study for the '
              'period stated below.',
              style: const pw.TextStyle(
                fontSize: 10,
                color: pdfInk,
                lineSpacing: 3,
              ),
            ),
            pw.SizedBox(height: 12),
            pdfKeyValue('Reason', c.diagnosis),
            pdfKeyValue('From', _dayFmt.format(c.fromDate)),
            pdfKeyValue('To (inclusive)', _dayFmt.format(c.toDate)),
            pdfKeyValue('Total', '${c.days} day${c.days == 1 ? '' : 's'}'),
            if (c.notes != null && c.notes!.isNotEmpty)
              pdfKeyValue('Notes', c.notes!),
          ],
        ),
      ),
      pdfSection(
        'Issued by',
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pdfKeyValue('Clinician', issuingClinician),
            pdfKeyValue('Date issued', _dayFmt.format(c.issuedAt)),
            pw.SizedBox(height: 24),
            pw.Container(width: 200, height: 0.7, color: pdfHairline),
            pw.SizedBox(height: 3),
            pw.Text(
              'Signature / clinic stamp',
              style: const pw.TextStyle(fontSize: 8, color: pdfMuted),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Clinic-issued referral letter — a patient carries this to the receiving
/// hospital. Same letterhead / section style as the sick-leave certificate.
Future<Uint8List> referralLetterPdf({
  required PdfIdentity patient,
  required String destination,
  required String reason,
  required String referringClinic,
  DateTime? date,
}) {
  final issued = date ?? DateTime.now();
  return ClinicPdf.build(
    title: 'Referral letter',
    subtitle: 'Issued ${_dayFmt.format(issued)}',
    patient: patient,
    body: [
      pdfSection(
        'Referral',
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'The above-named patient is referred to the service below for '
              'further assessment and management. Relevant history is held in '
              'the patient record and can be shared on request.',
              style: const pw.TextStyle(
                fontSize: 10,
                color: pdfInk,
                lineSpacing: 3,
              ),
            ),
            pw.SizedBox(height: 12),
            pdfKeyValue('Referred to', destination),
            pdfKeyValue('Reason for referral', reason),
            pdfKeyValue('Date', _dayFmt.format(issued)),
          ],
        ),
      ),
      pdfSection(
        'Referred by',
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pdfKeyValue('Referring clinic', referringClinic),
            pdfKeyValue('Date issued', _dayFmt.format(issued)),
            pw.SizedBox(height: 24),
            pw.Container(width: 200, height: 0.7, color: pdfHairline),
            pw.SizedBox(height: 3),
            pw.Text(
              'Signature / clinic stamp',
              style: const pw.TextStyle(fontSize: 8, color: pdfMuted),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Diagnostic imaging / radiology result.
Future<Uint8List> radiologyReportPdf({
  required PdfIdentity patient,
  required MedicalRecord record,
  String? reportingClinician,
}) {
  return ClinicPdf.build(
    title: 'Radiology report',
    subtitle: _dayFmt.format(record.occurredAt),
    patient: patient,
    body: [
      pdfSection(
        'Study',
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pdfKeyValue('Examination', record.title),
            pdfKeyValue('Date performed', _dayFmt.format(record.occurredAt)),
            if (record.sourceFacility != null)
              pdfKeyValue('Facility', record.sourceFacility!),
            if (reportingClinician != null)
              pdfKeyValue('Reporting clinician', reportingClinician),
          ],
        ),
      ),
      pdfSection(
        'Findings',
        pw.Text(
          (record.body ?? '').trim().isEmpty
              ? 'No findings were recorded with this study.'
              : record.body!.trim(),
          style: const pw.TextStyle(
            fontSize: 10,
            color: pdfInk,
            lineSpacing: 3,
          ),
        ),
      ),
    ],
  );
}
