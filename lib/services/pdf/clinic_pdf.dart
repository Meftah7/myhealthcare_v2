/// Shared PDF chrome for every patient-facing document (P10-01, Phase 5).
///
/// One letterhead, one patient strip, one provenance block, one footer — so a
/// vitals report, an imaging result and a sick-leave note all read as
/// documents from the same clinic and all say who issued them, where the
/// content came from, its date and its status.
///
/// Documents are real text (not images), so they can be selected, searched
/// and read by screen readers. Arabic documents are laid out right-to-left
/// with an embedded Arabic font; names and clinical free text are printed as
/// recorded.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/app_environment.dart';

import 'pdf_strings.dart';

/// The patient identity block printed at the top of every document.
class PdfIdentity {
  const PdfIdentity({
    required this.name,
    required this.patientId,
    this.bloodType,
    this.dob,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
  });

  final String name;
  final String patientId;
  final String? bloodType;
  final DateTime? dob;
  final List<String> allergies;

  /// Long-term conditions, printed so any reader sees the context.
  final List<String> conditions;

  /// Active medications, one line each ("Metformin 500 mg · twice daily").
  final List<String> medications;
}

/// Who issued a document, where its content came from, when, and in what
/// state — printed on every export so a reader never has to guess.
class DocumentProvenance {
  const DocumentProvenance({
    required this.issuer,
    required this.source,
    required this.documentDate,
    required this.status,
    required this.reference,
    this.originalFile,
    this.sha256,
  });

  final String issuer;
  final String source;
  final DateTime documentDate;
  final String status;

  /// A stable reference for the underlying record or certificate.
  final String reference;

  /// For an imported record: the original file's name and fingerprint.
  final String? originalFile;
  final String? sha256;
}

/// Brand colours, kept in step with `AppColors` but declared here so the PDF
/// layer has no dependency on the Flutter theme.
const _ink = PdfColor.fromInt(0xFF1A1A2E);
const _muted = PdfColor.fromInt(0xFF6B6B80);
const _brand = PdfColor.fromInt(0xFF1E5FAF);
const _hairline = PdfColor.fromInt(0xFFD9D9E3);
const _alertBg = PdfColor.fromInt(0xFFFDECEC);
const _alertInk = PdfColor.fromInt(0xFFB3261E);
const _panel = PdfColor.fromInt(0xFFF6F6FA);

/// Dates in documents. English spells the month; Arabic uses an unambiguous
/// numeric form that needs no locale data.
String pdfDate(DateTime d, {bool arabic = false}) => arabic
    ? DateFormat('d/M/yyyy').format(d)
    : DateFormat('d MMMM yyyy').format(d);

String pdfShortDate(DateTime d, {bool arabic = false}) => arabic
    ? DateFormat('d/M/yyyy').format(d)
    : DateFormat('d MMM yyyy').format(d);

String pdfStamp(DateTime d, {bool arabic = false}) => arabic
    ? DateFormat('d/M/yyyy HH:mm').format(d)
    : DateFormat('d MMM yyyy, HH:mm').format(d);

class ClinicPdf {
  const ClinicPdf._();

  static const clinicName = 'MyHealth Care';

