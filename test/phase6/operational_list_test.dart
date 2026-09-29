import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/presentation/operational_list.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

class _Work {
  const _Work(this.id, this.title, this.status);
  final String id;
  final String title;
  final String status;
}

Widget _host({required Size size}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: Scaffold(
      body: SizedBox(
        width: size.width,
        child: OperationalList<_Work>(
          items: const [
            _Work('1', 'Alpha result', 'open'),
            _Work('2', 'Beta result', 'closed'),
          ],
          itemId: (item) => item.id,
          searchText: (item) => '${item.title} ${item.status}',
          searchHint: 'Search work',
          allLabel: 'All',
          empty: const Text('No matches'),
          columns: [
            OperationalColumn(label: 'Work', value: (item) => item.title),
            OperationalColumn(label: 'Status', value: (item) => item.status),
          ],
          filters: [
            OperationalFilter(
              label: 'Status',
              options: const {'open': 'Open', 'closed': 'Closed'},
              matches: (item, value) => item.status == value,
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('search narrows the operational list', (tester) async {
    await tester.pumpWidget(_host(size: const Size(390, 800)));
    expect(find.text('Alpha result'), findsOneWidget);
    expect(find.text('Beta result'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'beta');
    await tester.pump();

    expect(find.text('Alpha result'), findsNothing);
    expect(find.text('Beta result'), findsOneWidget);
  });

  testWidgets('uses a table on wide screens and cards on phones', (
    tester,
  ) async {
    await tester.pumpWidget(_host(size: const Size(1000, 800)));
    expect(find.byType(DataTable), findsOneWidget);

    await tester.pumpWidget(_host(size: const Size(390, 800)));
    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(Card), findsNWidgets(2));
  });
}
