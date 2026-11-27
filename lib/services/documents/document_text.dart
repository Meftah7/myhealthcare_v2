/// Reads the text of a document a patient attaches: PDF, Word (.docx and
/// legacy .doc) or plain text (.txt). Untrusted input, so every format is
/// checked and bounded:
///  • the extension must match what the bytes actually are, executables are
///    refused whatever they are called, and empty or oversized files too;
///  • PDF reuses the bounded extractor (page and text caps);
///  • .docx is a zip: entry count and decompressed size are capped while
///    inflating, so a zip bomb stops early;
///  • .doc is an OLE compound file: sector chains are bounded and checked,
///    and the text is read from Word's piece table (MS-DOC), never by
///    treating the binary as text;
///  • .txt must be UTF-8 (with or without BOM) or UTF-16 with a BOM.
/// Password-protected files and scanned PDFs without text are reported as
/// such. The caller runs [readDocument] off the UI isolate with a timeout.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../pdf/pdf_text.dart';

/// Largest file accepted (the same limit as Records originals).
const maxDocumentBytes = 20 * 1024 * 1024;

/// Most text kept from one document.
const maxDocumentChars = maxExtractedChars;

enum DocumentFormat {
  pdf('PDF', 'application/pdf', ['pdf']),
  docx(
    'Word',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ['docx'],
  ),
  doc('Word 97–2003', 'application/msword', ['doc']),
  txt('Text', 'text/plain', ['txt']);

  const DocumentFormat(this.label, this.mimeType, this.extensions);

  final String label;
  final String mimeType;
  final List<String> extensions;

  /// Every extension the picker offers.
  static const pickerExtensions = ['pdf', 'docx', 'doc', 'txt'];

  /// The format a file name claims, or null for anything else.
  static DocumentFormat? forFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = name.substring(dot + 1).toLowerCase();
    for (final f in values) {
      if (f.extensions.contains(ext)) return f;
    }
    return null;
  }

  static DocumentFormat? forMimeType(String mime) {
    for (final f in values) {
      if (f.mimeType == mime) return f;
    }
    return null;
  }
}

/// Why a document could not be read.
enum DocumentProblem {
  empty,
  tooLarge,
  unsupportedType,

  /// The bytes are not what the extension says.
  mismatch,
  executable,
  encrypted,
  malformed,

  /// No text at all — typically a scanned PDF.
  noText,
  unsupportedEncoding,

  /// Too complex to read within the limits (time, pages, size).
  tooComplex,
}

class DocumentReadException implements Exception {
  const DocumentReadException(this.problem);
  final DocumentProblem problem;

  @override
  String toString() => 'DocumentReadException($problem)';
}

class ExtractedDocument {
  const ExtractedDocument({
    required this.format,
    required this.text,
    required this.complete,
  });

  final DocumentFormat format;

  /// The text, line breaks normalised to `\n`.
  final String text;

  /// False when the text was cut at [maxDocumentChars].
  final bool complete;
}

/// Validates and reads [bytes] on a background isolate with a time limit.
Future<ExtractedDocument> readDocument({
  required String fileName,
  required Uint8List bytes,
  Duration timeout = const Duration(seconds: 25),
}) async {
  // Cheap checks first, on this isolate, so the file is not copied for a
  // file that is refused anyway.
  final format = checkDocument(fileName: fileName, bytes: bytes);
  try {
    return await compute(_extractEntry, (
      format: format,
      bytes: bytes,
    )).timeout(timeout);
  } on DocumentReadException {
    rethrow;
  } on Object {
    throw const DocumentReadException(DocumentProblem.tooComplex);
  }
}

ExtractedDocument _extractEntry(
  ({DocumentFormat format, Uint8List bytes}) input,
) => extractDocument(input.format, input.bytes);

bool _startsWith(Uint8List b, List<int> magic) {
  if (b.length < magic.length) return false;
  for (var i = 0; i < magic.length; i++) {
    if (b[i] != magic[i]) return false;
  }
  return true;
}

const _pdfMagic = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
const _zipMagic = [0x50, 0x4B, 0x03, 0x04]; // PK\3\4
const _cfbMagic = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];

