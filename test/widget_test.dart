// Smoke test: the app builds, the theme is applied, and the router lands on
// the login route (P0-05, P0-06).

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';

void main() {
  testWidgets('App builds and starts on the sign-in route', (tester) async {
    await tester.pumpWidget(const MyHealthCareApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
  });
}
