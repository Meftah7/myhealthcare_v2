/// Material 3 window size classes (DESIGN.md §6).
///
/// One widget tree, re-flowed by size class — never separate phone/desktop
/// layouts. Compact is the design baseline: if it works at 360dp it works
/// everywhere.
library;

import 'package:flutter/widgets.dart';

enum WindowSize {
  /// < 600dp — `NavigationBar` (bottom), single pane, detail = full-screen push.
  compact,

  /// 600–839dp — `NavigationRail` (icons), single pane, wider gutters.
  medium,

  /// 840–1199dp — `NavigationRail` extended, list-detail 40/60 where it helps.
  expanded,

  /// ≥ 1200dp — persistent detail pane, content column capped ~1100 and centred.
  large;

  static WindowSize of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return fromSize(width: size.width, shortestSide: size.shortestSide);
  }

  /// Width alone misclassifies a rotated phone as a tablet — an iPhone in
  /// landscape is ~844dp wide (past the 840dp `expanded` cutoff) but only
  /// ~390dp on its short side. Gating on `shortestSide` too keeps a phone in
  /// `compact` in both orientations while leaving genuinely wide windows
  /// (tablets, desktop — whose shortest side is already ≥ 600dp) unaffected.
  static WindowSize fromSize({required double width, double? shortestSide}) {
    final short = shortestSide ?? width;
    if (width < 600 || short < 600) return WindowSize.compact;
    if (width < 840) return WindowSize.medium;
    if (width < 1200) return WindowSize.expanded;
    return WindowSize.large;
  }

  static WindowSize fromWidth(double width) => fromSize(width: width);

  bool get isCompact => this == WindowSize.compact;
  bool get isMedium => this == WindowSize.medium;
  bool get isExpanded => this == WindowSize.expanded;
  bool get isLarge => this == WindowSize.large;

  /// True once a `NavigationRail` replaces the bottom `NavigationBar`.
  bool get usesRail => this != WindowSize.compact;

  /// True once list-detail layouts should show both panes side by side.
  bool get usesPanes => this == WindowSize.expanded || this == WindowSize.large;

  /// Default screen edge padding for this size class (DESIGN.md §4.1).
  double get gutter => this == WindowSize.compact ? 16 : 24;

  /// Columns for a grid of short shortcut tiles (`TileGrid`). Two on a phone,
  /// and one more each time the content column can carry it without the tiles
  /// growing wider than the label they hold.
  int get tileColumns => switch (this) {
    WindowSize.compact => 2,
    WindowSize.medium => 2,
    WindowSize.expanded => 3,
    WindowSize.large => 4,
  };
}
