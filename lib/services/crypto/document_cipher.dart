/// AES-256-GCM encryption for health documents stored on the device
/// (SEC-PAT-08). Each file gets a fresh random 96-bit nonce; the GCM tag
/// rejects tampered or truncated files on decrypt.
///
/// File layout: `MHC1` magic (4 bytes) | nonce (12) | ciphertext | tag (16).
library;

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'device_key_store.dart';

class DocumentCipher {
  DocumentCipher({DeviceKeyStore? keys}) : _keys = keys ?? DeviceKeyStore();

  final DeviceKeyStore _keys;

  static const _magic = [0x4D, 0x48, 0x43, 0x31]; // "MHC1"

  static bool isEncrypted(Uint8List bytes) =>
      bytes.length > _magic.length &&
      listEquals(bytes.sublist(0, _magic.length), _magic);

  Future<Uint8List> encrypt(Uint8List plain) async {
    final key = await _keys.keyFor(DeviceKeyStore.documentKey);
    return compute(_encrypt, (key, plain));
  }

  Future<Uint8List> decrypt(Uint8List sealed) async {
    if (!isEncrypted(sealed)) {
      throw const FormatException('Not an encrypted document.');
    }
    final key = await _keys.keyFor(DeviceKeyStore.documentKey);
    return compute(_decrypt, (key, sealed));
  }
}

final _aes = AesGcm.with256bits();

Future<Uint8List> _encrypt((Uint8List, Uint8List) args) async {
  final (key, plain) = args;
  final box = await _aes.encrypt(plain, secretKey: SecretKey(key));
  return (BytesBuilder(copy: false)
        ..add(DocumentCipher._magic)
        ..add(box.nonce)
        ..add(box.cipherText)
        ..add(box.mac.bytes))
      .takeBytes();
}

Future<Uint8List> _decrypt((Uint8List, Uint8List) args) async {
  final (key, sealed) = args;
  const head = 4;
  const nonceLength = 12;
  const tagLength = 16;
  if (sealed.length < head + nonceLength + tagLength) {
    throw const FormatException('Encrypted document is truncated.');
  }
  final box = SecretBox(
    sealed.sublist(head + nonceLength, sealed.length - tagLength),
    nonce: sealed.sublist(head, head + nonceLength),
    mac: Mac(sealed.sublist(sealed.length - tagLength)),
  );
  final plain = await _aes.decrypt(box, secretKey: SecretKey(key));
  return Uint8List.fromList(plain);
}
