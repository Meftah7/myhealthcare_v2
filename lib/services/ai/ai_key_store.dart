/// Secure storage for the LLM API key (P3-06). Never logged, never committed.
///
/// A `--dart-define=GEMINI_API_KEY=...` value is used as a dev fallback when
/// nothing is stored (handy for `flutter test` / CI), but the stored value
/// always wins.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiKeyStore {
  AiKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'ai.apiKey';
  static const _dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<String?> read() async {
    final stored = await _storage.read(key: _key);
    if (stored != null && stored.isNotEmpty) return stored;
    return _dartDefineKey.isEmpty ? null : _dartDefineKey;
  }

  Future<bool> hasKey() async => (await read())?.isNotEmpty ?? false;

  Future<void> write(String key) =>
      _storage.write(key: _key, value: key.trim());

  Future<void> clear() => _storage.delete(key: _key);
}
