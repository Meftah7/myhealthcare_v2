/// The myhealth mark for generated PDFs — one loader and one header lockup
/// shared by every renderer, so documents never pick an asset themselves.
///
/// The logo is identity only: it is never a signature, stamp, seal or proof
/// of clinical approval, and it is never drawn behind document text.
library;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract final class BrandPdf {
  /// 256² PNG, transparent outside the navy rounded square.
  static const asset = 'assets/branding/myhealth-logo-pdf.png';

  /// Frozen into an issued version's template snapshot when it was issued
  /// with this mark. Versions issued before the mark existed render without
  /// it, exactly as originally issued.
  static const snapshotMark = 'myhealth-logo-2026-10';

  static pw.ImageProvider? _cached;

  /// The embedded logo, or `null` if the asset cannot be read (a missing
  /// asset must never stop a document from being produced).
  static Future<pw.ImageProvider?> logo() async {
    if (_cached != null) return _cached;
    try {
      final data = await rootBundle.load(asset);
      return _cached = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// Logo beside the [name] wordmark, for a document header.
  static pw.Widget lockup(
    pw.ImageProvider? logo,
    String name, {
    double size = 28,
    pw.TextStyle? style,
  }) => pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (logo != null) ...[
        pw.Image(logo, width: size, height: size, fit: pw.BoxFit.contain),
        pw.SizedBox(width: 8),
      ],
      pw.Text(
        name,
        style:
            style ??
            const pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF012D5E),
            ),
      ),
    ],
  );
}
