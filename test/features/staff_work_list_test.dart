import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/domain/entities/staff_task.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:myhealthcare/features/tasks/application/task_list.dart';
import 'package:myhealthcare/features/tasks/presentation/task_board_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

final now = DateTime(2026, 10, 9, 12);
StaffTask work(
  String id, {
  String owner = 'staff_01',
  String? cover,
  TaskStatus status = TaskStatus.open,
  WorkPriority priority = WorkPriority.routine,
  DateTime? due,
  double score = 0,
}) => StaffTask(
  id: id,
  staffId: owner,
  coverageStaffId: cover,
  title: 'Review $id',
  kind: TaskKind.unreviewedAbnormalLab,
  status: status,
  ruleScore: score,
  createdAt: now,
  dueAt: due,
  priority: priority,
);

void main() {
  test('views preserve ownership and groups put urgency above every score', () {
    final tasks = [
      work('upcoming', score: 1, due: now.add(const Duration(days: 1))),
      work('overdue', due: now.subtract(const Duration(days: 1))),
      work('today', due: now.add(const Duration(hours: 1))),
      work('urgent', priority: WorkPriority.urgent),
      work('covered', owner: 'staff_02', cover: 'staff_01'),
      work('private', owner: 'staff_03'),
      work('finished', status: TaskStatus.done),
      work('dismissed', status: TaskStatus.dismissed),
    ];
    List<String> view(StaffWorkView view, {String query = ''}) =>
        visibleStaffWork(
          tasks,
          staffId: 'staff_01',
          view: view,
          now: now,
          aiWeight: 1,
          query: query,
        ).map((t) => t.id).toList();
    expect(view(StaffWorkView.mine), [
      'urgent',
      'overdue',
      'today',
      'upcoming',
    ]);
    expect(view(StaffWorkView.covering), ['covered']);
    expect(view(StaffWorkView.completed), ['dismissed', 'finished']);
    expect(view(StaffWorkView.mine, query: 'TODAY'), ['today']);
    expect(
      taskTimeGroup(work('midnight', due: DateTime(2026, 10, 10)), now),
      TaskTimeGroup.upcoming,
    );
    expect(
      work('score', score: double.infinity).effectivePriority(double.nan),
      0,
    );
    expect(
      work(
        'score',
        score: 100,
      ).copyWith(aiPriorityScore: -100).effectivePriority(5),
      0,
    );
  });

  for (final locale in ['en', 'ar']) {
    testWidgets(
      '$locale task list fits 320px, filters completed work and preserves search',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final tasks = [
          work('urgent', priority: WorkPriority.urgent),
          work('finished', status: TaskStatus.done),
        ];
        final (c, _) = await seededContainer(
          overrides: [
            staffWorkProvider.overrideWith((ref) => Stream.value(tasks)),
          ],
        );
        await signInAs(c, 'staff1@myhealth.demo');
        final subscription = c.listen(staffWorkProvider, (_, _) {});
        addTearDown(subscription.close);
        await c.read(staffWorkProvider.future);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
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
              home: const TaskBoardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final urgent = find.text('Review urgent');
        await tester.scrollUntilVisible(
          urgent,
          150,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('staff-work-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(urgent, findsOneWidget);
        expect(find.text('Review finished'), findsNothing);
        expect(tester.takeException(), isNull);
        final completed = find.widgetWithText(
          ChoiceChip,
          locale == 'ar' ? 'المكتمل' : 'Completed',
        );
        await tester.scrollUntilVisible(
          completed.hitTestable(),
          -150,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('staff-work-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(completed);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'finished');
        final searchController = tester
            .widget<TextField>(find.byType(TextField).first)
            .controller!;
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final finished = find.text('Review finished');
        await tester.scrollUntilVisible(
          finished,
          150,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('staff-work-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(finished, findsOneWidget);
        expect(find.text('Review urgent'), findsNothing);
        expect(searchController.text, 'finished');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
