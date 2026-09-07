/// Test helper: clear the MFA verify screen if it's showing.
///
/// MFA is on by default ([kRequireMfaAtSignIn]) and the code field is
/// pre-filled with the demo code, so a UI sign-in in a test just has to press
/// "Verify". Call this right after tapping "Sign in" — it settles, presses
/// Verify if the screen appeared, and settles again.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> passMfa(WidgetTester tester) async {
  await _settle(tester);
  final verify = find.widgetWithText(FilledButton, 'Verify');
  if (verify.evaluate().isEmpty) return;
  await tester.tap(verify);
  await _settle(tester);
}
