import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/features/auth/presentation/login_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final language in ['en', 'ar']) {
      for (final scale in [1.0, 3.0]) {
        testWidgets(
          'full demo labels at $width in $language with scale $scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 1800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final (container, _) = await seededContainer();
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: AppTheme.light,
                  locale: Locale(language),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: const LoginScreen(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (final label
                in language == 'en'
                    ? [
                        'Doctor',
                        'Nurse',
                        'Receptionist',
                        'Pharmacist',
                        'Dentist',
                      ]
                    : ['طبيب', 'تمريض', 'استقبال', 'صيدلي', 'طبيب أسنان']) {
              final finder = find.text(label);
              expect(finder, findsOneWidget);
              final text = tester.widget<Text>(finder);
              expect(text.overflow, isNot(TextOverflow.ellipsis));
              expect(text.maxLines, isNull);
              final paragraph = tester.renderObject<RenderParagraph>(finder);
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(paragraph.size.width, greaterThan(0));
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
