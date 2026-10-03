import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/shell/app_shell.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

/// Select through the actual navigation controls, including the large-text menu.
Future<void> selectCompactDestination(WidgetTester tester, String label) async {
  if (find.byType(NavigationBar).evaluate().isNotEmpty) {
    await tester.tap(find.widgetWithText(NavigationDestination, label));
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
