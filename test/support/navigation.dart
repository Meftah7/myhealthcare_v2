import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/shell/app_shell.dart';
import 'package:myhealthcare/core/ui/patient/patient_components.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

/// Select through the actual navigation controls, including the large-text menu.
Future<void> selectCompactDestination(WidgetTester tester, String label) async {
  if (find.byType(NavigationBar).evaluate().isNotEmpty) {
    final direct = find.widgetWithText(NavigationDestination, label);
    if (direct.evaluate().isNotEmpty) {
      await tester.tap(direct);
    } else {
      await tester.tap(find.widgetWithText(NavigationDestination, 'More'));
      await _settle(tester);
      final destination = find.widgetWithText(ListTile, label).last;
      await tester.ensureVisible(destination);
      await tester.tap(destination);
    }
  } else {
    await tester.tap(
      find
          .descendant(
            of: find.byType(CompactNavigation),
            matching: find.byType(ListTile),
          )
          .first,
    );
    await _settle(tester);
    final destination = find.widgetWithText(ListTile, label).last;
    await tester.ensureVisible(destination);
    await tester.tap(destination);
  }
  await _settle(tester);
}

/// Read rendered labels rather than assuming that the compact layout is a bar.
Future<List<String>> compactNavigationLabels(WidgetTester tester) async {
  final menu = find.byType(NavigationBar).evaluate().isEmpty;
  if (menu) {
    await tester.tap(
      find
          .descendant(
            of: find.byType(CompactNavigation),
            matching: find.byType(ListTile),
          )
          .first,
    );
    await _settle(tester);
  }
  final labels = tester
      .widgetList<Text>(
        find.descendant(
          of: menu ? find.byType(BottomSheet) : find.byType(NavigationBar),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data ?? '')
      .toList();
  if (menu) {
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await _settle(tester);
  }
  return labels;
}

/// Opens a Home "Quick Access" tile by its catalogue id (e.g. 'records',
/// 'nutrition', 'profile', 'billing'), going to Home first.
Future<void> openQuickAccess(WidgetTester tester, String id) async {
  final tile = find.byKey(ValueKey('catalog-$id'));
  if (tile.evaluate().isEmpty) {
    final home = find.text('Home');
    if (home.evaluate().isNotEmpty) {
      await tester.tap(home.first);
      await _settle(tester);
    }
  }
  await tester.scrollUntilVisible(
    tile,
    300,
    // The Home page's own list — not the navigation rail's scroll view.
    scrollable: find
        .descendant(
          of: find.byType(PatientPageScaffold),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await _settle(tester);
  await tester.tap(tile);
  await _settle(tester);
}

/// Opens a patient drawer row by key suffix (e.g. 'profile', 'billing',
/// 'preferences') from the current shell page.
Future<void> openDrawerItem(WidgetTester tester, String id) async {
  await tester.tap(find.byTooltip('Open navigation menu').first);
  await _settle(tester);
  final row = find.byKey(ValueKey('drawer-$id'));
  // The drawer list is lazy: scroll it (not the page) to build the row.
  await tester.scrollUntilVisible(
    row,
    120,
    scrollable: find
        .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tap(row);
  await _settle(tester);
}
