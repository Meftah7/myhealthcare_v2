// Reading attached documents. The Word fixtures in test/fixtures/documents
// were saved by Microsoft Word (16.0) from SYNTHETIC content — a .docx and a
// legacy .doc with a table, and password-protected copies of each. PDFs are
// generated here; everything is invented test data.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/services/documents/document_text.dart';
import 'package:myhealthcare/services/pdf/pdf_text.dart' show maxPdfPages;
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

Uint8List _fixture(String name) =>
    File('test/fixtures/documents/$name').readAsBytesSync();

Future<Uint8List> _pdf(List<String> lines) => pw.Document()
    .let(
      (d) => d
        ..addPage(
          pw.Page(
            build: (_) =>
                pw.Column(children: [for (final l in lines) pw.Text(l)]),
          ),
        ),
    )
    .save();

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

Future<DocumentProblem?> _problem(String name, Uint8List bytes) async {
  try {
    await readDocument(fileName: name, bytes: bytes);
    return null;
  } on DocumentReadException catch (e) {
    return e.problem;
  }
}

void main() {
  test(
    'the file read accepts exactly 20 MiB and rejects the next byte',
    () async {
      final limit = Uint8List(maxDocumentBytes);
      expect(
        (await readBoundedDocumentBytes(Stream.value(limit))).length,
        maxDocumentBytes,
      );
      await expectLater(
        readBoundedDocumentBytes(Stream.fromIterable([limit, Uint8List(1)])),
        throwsA(
          isA<DocumentReadException>().having(
            (error) => error.problem,
            'problem',
            DocumentProblem.tooLarge,
          ),
        ),
      );
    },
  );

  group('reads real text from each format', () {
    test('PDF: whole lines, as written', () async {
      final doc = await readDocument(
        fileName: 'panel.pdf',
        bytes: await _pdf([
          'SYNTHETIC TEST REPORT',
          'HbA1c 7.9 % H (4.0-5.6)',
          'Comment: HbA1c above the reference range.',
        ]),
      );
      expect(doc.format, DocumentFormat.pdf);
      expect(doc.text, contains('HbA1c 7.9 % H (4.0-5.6)'));
      expect(doc.complete, isTrue);
    });

    test(
      'an external PDF layout may have a prefix before its header',
      () async {
        final pdf = await _pdf([
          'Community Library',
          'The building opens on Monday.',
          'Return borrowed books to the reception desk.',
        ]);
        final doc = await readDocument(
          fileName: 'event-handout.PDF',
          bytes: Uint8List.fromList([0xef, 0xbb, 0xbf, ...pdf]),
        );
        expect(doc.format, DocumentFormat.pdf);
        expect(doc.text, contains('The building opens on Monday.'));
        expect(
          doc.text,
          contains('Return borrowed books to the reception desk.'),
        );
        expect(doc.complete, isTrue);
      },
    );

    test('a long PDF is marked partial when it hits the page budget', () async {
      final pdf = pw.Document();
      for (var i = 0; i <= maxPdfPages; i++) {
        pdf.addPage(
          pw.Page(
            build: (_) => pw.Text(
              i < maxPdfPages ? 'Library page ${i + 1}' : 'Beyond the budget',
            ),
          ),
        );
      }
      final doc = await readDocument(
        fileName: 'long.pdf',
        bytes: await pdf.save(),
      );
      expect(doc.text, contains('Library page $maxPdfPages'));
      expect(doc.text, isNot(contains('Beyond the budget')));
      expect(doc.complete, isFalse);
    });

    test('DOCX saved by Word: paragraphs, Arabic and the table', () async {
      final doc = await readDocument(
        fileName: 'synthetic-report.docx',
        bytes: _fixture('synthetic-report.docx'),
      );
      expect(doc.format, DocumentFormat.docx);
      expect(doc.text, contains('Laboratory: Diabetes and lipid panel'));
      expect(doc.text, contains('تقرير تجريبي'));
      expect(doc.text, contains('HbA1c | 7.9 % H | 4.0-5.6'));
      expect(doc.text, contains('Creatinine | 88 umol/L | 62-106'));
      expect(doc.text, contains('Comment: HbA1c above the reference range.'));
    });

    test('DOC (Word 97–2003) saved by Word: real text, not binary', () async {
      final doc = await readDocument(
        fileName: 'synthetic-report.doc',
        bytes: _fixture('synthetic-report.doc'),
      );
      expect(doc.format, DocumentFormat.doc);
      expect(doc.text, contains('SYNTHETIC TEST REPORT - not a real patient'));
      expect(doc.text, contains('Date: 2026-11-20'));
      expect(doc.text, contains('تقرير تجريبي'));
      expect(doc.text, contains('HbA1c | 7.9 % H | 4.0-5.6'));
      expect(doc.text, contains('Comment: HbA1c above the reference range.'));
      // No binary noise.
      expect(doc.text, isNot(contains('\u0000')));
      expect(doc.text, isNot(contains('WordDocument')));
    });

    test('TXT: UTF-8, UTF-8 with BOM, UTF-16 with BOM', () async {
      const text = 'Glucose 5.2 mmol/L\nملاحظة: نص تجريبي';
      for (final bytes in [
        utf8.encode(text),
        [0xEF, 0xBB, 0xBF, ...utf8.encode(text)],
        [
          0xFF,
          0xFE,
          for (final u in text.codeUnits) ...[u & 0xFF, u >> 8],
        ],
        [
          0xFE,
          0xFF,
          for (final u in text.codeUnits) ...[u >> 8, u & 0xFF],
        ],
      ]) {
        final doc = await readDocument(
          fileName: 'note.txt',
          bytes: Uint8List.fromList(bytes),
        );
        expect(doc.text, text);
      }
    });
  });

  group('refuses what it cannot or must not read, with a reason', () {
    test('empty, oversized, unsupported type', () async {
      expect(await _problem('a.pdf', Uint8List(0)), DocumentProblem.empty);
      expect(
        await _problem('a.txt', Uint8List(maxDocumentBytes + 1)),
        DocumentProblem.tooLarge,
      );
      expect(
        await _problem('a.xlsx', Uint8List.fromList([1, 2, 3])),
        DocumentProblem.unsupportedType,
      );
    });

    test('disguised executables and mismatched contents', () async {
      final exe = Uint8List.fromList([0x4D, 0x5A, 0x90, 0, 3, 0, 0, 0]);
      for (final name in ['report.pdf', 'report.docx', 'report.txt']) {
        expect(
          await _problem(name, exe),
          DocumentProblem.executable,
          reason: name,
        );
      }
      // A PDF renamed to .docx / .doc, a Word file renamed to .pdf.
      final pdf = await _pdf(['x']);
      expect(await _problem('r.docx', pdf), DocumentProblem.mismatch);
      expect(await _problem('r.doc', pdf), DocumentProblem.mismatch);
      expect(
        await _problem('r.pdf', _fixture('synthetic-report.docx')),
        DocumentProblem.mismatch,
      );
      // A zip that is not a Word document.
      final zip = Uint8List.fromList(
        ZipEncoder().encodeBytes(
          Archive()..add(ArchiveFile.string('a.txt', 'hi')),
        ),
      );
      expect(await _problem('r.docx', zip), DocumentProblem.mismatch);
    });

    test('password-protected Word and PDF files', () async {
      expect(
        await _problem('locked.docx', _fixture('synthetic-locked.docx')),
        DocumentProblem.encrypted,
      );
      expect(
        await _problem('locked.doc', _fixture('synthetic-locked.doc')),
        DocumentProblem.encrypted,
      );
      final locked = sf.PdfDocument();
      locked.pages.add().graphics.drawString(
        'Secret',
        sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 12),
      );
      locked.security.userPassword = 'synthetic-pass';
      final bytes = Uint8List.fromList(await locked.save());
      locked.dispose();
      expect(await _problem('locked.pdf', bytes), DocumentProblem.encrypted);
    });

    test('malformed files and a scanned PDF without text', () async {
      final brokenPdf = Uint8List.fromList(
        ascii.encode('%PDF-1.7\nthis is not really a pdf'),
      );
      expect(await _problem('b.pdf', brokenPdf), DocumentProblem.malformed);
      final brokenZip = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 1, 2, 3]);
      expect(await _problem('b.docx', brokenZip), DocumentProblem.malformed);
      final brokenDoc = Uint8List.fromList([
        0xD0,
        0xCF,
        0x11,
        0xE0,
        0xA1,
        0xB1,
        0x1A,
        0xE1,
        ...List.filled(600, 0),
      ]);
      expect(await _problem('b.doc', brokenDoc), DocumentProblem.malformed);
      // A page with only a drawing: nothing to read.
      final scanned = pw.Document()
        ..addPage(pw.Page(build: (_) => pw.Container(width: 50, height: 50)));
      expect(
        await _problem('scan.pdf', await scanned.save()),
        DocumentProblem.noText,
      );
    });

    test('text that is not UTF-8 / UTF-16 with BOM', () async {
      // "مرحبا" in Windows-1256.
      final cp1256 = Uint8List.fromList([0xE3, 0xD1, 0xCD, 0xC8, 0xC7]);
      expect(
        await _problem('a.txt', cp1256),
        DocumentProblem.unsupportedEncoding,
      );
      final utf16NoBom = Uint8List.fromList([0x41, 0, 0x42, 0]);
      expect(
        await _problem('a.txt', utf16NoBom),
        DocumentProblem.unsupportedEncoding,
      );
    });

    test('a zip bomb stops at the decompression cap', () async {
      // 60 MB of zeros compresses to well under 1 MB.
      final big = Uint8List(60 * 1024 * 1024);
      final archive = Archive()
        ..add(ArchiveFile.bytes('word/document.xml', big))
        ..add(ArchiveFile.string('[Content_Types].xml', '<Types/>'));
      final zip = Uint8List.fromList(ZipEncoder().encodeBytes(archive));
      expect(zip.length, lessThan(maxDocumentBytes));
      expect(await _problem('bomb.docx', zip), DocumentProblem.tooComplex);
    });
  });

  test('long text is cut at the limit and marked incomplete', () async {
    final long = 'Line of synthetic text.\n' * 12000; // ~288k chars
    final doc = await readDocument(
      fileName: 'long.txt',
      bytes: Uint8List.fromList(utf8.encode(long)),
    );
    expect(doc.text.length, maxDocumentChars);
    expect(doc.complete, isFalse);
  });
}
