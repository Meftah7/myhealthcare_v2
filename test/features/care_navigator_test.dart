// The Care Navigator: emergency guard, offline navigation replies, and the
// floating widget opening from the FAB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/ai_chat/presentation/care_navigator_overlay.dart';
import 'package:myhealthcare/features/ai_chat/presentation/care_navigator_panel.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('offline responder', () {
    late ProviderContainer container;

    setUp(() async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).login(
            email: 'patient3@myhealth.demo',
            password: Seeder.demoPassword,
          );
    });

    Future<String> ask(String q) async {
      final nav = container.read(careNavigatorProvider.notifier);
      await nav.send(q);
      return container.read(careNavigatorProvider).messages.last.text;
    }

    test('greeting is the first message', () {
      expect(
        container.read(careNavigatorProvider).messages.single.role,
        ChatRole.model,
      );
    });

    test('emergency keywords trigger the emergency reply', () async {
      await ask('I have severe chest pain and I can\'t breathe');
      final last = container.read(careNavigatorProvider).messages.last;
      expect(last.isEmergency, isTrue);
      expect(last.text, contains('999'));
      // Never marked as "sending" for the emergency path.
      expect(container.read(careNavigatorProvider).sending, isFalse);
    });

    test('navigation questions route to the right area', () async {
      expect(await ask('how do I book an appointment?'),
          contains('Appointments'));
      expect(await ask('where are my lab results?'), contains('Health Records'));
      expect(await ask('I want to pay my bill'), contains('Wallet'));
      expect(await ask('help me with my calories'), contains('Nutrition'));
      expect(await ask('change my password'), contains('Profile'));
    });

    test('a symptom question is redirected, not answered', () async {
      final reply = await ask('what should I take for a fever?');
      expect(reply.toLowerCase(), contains("can't give medical advice"));
      expect(reply, contains('appointment'));
    });

    test('reset restores just the greeting', () async {
      await ask('hello');
      expect(container.read(careNavigatorProvider).messages.length,
          greaterThan(1));
      container.read(careNavigatorProvider.notifier).reset();
      expect(container.read(careNavigatorProvider).messages, hasLength(1));
    });
  });

  testWidgets('FAB opens the chat panel for a signed-in patient',
      (tester) async {
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
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyHealthCareApp(),
      ),
    );
    await _settle(tester);

    // Not shown on the sign-in screen.
    expect(find.byType(CareNavigatorPanel), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'patient3@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _settle(tester);

    // The FAB is now floating on Home.
    expect(find.byIcon(Icons.smart_toy_outlined), findsWidgets);
    await tester.tap(find.byIcon(Icons.smart_toy_outlined).first);
    await _settle(tester);

    expect(find.byType(CareNavigatorPanel), findsOneWidget);
    expect(find.text('Care Navigator'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);

    // Ask something and get a navigation answer.
    await tester.enterText(
      find.widgetWithText(TextField, 'Ask about the app…'),
      'how do I book an appointment',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await _settle(tester);
    expect(find.textContaining('Appointments'), findsWidgets);

    // Close the panel → back to the FAB.
    await tester.tap(find.byIcon(Icons.close).first);
    await _settle(tester);
    expect(find.byType(CareNavigatorPanel), findsNothing);

    // Dismiss the FAB with its "×" → it tucks to a right-edge tab.
    expect(find.byType(CareNavigatorOverlay), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).first);
    await _settle(tester);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget); // the tab

    // Tapping the edge tab brings the FAB back.
    await tester.tap(find.byIcon(Icons.smart_toy_outlined));
    await _settle(tester);
    // FAB + its dismiss badge are both back.
    expect(find.byIcon(Icons.close), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
