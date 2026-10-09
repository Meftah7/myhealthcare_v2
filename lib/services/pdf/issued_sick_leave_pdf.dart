import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
// The package shapes Arabic only for RTL paragraphs; reuse its shaper for
// Arabic runs embedded in LTR text.
// ignore: implementation_imports
import 'package:pdf/src/pdf/font/arabic.dart' as arabic;
import 'package:pdf/widgets.dart' as pw;

/// Receives frozen text only; never reads a session, patient provider or clock.
abstract interface class IssuedSickLeaveRenderer {
  Future<Uint8List> render({
    required String wording,
    required String language,
    required String reference,
    required DateTime issuedAt,
    bool draft = false,
    String title = 'Sick leave',
    String clinicName = 'MyHealth Care',
    String? verificationUrl,
  });
}

class IssuedSickLeavePdf implements IssuedSickLeaveRenderer {
  const IssuedSickLeavePdf();

  @override
  Future<Uint8List> render({
    required String wording,
    required String language,
    required String reference,
    required DateTime issuedAt,
    bool draft = false,
    String title = 'Sick leave',
    String clinicName = 'MyHealth Care',
    String? verificationUrl,
  }) async {
    final latin = pw.Font.ttf(
      await rootBundle.load('assets/fonts/static/Inter-Regular.ttf'),
    );
    final arabic = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic.ttf'),
    );
    final rtl = language == 'ar';
    String text(String value) => rtl ? value : _shapeArabicRuns(value);
    final theme = pw.ThemeData.withFont(
      base: rtl ? arabic : latin,
      bold: rtl ? arabic : latin,
      italic: rtl ? arabic : latin,
      boldItalic: rtl ? arabic : latin,
      fontFallback: [arabic, latin],
    );
    final document = pw.Document(
      title: title,
      author: clinicName,
      subject: reference,
      creator: 'MyHealth',
      theme: theme,
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(text(clinicName), style: const pw.TextStyle(fontSize: 20)),
            pw.Divider(),
            pw.Text(text(title), style: const pw.TextStyle(fontSize: 16)),
            if (draft)
              pw.Text(
                text('DRAFT / مسودة'),
                style: const pw.TextStyle(fontSize: 24, color: PdfColors.grey),
              ),
            // Separates the repeated header from text continued on later pages.
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Text(
          '$reference • ${issuedAt.toIso8601String()} • ${context.pageNumber}',
          textDirection: pw.TextDirection.ltr,
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (_) => [
          pw.SizedBox(height: 24),
          for (final paragraph in wording.split('\n')) ...[
            // Keep spanning text directly in MultiPage: a Padding wrapper
            // prevents a long paragraph from continuing onto the next page.
            pw.Text(
              text(paragraph),
              overflow: pw.TextOverflow.span,
              style: const pw.TextStyle(fontSize: 13, lineSpacing: 5),
            ),
            pw.SizedBox(height: 12),
          ],
          if (!draft)
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: verificationUrl ?? reference,
              drawText: false,
              textStyle: pw.TextStyle(font: latin, fontFallback: [latin]),
              width: 64,
              height: 64,
            ),
        ],
      ),
    );
    return document.save();
  }
}

final _arabicRun = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]+'
  r'(?:\s+[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]+)*',
);

/// Joins and orders each Arabic run visually so it reads correctly when the
/// surrounding paragraph is laid out left to right.
String _shapeArabicRuns(String value) =>
    value.replaceAllMapped(_arabicRun, (m) => arabic.convert(m[0]!));
