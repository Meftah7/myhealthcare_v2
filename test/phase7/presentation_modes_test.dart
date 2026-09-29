import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/presentation/app_card.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

Widget _fixture(ThemeData theme, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: theme,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            const Text('Patient status', style: TextStyle(fontSize: 20)),
            const SizedBox(height: Space.sm),
            const InlineBanner.error('Could not save this change.'),
            const SizedBox(height: Space.sm),
            const Text('ليان Smith — Metformin 500 mg'),
            const SizedBox(height: Space.xs),
            const Directionality(
              textDirection: TextDirection.ltr,
              child: Text('ID 901234567 · +973 3900 1234 · 120 mg/dL'),
            ),
            const SizedBox(height: Space.md),
            const FilledButton(onPressed: _noop, child: Text('Continue')),
          ],
        ),
      ),
    ),
  );
}

void _noop() {}

void main() {
  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
    'light high contrast': AppTheme.lightHighContrast,
    'dark high contrast': AppTheme.darkHighContrast,
  };

  for (final entry in themes.entries) {
    testWidgets('${entry.key} keeps text and controls accessible', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_fixture(entry.value));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  }

  testWidgets('RTL keeps mixed medical identifiers deliberately LTR', (
    tester,
  ) async {
    await tester.pumpWidget(
      _fixture(AppTheme.light, locale: const Locale('ar')),
    );
    expect(
      Directionality.of(tester.element(find.text('Patient status'))),
      TextDirection.rtl,
    );
    expect(
      Directionality.of(tester.element(find.textContaining('901234567'))),
      TextDirection.ltr,
    );
  });

  testWidgets('RTL, 200% text and reduced motion render together', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: _fixture(AppTheme.darkHighContrast, locale: const Locale('ar')),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
  });
}
