/// Secure storage for the LLM API key (P3-06). Never logged, never committed.
///
/// Provider credentials are never compiled into the application binary.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiKeyStore {
  AiKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'ai.apiKey';

  Future<String?> read() async {
    String? stored;
    try {
      stored = await _storage.read(key: _key);
    } catch (_) {
      // Secure storage can be unavailable (locked keystore, test harness with
      // no plugin, …) — treat the key as unavailable.
      stored = null;
    }
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  Future<bool> hasKey() async => (await read())?.isNotEmpty ?? false;

  Future<void> write(String key) =>
      _storage.write(key: _key, value: key.trim());

  Future<void> clear() => _storage.delete(key: _key);
}
