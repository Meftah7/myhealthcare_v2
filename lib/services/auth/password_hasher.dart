/// Salted, stretched password hashing (P2-01 — built early because the auth
/// repository and the seeder both need it).
///
/// PBKDF2-HMAC-SHA256. The stored hash string embeds its iteration count
/// (`<iterations>:<base64 key>`) so the work factor can change over time and
/// the bulk seeder can use a cheap count without breaking login. The report
/// should note a production system would use a memory-hard KDF (Argon2id /
/// scrypt / bcrypt).
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordHash {
  const PasswordHash({required this.hash, required this.salt});

  /// `<iterations>:<base64 derived key>`.
  final String hash;

  /// Base64 of the random salt.
  final String salt;
}

class PasswordHasher {
  const PasswordHasher({this.iterations = 20000, this.keyLength = 32});

  /// Work factor for *new* hashes. Verification reads the count from the
  /// stored string, so existing hashes keep working when this changes.
  final int iterations;
  final int keyLength;

  static final _random = Random.secure();

  PasswordHash hashNew(String password, {List<int>? salt}) {
    final saltBytes = salt ?? _randomBytes(16);
    final derived = _pbkdf2(utf8.encode(password), saltBytes, iterations);
    return PasswordHash(
      hash: '$iterations:${base64.encode(derived)}',
      salt: base64.encode(saltBytes),
    );
  }

  bool verify(String password, {required String hash, required String salt}) {
    final sep = hash.indexOf(':');
    if (sep <= 0) return false;
    final iters = int.tryParse(hash.substring(0, sep));
    if (iters == null) return false;
    final expected = hash.substring(sep + 1);
    final derived = _pbkdf2(utf8.encode(password), base64.decode(salt), iters);
    return _constantTimeEquals(base64.encode(derived), expected);
  }

  List<int> _randomBytes(int n) =>
      List<int>.generate(n, (_) => _random.nextInt(256));

  Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    final out = BytesBuilder();
    var block = 1;
    while (out.length < keyLength) {
      out.add(_deriveBlock(hmac, salt, block, iterations));
      block++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, keyLength));
  }

  List<int> _deriveBlock(
    Hmac hmac,
    List<int> salt,
    int blockIndex,
    int iterations,
  ) {
    final firstInput = <int>[
      ...salt,
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ];
    var u = hmac.convert(firstInput).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
