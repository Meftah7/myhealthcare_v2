import 'dart:typed_data';

/// Opens [bytes] in a new browser tab. False when not on the web.
bool openPdfInBrowser(Uint8List bytes) => false;

/// Saves [bytes] through the browser's download. False when not on the web.
bool downloadPdfInBrowser(Uint8List bytes, String filename) => false;
