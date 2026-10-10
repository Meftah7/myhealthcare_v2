import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/admin_workspace.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/admin/presentation/admin_workspace_screens.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Inter', 'assets/fonts/static/Inter-Regular.ttf'),
      ('Inter', 'assets/fonts/static/Inter-SemiBold.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-Medium.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-SemiBold.ttf'),
      ('NotoNaskhArabic', 'assets/fonts/NotoNaskhArabic.ttf'),
    ]) {
      await ui.loadFontFromList(
        await File(path).readAsBytes(),
        fontFamily: family,
      );
    }
  });
  for (final locale in ['en', 'ar']) {
    testWidgets(
      '$locale compact admin navigation restores five sections and preserves workspace routes',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final (c, _) = await seededContainer(
          prefs: {'ui.hasSeenOnboarding': true, 'ui.locale': locale},
        );
        await signInAs(c, 'admin@myhealth.demo');
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MyHealthCareApp(),
          ),
        );
        await settle(t);
        c.read(routerProvider).go('/admin/dashboard');
        await settle(t);
        final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
        final labels = AppLocalizations.of(
          t.element(find.byType(NavigationBar)),
        )!;
        expect(
          bar.destinations.cast<NavigationDestination>().map((d) => d.label),
          [
            labels.navDashboard,
            labels.navUsers,
            labels.navDepartments,
            labels.navBilling,
            labels.profile,
          ],
        );
        for (final (label, route) in [
          (labels.navUsers, AppRoutes.adminUsers),
          (labels.navDepartments, AppRoutes.adminDepartments),
          (labels.navBilling, AppRoutes.adminBilling),
          (labels.profile, AppRoutes.adminProfile),
          (labels.navDashboard, AppRoutes.adminDashboard),
        ]) {
          await t.tap(
            find
                .descendant(
                  of: find.byType(NavigationBar),
                  matching: find.text(label),
                )
                .last,
          );
          await settle(t);
          expect(
            c.read(routerProvider).routeInformationProvider.value.uri.path,
            route,
          );
        }
        for (final route in [
          '/admin/work',
          '/admin/clinic',
          '/admin/documents',
          '/admin/reports',
          '/admin/settings',
        ]) {
          c.read(routerProvider).go(route);
          await settle(t);
          expect(
            c.read(routerProvider).routeInformationProvider.value.uri.path,
            route,
          );
          expect(find.byType(NavigationBar), findsOneWidget);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      },
    );
    testWidgets(
      '$locale phone queue records an outcome and preserves source state',
      (t) async {
        t.view.physicalSize = const Size(320, 740);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final (c, db) = await seededContainer();
        await signInAs(c, 'admin@myhealth.demo');
        await db
            .into(db.feedbacks)
            .insert(
              FeedbacksCompanion.insert(
                id: 'phone-work',
                category: FeedbackCategory.generalFeedback,
                message: 'Service review',
              ),
            );
        final item = (await c.read(adminWorkspaceProvider).queue()).singleWhere(
          (w) => w.sourceId == 'phone-work',
        );
        final screen = ProviderContainer(
          parent: c,
          overrides: [
            adminWorkProvider.overrideWith((ref) => Stream.value([item])),
          ],
        );
        addTearDown(screen.dispose);
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: screen,
            child: MaterialApp(
              theme: AppTheme.light,
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: const TextScaler.linear(1.2)),
                child: child!,
              ),
              home: AdminUnifiedWorkScreen(filter: 'feedback', item: item.id),
            ),
          ),
        );
        await t.pumpAndSettle();
        final update = find.text(
          locale == 'ar' ? 'إسناد / تحديث' : 'Assign / update',
        );
        await t.drag(find.byType(ListView).first, const Offset(0, -600));
        await t.pumpAndSettle();
        await t.ensureVisible(update);
        await t.tap(update.hitTestable());
        await t.pumpAndSettle();
        final field = find.byType(TextFormField).last;
        await t.ensureVisible(field);
        await t.enterText(field, 'Follow-up information requested');
        final save = find.widgetWithText(
          FilledButton,
          locale == 'ar' ? 'حفظ' : 'Save',
        );
        await t.ensureVisible(save);
        await t.tap(save);
        await settle(t);
        expect(
          (await (db.select(
            db.adminWorkItems,
          )..where((w) => w.id.equals(item.id))).getSingle()).outcome,
          'Follow-up information requested',
        );
        expect(
          (await (db.select(
            db.feedbacks,
          )..where((f) => f.id.equals('phone-work'))).getSingle()).status,
          FeedbackStatus.open,
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      },
    );
  }
}
