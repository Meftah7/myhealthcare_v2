/// Which edges of the screen the shell's own navigation (bottom bar, rail or
/// sidebar) covers, for floating overlays that sit above the shell's Scaffold
/// and so cannot read its geometry themselves.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Published by `AppShell` around its overlay. [navigation] holds physical
/// insets: `bottom` is the measured height of the bottom navigation bar
/// (system inset included) and `left` / `right` the width of the rail or
/// sidebar on whichever side it sits; each is 0 when the layout has none.
class ShellInsets extends InheritedWidget {
  const ShellInsets({
    required this.navigation,
    required super.child,
    super.key,
  });

  final EdgeInsets navigation;

  /// The shell's navigation insets, or none outside a shell.
  static EdgeInsets navigationOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellInsets>()?.navigation ??
      EdgeInsets.zero;

  @override
  bool updateShouldNotify(ShellInsets oldWidget) =>
      oldWidget.navigation != navigation;
}

/// Reports [child]'s laid-out height to [onHeight] (after the frame) whenever
/// a layout changes it. The shell itself decides whether a bar is showing.
class MeasureHeight extends SingleChildRenderObjectWidget {
  const MeasureHeight({required this.onHeight, super.child, super.key});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMeasureHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMeasureHeight renderObject,
  ) => renderObject.onHeight = onHeight;
}

/// The render object behind [MeasureHeight].
class RenderMeasureHeight extends RenderProxyBox {
  RenderMeasureHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _last) return;
    _last = h;
    SchedulerBinding.instance.addPostFrameCallback((_) => onHeight(h));
  }
}
