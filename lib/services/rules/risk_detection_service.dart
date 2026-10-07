/// Deterministic clinical risk detection (P5-01, P5-02).
///
/// Rules first, AI second — this runs with no API key and no network, so the
/// staff dashboard is never empty. Each rule produces a [RiskFlag] with a
/// stable [RiskFlag.dedupeKey] so the same finding isn't recorded twice, and a
/// severity (info / warning / urgent) per P5-02.
library;

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/risk_sources.dart';

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
    return !RiskSources.supportedCondition(condition) ||
        meds.any(
          (m) =>
              m.isCurrent && RiskSources.medicationMatches(condition, m.name),
        );
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
      String sourceId,
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
          dedupeKey: RiskSources.key('$pid:$dedupeSuffix', sourceId),
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
            v.id,
          );
        } else if (v.systolic! >= 140 || v.diastolic! >= 90) {
          add(
            RiskFlagKind.abnormalVitals,
            Severity.warning,
            'Blood pressure above target (${v.systolic}/${v.diastolic}).',
            'vitals:bp',
            v.id,
          );
        }
      }
      if (v.spo2 != null && v.spo2! < 92) {
        add(
          RiskFlagKind.abnormalVitals,
          v.spo2! < 88 ? Severity.urgent : Severity.warning,
          'Low oxygen saturation (${v.spo2}%).',
          'vitals:spo2',
          v.id,
        );
      }
      if (v.glucose != null && v.glucose! >= 11) {
        add(
          RiskFlagKind.abnormalVitals,
          v.glucose! >= 15 ? Severity.urgent : Severity.warning,
          'Elevated glucose (${v.glucose} mmol/L).',
          'vitals:glucose',
          v.id,
        );
      }
    }

    // --- labs ---------------------------------------------------------
    final recs = await _unwrapList(records.timeline(pid, limit: 40));
    for (final record in recs.where(
      (r) => r.occurredAt.isAfter(now.subtract(const Duration(days: 120))),
    )) {
      final recentCritical = record.labValues
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
          record.id,
        );
      }
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
          RiskSources.medicationCourse(c, meds),
        );
      }
    }

    // --- overdue follow-up ---------------------------------------------------
    if (patient.chronicConditions.isNotEmpty && recs.isNotEmpty) {
      final last = recs.reduce(
        (a, b) => a.occurredAt.isAfter(b.occurredAt) ? a : b,
      );
      final months = now.difference(last.occurredAt).inDays / 30;
      final upcoming = (await _unwrapList(
        appointments.forPatient(pid, upcomingOnly: true),
      )).isNotEmpty;
      if (months >= 8 && !upcoming) {
        add(
          RiskFlagKind.overdueFollowUp,
          months >= 12 ? Severity.warning : Severity.info,
          'No encounter in ${months.round()} months and nothing booked.',
          'followup:overdue',
          last.id,
        );
      }
    }

    return flags;
  }

  /// Runs [scan] and upserts each flag (dedupe-safe).
  Future<Result<int>> runAndPersist(Patient patient) {
    return Result.guardAsync(() async {
      final flags = await scan(patient);
      var written = 0;
      for (final f in flags) {
        final result = await risk.upsertByDedupeKey(f);
        if (result case Err(:final failure)) {
          if (written == 0) throw failure;
          throw PartialOperationFailure(
            completed: written,
            total: flags.length,
            failure: failure,
          );
        }
        written++;
      }
      return written;
    });
  }

  Future<List<T>> _unwrapList<T>(Future<Result<List<T>>> f) async {
    final r = await f;
    return switch (r) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}
