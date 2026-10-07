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

import '../../domain/clinical/lab_history.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import 'clinic_pdf.dart';
import 'pdf_strings.dart';

const _bodyStyle = pw.TextStyle(fontSize: 11, color: pdfInk, lineSpacing: 3);
const _tableHeader = pw.TextStyle(
  fontSize: 9,
  fontWeight: pw.FontWeight.bold,
  color: pdfInk,
);
const _tableCell = pw.TextStyle(fontSize: 9, color: pdfInk);
const _tableCellAlert = pw.TextStyle(
  fontSize: 9,
  color: pdfAlertInk,
  fontWeight: pw.FontWeight.bold,
);
const _extractLimit = 6000;

/// Typical resting adult ranges — a guide for the reader, not a diagnosis.
typedef _Range = ({double low, double high});
const _sysRange = (low: 90.0, high: 129.0);
const _diaRange = (low: 60.0, high: 84.0);
const _hrRange = (low: 60.0, high: 100.0);
const _spo2Range = (low: 95.0, high: 100.0);
const _tempRange = (low: 36.1, high: 37.5);
const _glucoseRange = (low: 3.9, high: 7.8);

bool _out(num? v, _Range r) => v != null && (v < r.low || v > r.high);

String _fmt(double d) =>
    d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString();
String _rangeText(_Range r) => '${_fmt(r.low)}–${_fmt(r.high)}';

bool _bpOut(Vitals v) =>
    v.hasBloodPressure &&
    (_out(v.systolic, _sysRange) || _out(v.diastolic, _diaRange));

/// A latest-reading row: value, its flag and the typical range; highlighted
/// when outside it.
pw.Widget _vitalRow(
  PdfStrings s,
  String label,
  String value, {
  required bool out,
  required bool low,
  required String range,
}) {
  final flag = out ? (low ? s.flagLow : s.flagHigh) : s.flagNormal;
  return pdfKeyValue(
    label,
    '$value  ·  $flag  ·  ${s.typicalRange}: $range',
    valueStyle: out ? pdfOutOfRange : null,
  );
}

/// The latest value of an analyte from an earlier record, for comparison.
typedef PreviousLab = ({double value, String? unit, DateTime at});

String _labFlag(AbnormalFlag f, PdfStrings s) => switch (f) {
  AbnormalFlag.normal => s.flagNormal,
  AbnormalFlag.low => s.flagLow,
  AbnormalFlag.high => s.flagHigh,
  AbnormalFlag.critical => s.flagCritical,
  AbnormalFlag.unknown => s.noRange,
};

bool _labAbnormal(AbnormalFlag f) =>
    f == AbnormalFlag.low ||
    f == AbnormalFlag.high ||
    f == AbnormalFlag.critical;

