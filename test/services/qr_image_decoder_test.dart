// Verifying a document from a picture of its QR code.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/services/qr/qr_image_decoder.dart';

void main() {
  test('reads the verification QR from a screenshot', () {
    final bytes = File('test/fixtures/verify_qr.png').readAsBytesSync();
    expect(decodeQrFromImageSync(bytes), 'MHC-VERIFY:U45Y4-5SZF5');
  });

  test('returns null for a picture without a QR code', () {
    expect(decodeQrFromImageSync(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