bool _isExecutable(Uint8List b) =>
    _startsWith(b, const [0x4D, 0x5A]) || // MZ (Windows)
    _startsWith(b, const [0x7F, 0x45, 0x4C, 0x46]) || // ELF
    _startsWith(b, const [0xFE, 0xED, 0xFA, 0xCE]) || // Mach-O
    _startsWith(b, const [0xFE, 0xED, 0xFA, 0xCF]) ||
    _startsWith(b, const [0xCE, 0xFA, 0xED, 0xFE]) ||
    _startsWith(b, const [0xCF, 0xFA, 0xED, 0xFE]) ||
    _startsWith(b, const [0xCA, 0xFE, 0xBA, 0xBE]); // fat binary / class

/// The format of an acceptable file, or [DocumentReadException]: unknown
/// extension, empty, too large, executable, or bytes that do not match the
/// extension.
DocumentFormat checkDocument({
  required String fileName,
  required Uint8List bytes,
}) {
  final format = DocumentFormat.forFileName(fileName);
  if (format == null) {
    throw const DocumentReadException(DocumentProblem.unsupportedType);
  }
  if (bytes.isEmpty) throw const DocumentReadException(DocumentProblem.empty);
  if (bytes.length > maxDocumentBytes) {
    throw const DocumentReadException(DocumentProblem.tooLarge);
  }
  if (_isExecutable(bytes)) {
    throw const DocumentReadException(DocumentProblem.executable);
  }
  final ok = switch (format) {
    DocumentFormat.pdf => _startsWith(bytes, _pdfMagic),
    // An encrypted .docx is an OLE container, checked when read.
    DocumentFormat.docx =>
      _startsWith(bytes, _zipMagic) || _startsWith(bytes, _cfbMagic),
    DocumentFormat.doc => _startsWith(bytes, _cfbMagic),
    DocumentFormat.txt =>
      !_startsWith(bytes, _pdfMagic) &&
          !_startsWith(bytes, _zipMagic) &&
          !_startsWith(bytes, _cfbMagic),
  };
  if (!ok) throw const DocumentReadException(DocumentProblem.mismatch);
  return format;
}

/// Reads the text of an already checked document. Throws
/// [DocumentReadException].
ExtractedDocument extractDocument(DocumentFormat format, Uint8List bytes) {
  final raw = switch (format) {
    DocumentFormat.pdf => _pdfText(bytes),
    DocumentFormat.docx => _docxText(bytes),
    DocumentFormat.doc => _docText(bytes),
    DocumentFormat.txt => _txtText(bytes),
  };
  final text = _normalise(raw);
  if (text.trim().isEmpty) {
    throw const DocumentReadException(DocumentProblem.noText);
  }
  final complete = text.length <= maxDocumentChars;
  return ExtractedDocument(
    format: format,
    text: complete ? text : text.substring(0, maxDocumentChars),
    complete: complete,
  );
}

