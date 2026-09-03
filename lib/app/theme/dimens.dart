/// Spacing, shape and elevation tokens for MyHealth Care (redesign v2).
///
/// Spec: DESIGN.md §4. 4dp base grid. Every gap, gutter, radius and shadow in
/// the app comes from here — no magic numbers in widgets.
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

  /// Widest a reading column is allowed to grow before it is centred (§6).
  static const double maxContentWidth = 1120;
}

/// Corner radii (DESIGN.md §4.2). No fully-circular buttons — they waste
/// horizontal space on dense clinical screens; [pill] is for status badges,
/// which are not buttons.
abstract final class Radii {
  static const BorderRadius card = BorderRadius.all(Radius.circular(20));
  static const BorderRadius cardSmall = BorderRadius.all(Radius.circular(14));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(28),
  );
  static const BorderRadius field = BorderRadius.all(Radius.circular(14));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(10));
  static const BorderRadius button = BorderRadius.all(Radius.circular(14));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Depth (DESIGN.md §4.3). The redesign moves off heavy M3 surface-tint onto
/// **flat surfaces + a hairline border + one soft shadow** — the modern
/// product-UI look. Real shadows stay whisper-soft.
abstract final class Shadows {
  /// Resting card / raised surface. Barely there — it lifts, it doesn't loom.
  static const List<BoxShadow> e1 = [
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Menus, active search, popovers.
  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0D101828),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Dialogs, modal sheets, the FAB.
  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color(0x1F101828),
      blurRadius: 40,
      offset: Offset(0, 18),
    ),
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}
