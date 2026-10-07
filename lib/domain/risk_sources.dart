/// Stable rule/source identities shared by detection and legacy migration.
library;

import 'entities/medication.dart';

abstract final class RiskSources {
  static String key(String ruleKey, String sourceId) =>
      '$ruleKey:source:${Uri.encodeComponent(sourceId)}';

  static bool medicationMatches(String condition, String name) {
    final needles = switch (condition) {
      'Type 2 Diabetes' => ['metformin', 'gliclazide', 'empagliflozin'],
      'Hypertension' => ['amlodipine', 'lisinopril', 'losartan', 'bisoprolol'],
      'Hyperlipidaemia' => ['statin'],
      'Hypothyroidism' => ['levothyroxine'],
      'Anaemia' => ['ferrous', 'folic'],
      'Asthma' => ['salbutamol', 'budesonide'],
      _ => <String>[],
    };
    return needles.any(name.toLowerCase().contains);
  }

  static bool supportedCondition(String condition) => const {
    'Type 2 Diabetes',
    'Hypertension',
    'Hyperlipidaemia',
    'Hypothyroidism',
    'Anaemia',
    'Asthma',
  }.contains(condition);

  /// Untreated disease is one episode until a relevant treatment course
  /// changes. Unrelated prescriptions never create a new medication-gap task.
  static String medicationCourse(String condition, Iterable<Medication> meds) {
    final relevant =
        meds.where((m) => medicationMatches(condition, m.name)).toList()
          ..sort((a, b) {
            final date = b.startDate.compareTo(a.startDate);
            return date != 0 ? date : a.id.compareTo(b.id);
          });
    if (relevant.isEmpty) return 'untreated';
    final latest = relevant.first;
    return '${latest.id}/${latest.startDate.millisecondsSinceEpoch}/${latest.endDate?.millisecondsSinceEpoch ?? 'stopped'}';
  }
}
