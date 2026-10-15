import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../support/fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/features/workspace/workspace_repository.dart';
import 'package:myhealthcare/features/workspace/workspace_widgets.dart';
import 'package:myhealthcare/features/workspace/workspace_admin_screens.dart';
import 'package:myhealthcare/features/admin/presentation/user_management_screen.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_patients_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import '../support/sessions.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_WORKSPACE'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('workspace-capture')),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  File('preview/app-$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  image!.dispose();
}

Future<void> loadWorkspaceFonts() async {
  for (final (name, asset) in [
    ('Lexend', 'assets/fonts/static/Lexend-SemiBold.ttf'),
    ('Inter', 'assets/fonts/static/Inter-Regular.ttf'),
    ('NotoNaskhArabic', 'assets/fonts/NotoNaskhArabic.ttf'),
  ]) {
    final loader = FontLoader(name)..addFont(rootBundle.load(asset));
    await loader.load();
  }
  await loadMaterialIcons();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadWorkspaceFonts);
  testWidgets(
    'staff Chat navigation, preserved task links, schedule tabs and mobile theme',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (c, _) = (await tester.runAsync(
        () => seededContainer(prefs: {'ui.hasSeenOnboarding': true}),
      ))!;
      await tester.runAsync(() => signInAs(c, 'staff1@myhealth.demo'));
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('workspace-capture'),
          child: UncontrolledProviderScope(
            container: c,
            child: const MyHealthCareApp(),
          ),
        ),
      );
      await settle(tester);
      c.read(routerProvider).go(AppRoutes.staffDashboard);
      await settle(tester);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Quick Statistics'), findsOneWidget);
      expect(find.text('On duty'), findsNothing);
      expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
      await capture(tester, 'staff-mobile');
      c.read(routerProvider).go(AppRoutes.staffChat);
      await settle(tester);
      expect(c.read(routerProvider).state.uri.path, AppRoutes.staffChat);
      c.read(routerProvider).go(AppRoutes.staffTasks);
      await settle(tester);
      expect(c.read(routerProvider).state.uri.path, AppRoutes.staffTasks);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final (width, locale, scale, dark) in [
    (320.0, 'en', 2.0, false),
    (390.0, 'ar', 2.0, true),
    (768.0, 'en', 1.0, false),
    (1366.0, 'en', 1.0, true),
  ]) {
    testWidgets('admin reports adapt: $width / $locale / text $scale', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (c, _) = (await tester.runAsync(() => seededContainer()))!;
      await tester.runAsync(() => signInAs(c, 'admin@myhealth.demo'));
      await tester.runAsync(() => c.read(workspaceOverviewProvider.future));
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('workspace-capture'),
          child: UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              locale: Locale(locale),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: AdminClinicOverview(),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await capture(tester, 'admin-${width.toInt()}-$locale');
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final (name, email, screen) in <(String, String, Widget)>[
    ('patients', 'staff1@myhealth.demo', const StaffPatientsScreen()),
    ('users', 'admin@myhealth.demo', const UserManagementScreen()),
    ('feedback', 'admin@myhealth.demo', const WorkspaceFeedbackScreen()),
    ('rooms', 'admin@myhealth.demo', const ClinicRoomsScreen()),
  ]) {
    for (final locale in ['en', 'ar']) {
      testWidgets('$name supports narrow $locale and 200% text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final (c, _) = (await tester.runAsync(() => seededContainer()))!;
        await tester.runAsync(() => signInAs(c, email));
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('workspace-capture'),
            child: UncontrolledProviderScope(
              container: c,
              child: MaterialApp(
                theme: AppTheme.light,
                locale: Locale(locale),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(2)),
                  child: child!,
                ),
                home: screen,
              ),
            ),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        await capture(tester, '$name-$locale');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
