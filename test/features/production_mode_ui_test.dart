import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/app_environment.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('production login does not expose demo credentials', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appModeProvider.overrideWithValue(AppMode.production),
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const MyHealthCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo accounts'), findsNothing);
    expect(find.textContaining('@myhealth.demo'), findsNothing);
    expect(find.textContaining('Password for all accounts'), findsNothing);
  });
}
