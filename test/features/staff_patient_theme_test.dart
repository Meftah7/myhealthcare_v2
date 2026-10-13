import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/presentation/confirm_dialog.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

void main() {
  test('shared main text, links and action labels have readable contrast', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
    }

    for (final palette in [PatientPalette.light, PatientPalette.dark]) {
      for (final background in [palette.canvas, palette.card]) {
        expect(contrast(palette.text, background), greaterThanOrEqualTo(4.5));
        expect(
          contrast(palette.textMuted, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(palette.link, background), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(palette.onAction, palette.action),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('staff uses patient colours without changing geometry', () {
    for (final (staff, patient, palette) in [
      (AppTheme.light, AppTheme.patientLight, PatientPalette.light),
      (AppTheme.dark, AppTheme.patientDark, PatientPalette.dark),
      (
        AppTheme.lightHighContrast,
        AppTheme.patientLightHighContrast,
        PatientPalette.light,
      ),
      (
        AppTheme.darkHighContrast,
        AppTheme.patientDarkHighContrast,
        PatientPalette.dark,
      ),
    ]) {
      expect(staff.colorScheme, patient.colorScheme);
      expect(staff.extension<PatientPalette>(), same(palette));
      expect(
        staff.extension<ClinicalStatusColors>(),
        patient.extension<ClinicalStatusColors>(),
      );
      expect(staff.scaffoldBackgroundColor, patient.scaffoldBackgroundColor);
      expect(staff.cardTheme.color, patient.cardTheme.color);
      expect(staff.inputDecorationTheme, patient.inputDecorationTheme);
      expect(
        staff.navigationBarTheme.backgroundColor,
        patient.navigationBarTheme.backgroundColor,
      );
      expect(
        staff.navigationBarTheme.indicatorColor,
        patient.navigationBarTheme.indicatorColor,
      );
      for (final states in [
        <WidgetState>{},
        {WidgetState.selected},
        {WidgetState.disabled},
      ]) {
        expect(
          staff.navigationBarTheme.iconTheme!.resolve(states),
          patient.navigationBarTheme.iconTheme!.resolve(states),
        );
        expect(
          staff.navigationBarTheme.labelTextStyle!.resolve(states),
          patient.navigationBarTheme.labelTextStyle!.resolve(states),
        );
      }
      expect(staff.navigationRailTheme, patient.navigationRailTheme);
      expect(staff.tabBarTheme, patient.tabBarTheme);
      expect(staff.progressIndicatorTheme, patient.progressIndicatorTheme);
      expect(staff.popupMenuTheme, patient.popupMenuTheme);
      expect(staff.tooltipTheme, patient.tooltipTheme);
      expect(staff.snackBarTheme, patient.snackBarTheme);
      expect(staff.bottomSheetTheme, patient.bottomSheetTheme);
      for (final states in [
        <WidgetState>{},
        {WidgetState.disabled},
        {WidgetState.pressed},
        {WidgetState.focused},
        {WidgetState.hovered},
      ]) {
        expect(
          staff.filledButtonTheme.style!.backgroundColor!.resolve(states),
          patient.filledButtonTheme.style!.backgroundColor!.resolve(states),
        );
        expect(
          staff.filledButtonTheme.style!.foregroundColor!.resolve(states),
          patient.filledButtonTheme.style!.foregroundColor!.resolve(states),
        );
      }
      expect(
        (staff.cardTheme.shape! as RoundedRectangleBorder).borderRadius,
        Radii.card,
      );
      expect(
        staff.filledButtonTheme.style!.minimumSize!.resolve({}),
        const Size(0, 50),
      );
      expect(
        patient.filledButtonTheme.style!.minimumSize!.resolve({}),
        const Size(0, 52),
      );
    }
  });

  for (final language in ['en', 'ar']) {
    testWidgets('open destructive dialog follows live theme in $language', (
      tester,
    ) async {
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: mode,
          builder: (_, value, child) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: value,
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    await confirm(
                      context,
                      title: 'Confirm',
                      message: 'Delete?',
                      destructive: true,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      for (final selected in [ThemeMode.dark, ThemeMode.light]) {
        mode.value = selected;
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(AlertDialog));
        final theme = Theme.of(context);
        expect(
          theme.colorScheme,
          selected == ThemeMode.dark
              ? AppColors.patientDark
              : AppColors.patientLight,
        );
        final style = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style!;
        expect(style.backgroundColor!.resolve({}), theme.colorScheme.error);
        expect(style.foregroundColor!.resolve({}), theme.colorScheme.onError);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
