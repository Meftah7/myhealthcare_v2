import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/shared_mode.dart';
import 'core/di.dart';
import 'core/observability/operational_metrics.dart';
import 'data/remote/shared_client.dart';
import 'data/sync/idempotency.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Shared-server mode runs the same app on server repositories (see
  // lib/app/shared_mode.dart); nothing falls back to local data.
  final shared = kSharedApiOrigin.isEmpty
      ? null
      : SharedClient(kSharedApiOrigin, endSessionOnForbidden: false);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (shared != null) ...sharedModeOverrides(shared),
    ],
  );
  if (shared != null) bindSharedSession(container);

  final metrics = container.read(operationalMetricsProvider);
  recordSafely(metrics, OperationalSignal.sessionStarted);
  IdempotencyGuard.onDuplicatePrevented = (scope) => recordSafely(
    metrics,
    OperationalSignal.duplicatePrevented,
    workflow: scope,
  );

  final previousFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    recordSafely(
      metrics,
      OperationalSignal.appCrash,
      workflow: 'flutter.framework',
      reasonCode: 'uncaught_error',
    );
    previousFlutterError?.call(details);
  };

  // Async errors outside the framework (futures, timers).
  final previousPlatformError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    recordSafely(
      metrics,
      OperationalSignal.appCrash,
      workflow: 'platform.async',
      reasonCode: 'uncaught_error',
    );
    return previousPlatformError?.call(error, stack) ?? false;
  };

  // Render immediately. Bootstrap opens/migrates storage and, in demo mode
  // only, creates synthetic data. The router holds on the splash until it
  // finishes, so nothing reads partially initialized data.
  container.read(appBootstrapProvider);
  // Missed visits keep being marked while the app is open (local data only;
  // the shared server owns its own appointment states).
  if (shared == null) container.read(noShowSweepProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
}
