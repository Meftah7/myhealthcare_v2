import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
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
    String? verificationUrl,
  }) async {
    final latin = pw.Font.ttf(
      await rootBundle.load('assets/fonts/static/Inter-Regular.ttf'),
    );
    final arabic = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic.ttf'),
    );
    final rtl = language == 'ar';
    final theme = pw.ThemeData.withFont(
      base: rtl ? arabic : latin,
      bold: rtl ? arabic : latin,
      italic: rtl ? arabic : latin,
      boldItalic: rtl ? arabic : latin,
      fontFallback: [arabic, latin],
    );
    final document = pw.Document(
      title: title,
      author: 'MyHealth Care',
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
            pw.Text('MyHealth Care', style: const pw.TextStyle(fontSize: 20)),
            pw.Divider(),
            pw.Text(title, style: const pw.TextStyle(fontSize: 16)),
            if (draft)
              pw.Text(
                'DRAFT / مسودة',
                style: const pw.TextStyle(fontSize: 24, color: PdfColors.grey),
              ),
          ],
        ),
        footer: (context) => pw.Text(
          '$reference • ${issuedAt.toIso8601String()} • ${context.pageNumber}',
          textDirection: pw.TextDirection.ltr,
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (_) => [
          pw.SizedBox(height: 24),
          for (final paragraph in wording.split('\n'))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                paragraph,
                style: const pw.TextStyle(fontSize: 13, lineSpacing: 5),
              ),
            ),
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
