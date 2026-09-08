import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Render immediately — the opening splash is up within one frame. The
  // synthetic dataset is populated / migrated in the background via
  // [appBootstrapProvider]; the router keeps everyone on the splash until it
  // finishes, so nothing reads half-seeded data.
  container.read(appBootstrapProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
}
