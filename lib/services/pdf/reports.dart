/// Patient document builders (P10-02, P10-03, Phase 5). Each returns finished
/// PDF bytes through [ClinicPdf], so callers only deal with `Uint8List` +
/// `present`.
///
/// Every document carries its provenance (issuer, source, date, status,
/// reference). Trend data is exported as a source table *and* a plain-text
/// summary, so nothing depends on reading a chart. Pass `arabic: true` for an
/// Arabic, right-to-left document.
library;

import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import 'clinic_pdf.dart';
import 'pdf_strings.dart';

const _bodyStyle = pw.TextStyle(fontSize: 10, color: pdfInk, lineSpacing: 3);

/// Vital signs report — a text summary per measurement, the latest snapshot,
/// and the full reading history as a table.
Future<Uint8List> vitalsReportPdf({
  required PdfIdentity patient,
  required List<Vitals> readings,
  bool arabic = false,
  String issuer = ClinicPdf.clinicName,
}) {
  final s = PdfStrings.of(arabic: arabic);
  String day(DateTime d) => pdfShortDate(d, arabic: arabic);
  final sorted = [...readings]
    ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  final latest = sorted.firstOrNull;
  final oldest = sorted.lastOrNull;
  final now = DateTime.now();

  final subtitle = sorted.isEmpty
      ? null
      : sorted.length == 1
      ? day(sorted.first.recordedAt)
      : '${day(oldest!.recordedAt)} – ${day(latest!.recordedAt)}  ·  '
            '${s.readingsCount(sorted.length)}';

  return ClinicPdf.build(
    title: s.vitalsTitle,
    subtitle: subtitle,
    patient: patient,
    arabic: arabic,
    provenance: DocumentProvenance(
      issuer: issuer,
      source: s.sourceVitals,
      documentDate: latest?.recordedAt ?? now,
      status: s.statusRecordExtract,
      reference:
          'VIT-${patient.patientId}-${(latest?.recordedAt ?? now).millisecondsSinceEpoch ~/ 1000}',
    ),
    body: [
      if (sorted.isNotEmpty)
        pdfSection(
          s.summary,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                s.summaryNote,
                style: const pw.TextStyle(fontSize: 8, color: pdfMuted),
              ),
              pw.SizedBox(height: 6),
              for (final line in _vitalsSummary(sorted, s)) line,
            ],
          ),
        ),
      if (latest != null)
        pdfSection(
          s.mostRecent(pdfStamp(latest.recordedAt, arabic: arabic)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (latest.hasBloodPressure)
                pdfKeyValue(
                  s.bloodPressure,
                  '${latest.systolic}/${latest.diastolic} mmHg',
                ),
              if (latest.heartRate != null)
                pdfKeyValue(s.heartRate, '${latest.heartRate} bpm'),
              if (latest.spo2 != null) pdfKeyValue(s.oxygen, '${latest.spo2}%'),
              if (latest.tempC != null)
                pdfKeyValue(s.temperature, '${latest.tempC} °C'),
              if (latest.weightKg != null)
                pdfKeyValue(s.weight, '${latest.weightKg} kg'),
              if (latest.heightCm != null)
                pdfKeyValue(s.height, '${latest.heightCm} cm'),
              if (latest.bmi != null)
                pdfKeyValue(s.bmi, latest.bmi!.toStringAsFixed(1)),
              if (latest.glucose != null)
                pdfKeyValue(s.glucose, '${latest.glucose} mmol/L'),
            ],
          ),
        ),
      pdfSection(
        s.readingHistory,
        sorted.isEmpty
            ? pw.Text(
                s.noVitals,
                style: const pw.TextStyle(fontSize: 9, color: pdfMuted),
              )
            : _vitalsTable(sorted, s),
      ),
    ],
  );
}

/// One sentence per measurement: how many readings, the range, the latest.
List<pw.Widget> _vitalsSummary(List<Vitals> newestFirst, PdfStrings s) {
  pw.Widget? line<T extends num>(
    String label,
    T? Function(Vitals) pick,
    String unit,
  ) {
    final values = [
      for (final v in newestFirst)
        if (pick(v) != null) pick(v)!,
    ];
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    String f(num n) => '$n$unit';
    return pdfKeyValue(
      label,
      s.metricSummary(
        values.length,
        f(sorted.first),
        f(sorted.last),
        f(values.first),
      ),
    );
  }

  final bp = [
    for (final v in newestFirst)
      if (v.hasBloodPressure) v,
  ];
  return [
    if (bp.isNotEmpty)
      pdfKeyValue(
        s.bloodPressure,
        s.metricSummary(
          bp.length,
          '${bp.map((v) => v.systolic!).reduce((a, b) => a < b ? a : b)}/'
              '${bp.map((v) => v.diastolic!).reduce((a, b) => a < b ? a : b)}',
          '${bp.map((v) => v.systolic!).reduce((a, b) => a > b ? a : b)}/'
              '${bp.map((v) => v.diastolic!).reduce((a, b) => a > b ? a : b)} mmHg',
          '${bp.first.systolic}/${bp.first.diastolic} mmHg',
        ),
      ),
    ?line(s.heartRate, (v) => v.heartRate, ' bpm'),
    ?line(s.oxygen, (v) => v.spo2, '%'),
    ?line(s.temperature, (v) => v.tempC, ' °C'),
    ?line(s.weight, (v) => v.weightKg, ' kg'),
    ?line(s.glucose, (v) => v.glucose, ' mmol/L'),
  ];
}

