// The "<" / ">" buttons under the home Quick tools and Services rows show
// only for mouse / trackpad users: hidden on phones and tablets, shown on
// desktop platforms, and following the input actually used on a
// touchscreen laptop.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/service_catalog/presentation/catalog_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

/// Signs the demo patient in and shows Home on a phone-width view, tall
/// enough that the lazily built home list builds both rows.
Future<void> _home(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );
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
  await container
      .read(sessionProvider.notifier)
      .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _tearDownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

final _nextShortcuts = find.byTooltip('Next shortcuts');
final _nextServices = find.byTooltip('Next services');
final _previousServices = find.byTooltip('Previous services');

ScrollPosition _carouselPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(ServiceCarousel),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

void main() {
  testWidgets(
    'phones and tablets: no arrows, the rows are swiped',
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
    (tester) async {
      await _home(tester);
      expect(find.byType(ServiceCarousel), findsOneWidget);
      expect(_nextShortcuts, findsNothing);
      expect(_nextServices, findsNothing);
      expect(find.byKey(const ValueKey('scroll-arrows')), findsNothing);
      await _tearDownApp(tester);
    },
  );

  testWidgets(
    'laptops and PCs: arrows on both rows; Services moves a card at a time',
    variant: const TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }),
    (tester) async {
      await _home(tester);
      expect(_nextShortcuts, findsOneWidget);
      expect(_nextServices, findsOneWidget);
      expect(_previousServices, findsOneWidget);

      await tester.ensureVisible(_nextServices);
      await _settle(tester);
      final position = _carouselPosition(tester);
      expect(position.pixels, 0);

      // Clicked with a mouse, so the arrows stay.
      await tester.tap(_nextServices, kind: PointerDeviceKind.mouse);
      await _settle(tester);
      final card = tester.getSize(find.byType(ServicePromotionCard).first);
      expect(position.pixels, moreOrLessEquals(card.width + 12));

      await tester.tap(_previousServices, kind: PointerDeviceKind.mouse);
      await _settle(tester);
      expect(position.pixels, 0);

      await _tearDownApp(tester);
    },
  );

  testWidgets(
    'a touchscreen laptop: touching hides the arrows, the mouse brings them '
    'back',
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
    (tester) async {
      await _home(tester);
      expect(_nextServices, findsOneWidget);

      // A finger on the screen.
      await tester.tapAt(const Offset(195, 300));
      await _settle(tester);
      expect(_nextServices, findsNothing);
      expect(_nextShortcuts, findsNothing);

      // The mouse moves again.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(10, 10));
      await mouse.moveTo(const Offset(195, 400));
      await _settle(tester);
      expect(_nextServices, findsOneWidget);
      expect(_nextShortcuts, findsOneWidget);

      await _tearDownApp(tester);
    },
  );
}
