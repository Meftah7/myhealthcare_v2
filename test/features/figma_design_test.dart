import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:myhealthcare/features/admin/presentation/admin_status_menu.dart';
import 'package:myhealthcare/features/auth/presentation/auth_scaffold.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_dashboard_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sessions.dart';

void main() {
  for (final role in ['staff', 'admin']) {
    for (final language in ['en', 'ar']) {
      testWidgets('$role dashboard fits 320dp and 200% in $language', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final (container, _) = await seededContainer();
        await signInAs(
          container,
          role == 'staff' ? 'staff1@myhealth.demo' : 'admin@myhealth.demo',
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: role == 'staff'
                  ? const StaffDashboardScreen()
                  : const AdminDashboardScreen(),
            ),
          ),
        );
        for (var i = 0; i < 24; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        expect(tester.takeException(), isNull);
        if (role == 'admin') {
          expect(tester.getSize(find.byType(AdminStatusMenu)).width, 48);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }

  test('task actions expose conflicts and preserve unsaved work', () async {
    final (container, db) = await seededContainer();
    await signInAs(container, 'staff1@myhealth.demo');
    await db
        .into(db.staffTasks)
        .insert(
          StaffTasksCompanion.insert(
            id: 'design-task',
            staffId: 'staff_01',
            title: 'Review follow-up',
            kind: TaskKind.followUpDue,
          ),
        );
    final ops = container.read(staffOpsProvider);
    final conflict = await ops.setTaskStatus(
      'design-task',
      TaskStatus.done,
      expectedVersion: 99,
    );
    expect(conflict.failureOrNull, isA<ConflictFailure>());
    var task = await (db.select(
      db.staffTasks,
    )..where((t) => t.id.equals('design-task'))).getSingle();
    expect(task.status, TaskStatus.open);
    final started = await ops.setTaskStatus(
      'design-task',
      TaskStatus.inProgress,
      expectedVersion: task.version,
    );
    expect(started.isOk, isTrue);
    task = await (db.select(
      db.staffTasks,
    )..where((t) => t.id.equals('design-task'))).getSingle();
    expect(task.status, TaskStatus.inProgress);
  });

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'auth header wraps at 320dp and 200% in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: AppTheme.light,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => AuthScaffold(
                  title: AppLocalizations.of(context)!.createAccount,
                  onBack: () {},
                  child: const SizedBox(height: 200),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(BackButtonIcon), findsOneWidget);
      },
    );
  }
}
