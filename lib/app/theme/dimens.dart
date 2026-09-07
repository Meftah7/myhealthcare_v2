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
///
/// Nested surfaces step *down* by roughly the padding between them, so their
/// curves stay concentric: a [card] holding a [cardSmall] inset by 12–16dp
/// reads as one machined object rather than two stacked rectangles.
abstract final class Radii {
  static const BorderRadius card = BorderRadius.all(Radius.circular(22));
  static const BorderRadius cardSmall = BorderRadius.all(Radius.circular(16));
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
/// product-UI look.
///
/// Every shadow is tinted toward the scheme's deep indigo-slate rather than
/// neutral black: a grey shadow on a cool page reads as dirt, a hue-matched one
/// reads as depth. Two layers each — a wide diffuse ambient pass with negative
/// spread (so it blooms below the card rather than haloing it) and a tight
/// contact shadow that anchors the edge.
abstract final class Shadows {
  /// The shadow hue: the neutral ramp's darkest slate, never pure black.
  static const Color _tint = Color(0xFF1B1F3B);

  /// Resting card / raised surface. Barely there — it lifts, it doesn't loom.
  static const List<BoxShadow> e1 = [
    BoxShadow(
      color: Color(0x0F1B1F3B),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x0A1B1F3B),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: -1,
    ),
  ];

  /// Menus, active search, popovers.
  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color(0x141B1F3B),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x0D1B1F3B),
      blurRadius: 8,
      offset: Offset(0, 3),
      spreadRadius: -2,
    ),
  ];

  /// Dialogs, modal sheets, the FAB.
  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color(0x1F1B1F3B),
      blurRadius: 48,
      offset: Offset(0, 24),
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color(0x141B1F3B),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  /// A coloured bloom for the one brand surface per screen (the splash mark,
  /// the primary hero card). Reads as light coming *off* the surface.
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 32,
      offset: const Offset(0, 14),
      spreadRadius: -10,
    ),
    BoxShadow(
      color: _tint.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];
}
