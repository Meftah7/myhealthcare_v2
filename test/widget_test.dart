// Smoke test: the app builds with the DESIGN.md theme applied (P0-05).

import 'package:flutter_test/flutter_test.dart';

import 'package:myhealthcare/main.dart';

void main() {
  testWidgets('App builds and shows the placeholder screen', (tester) async {
    await tester.pumpWidget(const MyHealthCareApp());

    expect(find.text('MyHealth Care'), findsOneWidget);
    expect(find.text('Screen title'), findsOneWidget);
    expect(find.text('High risk'), findsOneWidget);
  });
}
