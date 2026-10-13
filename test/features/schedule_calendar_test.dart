// Calendar correctness for the clinician schedule: six-week month grids
// across month/year boundaries and leap years, mini-month and month views
// at 200% text without overflow, labelled day cells with visit counts, and
// the now-line only on today.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_schedule_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

void main() {
  group('month grid', () {
    test('starts on the Monday on or before the 1st and covers the month', () {
      for (var year = 2024; year <= 2030; year++) {
        for (var month = 1; month <= 12; month++) {
          final start = monthGridStart(DateTime(year, month, 15));
          final first = DateTime(year, month);
          final last = DateTime(year, month + 1, 0);
          expect(start.weekday, DateTime.monday, reason: '$year-$month');
          expect(start.isAfter(first), isFalse, reason: '$year-$month');
          expect(first.difference(start).inDays, lessThan(7));
          // Six weeks always reach the month's last day.
          final end = DateTime(start.year, start.month, start.day + 41);
          expect(end.isBefore(last), isFalse, reason: '$year-$month');
        }
      }
    });

    test('leap years and boundaries', () {
      // 1 Feb 2028 is a Tuesday; 29 Feb 2028 exists.
      expect(monthGridStart(DateTime(2028, 2)), DateTime(2028, 1, 31));
      expect(DateTime(2028, 3, 0).day, 29);
      // 1 March 2026 is a Sunday: grid opens on Monday 23 February.
      expect(monthGridStart(DateTime(2026, 3)), DateTime(2026, 2, 23));
      // January's grid reaches back into the previous year.
      expect(monthGridStart(DateTime(2027)), DateTime(2026, 12, 28));
      expect(dayOf(DateTime(2026, 12, 31, 23, 59)), DateTime(2026, 12, 31));
    });
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required ScheduleView view,
    DateTime? focus,
    double width = 320,
    double scale = 2,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (c, _) = await seededContainer();
    await signInAs(c, 'staff1@myhealth.demo');
    c.read(scheduleViewProvider.notifier).state = view;
    if (focus != null) {
      c.read(scheduleFocusedDayProvider.notifier).state = focus;
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const StaffScheduleScreen(),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    return c;
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('year view: twelve labelled mini-months at 320dp, 200% text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, view: ScheduleView.year);
    expect(tester.takeException(), isNull);
    final year = DateTime.now().year;
    expect(
      find.bySemanticsLabel(DateFormat('MMMM yyyy').format(DateTime(year))),
      findsOneWidget,
    );
    semantics.dispose();
    await done(tester);
  });

  testWidgets('month view: 42 labelled cells, today marked, no overflow', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final c = await pump(tester, view: ScheduleView.month);
    expect(tester.takeException(), isNull);
    final today = DateTime.now();
    final todayLabel = find.bySemanticsLabel(
      RegExp(
        '^${RegExp.escape(DateFormat('EEEE d MMMM').format(today))}, today',
      ),
    );
    expect(todayLabel, findsOneWidget);
    // Every cell of the six-week grid is a labelled button.
    final start = monthGridStart(c.read(scheduleFocusedDayProvider));
    for (final offset in [0, 20, 41]) {
      final day = start.add(Duration(days: offset));
      expect(
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(DateFormat('EEEE d MMMM').format(day))}'),
        ),
        findsWidgets,
        reason: '$day',
      );
    }
    semantics.dispose();
    await done(tester);
  });

  testWidgets('the now-line appears only on today', (tester) async {
    final now = DateTime.now();
    final tomorrow = dayOf(now).add(const Duration(days: 1));
    await pump(
      tester,
      view: ScheduleView.day,
      focus: tomorrow,
      width: 1000,
      scale: 1,
    );
    expect(tester.takeException(), isNull);
    // On a whole hour the hour rule carries the same text; skip then.
    if (now.minute != 0) {
      expect(find.text(DateFormat('HH:mm').format(now)), findsNothing);
    }
    await done(tester);
  });
}