pw.Widget _vitalsTable(List<Vitals> rows, PdfStrings s) {
  String cell(Object? v) => v == null ? '—' : '$v';
  return pw.TableHelper.fromTextArray(
    headers: s.vitalsHeaders,
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
          // * marks a reading the patient entered themselves.
          pdfShortDate(v.recordedAt, arabic: s.isArabic) +
              (v.recordedByStaffId == null ? ' *' : ''),
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
  bool arabic = false,
}) {
  final s = PdfStrings.of(arabic: arabic);
  final c = certificate;
  String day(DateTime d) => pdfShortDate(d, arabic: arabic);
  return ClinicPdf.build(
    title: s.certificateTitle,
    subtitle: s.issuedOn(day(c.issuedAt)),
    patient: patient,
    arabic: arabic,
    provenance: DocumentProvenance(
      issuer: '$issuingClinician · ${ClinicPdf.clinicName}',
      source: s.sourceClinicRecord,
      documentDate: c.issuedAt,
      status: s.statusIssued,
      reference: c.id,
    ),
    body: [
      pdfSection(
        s.certificate,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(s.certificateBody, style: _bodyStyle),
            pw.SizedBox(height: 12),
            pdfKeyValue(s.reason, c.diagnosis),
            pdfKeyValue(s.from, day(c.fromDate)),
            pdfKeyValue(s.toInclusive, day(c.toDate)),
            pdfKeyValue(s.total, s.days(c.days)),
            if (c.notes != null && c.notes!.isNotEmpty)
              pdfKeyValue(s.notes, c.notes!),
          ],
        ),
      ),
      _signatureBlock(s, s.clinician, issuingClinician, day(c.issuedAt)),
    ],
  );
}

/// Clinic-issued referral letter — a patient carries this to the receiving
/// hospital.
Future<Uint8List> referralLetterPdf({
  required PdfIdentity patient,
  required String destination,
  required String reason,
  required String referringClinic,
  DateTime? date,
  String? reference,
  bool arabic = false,
}) {
  final s = PdfStrings.of(arabic: arabic);
  final issued = date ?? DateTime.now();
  String day(DateTime d) => pdfShortDate(d, arabic: arabic);
  return ClinicPdf.build(
    title: s.referralTitle,
    subtitle: s.issuedOn(day(issued)),
    patient: patient,
    arabic: arabic,
    provenance: DocumentProvenance(
      issuer: referringClinic,
      source: s.sourceClinicRecord,
      documentDate: issued,
      status: s.statusIssued,
      reference: reference ?? 'REF-${patient.patientId}',
    ),
    body: [
      pdfSection(
        s.referral,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(s.referralBody, style: _bodyStyle),
            pw.SizedBox(height: 12),
            pdfKeyValue(s.referredTo, destination),
            pdfKeyValue(s.referralReason, reason),
            pdfKeyValue(s.date, day(issued)),
          ],
        ),
      ),
      _signatureBlock(s, s.referringClinic, referringClinic, day(issued)),
    ],
  );
}

pw.Widget _signatureBlock(
  PdfStrings s,
  String roleLabel,
  String name,
  String date,
) {
  return pdfSection(
    s.issuedByHeading,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pdfKeyValue(roleLabel, name),
        pdfKeyValue(s.dateIssued, date),
        pw.SizedBox(height: 24),
        pw.Container(width: 200, height: 0.7, color: pdfHairline),
        pw.SizedBox(height: 3),
        pw.Text(
          s.signature,
          style: const pw.TextStyle(fontSize: 8, color: pdfMuted),
        ),
      ],
    ),
  );
}

