import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';

import '../support/sessions.dart';

void main() {
  for (final account in ['nurse', 'reception', 'pharmacy']) {
    for (final language in ['en', 'ar']) {
      testWidgets(
        '$account real routes at 320px in $language with large text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final (c, _) = await seededContainer(
            prefs: {
              'ui.hasSeenOnboarding': true,
              'ui.locale': language,
              'ui.textScale': 'xLarge',
            },
          );
          await signInAs(c, '$account@myhealth.demo');
          final errors = <String>[];
          var route = 'initial';
          final previous = FlutterError.onError;
          FlutterError.onError = (details) =>
              errors.add('$route: ${details.exceptionAsString()}');
          try {
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData.fromView(
                  tester.view,
                ).copyWith(textScaler: const TextScaler.linear(3)),
                child: UncontrolledProviderScope(
                  container: c,
                  child: const MyHealthCareApp(),
                ),
              ),
            );
            for (var i = 0; i < 18; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            for (final target in [
              '/staff/dashboard',
              '/staff/patients',
              '/staff/chat',
              '/staff/schedule',
              '/staff/team',
              '/staff/documents',
              '/staff/care-tools',
              '/staff/schedule/work',
              '/staff/help',
            ]) {
              route = target;
              c.read(routerProvider).go(target);
              for (var i = 0; i < 12; i++) {
                await tester.pump(const Duration(milliseconds: 100));
              }
            }
            await tester.pumpWidget(const SizedBox());
            c.dispose();
            await tester.pump(const Duration(seconds: 1));
          } finally {
            FlutterError.onError = previous;
          }
          expect(errors, isEmpty, reason: errors.join('\n'));
        },
      );
    }
  }
}