/// Lab values as a table — out-of-range rows highlighted, flags in the
/// document's language, an optional "previous" column — followed by a plain
/// explanation of what the flags mean.
pw.Widget _labResults(
  List<LabValue> values,
  PdfStrings s, {
  Map<String, PreviousLab> previousLabs = const {},
}) {
  PreviousLab? previous(LabValue v) {
    final p =
        previousLabs[labHistoryKey(v)] ?? previousLabs[v.analyte.toLowerCase()];
    return (v.unit?.trim().isNotEmpty ?? false) &&
            p?.unit?.trim() == v.unit?.trim()
        ? p
        : null;
  }

  final showPrevious = values.any((v) => previous(v) != null);
  final abnormal = values.where((v) => _labAbnormal(v.abnormalFlag)).length;
  final critical = values.any((v) => v.abnormalFlag == AbnormalFlag.critical);
  final withRange = values.any((v) => v.abnormalFlag != AbnormalFlag.unknown);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.TableHelper.fromTextArray(
        headers: showPrevious ? s.labHeadersWithPrevious : s.labHeaders,
        headerStyle: _tableHeader,
        headerDecoration: const pw.BoxDecoration(color: pdfHeaderFill),
        cellStyle: _tableCell,
        textStyleBuilder: (_, _, rowNum) =>
            rowNum >= 1 && _labAbnormal(values[rowNum - 1].abnormalFlag)
            ? _tableCellAlert
            : null,
        border: pw.TableBorder.symmetric(
          inside: const pw.BorderSide(color: pdfHairline, width: 0.5),
        ),
        data: [
          for (final v in values)
            [
              v.analyte,
              '${v.value}${v.unit == null ? '' : ' ${v.unit}'}',
              switch ((v.refLow, v.refHigh)) {
                (final l?, final h?) => '$l–$h',
                (null, final h?) => '< $h',
                (final l?, null) => '> $l',
                _ => s.noRange,
              },
              _labFlag(v.abnormalFlag, s),
              if (showPrevious)
                switch (previous(v)) {
                  final p? =>
                    '${p.value}${p.unit == null ? '' : ' ${p.unit}'} '
                        '(${pdfShortDate(p.at, arabic: s.isArabic)})',
                  null => '—',
                },
            ],
        ],
      ),
      if (critical)
        pdfNote(s.criticalNote, alert: true)
      else if (abnormal > 0)
        pdfNote(s.abnormalNote(abnormal), alert: true)
      else if (withRange)
        pdfNote(s.allNormalNote),
    ],
  );
}

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
                _vitalRow(
                  s,
                  s.bloodPressure,
                  '${latest.systolic}/${latest.diastolic} mmHg',
                  out: _bpOut(latest),
                  low:
                      latest.systolic! < _sysRange.low ||
                      latest.diastolic! < _diaRange.low,
                  range: '${_rangeText(_sysRange)} / ${_rangeText(_diaRange)}',
                ),
              if (latest.heartRate case final hr?)
                _vitalRow(
                  s,
                  s.heartRate,
                  '$hr bpm',
                  out: _out(hr, _hrRange),
                  low: hr < _hrRange.low,
                  range: _rangeText(_hrRange),
                ),
              if (latest.spo2 case final o?)
                _vitalRow(
                  s,
                  s.oxygen,
                  '$o%',
                  out: _out(o, _spo2Range),
                  low: o < _spo2Range.low,
                  range: '${_rangeText(_spo2Range)}%',
                ),
              if (latest.tempC case final c?)
                _vitalRow(
                  s,
                  s.temperature,
                  '$c °C',
                  out: _out(c, _tempRange),
                  low: c < _tempRange.low,
                  range: _rangeText(_tempRange),
                ),
              if (latest.weightKg != null)
                pdfKeyValue(s.weight, '${latest.weightKg} kg'),
              if (latest.heightCm != null)
                pdfKeyValue(s.height, '${latest.heightCm} cm'),
              if (latest.bmi != null)
                pdfKeyValue(s.bmi, latest.bmi!.toStringAsFixed(1)),
              if (latest.glucose case final g?)
                _vitalRow(
                  s,
                  s.glucose,
                  '$g mmol/L',
                  out: _out(g, _glucoseRange),
                  low: g < _glucoseRange.low,
                  range: _rangeText(_glucoseRange),
                ),
              pdfNote(s.vitalsRangeNote),
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
  // Highlight a cell whose reading sits outside the typical range.
  pw.TextStyle? style(int col, dynamic _, int rowNum) {
    if (rowNum < 1) return null;
    final v = rows[rowNum - 1];
    final out = switch (col) {
      1 => _bpOut(v),
      2 => _out(v.heartRate, _hrRange),
      3 => _out(v.spo2, _spo2Range),
      4 => _out(v.tempC, _tempRange),
      6 => _out(v.glucose, _glucoseRange),
      _ => false,
    };
    return out ? _tableCellAlert : null;
  }

  return pw.TableHelper.fromTextArray(
    headers: s.vitalsHeaders,
    headerStyle: _tableHeader,
    headerDecoration: const pw.BoxDecoration(color: pdfHeaderFill),
    cellStyle: _tableCell,
    textStyleBuilder: style,
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
  String? clinicianLicence,
  String? verificationCode,
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
      _signatureBlock(
        s,
        s.clinician,
        issuingClinician,
        day(c.issuedAt),
        licenceNo: clinicianLicence,
      ),
      if (verificationCode != null) _verificationBlock(s, verificationCode),
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
  String? clinicianLicence,
  ReferralUrgency? urgency,
  String? verificationCode,
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
            if (urgency != null)
              pdfKeyValue(
                s.urgency,
                referralUrgencyLabel(urgency, s),
                valueStyle: urgency == ReferralUrgency.routine
                    ? null
                    : pdfOutOfRange,
              ),
            pdfKeyValue(s.referralReason, reason),
            pdfKeyValue(s.date, day(issued)),
          ],
        ),
      ),
      _signatureBlock(
        s,
        s.referringClinic,
        referringClinic,
        day(issued),
        licenceNo: clinicianLicence,
      ),
      if (verificationCode != null) _verificationBlock(s, verificationCode),
    ],
  );
}

String referralUrgencyLabel(ReferralUrgency u, PdfStrings s) => switch (u) {
  ReferralUrgency.routine => s.urgencyRoutine,
  ReferralUrgency.urgent => s.urgencyUrgent,
  ReferralUrgency.emergency => s.urgencyEmergency,
};