/// The provenance of a stored record: clinic-authored, or a patient import
/// with its review state and original file.
DocumentProvenance recordProvenance(
  MedicalRecord record,
  PdfStrings s, {
  String? authorName,
  String? reviewerName,
}) {
  final doc = record.sourceDocument;
  final status = switch (record.reviewStatus) {
    ImportReviewStatus.notRequired => s.statusFinal,
    ImportReviewStatus.pendingReview => s.statusNotReviewed,
    ImportReviewStatus.reviewed => s.statusReviewed(
      reviewerName ?? record.reviewedByStaffId ?? '—',
    ),
    ImportReviewStatus.rejected => s.statusRejected,
  };
  return DocumentProvenance(
    issuer:
        record.sourceFacility ??
        (record.uploadedByPatient
            ? s.sourcePatientImport
            : (authorName ?? ClinicPdf.clinicName)),
    source: record.uploadedByPatient
        ? s.sourcePatientImport
        : s.sourceClinicRecord,
    documentDate: record.occurredAt,
    status: status,
    reference: record.id,
    originalFile: doc == null
        ? null
        : '${doc.fileName} (${(doc.sizeBytes / 1024).toStringAsFixed(0)} KB)',
    sha256: doc?.sha256,
  );
}

/// Diagnostic imaging / radiology result.
Future<Uint8List> radiologyReportPdf({
  required PdfIdentity patient,
  required MedicalRecord record,
  String? reportingClinician,
  bool arabic = false,
}) {
  final s = PdfStrings.of(arabic: arabic);
  return ClinicPdf.build(
    title: s.radiologyTitle,
    subtitle: pdfShortDate(record.occurredAt, arabic: arabic),
    patient: patient,
    arabic: arabic,
    provenance: recordProvenance(record, s, authorName: reportingClinician),
    body: [
      pdfSection(
        s.study,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pdfKeyValue(s.examination, record.title),
            pdfKeyValue(
              s.datePerformed,
              pdfShortDate(record.occurredAt, arabic: arabic),
            ),
            if (record.sourceFacility != null)
              pdfKeyValue(s.facility, record.sourceFacility!),
            if (reportingClinician != null)
              pdfKeyValue(s.reportingClinician, reportingClinician),
          ],
        ),
      ),
      pdfSection(
        s.findings,
        pw.Text(
          (record.body ?? '').trim().isEmpty
              ? s.noFindings
              : record.body!.trim(),
          style: _bodyStyle,
        ),
      ),
    ],
  );
}

/// Any stored record — clinic note, lab result or a patient import — with
/// its provenance, values and (for an import) the text read from the
/// original file.
Future<Uint8List> recordSummaryPdf({
  required PdfIdentity patient,
  required MedicalRecord record,
  required String recordTypeLabel,
  String? authorName,
  String? reviewerName,
  bool arabic = false,
}) {
  final s = PdfStrings.of(arabic: arabic);
  final extracted = (record.extractedText ?? '').trim();
  return ClinicPdf.build(
    title: s.recordTitle,
    subtitle: record.title,
    patient: patient,
    arabic: arabic,
    provenance: recordProvenance(
      record,
      s,
      authorName: authorName,
      reviewerName: reviewerName,
    ),
    body: [
      pdfSection(
        s.details,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pdfKeyValue(s.recordType, recordTypeLabel),
            pdfKeyValue(
              s.date,
              pdfShortDate(record.occurredAt, arabic: arabic),
            ),
            if (authorName != null) pdfKeyValue(s.clinician, authorName),
          ],
        ),
      ),
      if ((record.body ?? '').trim().isNotEmpty)
        pdfSection(s.content, pw.Text(record.body!.trim(), style: _bodyStyle)),
      if (record.labValues.isNotEmpty)
        pdfSection(
          s.results,
          pw.TableHelper.fromTextArray(
            headers: s.labHeaders,
            headerStyle: const pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: pdfInk,
            ),
            headerDecoration: const pw.BoxDecoration(color: pdfHeaderFill),
            cellStyle: const pw.TextStyle(fontSize: 8, color: pdfInk),
            border: pw.TableBorder.symmetric(
              inside: const pw.BorderSide(color: pdfHairline, width: 0.5),
            ),
            data: [
              for (final v in record.labValues)
                [
                  v.analyte,
                  '${v.value}${v.unit == null ? '' : ' ${v.unit}'}',
                  switch ((v.refLow, v.refHigh)) {
                    (final l?, final h?) => '$l–$h',
                    (null, final h?) => '< $h',
                    (final l?, null) => '> $l',
                    _ => s.noRange,
                  },
                  v.abnormalFlag == AbnormalFlag.unknown
                      ? s.noRange
                      : v.abnormalFlag.name,
                ],
            ],
          ),
        ),
      if (extracted.isNotEmpty)
        pdfSection(
          s.extractedText,
          pw.Text(
            extracted.length > 6000
                ? '${extracted.substring(0, 6000)}…'
                : extracted,
            style: const pw.TextStyle(fontSize: 8, color: pdfInk),
          ),
        ),
    ],
  );
}
