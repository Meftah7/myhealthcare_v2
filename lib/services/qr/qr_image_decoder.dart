/// Reads a QR code from a picture (a screenshot or a photo of a document),
/// in pure Dart — so it works on every platform, including desktops without
/// camera scanning and laptops that can't point a webcam at their own
/// screen.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// The QR's text, or null when the picture holds no readable QR code.
Future<String?> decodeQrFromImage(Uint8List bytes) =>
    compute(decodeQrFromImageSync, bytes);

String? decodeQrFromImageSync(Uint8List bytes) {
  img.Image? image;
  try {
    image = img.decodeImage(bytes);
  } on Object {
    return null; // Not a picture this decoder understands.
  }
  if (image == null) return null;
  // Phone photos are large; a QR needs far fewer pixels than that.
  if (image.width > 1200 || image.height > 1200) {
    image = image.width >= image.height
        ? img.copyResize(image, width: 1200)
        : img.copyResize(image, height: 1200);
  }
  // A tight crop loses the white "quiet zone" a reader needs — add one.
  final padded = img.Image(
    width: image.width + 40,
    height: image.height + 40,
    numChannels: 4,
  );
  img.fill(padded, color: img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(padded, image, dstX: 20, dstY: 20);

  final pixels = padded
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.abgr)
      .buffer
      .asInt32List();
  final source = RGBLuminanceSource(padded.width, padded.height, pixels);
  for (final bitmap in [
    BinaryBitmap(HybridBinarizer(source)),
    BinaryBitmap(GlobalHistogramBinarizer(source)),
  ]) {
    try {
      return QRCodeReader().decode(bitmap).text;
    } on Object {
      // Try the next binarizer.
    }
  }
  return null;
}
