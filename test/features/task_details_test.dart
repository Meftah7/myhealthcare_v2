import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/task_workflow.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/tasks/presentation/task_detail_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import '../support/sessions.dart';

void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets('$locale task detail records waiting reason on a 320px phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await db
          .into(db.staffTasks)
          .insert(
            StaffTasksCompanion.insert(
              id: 'detail-phone',
              staffId: 'staff_01',
              patientId: const Value('patient_050'),
              title: 'Discuss result and follow-up plan',
              kind: TaskKind.unreviewedAbnormalLab,
            ),
          );
      final detail = await c
          .read(taskWorkflowProvider)
          .context('detail-phone', 'staff_01');
      final screenContainer = ProviderContainer(
        parent: c,
        overrides: [
          taskContextProvider('detail-phone').overrideWith((ref) => detail),
        ],
      );
      addTearDown(screenContainer.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: screenContainer,
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.2)),
              child: child!,
            ),
            home: const TaskDetailScreen(id: 'detail-phone'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final waiting = find.widgetWithText(
        OutlinedButton,
        locale == 'ar' ? 'انتظار' : 'Waiting',
      );
      await tester.scrollUntilVisible(
        waiting.hitTestable(),
        160,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('work-detail-detail-phone')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(waiting);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Awaiting patient callback; owner will review tomorrow',
      );
      final save = find.widgetWithText(
        FilledButton,
        locale == 'ar' ? 'حفظ' : 'Save',
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final task = await (db.select(
        db.staffTasks,
      )..where((t) => t.id.equals('detail-phone'))).getSingle();
      expect(task.status, TaskStatus.waiting);
      final history = await (db.select(
        db.taskHistory,
      )..where((h) => h.taskId.equals('detail-phone'))).get();
      expect(history.single.outcome, contains('Awaiting patient callback'));
      expect(history.single.afterJson, contains('reviewAt'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
