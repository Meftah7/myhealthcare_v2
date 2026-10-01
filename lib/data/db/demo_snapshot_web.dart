import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Fetches `demo_seed.sqlite` next to the app (under the page's base href).
/// Any failure — missing file, offline, not a SQLite file — returns null so
/// the app falls back to seeding in the browser.
Future<Uint8List?> loadDemoSnapshot() async {
  try {
    final response = await web.window.fetch('demo_seed.sqlite'.toJS).toDart;
    if (!response.ok) return null;
    final buffer = await response.arrayBuffer().toDart;
    final bytes = buffer.toDart.asUint8List();
    const header = 'SQLite format 3';
    if (bytes.length < 100 ||
        String.fromCharCodes(bytes.sublist(0, header.length)) != header) {
      return null;
    }
    return bytes;
  } on Object {
    return null;
  }
}
