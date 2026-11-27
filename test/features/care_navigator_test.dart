// The Care Navigator: emergency guard, offline navigation replies, and the
// floating mascot launcher — open, dock, restore and change sides.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/app_environment.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/ui/patient/patient_bottom_navigation.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/ai_chat/application/assistant_actions.dart';
import 'package:myhealthcare/features/ai_chat/application/assistant_policy.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/ai_chat/presentation/care_navigator_mascot.dart';
import 'package:myhealthcare/features/ai_chat/presentation/care_navigator_panel.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/patient_home/presentation/patient_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

const _fab = ValueKey('care-nav-fab');
const _dock = ValueKey('care-nav-dock');
const _head = ValueKey('care-nav-head');
const _fullBodyAsset = 'assets/images/care_navigator_full_body.png';
const _headLeftAsset = 'assets/images/care_navigator_head_left.png';
const _headRightAsset = 'assets/images/care_navigator_head_right.png';

/// The asset names of every image currently on screen.
Set<String> _imageAssets(WidgetTester tester) => {
  for (final image in tester.widgetList<Image>(find.byType(Image)))
    if (image.image case ResizeImage(
      imageProvider: AssetImage(:final assetName),
    ))
      assetName,
};

Size _viewSize(WidgetTester tester) =>
    tester.view.physicalSize / tester.view.devicePixelRatio;

/// Boots the app on a phone-sized view and signs the demo patient in through
/// the UI.
Future<ProviderContainer> _signIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
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
  expect(find.byKey(_fab), findsNothing);
  expect(find.byType(CareNavigatorPanel), findsNothing);

  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'patient3@myhealth.demo',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    Seeder.demoPassword,
  );
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await passMfa(tester);
  await _settle(tester);
  return container;
}

