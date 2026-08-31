/// Deterministic clinical risk detection (P5-01, P5-02).
///
/// Rules first, AI second — this runs with no API key and no network, so the
/// staff dashboard is never empty. Each rule produces a [RiskFlag] with a
/// stable [RiskFlag.dedupeKey] so the same finding isn't recorded twice, and a
/// severity (info / warning / urgent) per P5-02.
library;

import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/repositories.dart';

class RiskDetectionService {
  RiskDetectionService({
    required this.records,
    required this.vitals,
    required this.medications,
    required this.appointments,
    required this.risk,
  });

  final RecordRepository records;
  final VitalsRepository vitals;
  final MedicationRepository medications;
  final AppointmentRepository appointments;
  final RiskRepository risk;

  /// Chronic conditions whose analytes we know how to treat — reused from the
  /// mock AI's medication-gap check.
  static bool _hasMedFor(String condition, List<Medication> meds) {
    bool has(Iterable<String> needles) => meds.any(
      (m) =>
          m.isCurrent && needles.any((n) => m.name.toLowerCase().contains(n)),
    );
    return switch (condition) {
      'Type 2 Diabetes' => has(['metformin', 'gliclazide', 'empagliflozin']),
      'Hypertension' => has([
        'amlodipine',
        'lisinopril',
        'losartan',
        'bisoprolol',
      ]),
      'Hyperlipidaemia' => has(['statin']),
      'Hypothyroidism' => has(['levothyroxine']),
      'Anaemia' => has(['ferrous', 'folic']),
      'Asthma' => has(['salbutamol', 'budesonide']),
      _ => true,
    };
  }

  /// Computes (but does not persist) the current risk flags for [patient].
  Future<List<RiskFlag>> scan(Patient patient) async {
    final now = DateTime.now();
    final pid = patient.id;
    final flags = <RiskFlag>[];

    void add(
      RiskFlagKind kind,
      Severity severity,
      String rationale,
      String dedupeSuffix,
    ) {
      flags.add(
        RiskFlag(
          id: newId('flag'),
          patientId: pid,
          kind: kind,
          severity: severity,
          rationale: rationale,
          detectedAt: now,
          source: FlagSource.rule,
          dedupeKey: '$pid:$dedupeSuffix',
        ),
      );
    }

    // --- vitals ---------------------------------------------------------
    final vs = (await _unwrapList(vitals.forPatient(pid))).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    if (vs.isNotEmpty) {
      final v = vs.first;
      if (v.systolic != null && v.diastolic != null) {
        if (v.systolic! >= 180 || v.diastolic! >= 110) {
          add(
            RiskFlagKind.abnormalVitals,
            Severity.urgent,
            'Severe hypertension on the last reading '
                '(${v.systolic}/${v.diastolic}).',
            'vitals:bp',
          );
        } else if (v.systolic! >= 140 || v.diastolic! >= 90) {
          add(
            RiskFlagKind.abnormalVitals,
            Severity.warning,
            'Blood pressure above target (${v.systolic}/${v.diastolic}).',
            'vitals:bp',
          );
        }
      }
      if (v.spo2 != null && v.spo2! < 92) {
        add(
          RiskFlagKind.abnormalVitals,
          v.spo2! < 88 ? Severity.urgent : Severity.warning,
          'Low oxygen saturation (${v.spo2}%).',
          'vitals:spo2',
        );
      }
      if (v.glucose != null && v.glucose! >= 11) {
        add(
          RiskFlagKind.abnormalVitals,
          v.glucose! >= 15 ? Severity.urgent : Severity.warning,
          'Elevated glucose (${v.glucose} mmol/L).',
          'vitals:glucose',
        );
      }
    }

    // --- labs ---------------------------------------------------------
    final recs = await _unwrapList(records.timeline(pid, limit: 40));
    final recentCritical = recs
        .where(
          (r) => r.occurredAt.isAfter(now.subtract(const Duration(days: 120))),
        )
        .expand((r) => r.labValues)
        .where((l) => l.abnormalFlag == AbnormalFlag.critical)
        .map((l) => l.analyte)
        .toSet();
    if (recentCritical.isNotEmpty) {
      add(
        RiskFlagKind.abnormalLab,
        Severity.urgent,
        'Critical lab value(s) in the last 4 months: '
            '${recentCritical.join(', ')}.',
        'lab:critical',
      );
    }

    // --- medication gaps ---------------------------------------------------
    final meds = await _unwrapList(medications.forPatient(pid));
    for (final c in patient.chronicConditions) {
      if (!_hasMedFor(c, meds)) {
        add(
          RiskFlagKind.medicationGap,
          Severity.warning,
          'No active medication recorded for $c.',
          'medgap:$c',
        );
      }
    }

    // --- overdue follow-up ---------------------------------------------------
    if (patient.chronicConditions.isNotEmpty && recs.isNotEmpty) {
      final last = recs
          .map((r) => r.occurredAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final months = now.difference(last).inDays / 30;
      final upcoming = (await _unwrapList(
        appointments.forPatient(pid, upcomingOnly: true),
      )).isNotEmpty;
      if (months >= 8 && !upcoming) {
        add(
          RiskFlagKind.overdueFollowUp,
          months >= 12 ? Severity.warning : Severity.info,
          'No encounter in ${months.round()} months and nothing booked.',
          'followup:overdue',
        );
      }
    }

    return flags;
  }

  /// Runs [scan] and upserts each flag (dedupe-safe).
  Future<Result<int>> runAndPersist(Patient patient) {
    return Result.guardAsync(() async {
      final flags = await scan(patient);
      for (final f in flags) {
        await risk.upsertByDedupeKey(f);
      }
      return flags.length;
    });
  }

  Future<List<T>> _unwrapList<T>(Future<Result<List<T>>> f) async {
    final r = await f;
    return switch (r) {
      Ok(:final value) => value,
      Err() => const [],
    };
  }
}
