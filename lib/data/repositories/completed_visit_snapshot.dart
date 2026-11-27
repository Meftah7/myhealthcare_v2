import 'package:drift/drift.dart';

import '../../domain/documents/document_rules.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/export_repository.dart';
import '../db/app_database.dart';
import 'document_sources.dart';

/// Called inside the completion transaction, so subsequent edits and
/// releases cannot change the issued report.
Future<Map<String, Object?>> completedVisitSnapshot(
  AppDatabase db,
  AppointmentRow visit, {
  required bool arabic,
}) async {
  String label(String en, String ar) => arabic ? ar : en;
  final department = await (db.select(
    db.departments,
  )..where((d) => d.id.equals(visit.departmentId ?? ''))).getSingleOrNull();
  final records =
      await (db.select(db.medicalRecords)
            ..where(
              (r) =>
                  r.patientId.equals(visit.patientId) &
                  r.appointmentId.equals(visit.id) &
                  r.uploadedByPatient.equals(false),
            )
            ..orderBy([
              (r) => OrderingTerm.asc(r.occurredAt),
              (r) => OrderingTerm.asc(r.id),
            ]))
          .get();
  final vitals =
      await (db.select(db.vitals)
            ..where(
              (v) =>
                  v.patientId.equals(visit.patientId) &
                  v.appointmentId.equals(visit.id),
            )
            ..orderBy([
              (v) => OrderingTerm.asc(v.recordedAt),
              (v) => OrderingTerm.asc(v.id),
            ]))
          .get();
  final medications =
      await (db.select(db.medications)
            ..where(
              (m) =>
                  m.patientId.equals(visit.patientId) &
                  m.appointmentId.equals(visit.id),
            )
            ..orderBy([
              (m) => OrderingTerm.asc(m.startDate),
              (m) => OrderingTerm.asc(m.id),
            ]))
          .get();
  final linkedDocuments = await db
      .customSelect(
        'SELECT v.document_type, v.issued_at FROM issued_document_versions v '
        'JOIN document_requests r ON r.id = v.request_id '
        'JOIN document_verifications d ON d.issued_version_id = v.id '
        "WHERE v.patient_id = ? AND r.patient_id = v.patient_id AND r.appointment_id = ? "
        "AND d.validity = 'valid' AND v.document_type != 'financeStatement' "
        'ORDER BY v.issued_at, v.id',
        variables: [
          Variable.withString(visit.patientId),
          Variable.withString(visit.id),
        ],
      )
      .get();

  final sections = <String>[
    '${label('Appointment', 'الموعد')}: ${visit.slotStart.toIso8601String()}',
    if (department != null)
      '${label('Department', 'القسم')}: ${department.name}',
    if (visit.reasonText case final reason? when reason.trim().isNotEmpty)
      '${label('Reason for visit', 'سبب الزيارة')}: $reason',
  ];
  final sources = DocumentSources(db);
  const resultTypes = {RecordType.labResult, RecordType.imaging};
  for (final r in records) {
    if (resultTypes.contains(r.recordType)) {
      final source = r.authorStaffId == null
          ? null
          : await sources.record(r.id);
      final values =
          (source?['values'] as List?)?.cast<Map<String, Object?>>() ?? [];
      if (source == null ||
          !await sources.released(source) ||
          (r.recordType == RecordType.labResult &&
              (values.isEmpty ||
                  values.any((v) => v['verified'] == 'unverified')))) {
        sections.add(
          label(
            'A linked result was unavailable or awaiting release at completion.',
            'كانت إحدى النتائج المرتبطة غير متاحة أو بانتظار إتاحتها عند إكمال الزيارة.',
          ),
        );
        continue;
      }
      sections.add(
        [
          r.title,
          if (r.body case final body? when body.trim().isNotEmpty) body,
          for (final v in values)
            '${v['analyte']}: ${v['value']} ${v['unit'] ?? ''}'.trim(),
        ].join('\n'),
      );
    } else {
      sections.add(
        [
          r.title,
          if (r.body case final body? when body.trim().isNotEmpty) body,
        ].join('\n'),
      );
    }
  }
  for (final v in vitals) {
    final measurements = [
      if (v.systolic != null)
        '${label('Systolic BP', 'الضغط الانقباضي')} ${v.systolic} mmHg',
      if (v.diastolic != null)
        '${label('Diastolic BP', 'الضغط الانبساطي')} ${v.diastolic} mmHg',
      if (v.heartRate != null)
        '${label('Heart rate', 'معدل النبض')} ${v.heartRate} bpm',
      if (v.tempC != null) '${label('Temperature', 'الحرارة')} ${v.tempC} °C',
      if (v.weightKg != null) '${label('Weight', 'الوزن')} ${v.weightKg} kg',
      if (v.heightCm != null) '${label('Height', 'الطول')} ${v.heightCm} cm',
      if (v.spo2 != null) 'SpO2 ${v.spo2}%',
      if (v.glucose != null) '${label('Glucose', 'سكر الدم')} ${v.glucose}',
    ];
    if (measurements.isNotEmpty) {
      sections.add(
        '${label('Vitals', 'العلامات الحيوية')} (${v.recordedAt.toIso8601String()}): '
        '${measurements.join(', ')}',
      );
    }
  }
  for (final m in medications) {
    sections.add(
      '${label('Prescription', 'الوصفة الطبية')}: ' +
          [
            m.name,
            ?m.dose,
            ?m.frequency,
            if (m.orderedUnits != null)
              '${label('Quantity', 'الكمية')}: ${m.orderedUnits}',
          ].join(' · '),
    );
  }
  if (visit.outcomeNote case final outcome? when outcome.trim().isNotEmpty) {
    sections.add('${label('Clinician outcome', 'خلاصة الطبيب')}\n$outcome');
  }
  for (final document in linkedDocuments) {
    final type = ExportDocument.values.byName(
      document.read<String>('document_type'),
    );
    final date = document
        .read<DateTime>('issued_at')
        .toIso8601String()
        .split('T')
        .first;
    sections.add(
      '${label('Issued document', 'مستند صادر')}: '
      '${DocumentRules.title(type, arabic: arabic)} ($date)',
    );
  }
  return {'sourceText': sections.join('\n\n')};
}
