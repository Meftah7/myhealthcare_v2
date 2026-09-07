// Admin dashboard rebuild: the Quick actions grid — broadcast, create invoice,
// billing overview, all-appointments.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/admin/application/admin_providers.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
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

  testWidgets('admin dashboard shows Quick actions', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    expect(find.text('Broadcast'), findsOneWidget);
    expect(find.text('Create invoice'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('broadcast reaches every patient', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Broadcast'));
    await _settle(tester);
    expect(find.text('Broadcast a notification'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'Clinic closed Friday',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Message'),
      'The clinic is closed this Friday for a public holiday.',
    );
    await tester.pump();
    final send = find.widgetWithText(FilledButton, 'Send');
    await tester.ensureVisible(send);
    await tester.pump();
    await tester.tap(send);
    await _settle(tester);
    expect(find.textContaining('Sent to'), findsOneWidget);

    // A seeded patient now has the notification.
    final patients = await container
        .read(userRepositoryProvider)
        .byRole(UserRole.patient);
    final someone = patients.valueOrNull!.first.id;
    final notes = await container
        .read(notificationRepositoryProvider)
        .forRecipient(someone);
    expect(
      notes.valueOrNull!.any((n) => n.title == 'Clinic closed Friday'),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('create-invoice sheet opens from the dashboard', (tester) async {
    tester.view.physicalSize = const Size(1400, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Create invoice'));
    await _settle(tester);
    expect(find.text('Create an invoice'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Amount (BD, before tax)'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  test('admin issueInvoice raises a bill the patient can see', () async {
    final db = newTestDatabase();
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).login(
          email: 'admin@myhealth.demo',
          password: Seeder.demoPassword,
        );

    final patients = (await container
            .read(userRepositoryProvider)
            .byRole(UserRole.patient))
        .valueOrNull!;
    final target = patients.first;
    final before = (await container
            .read(billingRepositoryProvider)
            .forPatient(target.id))
        .valueOrNull!
        .length;

    final r = await container.read(adminActionsProvider).issueInvoice(
          patientId: target.id,
          subtotal: 80,
          notes: 'Consultation',
        );
    expect(r.isOk, isTrue);

    final after = (await container
            .read(billingRepositoryProvider)
            .forPatient(target.id))
        .valueOrNull!;
    expect(after.length, before + 1);
    expect(after.first.totalAmount, closeTo(88.0, 0.01));
    expect(after.first.status, InvoiceStatus.pending);
  });

  testWidgets('billing overview lists invoices and marks one paid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Billing'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Billing'), findsOneWidget);
    expect(find.textContaining('BD '), findsWidgets);

    // Filter to open invoices and pay the first one.
    await tester.tap(find.widgetWithText(FilterChip, 'Open'));
    await _settle(tester);
    final payButtons = find.widgetWithText(FilledButton, 'Mark paid');
    if (payButtons.evaluate().isNotEmpty) {
      await tester.tap(payButtons.first);
      await _settle(tester);
      expect(find.textContaining('marked paid'), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('all-appointments screen renders with filters', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Appointments'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Appointments'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Completed'));
    await _settle(tester);
    expect(find.byType(FilterChip), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
