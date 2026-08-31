/// Spacing and shape tokens for MyHealth Care.
///
/// Spec: DESIGN.md §4. 4dp base grid. Every gap, gutter and radius in the app
/// comes from here — no magic numbers in widgets.
library;

import 'package:flutter/widgets.dart';

/// 4dp-based spacing scale (DESIGN.md §4.1).
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;

  /// Default screen gutter on compact widths.
  static const double md = 16;

  /// Screen gutter on medium+ widths; also card interior padding.
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii (DESIGN.md §4.2). No fully-circular ("pill") buttons — they
/// waste horizontal space on dense clinical screens.
abstract final class Radii {
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(28),
  );
  static const BorderRadius field = BorderRadius.all(Radius.circular(12));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(8));
  static const BorderRadius button = BorderRadius.all(Radius.circular(12));
}
