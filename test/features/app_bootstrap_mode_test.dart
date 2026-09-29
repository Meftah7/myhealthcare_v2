import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/app_environment.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<int> bootstrapAndCountUsers(AppMode mode) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = newTestDatabase();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        appModeProvider.overrideWithValue(mode),
      ],
    );
    try {
      await container.read(appBootstrapProvider.future);
      return (await db.select(db.users).get()).length;
    } finally {
      container.dispose();
      await db.close();
    }
  }

  test('demo bootstrap creates the synthetic accounts', () async {
    expect(await bootstrapAndCountUsers(AppMode.demo), greaterThan(0));
  });

  test('production bootstrap never creates demo accounts', () async {
    expect(await bootstrapAndCountUsers(AppMode.production), 0);
  });
}
