/// Builds the compact, token-budgeted [PatientContext] handed to the model
/// (P3-02).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/utils/format.dart';
import '../../domain/entities/entities.dart';
import 'ai_models.dart';

class PatientContextBuilder {
  const PatientContextBuilder({this.tokenBudget = 6000});

  /// Rough character budget = tokenBudget * 4.
  final int tokenBudget;

  PatientContext build({
    required Patient patient,
    required List<MedicalRecord> records,
    required List<Vitals> vitals,
    required List<Medication> medications,
  }) {
    final b = StringBuffer();
    final u = patient.user;

    b.writeln('# Patient');
    b.writeln('- Age: ${u.ageYears ?? 'unknown'}, ${u.gender?.name ?? 'n/a'}');
    b.writeln('- Blood type: ${patient.bloodType ?? 'unknown'}');
    b.writeln(
      '- Chronic conditions: '
      '${patient.chronicConditions.isEmpty ? 'none recorded' : patient.chronicConditions.join(', ')}',
    );
    b.writeln(
      '- Allergies: '
      '${patient.allergies.isEmpty ? 'none recorded' : patient.allergies.join(', ')}',
    );

    b.writeln('\n# Current medications');
    final active = medications.where((m) => m.isCurrent).toList();
    if (active.isEmpty) {
      b.writeln('- none');
    } else {
      for (final m in active) {
        b.writeln(
          '- ${m.name}${m.frequency == null ? '' : ' (${m.frequency})'}',
        );
      }
    }

    b.writeln('\n# Recent vitals (newest first)');
    final vs = [...vitals]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    for (final v in vs.take(8)) {
      final parts = <String>[
        if (v.hasBloodPressure) 'BP ${v.systolic}/${v.diastolic}',
        if (v.heartRate != null) 'HR ${v.heartRate}',
        if (v.weightKg != null) 'wt ${v.weightKg}kg',
        if (v.glucose != null) 'glucose ${v.glucose}',
        if (v.spo2 != null) 'SpO2 ${v.spo2}%',
      ];
      b.writeln('- ${fmtDate(v.recordedAt)}: ${parts.join(', ')}');
    }

    b.writeln('\n# Record history (newest first, oldest truncated to budget)');
    final rs = [...records]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final charBudget = tokenBudget * 4;
    for (final r in rs) {
      if (b.length > charBudget) {
        b.writeln('- … older records omitted to fit the context budget …');
        break;
      }
      b.writeln(
        '\n## ${fmtDate(r.occurredAt)} — ${r.recordType.name}: ${r.title}',
      );
      if (r.sourceFacility != null) b.writeln('Facility: ${r.sourceFacility}');
      if (r.body != null) b.writeln(r.body);
      for (final lab in r.labValues) {
        final flag = lab.abnormalFlag.name;
        b.writeln(
          '- ${lab.analyte}: ${lab.value}${lab.unit == null ? '' : ' ${lab.unit}'}'
          ' [$flag${lab.refLow != null ? ', ref ${lab.refLow}-${lab.refHigh}' : ''}]',
        );
      }
    }

    final text = b.toString();
    final hash = sha256.convert(utf8.encode(text)).toString();
    return PatientContext(
      patientId: patient.id,
      contextText: text,
      hash: hash,
      approxTokens: (text.length / 4).ceil(),
    );
  }
}
