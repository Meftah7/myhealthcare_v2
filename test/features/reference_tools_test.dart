import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/booking/application/discovery_providers.dart';
import 'package:myhealthcare/features/booking/presentation/select_hospital_sheet.dart';
import 'package:myhealthcare/features/health_tools/domain/lab_conversion.dart';
import 'package:myhealthcare/features/health_tools/presentation/emergency_services_screen.dart';
import 'package:myhealthcare/features/health_tools/presentation/health_tools_directory.dart';
import 'package:myhealthcare/features/patient_home/presentation/patient_home_screen.dart';
import 'package:myhealthcare/features/service_catalog/domain/patient_catalog.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/fonts.dart';
import '../support/sessions.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> mount(
  WidgetTester tester, {
  List<Override> overrides = const [],
  String language = 'en',
  String theme = 'light',
  TextScaleLevel scale = TextScaleLevel.small,
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final (c, _) = await seededContainer(
    overrides: overrides,
    prefs: {
      'ui.hasSeenOnboarding': true,
      'ui.locale': language,
      'ui.themeMode': theme,
      'ui.textScale': scale.name,
    },
  );
  await signInAs(c, 'patient1@myhealth.demo');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const RepaintBoundary(
        key: ValueKey('reference-tools-render'),
        child: MyHealthCareApp(),
      ),
    ),
  );
  await settle(tester);
  return c;
}

