import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/export_repository.dart';
import '../db/app_database.dart';

/// Source records are checked again at approval and issuance. A release is an
/// immutable audit decision bound to the exact record and analyte fingerprint.
class DocumentSources {
  DocumentSources(this.db);
  final AppDatabase db;
  Future<Map<String, Object?>> record(String id) async {
    final row = await (db.select(
      db.medicalRecords,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null || row.uploadedByPatient || row.authorStaffId == null) {
      throw const ValidationFailure(
        'Select a clinic-authored source record. Patient imports cannot be issued as clinic results.',
      );
    }
    final values =
        await (db.select(db.labValues)
              ..where((v) => v.recordId.equals(id))
              ..orderBy([(v) => OrderingTerm.asc(v.id)]))
            .get();
    return {
      'sourceId': row.id,
      'patientId': row.patientId,
      'appointmentId': row.appointmentId,
      'recordType': row.recordType.name,
      'title': row.title,
      'body': row.body ?? '',
      'occurredAt': row.occurredAt.toIso8601String(),
      'authorStaffId': row.authorStaffId,
      'values': [
        for (final v in values)
          {
            'id': v.id,
            'analyte': v.analyte,
            'value': v.value,
            'unit': v.unit,
            'low': v.refLow,
            'high': v.refHigh,
            'flag': v.abnormalFlag.name,
            'verified': v.verificationStatus.name,
            'verifiedAt': v.verifiedAt?.toIso8601String(),
          },
      ],
    };
  }

  static String fingerprint(Map<String, Object?> source) =>
      sha256.convert(utf8.encode(jsonEncode(source))).toString();

  Future<bool> released(Map<String, Object?> source) async {
    final rows = await db
        .customSelect(
          "SELECT action, detail FROM audit_log WHERE entity_type = 'document_source_release' AND entity_id = ? ORDER BY rowid DESC LIMIT 1",
          variables: [Variable.withString(source['sourceId']! as String)],
        )
        .get();
    if (rows.isEmpty ||
        rows.single.read<String>('action') != 'document.source.release') {
      return false;
    }
    final detail = jsonDecode(rows.single.read<String>('detail')) as Map;
    return detail['fingerprint'] == fingerprint(source);
  }

  Future<Map<String, Object?>> resolve(
    String patientId,
    String visitId,
    ExportDocument type,
    Map<String, Object?> input, {
    String language = 'en',
  }) async {
    final visit = await (db.select(
      db.appointments,
    )..where((v) => v.id.equals(visitId))).getSingle();
    if (visit.patientId != patientId) {
      throw const ValidationFailure('Source visit belongs to another patient.');
    }
    if (type == ExportDocument.sickLeaveCertificate ||
        type == ExportDocument.fitnessCertificate) {
      return {...input};
    }
    if (type == ExportDocument.attendanceCertificate ||
        type == ExportDocument.visitSummary) {
      if (!{
        AppointmentStatus.inProgress,
        AppointmentStatus.completed,
      }.contains(visit.status)) {
        throw const ValidationFailure(
          'Attendance requires a visit that has started or completed.',
        );
      }
      if (type == ExportDocument.visitSummary &&
          (visit.status != AppointmentStatus.completed ||
              (visit.outcomeNote ?? '').trim().isEmpty)) {
        throw const ValidationFailure(
          'A completed visit with a recorded clinician outcome is required.',
        );
      }
      return {
        if (type == ExportDocument.visitSummary)
          'sourceText': visit.outcomeNote!,
        'visitDate': visit.slotStart.toIso8601String(),
        'visitStatus': visit.status.name,
      };
    }
    final id = input['sourceId'] as String;
    if (type == ExportDocument.financeStatement) {
      final invoice = await (db.select(
        db.invoices,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (invoice == null ||
          invoice.patientId != patientId ||
          invoice.appointmentId != visitId) {
        throw const ValidationFailure(
          'Select an invoice belonging to this patient and visit.',
        );
      }
      return {
        'sourceId': id,
        'sourceVersion': invoice.version,
        'sourceText': language == 'ar'
            ? 'الفاتورة: $id\nالمجموع الفرعي: ${invoice.subtotal.toStringAsFixed(3)} BHD\nالضريبة: ${invoice.taxAmount.toStringAsFixed(3)} BHD\nالإجمالي: ${invoice.totalAmount.toStringAsFixed(3)} BHD\nالحالة: ${invoice.status.name}'
            : 'Invoice: $id\nSubtotal: ${invoice.subtotal.toStringAsFixed(3)} BHD\nTax: ${invoice.taxAmount.toStringAsFixed(3)} BHD\nTotal: ${invoice.totalAmount.toStringAsFixed(3)} BHD\nStatus: ${invoice.status.name}',
        'invoiceStatus': invoice.status.name,
      };
    }
    final source = await record(id);
    final expected = switch (type) {
      ExportDocument.referralLetter => RecordType.referral,
      ExportDocument.prescriptionCopy => RecordType.prescription,
      ExportDocument.releasedLabReport => RecordType.labResult,
      ExportDocument.releasedImagingReport => RecordType.imaging,
      _ => throw const ValidationFailure('Unsupported source document.'),
    };
    if (source['patientId'] != patientId ||
        source['appointmentId'] != visitId ||
        source['recordType'] != expected.name) {
      throw const ValidationFailure(
        'Source type, patient and visit must match the requested document.',
      );
    }
    final values = source['values']! as List;
    if (type == ExportDocument.releasedLabReport ||
        type == ExportDocument.releasedImagingReport) {
      if (!await released(source)) {
        throw const ValidationFailure(
          'A doctor must release this exact result for document issuance first.',
        );
      }
      if (type == ExportDocument.releasedLabReport &&
          (values.isEmpty ||
              values.any((v) => (v as Map)['verified'] == 'unverified'))) {
        throw const ValidationFailure(
          'Laboratory values must be verified before issuing a report.',
        );
      }
    }
    if ((source['body']! as String).trim().isEmpty && values.isEmpty) {
      throw const ValidationFailure('The source has no report content.');
    }
    return {
      'sourceId': id,
      'sourceFingerprint': fingerprint(source),
      'sourceText':
          '${source['title']}\n${source['body']}\n${values.map((v) {
            final m = v as Map;
            return '${m['analyte']}: ${m['value']} ${m['unit'] ?? ''} (reference ${m['low'] ?? '?'}–${m['high'] ?? '?'}, ${m['flag']})';
          }).join('\n')}',
    };
  }
}
