import 'dart:typed_data';

/// Native builds have no shipped snapshot.
Future<Uint8List?> loadDemoSnapshot() async => null;
