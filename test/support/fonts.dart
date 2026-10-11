import 'package:flutter/services.dart';

/// Flutter bundles this font for uses-material-design apps on every platform.
/// Loading through the test asset bundle avoids SDK paths and FLUTTER_ROOT.
Future<void> loadMaterialIcons() async {
  final loader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await loader.load();
}
