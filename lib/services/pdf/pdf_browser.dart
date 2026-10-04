/// Hands a finished PDF to the browser on the web; a no-op elsewhere.
///
/// The in-app preview renders pages with pdf.js fetched from a CDN, which
/// the app's Content-Security-Policy (`script-src 'self'`) blocks — so on
/// the web the preview never finished loading. The browser's own PDF viewer
/// needs no extra script.
library;

export 'pdf_browser_stub.dart'
    if (dart.library.js_interop) 'pdf_browser_web.dart';
