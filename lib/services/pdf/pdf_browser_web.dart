import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String _url(Uint8List bytes) => web.URL.createObjectURL(
  web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf')),
);

/// Opens [bytes] in a new tab, in the browser's PDF viewer. Call from a tap
/// so the browser does not treat it as a pop-up.
bool openPdfInBrowser(Uint8List bytes) {
  final opened = web.window.open(_url(bytes), '_blank');
  return opened != null;
}

/// Saves [bytes] as [filename] through the browser's download.
bool downloadPdfInBrowser(Uint8List bytes, String filename) {
  (web.HTMLAnchorElement()
        ..href = _url(bytes)
        ..download = filename)
      .click();
  return true;
}
