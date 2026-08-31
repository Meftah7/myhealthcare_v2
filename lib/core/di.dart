/// Dependency-injection registry (task P0-07).
///
/// Central home for app-wide Riverpod providers. Feature providers live with
/// their feature; this file holds cross-cutting singletons (platform services,
/// database, repositories) that many features share. Repositories are
/// registered here in Phase 1 (P1-18).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key–value store for lightweight local state (session, settings).
///
/// Overridden in `main()` once [SharedPreferences.getInstance] has completed —
/// reading it before then is a programming error.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});
