// FallbackAiService + GeminiAiService error handling (P3-05).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/services/ai/ai_models.dart';
import 'package:myhealthcare/services/ai/ai_service.dart';
import 'package:myhealthcare/services/ai/gemini_ai_service.dart';
import 'package:myhealthcare/services/ai/mock_ai_service.dart';

const _ctx = PatientContext(
  patientId: 'p1',
  contextText: 'ctx',
  hash: 'h',
  approxTokens: 1,
);

MockAiService _mock() => MockAiService(
  patient: Patient(
    user: User(
      id: 'p1',
      role: UserRole.patient,
      fullName: 'P',
      email: 'p@e.com',
      isActive: true,
      createdAt: DateTime(2024, 6, 12),
    ),
  ),
  records: const [],
  vitals: const [],
  medications: const [],
);

class _AlwaysFails implements AiService {
  @override
  Future<Result<HealthSummary>> summarizeRecords(PatientContext c) async =>
      const Err(AiFailure('boom'));
}

void main() {
  test('FallbackAiService uses the mock when the primary errors', () async {
    final svc = FallbackAiService(primary: _AlwaysFails(), fallback: _mock());
    final r = await svc.summarizeRecords(_ctx);
    expect(r.isOk, isTrue);
    expect(r.valueOrNull!.modelId, 'mock-ai');
  });

  test('GeminiAiService returns Err (not throw) on a transport failure', () async {
    // No network / bad host → DioException → NetworkFailure, never an exception.
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:1'));
    final svc = GeminiAiService(apiKey: 'x', dio: dio);
    final r = await svc.summarizeRecords(_ctx);
    expect(r.isErr, isTrue);
  });

  test('FallbackAiService wrapping a broken Gemini still succeeds', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:1'));
    final svc = FallbackAiService(
      primary: GeminiAiService(apiKey: 'x', dio: dio),
      fallback: _mock(),
    );
    final r = await svc.summarizeRecords(_ctx);
    expect(r.valueOrNull?.modelId, 'mock-ai');
  });
}
