// Admin dashboard Tier B: feedback inbox, AI usage log, capacity forecast.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/admin/application/admin_providers.dart';
import 'package:myhealthcare/features/admin/application/capacity_forecast.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _container() async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}

Future<ProviderContainer> _signInAdmin(WidgetTester tester) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
  await _settle(tester);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'admin@myhealth.demo',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    Seeder.demoPassword,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await _settle(tester);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  test('feedback: submit → admin sees it → resolve', () async {
    final container = await _container();
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).login(
          email: 'patient3@myhealth.demo',
          password: Seeder.demoPassword,
        );
    final me = container.read(currentUserProvider)!.id;

    await container.read(feedbackRepositoryProvider).submit(
          category: FeedbackCategory.bug,
          message: 'The medication list does not scroll on my phone.',
          reporterId: me,
        );

    final open = await container.read(feedbackProvider(FeedbackStatus.open).future);
    final mine = open.firstWhere((f) => f.reporterId == me);
    expect(mine.category, FeedbackCategory.bug);
    expect(mine.reporterName, isNotNull);

    await container.read(sessionProvider.notifier).logout();
    await container.read(sessionProvider.notifier).login(
          email: 'admin@myhealth.demo',
          password: Seeder.demoPassword,
        );
    await container
        .read(adminActionsProvider)
        .setFeedbackStatus(id: mine.id, status: FeedbackStatus.resolved);

    final stillOpen =
        await container.read(feedbackProvider(FeedbackStatus.open).future);
    expect(stillOpen.any((f) => f.id == mine.id), isFalse);
  });

  test('forecastFromHistory bins by weekday and always returns 7 days', () async {
    final container = await _container();
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).login(
          email: 'admin@myhealth.demo',
          password: Seeder.demoPassword,
        );
    final appts = await container.read(allAppointmentsProvider.future);
    final forecast = forecastFromHistory(appts);
    expect(forecast.days, hasLength(7));
    expect(forecast.aiNarrated, isFalse);
    expect(forecast.days.map((d) => d.weekday).toSet(), {1, 2, 3, 4, 5, 6, 7});
  });

  test('AI usage is logged when the Care Navigator answers', () async {
    final container = await _container();
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).login(
          email: 'patient3@myhealth.demo',
          password: Seeder.demoPassword,
        );

    await container
        .read(careNavigatorProvider.notifier)
        .send('how do I book an appointment?');

    final log = await container
        .read(aiUsageProvider(AiFeature.careNavigator).future);
    expect(log, isNotEmpty);
    expect(log.first.feature, AiFeature.careNavigator);
    expect(log.first.usedLiveModel, isFalse); // no key in tests
  });

  testWidgets('admin dashboard: Feedback / AI activity / Forecast tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    expect(find.text('Feedback'), findsWidgets);
    expect(find.text('AI activity'), findsOneWidget);
    expect(find.text('Forecast'), findsOneWidget);

    // Feedback inbox opens and shows the seeded reports.
    await tester.tap(find.text('Feedback').first);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Feedback'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Mark resolved'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Mark resolved').first);
    await _settle(tester);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('capacity forecast screen renders 7 day cards', (tester) async {
    tester.view.physicalSize = const Size(1400, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Forecast'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Capacity forecast'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
