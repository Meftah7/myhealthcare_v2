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

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static WindowSize fromWidth(double width) {
    if (width < 600) return WindowSize.compact;
    if (width < 840) return WindowSize.medium;
    if (width < 1200) return WindowSize.expanded;
    return WindowSize.large;
  }

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
}