String _normalise(String text) => text
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .replaceAll(RegExp(r'[ \t]+\n'), '\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

// --- PDF -------------------------------------------------------------------

bool _containsAscii(Uint8List b, String token) {
  final t = ascii.encode(token);
  outer:
  for (var i = 0; i <= b.length - t.length; i++) {
    for (var j = 0; j < t.length; j++) {
      if (b[i + j] != t[j]) continue outer;
    }
    return true;
  }
  return false;
}

String _pdfText(Uint8List bytes) {
  try {
    return extractPdfText(bytes);
  } on FormatException catch (e) {
    if (e.message == 'too many pages') {
      throw const DocumentReadException(DocumentProblem.tooComplex);
    }
    throw const DocumentReadException(DocumentProblem.malformed);
  } on Object {
    // A password-protected PDF cannot be opened without its password.
    throw DocumentReadException(
      _containsAscii(bytes, '/Encrypt')
          ? DocumentProblem.encrypted
          : DocumentProblem.malformed,
    );
  }
}

// --- DOCX ------------------------------------------------------------------

const _maxZipEntries = 5000;
const _maxDocumentXmlBytes = 40 * 1024 * 1024;

/// An output stream that refuses to grow past [cap] bytes: decompression
/// stops as soon as a zip entry inflates beyond it.
class _CappedOutput extends OutputMemoryStream {
  _CappedOutput(this.cap);
  final int cap;

  void _check(int more) {
    if (length + more > cap) {
      throw const DocumentReadException(DocumentProblem.tooComplex);
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }
}

String _docxText(Uint8List bytes) {
  if (_startsWith(bytes, _cfbMagic)) {
    // Office stores a password-protected .docx inside an OLE container.
    final cfb = _Cfb.parse(bytes);
    throw DocumentReadException(
      cfb.has('EncryptedPackage')
          ? DocumentProblem.encrypted
          : DocumentProblem.mismatch,
    );
  }
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  // A truncated zip decodes to nothing rather than throwing.
  if (archive.isEmpty) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  if (archive.length > _maxZipEntries) {
    throw const DocumentReadException(DocumentProblem.tooComplex);
  }
  final entry = archive.find('word/document.xml');
  if (entry == null || !entry.isFile) {
    throw const DocumentReadException(DocumentProblem.mismatch);
  }
  final out = _CappedOutput(_maxDocumentXmlBytes);
  try {
    entry.decompress(out);
  } on DocumentReadException {
    rethrow;
  } on Object {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  final XmlDocument xml;
  try {
    xml = XmlDocument.parse(utf8.decode(out.getBytes(), allowMalformed: true));
  } on Object {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  final body = xml.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 'body')
      .firstOrNull;
  if (body == null) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  final buffer = StringBuffer();
  _writeBlock(body, buffer);
  return buffer.toString();
}

/// Paragraphs and tables in reading order.
void _writeBlock(XmlElement parent, StringBuffer out) {
  for (final child in parent.childElements) {
    switch (child.name.local) {
      case 'p':
        out.writeln(_paragraphText(child));
      case 'tbl':
        for (final row in child.childElements.where(
          (e) => e.name.local == 'tr',
        )) {
          final cells = [
            for (final cell in row.childElements.where(
              (e) => e.name.local == 'tc',
            ))
              cell.childElements
                  .where((e) => e.name.local == 'p')
                  .map(_paragraphText)
                  .where((t) => t.trim().isNotEmpty)
                  .join(' ')
                  .trim(),
          ];
          out.writeln(cells.join(' | '));
        }
      // Content controls and custom XML wrap ordinary blocks.
      case 'sdt' || 'sdtContent' || 'customXml':
        _writeBlock(child, out);
    }
  }
}

String _paragraphText(XmlElement p) {
  final out = StringBuffer();
  for (final node in p.descendants.whereType<XmlElement>()) {
    switch (node.name.local) {
      case 't':
        out.write(node.innerText);
      case 'tab':
        out.write('\t');
      case 'br' || 'cr':
        out.write('\n');
    }
  }
  return out.toString();
}

// --- DOC (OLE compound file + Word piece table) -----------------------------

const _endOfChain = 0xFFFFFFFE;
const _freeSector = 0xFFFFFFFF;

class _DirEntry {
  const _DirEntry(this.name, this.type, this.start, this.size);
  final String name;
  final int type;
  final int start;
  final int size;
}

/// A bounded reader for OLE compound files (MS-CFB).
class _Cfb {
  _Cfb._(
    this.bytes,
    this.sectorSize,
    this.fat,
    this.dir,
    this.miniFat,
    this.miniStream,
    this.cutoff,
  );

  final Uint8List bytes;
  final int sectorSize;
  final List<int> fat;
  final List<_DirEntry> dir;
  final List<int> miniFat;
  final Uint8List miniStream;
  final int cutoff;

  static int _u16(Uint8List b, int o) {
    if (o < 0 || o + 2 > b.length) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }
    return b[o] | b[o + 1] << 8;
  }

  static int _u32(Uint8List b, int o) {
    if (o < 0 || o + 4 > b.length) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }
    return b[o] | b[o + 1] << 8 | b[o + 2] << 16 | b[o + 3] << 24;
  }

  static _Cfb parse(Uint8List b) {
    if (!_startsWith(b, _cfbMagic) || b.length < 512) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }
    if (_u16(b, 0x1C) != 0xFFFE) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }
    final shift = _u16(b, 0x1E);
    if (shift != 9 && shift != 12) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }
    final sectorSize = 1 << shift;
    final miniShift = _u16(b, 0x20);
    if (miniShift != 6) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }
    final totalSectors = (b.length ~/ sectorSize) + 1;
    final numFat = _u32(b, 0x2C);
    if (numFat > totalSectors) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }

    // FAT sector numbers: 109 in the header, the rest in the DIFAT chain.
    final fatSectors = <int>[];
    for (var i = 0; i < 109 && fatSectors.length < numFat; i++) {
      final s = _u32(b, 0x4C + i * 4);
      if (s != _freeSector) fatSectors.add(s);
    }
    var difat = _u32(b, 0x44);
    var guard = 0;
    while (fatSectors.length < numFat &&
        difat != _endOfChain &&
        difat != _freeSector) {
      if (++guard > totalSectors) {
        throw const DocumentReadException(DocumentProblem.malformed);
      }
      final base = (difat + 1) * sectorSize;
      final per = sectorSize ~/ 4 - 1;
      for (var i = 0; i < per && fatSectors.length < numFat; i++) {
        final s = _u32(b, base + i * 4);
        if (s != _freeSector) fatSectors.add(s);
      }
      difat = _u32(b, base + per * 4);
    }

    final fat = <int>[];
    for (final s in fatSectors) {
      final base = (s + 1) * sectorSize;
      for (var i = 0; i < sectorSize ~/ 4; i++) {
        fat.add(_u32(b, base + i * 4));
      }
    }

    List<int> chain(int start, List<int> table, int limit) {
      final out = <int>[];
      var s = start;
      while (s != _endOfChain && s != _freeSector) {
        if (s < 0 || s >= table.length || out.length > limit) {
          throw const DocumentReadException(DocumentProblem.malformed);
        }
        out.add(s);
        s = table[s];
      }
      return out;
    }

    Uint8List readChain(int start, int size) {
      final sectors = chain(start, fat, totalSectors);
      final out = BytesBuilder(copy: false);
      for (final s in sectors) {
        final base = (s + 1) * sectorSize;
        if (base + sectorSize > b.length) {
          // The last sector of a file may be short.
          if (base < b.length) out.add(b.sublist(base));
          continue;
        }
        out.add(Uint8List.sublistView(b, base, base + sectorSize));
      }
      final all = out.takeBytes();
      return size >= 0 && size <= all.length
          ? Uint8List.sublistView(all, 0, size)
          : all;
    }

    final dirBytes = readChain(_u32(b, 0x30), -1);
    final dir = <_DirEntry>[];
    for (var o = 0; o + 128 <= dirBytes.length; o += 128) {
      final nameLen = _u16(dirBytes, o + 0x40);
      final name = nameLen >= 2 && nameLen <= 64
          ? String.fromCharCodes([
              for (var i = 0; i < nameLen ~/ 2 - 1; i++)
                _u16(dirBytes, o + i * 2),
            ])
          : '';
      dir.add(
        _DirEntry(
          name,
          dirBytes[o + 0x42],
          _u32(dirBytes, o + 0x74),
          _u32(dirBytes, o + 0x78),
        ),
      );
    }
    if (dir.isEmpty || dir.first.type != 5) {
      throw const DocumentReadException(DocumentProblem.malformed);
    }

    final miniFatBytes = _u32(b, 0x40) == 0
        ? Uint8List(0)
        : readChain(_u32(b, 0x3C), -1);
    final miniFat = [
      for (var o = 0; o + 4 <= miniFatBytes.length; o += 4)
        _u32(miniFatBytes, o),
    ];
    final root = dir.first;
    final miniStream = root.start == _endOfChain
        ? Uint8List(0)
        : readChain(root.start, root.size);

    final cfb = _Cfb._(
      b,
      sectorSize,
      fat,
      dir,
      miniFat,
      miniStream,
      _u32(b, 0x38),
    );
    cfb._readChain = readChain;
    cfb._chain = chain;
    return cfb;
  }

  late final Uint8List Function(int start, int size) _readChain;
  late final List<int> Function(int start, List<int> table, int limit) _chain;

  bool has(String name) => dir.any((e) => e.type == 2 && e.name == name);

  Uint8List? stream(String name) {
    final entry = dir.where((e) => e.type == 2 && e.name == name).firstOrNull;
    if (entry == null) return null;
    if (entry.size >= cutoff) return _readChain(entry.start, entry.size);
    // Small streams live in the mini stream, in 64-byte sectors.
    final sectors = _chain(entry.start, miniFat, miniStream.length ~/ 64 + 1);
    final out = BytesBuilder(copy: false);
    for (final s in sectors) {
      final base = s * 64;
      if (base + 64 > miniStream.length) {
        throw const DocumentReadException(DocumentProblem.malformed);
      }
      out.add(Uint8List.sublistView(miniStream, base, base + 64));
    }
    final all = out.takeBytes();
    return entry.size <= all.length
        ? Uint8List.sublistView(all, 0, entry.size)
        : all;
  }
}

