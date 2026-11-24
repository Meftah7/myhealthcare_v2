// The Book Appointment service card shows the doctor illustration in place
// of the calendar watermark (keeping its small calendar tile), the image is
// bundled and decodes, and tapping the card still opens booking.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/service_catalog/presentation/catalog_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

const _asset = 'assets/images/doctor-with-gitra';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  test('the doctor illustration is a bundled PNG that decodes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = (await rootBundle.load(_asset)).buffer.asUint8List();
    final frame = await (await ui.instantiateImageCodec(bytes)).getNextFrame();
    expect(frame.image.width, greaterThan(0));
    frame.image.dispose();
  });

  testWidgets('Book Appointment card: doctor illustration, opens booking', (
    tester,
  ) async {
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
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(c.dispose);
    await c
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
    );
    await _settle(tester);

    final card = find
        .ancestor(
          of: find.text('Book Appointment'),
          matching: find.byType(ServicePromotionCard),
        )
        .first;
    final art = find.descendant(
      of: card,
      matching: find.byKey(
        const ValueKey('service-illustration-book-appointment'),
      ),
    );
    expect(art, findsOneWidget);
    final image = tester.widget<Image>(
      find.descendant(of: art, matching: find.byType(Image)),
    );
    expect((image.image as AssetImage).assetName, _asset);
    // The small calendar tile stays; the big calendar watermark is gone.
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.calendar_month_outlined),
      ),
      findsOneWidget,
    );
    // Standing on the band's bottom edge, inside the card's right side.
    final cardRect = tester.getRect(card);
    final artRect = tester.getRect(art);
    expect(artRect.right, lessThan(cardRect.right));
    expect(artRect.center.dx, greaterThan(cardRect.center.dx));

    await tester.tap(find.text('Book Appointment').first);
    await _settle(tester);
    expect(
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
      AppRoutes.patientBookLanding,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