Future<void> _tearDownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // flutter_secure_storage has no test implementation; make it a no-op so
    // the AI key store resolves to "no key" instead of stalling the reply.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  group('offline responder', () {
    late ProviderContainer container;

    setUp(() async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(sessionProvider.notifier)
          .login(
            email: 'patient3@myhealth.demo',
            password: Seeder.demoPassword,
          );
    });

    Future<String> ask(String q) async {
      container.read(careNavigatorProvider.notifier).send(q);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
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
      expect(
        await ask('how do I book an appointment?'),
        contains('Book Appointment'),
      );
      expect(await ask('where are my lab results?'), contains('Records'));
      expect(await ask('I want to pay my bill'), contains('Payments'));
      expect(await ask('where is nutrition?'), contains('Nutrition'));
      // Personal diet advice is a medical question: refused.
      expect(
        await ask('how many calories should I eat?'),
        AssistantText.medical(false),
      );
      expect(await ask('change my password'), contains('Profile'));
    });

    test(
      'a symptom question is declined, with the way to a clinician',
      () async {
        final reply = await ask('what should I take for a fever?');
        expect(reply, AssistantText.medical(false));
        expect(
          container.read(careNavigatorProvider).messages.last.actions,
          contains(AssistantAction.bookAppointment),
        );
      },
    );

    test('reset restores just the greeting', () async {
      await ask('hello');
      expect(
        container.read(careNavigatorProvider).messages.length,
        greaterThan(1),
      );
      container.read(careNavigatorProvider.notifier).reset();
      expect(container.read(careNavigatorProvider).messages, hasLength(1));
    });
  });

  test(
    'production navigator is the labelled offline guide, never live AI',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          appModeProvider.overrideWithValue(AppMode.production),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(careNavigatorProvider.notifier)
          .send('how do I book an appointment?');

      // No provider is called from the device in any mode: the chat header
      // reports "On-device assistant · no live AI" and replies are the deterministic
      // navigation guide, consistent with demo mode.
      expect(await container.read(careNavigatorLiveProvider.future), isFalse);
      final reply = container.read(careNavigatorProvider).messages.last.text;
      expect(
        reply,
        AssistantText.navigation(AssistantAction.openAppointments, false),
      );
    },
  );

  test('the three mascot images are bundled PNGs that decode', () async {
    for (final asset in [_fullBodyAsset, _headLeftAsset, _headRightAsset]) {
      // The web build writes asset files under their URL-encoded names (a
      // space becomes a literal "%20" in the filename), which static hosts
      // such as GitHub Pages then 404. Keep names URL-safe.
      expect(asset, matches(RegExp(r'^[A-Za-z0-9_./-]+$')), reason: asset);
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List();
      // PNG signature.
      expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1254, reason: asset);
      expect(frame.image.height, 1254, reason: asset);
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets(
    'the mascot button opens chat; × docks it; the head restores it',
    (tester) async {
      final container = await _signIn(tester);
      final view = _viewSize(tester);

      // The floating mascot button sits in the lower-right, above the bottom
      // navigation bar.
      expect(find.byKey(_fab), findsOneWidget);
      expect(find.byKey(_head), findsNothing);
      final fabRect = tester.getRect(find.byKey(_fab));
      expect(fabRect.size, const Size(56, 56));
      expect(fabRect.center.dx, greaterThan(view.width / 2));
      final nav = tester.getRect(find.byType(PatientBottomNavigation));
      expect(fabRect.bottom, lessThan(nav.top), reason: 'clear of the nav');
      expect(fabRect.bottom, greaterThan(nav.top - 60), reason: 'near it');
      expect(_imageAssets(tester), {_fullBodyAsset});

      // Accessible labels on the button and its ×.
      expect(find.bySemanticsLabel('Open Care Navigator'), findsOneWidget);
      expect(find.bySemanticsLabel('Hide Care Navigator'), findsOneWidget);
      expect(tester.getSize(find.byKey(_dock)), const Size(48, 48));

      await tester.tap(find.byKey(_fab));
      await _settle(tester);

      expect(find.byType(CareNavigatorPanel), findsOneWidget);
      expect(find.text('Care Navigator'), findsOneWidget);
      expect(find.text('On-device assistant · no live AI'), findsOneWidget);

      // Ask something and get a navigation answer.
      await tester.enterText(
        find.widgetWithText(TextField, 'Ask about the app…'),
        'how do I book an appointment',
      );
      await tester.pump();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await _settle(tester);
      expect(find.textContaining('Book Appointment'), findsWidgets);
      final messages = container.read(careNavigatorProvider).messages;
      expect(messages.length, greaterThan(1));

      // Close the panel → back to the button.
      await tester.tap(find.byIcon(Icons.close).first);
      await _settle(tester);
      expect(find.byType(CareNavigatorPanel), findsNothing);
      expect(find.byKey(_fab), findsOneWidget);

      // × docks the mascot on its own (right) side: just the head, flush with
      // the right edge, with no button behind it.
      await tester.tap(find.byKey(_dock));
      await _settle(tester);
      expect(find.byKey(_fab), findsNothing);
      expect(find.byKey(_head), findsOneWidget);
      expect(tester.getRect(find.byKey(_head)).right, view.width);
      expect(_imageAssets(tester), {_headRightAsset});
      expect(find.bySemanticsLabel('Show Care Navigator'), findsOneWidget);

      // Docking keeps the conversation.
      expect(container.read(careNavigatorProvider).messages, same(messages));

      // Tapping the head brings the button back on the right — it does not
      // open the chat by itself.
      await tester.tap(find.byKey(_head));
      await _settle(tester);
      expect(find.byKey(_head), findsNothing);
      expect(find.byType(CareNavigatorPanel), findsNothing);
      expect(
        tester.getRect(find.byKey(_fab)).center.dx,
        greaterThan(view.width / 2),
      );

      // …and a separate tap opens the same conversation.
      await tester.tap(find.byKey(_fab));
      await _settle(tester);
      expect(find.byType(CareNavigatorPanel), findsOneWidget);
      expect(container.read(careNavigatorProvider).messages, same(messages));

      await _tearDownApp(tester);
    },
  );

  testWidgets('the launcher changes sides by dragging, docked or floating', (
    tester,
  ) async {
    final container = await _signIn(tester);
    final prefs = container.read(sharedPreferencesProvider);
    final view = _viewSize(tester);

    // Starts on the right.
    expect(container.read(careNavPlacementProvider).onRight, isTrue);

    // Drag the button across to the left half of the screen and release.
    await tester.drag(find.byKey(_fab), const Offset(-500, -120));
    await _settle(tester);

    expect(
      container.read(careNavPlacementProvider).onRight,
      isFalse,
      reason: 'snapped to the near side',
    );
    expect(prefs.getString('ui.careNav.placement'), isNotNull);

    // × → the head docks flush on the left edge, peeking right.
    await tester.tap(find.byKey(_dock));
    await _settle(tester);
    expect(tester.getRect(find.byKey(_head)).left, 0);
    expect(_imageAssets(tester), {_headLeftAsset});

    // Restoring from the left keeps the button on the left.
    await tester.tap(find.byKey(_head));
    await _settle(tester);
    expect(
      tester.getRect(find.byKey(_fab)).center.dx,
      lessThan(view.width / 2),
    );

    // Dock again, then drag the head across: it snaps to the right edge and
    // turns to peek in from there.
    await tester.tap(find.byKey(_dock));
    await _settle(tester);
    await tester.drag(find.byKey(_head), Offset(view.width * 0.7, 0));
    await _settle(tester);
    expect(container.read(careNavPlacementProvider).onRight, isTrue);
    expect(tester.getRect(find.byKey(_head)).right, view.width);
    expect(_imageAssets(tester), {_headRightAsset});

    // A short drag that doesn't cross the middle stays on the same side.
    await tester.drag(find.byKey(_head), const Offset(-60, 0));
    await _settle(tester);
    expect(tester.getRect(find.byKey(_head)).right, view.width);

    // Restoring from the right brings the button back on the right.
    await tester.tap(find.byKey(_head));
    await _settle(tester);
    expect(
      tester.getRect(find.byKey(_fab)).center.dx,
      greaterThan(view.width / 2),
    );

    await _tearDownApp(tester);
  });

  testWidgets('taps away from the launcher reach the page beneath', (
    tester,
  ) async {
    await _signIn(tester);

    bool reaches(Offset point, Finder target) {
      final hits = tester.hitTestOnBinding(point).path.map((e) => e.target);
      final targets = target.evaluate().map((e) => e.renderObject).toSet();
      return hits.any(targets.contains);
    }

    final home = find.byType(PatientHomeScreen);
    final nav = find.byType(PatientBottomNavigation);
    final fab = tester.getRect(find.byKey(_fab));
    final dock = tester.getRect(find.byKey(_dock));

    // The dashboard, the bottom navigation, and the empty corners of the
    // button's box (outside the circle and the × target) all reach the page.
    expect(reaches(tester.getCenter(home), home), isTrue);
    expect(reaches(tester.getCenter(nav), nav), isTrue);
    expect(reaches(fab.bottomLeft + const Offset(-20, 20), home), isTrue);
    expect(reaches(fab.topLeft - const Offset(20, 20), home), isTrue);
    // The launcher's own targets do not.
    expect(reaches(fab.center, home), isFalse);
    expect(reaches(dock.center, home), isFalse);

    // Same once docked: only the head itself is a target.
    await tester.tap(find.byKey(_dock));
    await _settle(tester);
    final head = tester.getRect(find.byKey(_head));
    expect(reaches(head.center, home), isFalse);
    expect(reaches(head.centerLeft + const Offset(-12, 0), home), isTrue);
    expect(reaches(head.topCenter + const Offset(0, -12), home), isTrue);

    await _tearDownApp(tester);
  });

  testWidgets(
    'the chat header shows the launcher mascot, and the greeting follows the '
    'app language',
    (tester) async {
      final container = await _signIn(tester);
      const en =
          'Hi! Ask me how to find something in the app, or attach a document '
          '(PDF, Word or text) to get a short summary.';
      const ar =
          'مرحبًا! اسألني عن أي مكان في التطبيق، أو أرفق مستندًا (PDF أو Word '
          'أو نص) لتحصل على ملخص قصير.';

      // The launcher and the open panel show the same avatar.
      expect(
        find.descendant(
          of: find.byKey(_fab),
          matching: find.byType(MascotImage),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(_fab));
      await _settle(tester);
      final header = find.descendant(
        of: find.byType(CareNavigatorPanel),
        matching: find.byType(CareNavigatorAvatar),
      );
      expect(header, findsOneWidget);
      expect(_imageAssets(tester), {_fullBodyAsset});

      // Short, plain greeting in English…
      expect(find.text(en), findsOneWidget);
      expect(find.textContaining('👋'), findsNothing);

      // …and in Arabic as soon as the language changes, even mid-chat.
      await container.read(localeProvider.notifier).set(const Locale('ar'));
      await _settle(tester);
      expect(find.text(ar), findsOneWidget);
      expect(find.text(en), findsNothing);

      // Restarting the conversation keeps it in Arabic.
      container.read(careNavigatorProvider.notifier).reset();
      await _settle(tester);
      expect(find.text(ar), findsOneWidget);

      await _tearDownApp(tester);
    },
  );
}
