// The Services cards show their illustrations in place of the old icon
// watermark: each bundled PNG decodes, sits toward the bottom-end of its
// banner clear of the icon tile, stays below a "Future work" badge, and the
// cards still open what they did before.

import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/ui/patient/patient_components.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/service_catalog/domain/patient_catalog.dart';
import 'package:myhealthcare/features/service_catalog/presentation/catalog_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

/// Card id → its illustration asset.
const _art = {
  'book-appointment': 'assets/images/book-appointment-illustration.png',
  'explain-report': 'assets/images/explain-report-illustration.png',
  'virtual-care': 'assets/images/virtual-care-illustration.png',
  'home-visits': 'assets/images/home-visits-illustration.png',
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

/// Signs the demo patient in and opens the full Services page, which lists
/// every service card, at a narrow phone width.
Future<ProviderContainer> _services(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 2400);
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
  c.read(routerProvider).go(AppRoutes.patientServices);
  await _settle(tester);
  return c;
}

Finder _card(String id) => find.byWidgetPredicate(
  (w) => w is ServicePromotionCard && w.item.id == id,
  description: 'service card $id',
);

String _path(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

void main() {
  test('every service illustration is a bundled PNG that decodes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final asset in _art.values) {
      final bytes = (await rootBundle.load(asset)).buffer.asUint8List();
      expect(bytes.sublist(0, 4), [137, 80, 78, 71], reason: asset);
      final frame = await (await ui.instantiateImageCodec(
        bytes,
      )).getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: asset);
      frame.image.dispose();
    }
  });

  testWidgets('each card shows its illustration in the right place', (
    tester,
  ) async {
    await _services(tester);
    for (final MapEntry(key: id, value: asset) in _art.entries) {
      final card = _card(id);
      await tester.ensureVisible(card);
      await tester.pump();
      final art = find.byKey(ValueKey('service-illustration-$id'));
      expect(art, findsOneWidget, reason: id);
      expect(
        (tester.widget<Image>(art).image as AssetImage).assetName,
        asset,
        reason: id,
      );

      final cardRect = tester.getRect(card);
      final artRect = tester.getRect(art);
      // Toward the end (right), inside the card.
      expect(artRect.right, lessThan(cardRect.right), reason: id);
      expect(artRect.center.dx, greaterThan(cardRect.center.dx), reason: id);

      // Clear of the small icon tile at the top-start.
      final tile = tester.getRect(
        find.descendant(of: card, matching: find.byIcon(_iconOf(id))).first,
      );
      expect(artRect.left, greaterThanOrEqualTo(tile.right), reason: id);

      // Book Appointment keeps to the right 60% of its banner.
      if (id == 'book-appointment') {
        expect(
          artRect.left,
          greaterThanOrEqualTo(cardRect.left + cardRect.width * 0.4 - 0.5),
          reason: id,
        );
      }

      // Below the "Future work" badge, never over it.
      final badge = find.descendant(
        of: card,
        matching: find.byType(FutureWorkBadge),
      );
      if (id == 'virtual-care' || id == 'home-visits') {
        expect(badge, findsOneWidget, reason: id);
        expect(
          artRect.top,
          greaterThanOrEqualTo(tester.getRect(badge).bottom),
          reason: id,
        );
      }
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the cards still open what they did before', (tester) async {
    final c = await _services(tester);

    Future<void> open(String id) async {
      // The row builds its cards lazily and keeps its scroll position:
      // start from its beginning, then scroll sideways to the card.
      final row = find
          .descendant(
            of: find.byType(ServiceCarousel).first,
            matching: find.byType(Scrollable),
          )
          .first;
      tester.state<ScrollableState>(row).position.jumpTo(0);
      await tester.pump();
      await tester.scrollUntilVisible(_card(id), 120, scrollable: row);
      await tester.ensureVisible(_card(id));
      await tester.pump();
      await tester.tap(_card(id));
      await _settle(tester);
    }

    await open('book-appointment');
    expect(_path(c), AppRoutes.patientBookLanding);

    c.read(routerProvider).go(AppRoutes.patientServices);
    await _settle(tester);
    await open('virtual-care');
    expect(_path(c), '${AppRoutes.patientBookLanding}?mode=virtual');

    c.read(routerProvider).go(AppRoutes.patientServices);
    await _settle(tester);
    await open('home-visits');
    expect(_path(c), AppRoutes.patientHomeVisit);

    // Explain a Report goes straight to choosing a document (no form).
    final picker = _Picker();
    final original = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = original);
    c.read(routerProvider).go(AppRoutes.patientServices);
    await _settle(tester);
    await open('explain-report');
    expect(picker.allowed, ['pdf', 'docx', 'doc', 'txt']);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

/// Records that a PDF was asked for; the patient then cancels.
class _Picker extends FilePickerPlatform {
  List<String>? allowed;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    allowed = allowedExtensions;
    return null;
  }
}

IconData _iconOf(String id) => switch (id) {
  'book-appointment' => PatientCatalog.bookAppointment.icon,
  'explain-report' => PatientCatalog.explainReport.icon,
  'virtual-care' => PatientCatalog.virtualCare.icon,
  _ => PatientCatalog.homeVisits.icon,
};
