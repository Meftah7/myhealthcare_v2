// The "no medical questions" rule on the device. The cases are shared with
// the gateway's tests (services/report_ai/eval/medical_questions.json), so
// the app and the server classify every example the same way.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/features/ai_chat/application/assistant_policy.dart';

void main() {
  final cases =
      (jsonDecode(
                File(
                  'services/report_ai/eval/medical_questions.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['cases']
          as List<dynamic>;

  test('every shared case classifies as the server does', () {
    expect(cases.length, greaterThan(50));
    for (final raw in cases.cast<Map<String, dynamic>>()) {
      final text = raw['text'] as String;
      if (raw.containsKey('emergency')) {
        expect(isEmergencyStatement(text), raw['emergency'], reason: text);
        continue;
      }
      final history = [
        for (final t in (raw['history'] as List<dynamic>? ?? const []))
          (
            fromPatient: (t as Map<String, dynamic>)['role'] == 'user',
            text: t['text'] as String,
          ),
      ];
      expect(
        isMedicalQuestion(
          text,
          history: history,
          hasDocument: raw['hasDocument'] == true,
        ),
        raw['medical'],
        reason: text,
      );
    }
  });

  test('the fixed refusal matches the required wording in both languages', () {
    expect(
      AssistantText.medical(false),
      'I can help you use the app and summarize your document, but I can’t '
      'answer medical questions. Please message your doctor or book an '
      'appointment to discuss this.',
    );
    expect(
      AssistantText.medical(true),
      'يمكنني مساعدتك في استخدام التطبيق وتلخيص مستندك، لكن لا يمكنني الإجابة '
      'عن الأسئلة الطبية. يرجى مراسلة طبيبك أو حجز موعد لمناقشة سؤالك.',
    );
  });
}
