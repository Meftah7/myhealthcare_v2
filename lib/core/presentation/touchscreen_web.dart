import 'package:web/web.dart' as web;

bool get hasTouchscreen => web.window.navigator.maxTouchPoints > 0;