/// The document's verification code, as text and as a QR code.
pw.Widget _verificationBlock(PdfStrings s, String code) {
  return pdfSection(
    s.verificationHeading,
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: 'MHC-VERIFY:$code',
          width: 64,
          height: 64,
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pdfKeyValue(
                s.verificationCode,
                code,
                valueStyle: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: pdfInk,
                  letterSpacing: 1,
                ),
              ),
              pw.Text(
                s.verificationHelp,
                style: const pw.TextStyle(fontSize: 9, color: pdfMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _signatureBlock(
  PdfStrings s,
  String roleLabel,
  String name,
  String date, {
  String? licenceNo,
}) {
  return pdfSection(
    s.issuedByHeading,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pdfKeyValue(roleLabel, name),
        if (licenceNo != null && licenceNo.isNotEmpty)
          pdfKeyValue(s.licenceNo, licenceNo),
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
  String? clinicianLicence,
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
            if (clinicianLicence != null && clinicianLicence.isNotEmpty)
              pdfKeyValue(s.licenceNo, clinicianLicence),
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
  Map<String, PreviousLab> previousLabs = const {},
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
          _labResults(record.labValues, s, previousLabs: previousLabs),
        ),
      if (extracted.isNotEmpty)
        pdfSection(
          s.extractedText,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                extracted.length > _extractLimit
                    ? '${extracted.substring(0, _extractLimit)}…'
                    : extracted,
                style: const pw.TextStyle(fontSize: 9.5, color: pdfInk),
              ),
              if (extracted.length > _extractLimit)
                pdfNote(s.truncated(_extractLimit, extracted.length)),
            ],
          ),
        ),
    ],
  );
}

/// One visit on one page: who, when, the vitals taken, notes and results,
/// medications started, and what happens next.
Future<Uint8List> visitSummaryPdf({
  required PdfIdentity patient,
  required Appointment appointment,
  required List<MedicalRecord> records,
  required List<Vitals> vitals,
  required List<Medication> medications,
  String? clinicianName,
  String? clinicianLicence,
  String? departmentName,
  Appointment? nextAppointment,
  bool arabic = false,
}) {
  final s = PdfStrings.of(arabic: arabic);
  final when = pdfStamp(appointment.slotStart, arabic: arabic);
  final nothing = records.isEmpty && vitals.isEmpty && medications.isEmpty;
  return ClinicPdf.build(
    title: s.visitTitle,
    subtitle: when,
    patient: patient,
    arabic: arabic,
    provenance: DocumentProvenance(
      issuer: clinicianName == null
          ? ClinicPdf.clinicName
          : '$clinicianName · ${ClinicPdf.clinicName}',
      source: s.sourceClinicRecord,
      documentDate: appointment.slotStart,
      status: s.statusRecordExtract,
      reference: appointment.id,
    ),
    body: [
      pdfSection(
        s.visit,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pdfKeyValue(s.date, when),
            if (departmentName != null)
              pdfKeyValue(s.department, departmentName),
            if (clinicianName != null) pdfKeyValue(s.clinician, clinicianName),
            if (clinicianLicence != null && clinicianLicence.isNotEmpty)
              pdfKeyValue(s.licenceNo, clinicianLicence),
            if ((appointment.reasonText ?? '').trim().isNotEmpty)
              pdfKeyValue(s.reason, appointment.reasonText!.trim()),
          ],
        ),
      ),
      if (nothing) pw.Text(s.nothingRecorded, style: _bodyStyle),
      if (vitals.isNotEmpty)
        pdfSection(s.vitalsAtVisit, _vitalsTable(vitals, s)),
      for (final r in records)
        pdfSection(
          r.title,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if ((r.body ?? '').trim().isNotEmpty)
                pw.Text(r.body!.trim(), style: _bodyStyle),
              if (r.labValues.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _labResults(r.labValues, s),
              ],
            ],
          ),
        ),
      if (medications.isNotEmpty)
        pdfSection(
          s.visitMedications,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final m in medications)
                pdfKeyValue(m.name, [?m.dose, ?m.frequency].join('  ·  ')),
            ],
          ),
        ),
      pdfSection(
        s.followUp,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if ((appointment.outcomeNote ?? '').trim().isNotEmpty)
              pw.Text(appointment.outcomeNote!.trim(), style: _bodyStyle),
            if (nextAppointment != null)
              pdfKeyValue(
                s.nextAppointment,
                pdfStamp(nextAppointment.slotStart, arabic: arabic),
              )
            else
              pdfNote(s.noFollowUp),
          ],
        ),
      ),
    ],
  );
}
