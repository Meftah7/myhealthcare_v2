/// Shared PDF chrome for every patient-facing document (P10-01).
///
/// One letterhead, one patient strip, one footer — so a vitals report, an
/// imaging result and a sick-leave note all read as documents from the same
/// clinic. Report builders live in `reports.dart`; they hand this a title and
/// a list of `pw.Widget` body blocks and get back the finished bytes.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// The patient identity block printed at the top of every document.
class PdfIdentity {
  const PdfIdentity({
    required this.name,
    required this.patientId,
    this.bloodType,
    this.dob,
    this.allergies = const [],
  });

  final String name;
  final String patientId;
  final String? bloodType;
  final DateTime? dob;
  final List<String> allergies;
}

/// Brand colours, kept in step with `AppColors` but declared here so the PDF
/// layer has no dependency on the Flutter theme.
const _ink = PdfColor.fromInt(0xFF1A1A2E);
const _muted = PdfColor.fromInt(0xFF6B6B80);
const _brand = PdfColor.fromInt(0xFF5B4FE9);
const _hairline = PdfColor.fromInt(0xFFD9D9E3);
const _alertBg = PdfColor.fromInt(0xFFFDECEC);
const _alertInk = PdfColor.fromInt(0xFFB3261E);

final _dateFmt = DateFormat('d MMMM yyyy');
final _stampFmt = DateFormat('d MMM yyyy, HH:mm');

class ClinicPdf {
  const ClinicPdf._();

  static const clinicName = 'MyHealth Care';
  static const clinicTagline = 'Integrated clinic & patient portal';
  static const _disclaimer =
      'This document is generated from the patient record and is not a '
      'substitute for direct clinical advice.';

  /// Builds a finished PDF. [title] is the document name ("Vital signs '
  /// report"); [subtitle] is an optional line under it (a date range, say).
  static Future<Uint8List> build({
    required String title,
    required PdfIdentity patient,
    required List<pw.Widget> body,
    String? subtitle,
  }) async {
    final logo = await _logo();
    final theme = await _theme();
    final generatedAt = DateTime.now();
    final doc = pw.Document(title: title, author: clinicName, theme: theme);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 48),
        header: (context) => context.pageNumber == 1
            ? _letterhead(logo, title, subtitle)
            : _runningHeader(title),
        footer: _footer(generatedAt),
        build: (context) => [
          _identityStrip(patient),
          pw.SizedBox(height: 18),
          ...body,
        ],
      ),
    );
    return doc.save();
  }

  /// Opens the platform print / preview / share sheet for [bytes].
  static Future<void> present(Uint8List bytes, {required String filename}) {
    return Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
  }

  // --- chrome ---------------------------------------------------------------

  static pw.Widget _letterhead(
    pw.ImageProvider? logo,
    String title,
    String? subtitle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                if (logo != null) ...[
                  pw.Image(logo, height: 26, width: 26),
                  pw.SizedBox(width: 8),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      clinicName,
                      style: const pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    pw.Text(
                      clinicTagline,
                      style: const pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _brand,
                  ),
                ),
                if (subtitle != null)
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _hairline, height: 1),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _runningHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _hairline)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            clinicName,
            style: const pw.TextStyle(
              fontSize: 8,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _identityStrip(PdfIdentity p) {
    final facts = <String>[
      'ID ${_shortId(p.patientId)}',
      if (p.dob != null) 'DOB ${_dateFmt.format(p.dob!)}',
      if (p.bloodType != null && p.bloodType!.isNotEmpty)
        'Blood type ${p.bloodType}',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PATIENT',
          style: const pw.TextStyle(
            fontSize: 7,
            color: _muted,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          p.name,
          style: const pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          facts.join('   ·   '),
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
        pw.SizedBox(height: 8),
        _allergyBanner(p.allergies),
      ],
    );
  }

  static pw.Widget _allergyBanner(List<String> allergies) {
    if (allergies.isEmpty) {
      return pw.Text(
        'No known allergies recorded.',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      );
    }
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _alertBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _alertInk, width: 0.5),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            const pw.TextSpan(
              text: 'ALLERGIES  ',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _alertInk,
                letterSpacing: 0.5,
              ),
            ),
            pw.TextSpan(
              text: allergies.join(', '),
              style: const pw.TextStyle(fontSize: 9, color: _alertInk),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget Function(pw.Context) _footer(DateTime generatedAt) {
    return (context) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _hairline)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _disclaimer,
            style: const pw.TextStyle(fontSize: 6.5, color: _muted),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated ${_stampFmt.format(generatedAt)}',
                style: const pw.TextStyle(fontSize: 6.5, color: _muted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 6.5, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- helpers -------------------------------------------------------------

  static pw.ImageProvider? _cachedLogo;

  static Future<pw.ImageProvider?> _logo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      return _cachedLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // A missing asset must never sink a report — just drop the mark.
      return null;
    }
  }

  static pw.ThemeData? _cachedTheme;
  static bool _themeTried = false;

  /// The bundled app font (Inter) so a PDF can render dashes, symbols and any
  /// non-Latin text — the pdf package's built-in Helvetica is ASCII-only. Falls
  /// back to Helvetica if the asset can't be read (e.g. in some test hosts).
  static Future<pw.ThemeData?> _theme() async {
    if (_themeTried) return _cachedTheme;
    _themeTried = true;
    try {
      final inter = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Inter.ttf'),
      );
      return _cachedTheme = pw.ThemeData.withFont(base: inter, bold: inter);
    } catch (_) {
      return null;
    }
  }

  static String _shortId(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 12)}...';
}

// --- reusable body blocks the reports share --------------------------------

/// A titled section with a hairline rule under the heading.
pw.Widget pdfSection(String heading, pw.Widget child) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        heading.toUpperCase(),
        style: const pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _muted,
          letterSpacing: 1,
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Divider(color: _hairline, thickness: 1, height: 1),
      pw.SizedBox(height: 8),
      child,
      pw.SizedBox(height: 18),
    ],
  );
}

/// A key/value row, used for summary blocks.
pw.Widget pdfKeyValue(String key, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text(
            key,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9, color: _ink),
          ),
        ),
      ],
    ),
  );
}

/// Shared palette, re-exported for the report builders in `reports.dart`.
const pdfInk = _ink;
const pdfMuted = _muted;
const pdfHairline = _hairline;
const pdfHeaderFill = PdfColor.fromInt(0xFFF2F2F7);