Future<void> snapshot(WidgetTester tester, String name) async {
  final directory = Platform.environment['REFERENCE_TOOLS_CAPTURE_DIR'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('reference-tools-render')),
  );
  await tester.runAsync(() async {
    final render = await boundary.toImage();
    final bytes = await render.toByteData(format: ui.ImageByteFormat.png);
    File('$directory/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
    render.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final (family, path) in const [
      ('Inter', 'assets/fonts/static/Inter-Regular.ttf'),
      ('Inter', 'assets/fonts/static/Inter-Medium.ttf'),
      ('Inter', 'assets/fonts/static/Inter-SemiBold.ttf'),
      ('Inter', 'assets/fonts/static/Inter-Bold.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-Medium.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-SemiBold.ttf'),
      ('NotoNaskhArabic', 'assets/fonts/NotoNaskhArabic.ttf'),
    ]) {
      await ui.loadFontFromList(
        await File(path).readAsBytes(),
        fontFamily: family,
      );
    }
    await loadMaterialIcons();
  });

  for (final analyte in LabAnalyte.values) {
    testWidgets(
      '${analyte.name}: localized input, repeated swaps, invalid, empty and copy',
      (tester) async {
        final c = await mount(tester, language: 'ar');
        c
            .read(routerProvider)
            .go('${AppRoutes.patientConverters}/${analyte.name}');
        await settle(tester);
        final input = find.byKey(const ValueKey('lab-input'));
        final swap = find.byKey(const ValueKey('lab-swap'));
        await tester.enterText(input, '١٢٠٫٥');
        await tester.pump();
        final output = tester
            .widget<Text>(find.byKey(const ValueKey('lab-output')))
            .data!;
        expect(output, endsWith('mmol/L'));
        expect(
          output,
          contains(
            NumberFormat('0.00', 'ar').format(120.5 * analyte.mmolPerMg),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await tester.tap(swap);
          await tester.pump();
        }
        expect(
          parseLocalizedNumber(
            tester.widget<TextField>(input).controller!.text,
          ),
          closeTo(120.5, 1e-9),
        );
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('lab-output'))).data,
          output,
        );
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.ensureVisible(find.byKey(const ValueKey('lab-copy')));
        await tester.tap(find.byKey(const ValueKey('lab-copy')));
        await tester.pump();
        expect(copied, output);
        for (final invalid in ['-1', 'NaN', 'abc', '1e999']) {
          await tester.enterText(input, invalid);
          await tester.pump();
          expect(
            tester.widget<TextField>(input).decoration!.errorText,
            isNotNull,
          );
          expect(tester.widget<IconButton>(swap).onPressed, isNull);
          expect(
            tester.widget<Text>(find.byKey(const ValueKey('lab-output'))).data,
            startsWith('—'),
          );
        }
        await tester.enterText(input, '');
        await tester.pump();
        expect(tester.widget<TextField>(input).decoration!.errorText, isNull);
        await tester.enterText(input, '0');
        await tester.pump();
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('lab-output'))).data,
          startsWith('0'),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await settle(tester);
      },
    );
  }

  testWidgets(
    'emergency phone launch failure is honest and planned actions never dispatch',
    (tester) async {
      final calls = <Uri>[];
      final c = await mount(
        tester,
        overrides: [
          emergencyDialerProvider.overrideWithValue((uri) async {
            calls.add(uri);
            return false;
          }),
        ],
      );
      c.read(routerProvider).go(AppRoutes.patientEmergency);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('emergency-call')));
      await tester.pump();
      expect(calls, [Uri.parse('tel:999')]);
      expect(
        find.byKey(const ValueKey('emergency-phone-failed')),
        findsOneWidget,
      );
      final t = AppLocalizations.of(
        tester.element(find.byType(EmergencyServicesScreen)),
      )!;
      await tester.ensureVisible(find.text(t.htNearestEr));
      await tester.tap(find.text(t.htNearestEr));
      await settle(tester);
      expect(find.text(t.htNearestErUnavailable), findsWidgets);
      expect(calls.length, 1);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    },
  );

  testWidgets(
    'calculator groups collapse, BMI is reused and unsupported tools collect no inputs',
    (tester) async {
      final c = await mount(tester);
      c.read(routerProvider).go(AppRoutes.patientCalculators);
      await settle(tester);
      final t = AppLocalizations.of(
        tester.element(find.byType(HealthCalculatorsScreen)),
      )!;
      await tester.tap(find.text(t.htWomensHealth));
      await settle(tester);
      expect(find.text(t.htOvulation).hitTestable(), findsNothing);
      await tester.tap(find.text(t.htWomensHealth));
      await settle(tester);
      await tester.tap(find.text(t.htOvulation));
      await settle(tester);
      expect(c.read(routerProvider).state.uri.path, AppRoutes.patientOvulation);
      // No period date entered: no estimate, an explanation instead.
      await tester.ensureVisible(find.text(t.paCalculate));
      await tester.tap(find.text(t.paCalculate));
      await tester.pump();
      expect(find.text(t.htInvalidInput), findsOneWidget);
      expect(find.text(t.htOvulationResult), findsNothing);

      // Body fat: a real estimate, cleared when an input changes.
      c.read(routerProvider).go(AppRoutes.patientBodyFat);
      await settle(tester);
      await tester.tap(find.text(t.htMale));
      await tester.pump();
      final bf = find.byType(TextField);
      await tester.enterText(bf.at(0), '180');
      await tester.enterText(bf.at(1), '38');
      await tester.enterText(bf.at(2), '85');
      await tester.ensureVisible(find.text(t.paCalculate));
      await tester.tap(find.text(t.paCalculate));
      await tester.pump();
      expect(find.text('16.1%'), findsOneWidget);
      await tester.enterText(bf.at(2), '86');
      await tester.pump();
      expect(find.text('16.1%'), findsNothing);
      c.read(routerProvider).go(AppRoutes.patientCalculators);
      await settle(tester);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('bmi'))),
        alignment: .2,
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('bmi')));
      await settle(tester);
      expect(
        c.read(routerProvider).state.uri.path,
        AppRoutes.patientBodyMeasurements,
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '70');
      await tester.enterText(fields.at(1), '175');
      await tester.ensureVisible(find.text(t.paCalculate));
      await tester.tap(find.text(t.paCalculate));
      await tester.pump();
      expect(find.text('22.9'), findsOneWidget);
      c.read(routerProvider).go(AppRoutes.patientCalculators);
      await settle(tester);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('calories'))),
        alignment: .2,
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('calories')));
      await settle(tester);
      expect(c.read(routerProvider).state.uri.path, AppRoutes.patientNutrition);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    },
  );

  testWidgets(
    'doctor keyboard Search, details and fresh booking route use real directory',
    (tester) async {
      final c = await mount(tester);
      c.read(routerProvider).go(AppRoutes.patientFindDoctor);
      await settle(tester);
      final doctors = await c.read(publicDoctorsProvider.future);
      final doctor = doctors.first;
      final input = find.byKey(const ValueKey('doctor-search-input'));
      await tester.enterText(input, 'not-a-real-doctor');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      final t = AppLocalizations.of(tester.element(input))!;
      expect(find.text(t.paNoResults), findsOneWidget);
      await tester.enterText(input, doctor.fullName);
      await tester.tap(find.byKey(const ValueKey('doctor-search-submit')));
      await settle(tester);
      await tester.ensureVisible(find.text(t.htDoctorDetails).first);
      await tester.tap(find.text(t.htDoctorDetails).first);
      await settle(tester);
      expect(find.text(doctor.fullName), findsWidgets);
      await tester.tap(find.text(t.paClose));
      await settle(tester);
      await tester.ensureVisible(find.text(t.paSeeAvailability).first);
      await tester.tap(find.text(t.paSeeAvailability).first);
      await settle(tester);
      expect(c.read(routerProvider).state.uri.path, AppRoutes.patientBook);
      expect(
        c.read(routerProvider).state.uri.queryParameters['staff'],
        doctor.id,
      );
      expect(
        c.read(routerProvider).state.uri.queryParameters['dept'],
        doctor.departmentId,
      );
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    },
  );

  testWidgets('doctor loading/error/empty states do not invent clinicians', (
    tester,
  ) async {
    final source = Completer<List<Staff>>();
    var empty = false;
    final c = await mount(
      tester,
      overrides: [
        publicDoctorsProvider.overrideWith(
          (ref) => empty ? Future.value(<Staff>[]) : source.future,
        ),
      ],
    );
    c.read(routerProvider).go(AppRoutes.patientFindDoctor);
    await settle(tester);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    source.completeError(StateError('synthetic directory unavailable'));
    await settle(tester);
    final t = AppLocalizations.of(
      tester.element(find.byKey(const ValueKey('doctor-search-input'))),
    )!;
    expect(find.text(t.paLoadFailed), findsWidgets);
    empty = true;
    c.invalidate(publicDoctorsProvider);
    await settle(tester);
    expect(find.text(t.paNoResults), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets(
    'hospital sheet closes without changing draft; fallback reuses clinic search',
    (tester) async {
      final c = await mount(tester);
      const draft = BookingRequestDraft(
        departmentId: 'saved-dept',
        reason: 'keep draft',
      );
      c.read(bookingDraftProvider.notifier).state = draft;
      final home = tester.element(find.byType(PatientHomeScreen));
      unawaited(showSelectHospitalSheet(home));
      await settle(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tester.tap(find.byKey(const ValueKey('hospital-close')));
      await settle(tester);
      expect(c.read(bookingDraftProvider), same(draft));
      unawaited(showSelectHospitalSheet(home));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('hospital-browse-clinic')));
      await settle(tester);
      expect(
        c.read(routerProvider).state.uri.path,
        AppRoutes.patientFindClinic,
      );
      expect(c.read(bookingDraftProvider), same(draft));
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    },
  );

  test('reference shortcuts, scope and source exclusion are explicit', () {
    expect(PatientCatalog.quickTools.map((i) => i.id), [
      'emergency',
      'find-doctor',
      'calculators',
      'converters',
    ]);
    expect(PatientCatalog.selectHospital.isAvailable, isFalse);
    expect(PatientCatalog.selectHospital.isFutureWork, isTrue);
    for (final item in [PatientCatalog.converters, PatientCatalog.emergency]) {
      expect(item.isFutureWork, isTrue);
    }
    // Owner-approved (2026-10-13): the calculators are current scope.
    expect(PatientCatalog.calculators.isFutureWork, isFalse);
    expect(PatientCatalog.weather.isAvailable, isFalse);
    expect(PatientCatalog.news.isAvailable, isFalse);
  });

  testWidgets('new patient tool routes stay guarded after logout', (
    tester,
  ) async {
    final c = await mount(tester);
    await tester.runAsync(() => c.read(sessionProvider.notifier).logout());
    await settle(tester);
    for (final path in [
      AppRoutes.patientEmergency,
      AppRoutes.patientBodyMeasurements,
      '${AppRoutes.patientConverters}/cholesterol',
      '${AppRoutes.patientConverters}/triglycerides',
    ]) {
      c.read(routerProvider).go(path);
      await settle(tester);
      expect(c.read(routerProvider).state.uri.path, AppRoutes.login);
      expect(find.byKey(const ValueKey('lab-input')), findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  for (final language in ['en', 'ar']) {
    for (final theme in ['light', 'dark']) {
      for (final scale in TextScaleLevel.options) {
        testWidgets(
          '$language $theme ${scale.label}: reference screen renders and system scaling',
          (tester) async {
            final c = await mount(
              tester,
              language: language,
              theme: theme,
              scale: scale,
            );
            final routes = {
              'home': AppRoutes.patientHome,
              'emergency': AppRoutes.patientEmergency,
              'calculators': AppRoutes.patientCalculators,
              'bmi': AppRoutes.patientBodyMeasurements,
              'converters': AppRoutes.patientConverters,
              for (final analyte in LabAnalyte.values)
                analyte.name: '${AppRoutes.patientConverters}/${analyte.name}',
              'general': AppRoutes.patientGeneralConverters,
              'doctors': AppRoutes.patientFindDoctor,
            };
            for (final size in [
              const Size(390, 844),
              const Size(768, 1024),
              const Size(1366, 768),
            ]) {
              tester.view.physicalSize = size;
              for (final entry in routes.entries) {
                c.read(routerProvider).go(entry.value);
                await settle(tester);
                if (LabAnalyte.values.any((a) => a.name == entry.key)) {
                  await tester.enterText(
                    find.byKey(const ValueKey('lab-input')),
                    language == 'ar' ? '١٢٠' : '120',
                  );
                  await settle(tester);
                }
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '${entry.key} $size',
                );
                if (scale == TextScaleLevel.small &&
                    ((language == 'en' && theme == 'light') ||
                        (language == 'ar' && theme == 'dark'))) {
                  await snapshot(
                    tester,
                    '${entry.key}_${size.width.toInt()}_${language}_${theme}_default',
                  );
                  if (entry.key == 'home') {
                    final scrollable = find
                        .descendant(
                          of: find.byType(PatientHomeScreen),
                          matching: find.byType(Scrollable),
                        )
                        .first;
                    await tester.scrollUntilVisible(
                      find.byKey(const ValueKey('tool-emergency')),
                      300,
                      scrollable: scrollable,
                    );
                    await settle(tester);
                    await snapshot(
                      tester,
                      'shortcuts_${size.width.toInt()}_${language}_${theme}_default',
                    );
                    tester
                        .state<ScrollableState>(scrollable)
                        .position
                        .jumpTo(0);
                    await tester.pump();
                  }
                  if (entry.key == 'calculators') {
                    final scrollable = find
                        .descendant(
                          of: find.byType(HealthCalculatorsScreen),
                          matching: find.byType(Scrollable),
                        )
                        .first;
                    await tester.scrollUntilVisible(
                      find.byKey(const ValueKey('bmi')),
                      300,
                      scrollable: scrollable,
                    );
                    await settle(tester);
                    await snapshot(
                      tester,
                      'calculators_general_${size.width.toInt()}_${language}_${theme}_default',
                    );
                  }
                }
              }
              c.read(routerProvider).go(AppRoutes.patientHome);
              await settle(tester);
              final home = tester.element(find.byType(PatientHomeScreen));
              unawaited(showSelectHospitalSheet(home));
              await settle(tester);
              expect(tester.takeException(), isNull, reason: 'hospital $size');
              if (scale == TextScaleLevel.small &&
                  ((language == 'en' && theme == 'light') ||
                      (language == 'ar' && theme == 'dark'))) {
                await snapshot(
                  tester,
                  'hospital_${size.width.toInt()}_${language}_${theme}_default',
                );
              }
              await tester.tap(find.byKey(const ValueKey('hospital-close')));
              await settle(tester);
            }
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            for (final size in [
              const Size(360, 800),
              const Size(768, 1024),
              const Size(1366, 768),
            ]) {
              tester.view.physicalSize = size;
              for (final route in routes.values) {
                c.read(routerProvider).go(route);
                await settle(tester);
                expect(
                  tester.takeException(),
                  isNull,
                  reason: 'OS 2x $size $route',
                );
              }
              c.read(routerProvider).go(AppRoutes.patientHome);
              await settle(tester);
              unawaited(
                showSelectHospitalSheet(
                  tester.element(find.byType(PatientHomeScreen)),
                ),
              );
              await settle(tester);
              expect(
                tester.takeException(),
                isNull,
                reason: 'OS 2x hospital $size',
              );
              await tester.tap(find.byKey(const ValueKey('hospital-close')));
              await settle(tester);
            }
            await tester.pumpWidget(const SizedBox());
            await settle(tester);
          },
        );
      }
    }
  }
}
