/// Random 256-bit keys for on-device encryption, held in platform secure
/// storage (Android Keystore, iOS/macOS Keychain, Windows DPAPI, libsecret).
///
/// Keys are generated from a CSPRNG on first use and are never derived from a
/// password or constant. Destroying a key crypto-shreds everything it
/// protected (SEC-PAT-08, SEC-XCUT-02).
library;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceKeyStore {
  DeviceKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Key for the SQLite3MultipleCiphers database.
  static const databaseKey = 'device_key.database.v1';

  /// Key for imported health documents on disk.
  static const documentKey = 'device_key.documents.v1';

  // One shared load per key name, so concurrent first calls can't each
  // generate (and race to store) a different key. Failed loads are retried.
  static final _cache = <String, Future<Uint8List>>{};

  Future<Uint8List> keyFor(String name) async =>
      _cache[name] ??= _loadOrCreate(name).onError<Object>((e, st) {
        unawaited(_cache.remove(name));
        Error.throwWithStackTrace(e, st);
      });

  Future<Uint8List> _loadOrCreate(String name) async {
    final stored = await _storage.read(key: name);
    if (stored != null && stored.length == 64) return _fromHex(stored);
    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _storage.write(key: name, value: toHex(key));
    return key;
  }

  static String toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _fromHex(String hex) => Uint8List.fromList([
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}
