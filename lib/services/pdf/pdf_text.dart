/// Text extraction from untrusted PDF bytes, shared by the record import
/// sheet and the shared-server pilot (SEC-PAT-10): magic-byte check, page and
/// text caps, run off the UI isolate with a timeout.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const maxPdfPages = 200;
const maxExtractedChars = 200000;

/// With [allowPrefix], accepts a short prefix before the header as Acrobat
/// readers do. The parser still validates the document structure.
bool looksLikePdf(Uint8List bytes, {bool allowPrefix = false}) {
  const signature = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
  if (bytes.length <= signature.length) return false;
  final last = allowPrefix
      ? math.min(bytes.length, 1024) - signature.length
      : 0;
  for (var start = 0; start <= last; start++) {
    if (bytes[start] == signature[0] &&
        bytes[start + 1] == signature[1] &&
        bytes[start + 2] == signature[2] &&
        bytes[start + 3] == signature[3] &&
        bytes[start + 4] == signature[4]) {
      return true;
    }
  }
  return false;
}

/// Top-level so [compute] can run it on a background isolate.
String extractPdfText(Uint8List bytes) =>
    extractPdfTextWithCoverage(bytes, allowPartialPages: false).text;

/// Reads one page at a time and stops at the page or text budget.
({String text, bool complete}) extractPdfTextWithCoverage(
  Uint8List bytes, {
  bool allowPartialPages = true,
}) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final pageCount = document.pages.count;
    if (pageCount > maxPdfPages && !allowPartialPages) {
      throw const FormatException('too many pages');
    }
    final extractor = PdfTextExtractor(document);
    final output = StringBuffer();
    for (var page = 0; page < math.min(pageCount, maxPdfPages); page++) {
      // Whole lines keep labels, values, units and flags together.
      final lines = extractor.extractTextLines(startPageIndex: page);
      final text = lines.isEmpty
          ? [extractor.extractText(startPageIndex: page)]
          : lines.map((line) => line.text);
      for (final line in text) {
        if (line.isEmpty) continue;
        final separator = output.isEmpty ? '' : '\n';
        final remaining = maxExtractedChars - output.length - separator.length;
        if (line.length > remaining) {
          if (remaining > 0) {
            output.write(separator);
            output.write(line.substring(0, remaining));
          }
          return (text: output.toString(), complete: false);
        }
        output.write(separator);
        output.write(line);
      }
    }
    return (text: output.toString(), complete: pageCount <= maxPdfPages);
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
