import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool get hasTouchscreen =>
    web.window.navigator.maxTouchPoints > 0 ||
    // Some WebKit profiles expose touch events and a coarse pointer without
    // reporting touch points. A mouse or trackpad alone is a fine pointer.
    (web.window.has('ontouchstart') &&
        web.window.matchMedia('(any-pointer: coarse)').matches);
