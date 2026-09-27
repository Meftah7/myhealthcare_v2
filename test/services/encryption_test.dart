import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/services/crypto/document_cipher.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('DocumentCipher', () {
    final plain = Uint8List.fromList(List.generate(4096, (i) => i % 251));

    test('round-trips and never stores plaintext', () async {
      final cipher = DocumentCipher();
      final sealed = await cipher.encrypt(plain);
      expect(DocumentCipher.isEncrypted(sealed), isTrue);
      expect(sealed.length, plain.length + 4 + 12 + 16);
      expect(await cipher.decrypt(sealed), plain);
    });

    test('uses a fresh nonce per file', () async {
      final cipher = DocumentCipher();
      final a = await cipher.encrypt(plain);
      final b = await cipher.encrypt(plain);
      expect(a, isNot(b));
    });

    test('rejects tampered ciphertext', () async {
      final cipher = DocumentCipher();
      final sealed = await cipher.encrypt(plain);
      sealed[40] ^= 0x01;
      await expectLater(cipher.decrypt(sealed), throwsA(anything));
    });
  });

  group('SQLite3MultipleCiphers database', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('mhc_enc'));
    tearDown(() => dir.deleteSync(recursive: true));

    const key =
        'aa11223344556677889900aabbccddeeff00112233445566778899aabbccddee';

    bool plaintextHeader(String path) =>
        String.fromCharCodes(File(path).readAsBytesSync().take(16)) ==
        'SQLite format 3\u0000';

    test('keyed database is unreadable without the key', () {
      final path = '${dir.path}/k.sqlite';
      sqlite3.open(path)
        ..execute("PRAGMA hexkey = '$key'")
        ..execute('CREATE TABLE t (v TEXT)')
        ..execute("INSERT INTO t VALUES ('diagnosis')")
        ..dispose();

      expect(plaintextHeader(path), isFalse);
      expect(
        File(path).readAsStringSync(encoding: latin1),
        isNot(contains('diagnosis')),
      );

      final noKey = sqlite3.open(path);
      expect(
        () => noKey.select('SELECT * FROM t'),
        throwsA(isA<SqliteException>()),
      );
      noKey.dispose();

      final keyed = sqlite3.open(path)..execute("PRAGMA hexkey = '$key'");
      expect(keyed.select('SELECT v FROM t').single['v'], 'diagnosis');
      keyed.dispose();
    });

    test('an existing plaintext database is encrypted in place by rekey', () {
      final path = '${dir.path}/legacy.sqlite';
      sqlite3.open(path)
        ..execute('CREATE TABLE t (v TEXT)')
        ..execute("INSERT INTO t VALUES ('kept')")
        ..dispose();
      expect(plaintextHeader(path), isTrue);

      sqlite3.open(path)
        ..execute("PRAGMA hexrekey = '$key'")
        ..dispose();
      expect(plaintextHeader(path), isFalse);

      final keyed = sqlite3.open(path)..execute("PRAGMA hexkey = '$key'");
      expect(keyed.select('SELECT v FROM t').single['v'], 'kept');
      keyed.dispose();
    });
  });
}
