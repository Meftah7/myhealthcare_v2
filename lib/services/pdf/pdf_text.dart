/// Text extraction from untrusted PDF bytes, shared by the record import
/// sheet and the shared-server pilot (SEC-PAT-10): magic-byte check, page and
/// text caps, run off the UI isolate with a timeout.
library;

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const maxPdfPages = 200;
const maxExtractedChars = 200000;

/// True when [bytes] start with the `%PDF-` signature.
bool looksLikePdf(Uint8List bytes) =>
    bytes.length > 5 &&
    bytes[0] == 0x25 && // %PDF-
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46 &&
    bytes[4] == 0x2D;

/// Top-level so [compute] can run it on a background isolate.
String extractPdfText(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    if (document.pages.count > maxPdfPages) {
      throw const FormatException('too many pages');
    }
    final text = PdfTextExtractor(document).extractText();
    return text.length > maxExtractedChars
        ? text.substring(0, maxExtractedChars)
        : text;
  } finally {
    document.dispose();
  }
}

/// Validates and extracts [bytes] on a background isolate (20 s cap).
Future<String> extractPdfTextSafely(Uint8List bytes) async {
  if (!looksLikePdf(bytes)) throw const FormatException('not a PDF');
  final text = await compute(
    extractPdfText,
    bytes,
  ).timeout(const Duration(seconds: 20));
  return text.trim();
}
