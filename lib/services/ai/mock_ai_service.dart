/// Deterministic offline [AiService] (P3-03) — built before the real one so no
/// screen is ever blocked on an API key.
///
/// It derives a plausible summary from the patient's *actual* data (conditions,
/// abnormal labs, medication timeline, vitals trends), so it looks real in a
/// demo and produces the same output every run.
library;

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import 'ai_models.dart';
import 'ai_service.dart';
import 'prompts/summarize_records.dart';

class MockAiService implements AiService {
  const MockAiService({
    required this.patient,
    required this.records,
    required this.vitals,
    required this.medications,
  });

  final Patient patient;
  final List<MedicalRecord> records;
  final List<Vitals> vitals;
  final List<Medication> medications;

  static const modelId = 'mock-ai';

  @override
  Future<Result<HealthSummary>> summarizeRecords(PatientContext context) async {
    // A tiny delay so callers exercise their loading states.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final conditions = patient.chronicConditions;
    final recent = [...records]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final activeMeds = medications.where((m) => m.isCurrent).toList();

    final summary = StringBuffer()
      ..write(
        conditions.isEmpty
            ? 'This record shows a patient with no chronic conditions on file. '
            : 'This patient is managed for ${_join(conditions)}. ',
      )
      ..write(
        activeMeds.isEmpty
            ? 'No active medications are recorded. '
            : '${activeMeds.length} active medication${activeMeds.length == 1 ? '' : 's'} '
                  'including ${activeMeds.first.name}. ',
      )
      ..write(
        recent.isEmpty
            ? 'There are no clinical encounters recorded.'
            : 'The most recent encounter was on '
                  '${_isoDate(recent.first.occurredAt)} (${recent.first.title}). '
                  '${records.length} records span the history.',
      );

    return Ok(
      HealthSummary(
        summaryMarkdown: summary.toString(),
        modelId: modelId,
        promptVersion: summarizePromptVersion,
        keyEvents: _keyEvents(recent),
        trends: _trends(),
        redFlags: _redFlags(),
      ),
    );
  }

  List<KeyEvent> _keyEvents(List<MedicalRecord> recent) {
    const wanted = {
      RecordType.discharge,
      RecordType.imaging,
      RecordType.prescription,
      RecordType.vaccination,
      RecordType.referral,
    };
    final events = recent
        .where((r) => wanted.contains(r.recordType) || r.hasAbnormalLabs)
        .take(8)
        .map(
          (r) => KeyEvent(
            date: r.occurredAt,
            title: r.title,
            description: r.hasAbnormalLabs
                ? 'Contains out-of-range results.'
                : null,
            category: r.recordType.name,
            recordId: r.id,
          ),
        )
        .toList();
    return events;
  }

  List<Trend> _trends() {
    final out = <Trend>[];
    final sorted = [...vitals]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    void addNumeric(String metric, List<num?> values) {
      final v = values.whereType<num>().toList();
      if (v.length < 2) return;
      final delta = v.last - v.first;
      final dir = delta.abs() < (v.first * 0.03)
          ? 'stable'
          : (delta > 0 ? 'up' : 'down');
      out.add(
        Trend(
          metric: metric,
          direction: dir,
          summary:
              '$metric went from ${_num(v.first)} to ${_num(v.last)} '
              'over ${sorted.length} readings.',
        ),
      );
    }

    addNumeric('Systolic BP', [for (final x in sorted) x.systolic]);
    addNumeric('Weight (kg)', [for (final x in sorted) x.weightKg]);
    addNumeric('Glucose', [for (final x in sorted) x.glucose]);
    return out;
  }

  List<RedFlag> _redFlags() {
    final out = <RedFlag>[];

    final abnormal = records
        .expand((r) => r.labValues)
        .where((l) => l.abnormalFlag != AbnormalFlag.normal)
        .toList();
    final critical = abnormal
        .where((l) => l.abnormalFlag == AbnormalFlag.critical)
        .toList();
    if (critical.isNotEmpty) {
      out.add(
        RedFlag(
          severity: Severity.urgent,
          description:
              'Critical lab value(s) on record: ${_join(critical.map((l) => l.analyte).toSet().toList())}. '
              'Confirm these were actioned.',
        ),
      );
    } else if (abnormal.isNotEmpty) {
      out.add(
        RedFlag(
          severity: Severity.warning,
          description:
              '${abnormal.length} out-of-range lab result(s) across the record.',
        ),
      );
    }

    // Chronic condition with no active medication.
    for (final c in patient.chronicConditions) {
      final treated = medications.any(
        (m) => m.isCurrent && _looksRelated(m.name, c),
      );
      if (!treated) {
        out.add(
          RedFlag(
            severity: Severity.warning,
            description: 'No active medication recorded for $c.',
          ),
        );
      }
    }

    // Overdue follow-up: last visit > 8 months ago for a chronic patient.
    if (patient.chronicConditions.isNotEmpty && records.isNotEmpty) {
      final last = records
          .map((r) => r.occurredAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (DateTime.now().difference(last).inDays > 240) {
        out.add(
          const RedFlag(
            severity: Severity.info,
            description: 'No encounter in over 8 months — a review may be due.',
          ),
        );
      }
    }
    return out;
  }

  static bool _looksRelated(String med, String condition) {
    final m = med.toLowerCase();
    return switch (condition) {
      'Type 2 Diabetes' =>
        m.contains('metformin') ||
            m.contains('gliclazide') ||
            m.contains('empagliflozin'),
      'Hypertension' =>
        m.contains('amlodipine') ||
            m.contains('lisinopril') ||
            m.contains('losartan') ||
            m.contains('bisoprolol'),
      'Hyperlipidaemia' => m.contains('statin'),
      'Hypothyroidism' => m.contains('levothyroxine'),
      _ => true, // don't false-flag conditions we don't model
    };
  }

  static String _join(List<String> xs) => switch (xs.length) {
    0 => '',
    1 => xs.first,
    2 => '${xs[0]} and ${xs[1]}',
    _ => '${xs.take(xs.length - 1).join(', ')}, and ${xs.last}',
  };

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _num(num n) => n is int ? '$n' : n.toStringAsFixed(1);
}
