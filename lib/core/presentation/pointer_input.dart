/// Whether the person is driving the app with a mouse or trackpad (a laptop,
/// a PC, any screen without touch) rather than a finger or stylus — for
/// controls that only make sense with a pointer, like the "<" / ">" buttons
/// on horizontal rows that touch users simply swipe.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Wrap the app once (at its root). It starts from the platform — desktop
/// operating systems, in a browser or not, assume a mouse; phones and tablets
/// assume touch — and then follows the input actually used: moving a mouse,
/// scrolling a wheel or using a trackpad switches to "mouse", touching the
/// screen switches back. A touchscreen laptop therefore shows pointer-only
/// controls while the mouse is in use and hides them once it is touched.
class PointerInput extends StatefulWidget {
  const PointerInput({required this.child, super.key});

  final Widget child;

  /// True when pointer-only controls should show. Outside a [PointerInput]
  /// this falls back to the platform guess.
  static bool usesMouse(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PointerInputScope>()
          ?.usesMouse ??
      platformDefault;

  /// The guess before any input: touch on phones and tablets, a mouse
  /// everywhere else.
  static bool get platformDefault => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => false,
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux => true,
  };

  @override
  State<PointerInput> createState() => _PointerInputState();
}

class _PointerInputState extends State<PointerInput> {
  late bool _usesMouse = PointerInput.platformDefault;

  void _saw(PointerDeviceKind kind) {
    final mouse =
        kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.trackpad;
    if (mouse != _usesMouse) setState(() => _usesMouse = mouse);
  }

  @override
  Widget build(BuildContext context) => Listener(
    // Only observes: every event still reaches the widgets underneath.
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) => _saw(e.kind),
    // Only a mouse (or a hovering stylus) produces hover events.
    onPointerHover: (e) => _saw(e.kind),
    onPointerSignal: (e) => _saw(e.kind),
    onPointerPanZoomStart: (_) => _saw(PointerDeviceKind.trackpad),
    child: _PointerInputScope(usesMouse: _usesMouse, child: widget.child),
  );
}

class _PointerInputScope extends InheritedWidget {
  const _PointerInputScope({required this.usesMouse, required super.child});

  final bool usesMouse;

  @override
  bool updateShouldNotify(_PointerInputScope oldWidget) =>
      oldWidget.usesMouse != usesMouse;
}