/// Windows-1252 for the bytes Word stores in "compressed" text pieces
/// (0x80–0x9F differ from Latin-1).
const _cp1252 = {
  0x80: 0x20AC,
  0x82: 0x201A,
  0x83: 0x0192,
  0x84: 0x201E,
  0x85: 0x2026,
  0x86: 0x2020,
  0x87: 0x2021,
  0x88: 0x02C6,
  0x89: 0x2030,
  0x8A: 0x0160,
  0x8B: 0x2039,
  0x8C: 0x0152,
  0x8E: 0x017D,
  0x91: 0x2018,
  0x92: 0x2019,
  0x93: 0x201C,
  0x94: 0x201D,
  0x95: 0x2022,
  0x96: 0x2013,
  0x97: 0x2014,
  0x98: 0x02DC,
  0x99: 0x2122,
  0x9A: 0x0161,
  0x9B: 0x203A,
  0x9C: 0x0153,
  0x9E: 0x017E,
  0x9F: 0x0178,
};

String _docText(Uint8List bytes) {
  final cfb = _Cfb.parse(bytes);
  final wd = cfb.stream('WordDocument');
  if (wd == null) {
    throw DocumentReadException(
      cfb.has('EncryptedPackage')
          ? DocumentProblem.encrypted
          : DocumentProblem.mismatch,
    );
  }
  const u16 = _Cfb._u16;
  const u32 = _Cfb._u32;
  if (u16(wd, 0) != 0xA5EC) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  // Word 6/95 and older keep text differently: not supported.
  if (u16(wd, 2) < 0x00C1) {
    throw const DocumentReadException(DocumentProblem.unsupportedType);
  }
  final flags = u16(wd, 0x0A);
  if (flags & 0x0100 != 0) {
    throw const DocumentReadException(DocumentProblem.encrypted);
  }
  final table = cfb.stream(flags & 0x0200 != 0 ? '1Table' : '0Table');
  if (table == null) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }

  // FIB: FibBase (32 bytes), csw + FibRgW, cslw + FibRgLw, cbRgFcLcb + blob.
  final csw = u16(wd, 0x20);
  final lwAt = 0x22 + csw * 2;
  final cslw = u16(wd, lwAt);
  final ccpText = u32(wd, lwAt + 2 + 12);
  final fcLcbAt = lwAt + 2 + cslw * 4;
  final cbRgFcLcb = u16(wd, fcLcbAt);
  if (cbRgFcLcb < 34) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  final blob = fcLcbAt + 2;
  final fcClx = u32(wd, blob + 33 * 8);
  final lcbClx = u32(wd, blob + 33 * 8 + 4);
  if (lcbClx == 0 || fcClx + lcbClx > table.length || ccpText > 20000000) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  final clx = Uint8List.sublistView(table, fcClx, fcClx + lcbClx);

  // Skip Prc entries (formatting), then the piece table (Pcdt).
  var i = 0;
  while (i < clx.length && clx[i] == 0x01) {
    final cb = u16(clx, i + 1);
    i += 3 + cb;
  }
  if (i >= clx.length || clx[i] != 0x02) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  final lcb = u32(clx, i + 1);
  final plc = i + 5;
  if (plc + lcb > clx.length || lcb < 16) {
    throw const DocumentReadException(DocumentProblem.malformed);
  }
  final n = (lcb - 4) ~/ 12;
  final out = StringBuffer();
  var written = 0;
  for (var k = 0; k < n && written <= maxDocumentChars; k++) {
    final cpStart = u32(clx, plc + k * 4);
    final cpEnd = u32(clx, plc + (k + 1) * 4);
    final start = cpStart.clamp(0, ccpText);
    final end = cpEnd.clamp(0, ccpText);
    if (end <= start) continue;
    final pcd = plc + (n + 1) * 4 + k * 8;
    final raw = u32(clx, pcd + 2);
    final compressed = raw & 0x40000000 != 0;
    final fc = raw & 0x3FFFFFFF;
    final count = end - start;
    if (compressed) {
      final at = fc ~/ 2 + (start - cpStart);
      if (at < 0 || at + count > wd.length) {
        throw const DocumentReadException(DocumentProblem.malformed);
      }
      for (var c = 0; c < count; c++) {
        final byte = wd[at + c];
        out.writeCharCode(_cp1252[byte] ?? byte);
      }
    } else {
      final at = fc + 2 * (start - cpStart);
      if (at < 0 || at + count * 2 > wd.length) {
        throw const DocumentReadException(DocumentProblem.malformed);
      }
      for (var c = 0; c < count; c++) {
        out.writeCharCode(wd[at + c * 2] | wd[at + c * 2 + 1] << 8);
      }
    }
    written += count;
  }
  return _wordControls(out.toString());
}