  /// Builds a finished PDF. [title] is the document name; [subtitle] an
  /// optional line under it (a date range, say).
  static Future<Uint8List> build({
    required String title,
    required PdfIdentity patient,
    required DocumentProvenance provenance,
    required List<pw.Widget> body,
    String? subtitle,
    bool arabic = false,
  }) async {
    final s = PdfStrings.of(arabic: arabic);
    final logo = await _logo();
    final theme = await _theme();
    final generatedAt = DateTime.now();
    final doc = pw.Document(
      title: title,
      author: clinicName,
      subject: provenance.reference,
      theme: theme,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 48),
        header: (context) => context.pageNumber == 1
            ? _letterhead(logo, title, subtitle, s)
            : _runningHeader(title),
        footer: _footer(generatedAt, s),
        build: (context) => [
          _identityStrip(patient, s),
          pw.SizedBox(height: 12),
          _provenanceBlock(provenance, s),
          pw.SizedBox(height: 18),
          ...body,
        ],
      ),
    );
    return doc.save();
  }

  // --- chrome ---------------------------------------------------------------

  static pw.Widget _letterhead(
    pw.ImageProvider? logo,
    String title,
    String? subtitle,
    PdfStrings s,
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
                      s.clinicTagline,
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

  static pw.Widget _identityStrip(PdfIdentity p, PdfStrings s) {
    final facts = <String>[
      s.id(_shortId(p.patientId)),
      if (p.dob != null) s.dob(pdfDate(p.dob!, arabic: s.isArabic)),
      if (p.dob != null) s.age(_ageYears(p.dob!)),
      if (p.bloodType != null && p.bloodType!.isNotEmpty)
        s.bloodType(p.bloodType!),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          s.patient,
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
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
        pw.SizedBox(height: 8),
        _allergyBanner(p.allergies, s),
        if (p.conditions.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          _contextLine(s.conditions, p.conditions.join(', ')),
        ],
        if (p.medications.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _contextLine(s.medications, p.medications.join('  ·  ')),
        ],
      ],
    );
  }

  static pw.Widget _contextLine(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label  ',
            style: const pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
              letterSpacing: 0.5,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: const pw.TextStyle(fontSize: 10, color: _ink),
          ),
        ],
      ),
    );
  }

  static int _ageYears(DateTime dob) {
    final now = DateTime.now();
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    return now.year - dob.year - (hadBirthday ? 0 : 1);
  }

  static pw.Widget _allergyBanner(List<String> allergies, PdfStrings s) {
    if (allergies.isEmpty) {
      return pw.Text(
        s.noAllergies,
        style: const pw.TextStyle(fontSize: 9.5, color: _muted),
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
            pw.TextSpan(
              text: '${s.allergies}  ',
              style: const pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _alertInk,
                letterSpacing: 0.5,
              ),
            ),
            pw.TextSpan(
              text: allergies.join(', '),
              style: const pw.TextStyle(fontSize: 10.5, color: _alertInk),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _provenanceBlock(DocumentProvenance p, PdfStrings s) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _hairline, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            s.provenanceHeading.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 7,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 4),
          pdfKeyValue(s.issuedBy, p.issuer),
          pdfKeyValue(s.source, p.source),
          pdfKeyValue(
            s.documentDate,
            pdfDate(p.documentDate, arabic: s.isArabic),
          ),
          pdfKeyValue(s.status, p.status),
          pdfKeyValue(s.reference, p.reference),
          if (p.originalFile != null)
            pdfKeyValue(s.originalFile, p.originalFile!),
          // Small enough to stay on one line, so it can be copied whole.
          if (p.sha256 != null)
            pdfKeyValue(
              s.fingerprint,
              p.sha256!,
              valueStyle: const pw.TextStyle(fontSize: 8, color: _ink),
            ),
        ],
      ),
    );
  }

  static pw.Widget Function(pw.Context) _footer(
    DateTime generatedAt,
    PdfStrings s,
  ) {
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
            '${ClinicPdf.clinicName}  ·  ${s.clinicContact}',
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            configuredAppMode.isDemo
                ? '${s.disclaimer} ${s.demoNote}'
                : s.disclaimer,
            style: const pw.TextStyle(fontSize: 7.5, color: _muted),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                s.generated(pdfStamp(generatedAt, arabic: s.isArabic)),
                style: const pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
              pw.Text(
                s.page(context.pageNumber, context.pagesCount),
                style: const pw.TextStyle(fontSize: 7.5, color: _muted),
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
      // A PDF page is always white paper, regardless of the app's theme —
      // always the light-background mark.
      final data = await rootBundle.load('assets/images/logo_light.png');
      return _cachedLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // A missing asset must never sink a report — just drop the mark.
      return null;
    }
  }

  static pw.ThemeData? _cachedTheme;
  static bool _themeTried = false;

  /// The bundled app font (Inter) with Noto Naskh Arabic as fallback, so a
  /// document can mix Arabic and Latin text — the pdf package's built-in
  /// Helvetica is ASCII-only. Falls back to Helvetica if the assets can't be
  /// read (e.g. in some test hosts).
  ///
  /// Loads the static Regular/SemiBold instances of Inter, not the
  /// variable-font source — the `pdf` package embeds a font's glyphs as-is
  /// with no weight interpolation.
  static Future<pw.ThemeData?> _theme() async {
    if (_themeTried) return _cachedTheme;
    _themeTried = true;
    try {
      final base = pw.Font.ttf(
        await rootBundle.load('assets/fonts/static/Inter-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/static/Inter-SemiBold.ttf'),
      );
      final arabic = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoNaskhArabic.ttf'),
      );
      return _cachedTheme = pw.ThemeData.withFont(
        base: base,
        bold: bold,
        fontFallback: [arabic],
      );
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
          fontSize: 9,
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
pw.Widget pdfKeyValue(String key, String value, {pw.TextStyle? valueStyle}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 140,
          child: pw.Text(
            key,
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style:
                valueStyle ?? const pw.TextStyle(fontSize: 10.5, color: _ink),
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
const pdfAlertInk = _alertInk;
const pdfAlertBg = _alertBg;

/// Style for a value outside its range: bold, in the alert colour.
const pdfOutOfRange = pw.TextStyle(
  fontSize: 10.5,
  color: _alertInk,
  fontWeight: pw.FontWeight.bold,
);

/// A shaded note box — used for "what this means" explanations.
pw.Widget pdfNote(String text, {bool alert = false}) {
  return pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: alert ? _alertBg : _panel,
      borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(color: alert ? _alertInk : _hairline, width: 0.5),
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 10, color: alert ? _alertInk : _ink),
    ),
  );
}
