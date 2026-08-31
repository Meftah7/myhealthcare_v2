// AI layer: mock service determinism + summary JSON parsing (P3-03, P3-04,
// P6-03).

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/services/ai/ai_models.dart';
import 'package:myhealthcare/services/ai/mock_ai_service.dart';
import 'package:myhealthcare/services/ai/summary_parser.dart';

const _ctx = PatientContext(
  patientId: 'p1',
  contextText: 'ctx',
  hash: 'h',
  approxTokens: 1,
);

Patient _patient({List<String> conditions = const []}) => Patient(
  user: User(
    id: 'p1',
    role: UserRole.patient,
    fullName: 'Test Patient',
    email: 't@e.com',
    isActive: true,
    createdAt: DateTime(2024, 6, 12),
    dob: DateTime(1980, 5, 12),
  ),
  chronicConditions: conditions,
);

MedicalRecord _labRecord(DateTime at, AbnormalFlag flag) => MedicalRecord(
  id: 'r-${at.microsecondsSinceEpoch}',
  patientId: 'p1',
  recordType: RecordType.labResult,
  title: 'Panel',
  occurredAt: at,
  createdAt: at,
  labValues: [
    LabValue(
      id: 'l1',
      recordId: 'r1',
      analyte: 'HbA1c',
      value: 9,
      abnormalFlag: flag,
      refLow: 4,
      refHigh: 5.6,
    ),
  ],
);

void main() {
  group('MockAiService', () {
    test('is deterministic and derives flags from real data', () async {
      final svc = MockAiService(
        patient: _patient(conditions: ['Type 2 Diabetes']),
        records: [_labRecord(DateTime(2026, 3), AbnormalFlag.critical)],
        vitals: const [],
        medications: const [], // diabetic with no meds → red flag
      );

      final a = (await svc.summarizeRecords(_ctx)).valueOrNull!;
      final b = (await svc.summarizeRecords(_ctx)).valueOrNull!;
      expect(a, b); // identical output

      expect(a.modelId, 'mock-ai');
      expect(
        a.redFlags.any((f) => f.severity == Severity.urgent),
        isTrue,
        reason: 'critical lab → urgent flag',
      );
      expect(
        a.redFlags.any((f) => f.description.contains('Type 2 Diabetes')),
        isTrue,
        reason: 'chronic condition with no medication → flag',
      );
    });

    test('healthy patient has an empty red-flag list', () async {
      final svc = MockAiService(
        patient: _patient(),
        records: [_labRecord(DateTime(2026, 3), AbnormalFlag.normal)],
        vitals: const [],
        medications: const [],
      );
      final r = (await svc.summarizeRecords(_ctx)).valueOrNull!;
      expect(r.redFlags, isEmpty);
    });
  });

  group('parseHealthSummary', () {
    HealthSummary parse(String raw) =>
        parseHealthSummary(raw, modelId: 'test', promptVersion: 'v1');

    test('parses a clean JSON object', () {
      final s = parse('''
{"summary":"All stable.","keyEvents":[{"date":"2026-01-02","title":"MRI"}],
 "trends":[{"metric":"Weight","direction":"down","summary":"-3kg"}],
 "redFlags":[{"severity":"warning","description":"Overdue review"}]}
''');
      expect(s.summaryMarkdown, 'All stable.');
      expect(s.keyEvents.single.title, 'MRI');
      expect(s.trends.single.direction, 'down');
      expect(s.redFlags.single.severity, Severity.warning);
    });

    test('unwraps a ```json fence and surrounding prose', () {
      final s = parse('Here you go:\n```json\n{"summary":"ok"}\n```\nThanks');
      expect(s.summaryMarkdown, 'ok');
    });

    test('skips malformed list entries but keeps the summary', () {
      final s = parse('{"summary":"ok","keyEvents":[{"nope":1},{"date":"x"}]}');
      expect(s.summaryMarkdown, 'ok');
      expect(s.keyEvents, isEmpty);
    });

    test('throws AiFailure on non-JSON', () {
      expect(
        () => parse('the model is unavailable'),
        throwsA(isA<AiFailure>()),
      );
    });

    test('throws AiFailure on JSON without a summary', () {
      expect(() => parse('{"keyEvents":[]}'), throwsA(isA<AiFailure>()));
    });

    test('throws AiFailure on an empty response', () {
      expect(() => parse(''), throwsA(isA<AiFailure>()));
      expect(() => parse('   \n  '), throwsA(isA<AiFailure>()));
    });

    test('throws AiFailure on an empty JSON object (no summary)', () {
      expect(() => parse('{}'), throwsA(isA<AiFailure>()));
    });

    test('throws AiFailure when summary is present but blank', () {
      expect(() => parse('{"summary":"   "}'), throwsA(isA<AiFailure>()));
    });
  });
}