/// Word's special characters: paragraph and cell marks become line breaks
/// and separators; field instructions are dropped and their results kept.
String _wordControls(String raw) {
  final out = StringBuffer();
  // Per open field: true while still in its instruction part.
  final fields = <bool>[];
  for (final code in raw.runes) {
    switch (code) {
      case 0x13: // field begin
        fields.add(true);
        continue;
      case 0x14: // field separator
        if (fields.isNotEmpty) fields[fields.length - 1] = false;
        continue;
      case 0x15: // field end
        if (fields.isNotEmpty) fields.removeLast();
        continue;
    }
    if (fields.isNotEmpty && fields.last) continue;
    switch (code) {
      case 0x0D || 0x0B || 0x0C || 0x0E:
        out.write('\n');
      case 0x07: // cell / row end
        out.write(' | ');
      case 0x09:
        out.write('\t');
      case 0x1E:
        out.write('-');
      case 0xA0:
        out.write(' ');
      default:
        if (code >= 0x20) out.writeCharCode(code);
    }
  }
  return out
      .toString()
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'(\s*\|\s*)+$'), '').trimRight())
      .join('\n');
}

// --- TXT -------------------------------------------------------------------

String _txtText(Uint8List b) {
  try {
    if (_startsWith(b, const [0xEF, 0xBB, 0xBF])) {
      return utf8.decode(Uint8List.sublistView(b, 3));
    }
    if (_startsWith(b, const [0xFF, 0xFE])) return _utf16(b, 2, little: true);
    if (_startsWith(b, const [0xFE, 0xFF])) return _utf16(b, 2, little: false);
  } on FormatException {
    throw const DocumentReadException(DocumentProblem.unsupportedEncoding);
  }
  // NUL bytes: binary data, or UTF-16 without a byte-order mark.
  if (b.contains(0)) {
    throw const DocumentReadException(DocumentProblem.unsupportedEncoding);
  }
  try {
    return utf8.decode(b);
  } on FormatException {
    // Not UTF-8 (for example Windows-1256): ask for a UTF-8 copy rather
    // than guessing a code page.
    throw const DocumentReadException(DocumentProblem.unsupportedEncoding);
  }
}

String _utf16(Uint8List b, int start, {required bool little}) {
  if ((b.length - start).isOdd) throw const FormatException('odd length');
  final units = <int>[
    for (var i = start; i + 1 < b.length; i += 2)
      little ? b[i] | b[i + 1] << 8 : b[i] << 8 | b[i + 1],
  ];
  return String.fromCharCodes(units);
}
