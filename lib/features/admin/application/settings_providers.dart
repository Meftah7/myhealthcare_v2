/// App settings + AI configuration providers (P3-07, P5-16).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';

/// Current app settings row (auto-created on first read).
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final result = await ref.watch(settingsRepositoryProvider).get();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Whether an API key is stored / provided via --dart-define.
final aiKeyPresentProvider = FutureProvider<bool>(
  (ref) => ref.watch(aiKeyStoreProvider).hasKey(),
);

class SettingsController {
  SettingsController(this._ref);
  final Ref _ref;

  Future<void> update(AppSettings next) async {
    await _ref.read(settingsRepositoryProvider).update(next);
    _ref.invalidate(appSettingsProvider);
  }

  Future<void> setApiKey(String key) async {
    final store = _ref.read(aiKeyStoreProvider);
    if (key.trim().isEmpty) {
      await store.clear();
    } else {
      await store.write(key);
    }
    _ref
      ..invalidate(aiKeyPresentProvider)
      ..invalidate(appSettingsProvider);
  }
}

final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);
