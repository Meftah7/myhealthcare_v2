// Per-meal nutrition targets, the doctor chat section, and the AI chat's
// plain-language PDF explanation.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/app_theme.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/care/application/care_providers.dart';
import 'package:myhealthcare/features/care/presentation/patient_doctor_chat_section.dart';
import 'package:myhealthcare/features/nutrition/application/macro_calculator.dart';
import 'package:myhealthcare/features/nutrition/application/nutrition_providers.dart';
import 'package:myhealthcare/features/nutrition/domain/nutrition_data.dart';
import 'package:myhealthcare/features/patient/application/visited_doctors_provider.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _targets = MacroResult(
  bmr: 1600,
  tdee: 2200,
  targetCalories: 2000,
  protein: 150,
  carbs: 200,
  fat: 67,
  maxSugar: 40,
  maxSatFat: 20,
);

class _FixedTargets extends MacroTargetsController {
  @override
  MacroResult? build() => _targets;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('meal targets', () {
    test('three meals with all six figures; a dessert adds a fourth', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          macroTargetsProvider.overrideWith(_FixedTargets.new),
        ],
      );
      addTearDown(c.dispose);

      await c
          .read(mealPlanProvider.notifier)
          .generate(const MealPlanRequest(includeSweet: false));
      var meals = c.read(mealPlanProvider)!.perMeal!;
      expect(meals.map((m) => m.type), [
        MealType.breakfast,
        MealType.lunch,
        MealType.dinner,
      ]);
      for (final m in meals) {
        expect(m.calories, greaterThan(0));
        expect(m.maxSugar, greaterThan(0));
        expect(m.maxSatFat, greaterThan(0));
      }
      expect(meals.fold<int>(0, (s, m) => s + m.calories), closeTo(2000, 3));

      await c
          .read(mealPlanProvider.notifier)
          .generate(const MealPlanRequest(includeSweet: true));
      meals = c.read(mealPlanProvider)!.perMeal!;
      expect(meals.last.type, MealType.sweet);
      expect(meals.last.maxSugar, greaterThan(0));
    });
  });

  group('doctor chat section', () {
    final now = DateTime(2026, 10, 1);
    VisitedDoctor doctor(String id, String name) => VisitedDoctor(
      staffId: id,
      name: name,
      departmentName: 'Internal Medicine',
      visitCount: 1,
      lastVisit: now,
      nextVisit: null,
    );

    Future<void> pump(WidgetTester tester, List<CareThread> threads) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            visitedDoctorsProvider.overrideWith(
              (ref) async => [
                doctor('d1', 'Dr Messaged'),
                doctor('d2', 'Dr Quiet'),
              ],
            ),
            patientThreadsProvider.overrideWith((ref) async => threads),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: PatientDoctorChatSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('only conversations are listed; others via the button', (
      tester,
    ) async {
      await pump(tester, [
        CareThread(
          patientId: 'p',
          staffId: 'd1',
          counterpartName: 'Dr Messaged',
          lastMessage: CareMessage(
            id: 'm1',
            patientId: 'p',
            staffId: 'd1',
            fromStaff: true,
            body: 'Your results are ready.',
            sentAt: now,
          ),
          unreadForPatient: 1,
          unreadForStaff: 0,
        ),
      ]);
      expect(find.textContaining('Dr Messaged'), findsWidgets);
      expect(find.text('Dr Quiet'), findsNothing);

      await tester.tap(find.text('Chat with doctor'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a doctor'), findsOneWidget);
      expect(find.text('Dr Quiet'), findsOneWidget);
    });

    testWidgets('with no messages, says so and offers the button', (
      tester,
    ) async {
      await pump(tester, const []);
      expect(find.textContaining('No messages yet'), findsOneWidget);
      expect(find.text('Chat with doctor'), findsOneWidget);
      expect(find.text('Dr Messaged'), findsNothing);
    });
  });

  group('PDF explanation', () {
    test('names the tests, what they measure, and what is marked', () {
      final text = explainDocumentOffline(
        'Gulf Diagnostics Lab\n'
        'Ferritin 8 ng/mL L (15-150)\n'
        'Hemoglobin 13.1 g/dL (12-16)\n'
        'Glucose 7.9 mmol/L H\n',
        title: 'Blood test',
      );
      expect(text, contains('Blood test'));
      expect(text, contains("iron stores"));
      expect(text, contains('Marked high: glucose'));
      expect(text, contains('Marked low: ferritin'));
      expect(text, contains('talk it through with your doctor'));
    });

    test('says so when it cannot find results', () {
      final text = explainDocumentOffline(
        'Thank you for your visit.',
        title: 'Letter',
      );
      expect(text, contains("couldn't spot specific test results"));
    });
  });
}
