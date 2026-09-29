/// Test helpers: a seeded app container, and acting as a seeded account in
/// it.
///
/// Repositories authorize every call against the signed-in principal, so a
/// test reads or writes data *as someone* — the same way the app does.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_database.dart';

/// A container over a freshly seeded in-memory database, torn down with the
/// test.
Future<(ProviderContainer, AppDatabase)> seededContainer({
  List<Override> overrides = const [],
  Map<String, Object> prefs = const {},
}) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues(prefs);
  final shared = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(shared),
      appDatabaseProvider.overrideWithValue(db),
      ...overrides,
    ],
  );
  addTearDown(db.close);
  addTearDown(container.dispose);
  return (container, db);
}

/// Sign out whoever is signed in, then sign in as [email] with the demo
/// password.
Future<void> signInAs(ProviderContainer container, String email) async {
  final session = container.read(sessionProvider.notifier);
  if (container.read(sessionProvider).isAuthenticated) await session.logout();
  final result = await session.login(
    email: email,
    password: Seeder.demoPassword,
  );
  if (result.isErr) {
    throw StateError('Sign-in as $email failed: ${result.failureOrNull}');
  }
}
