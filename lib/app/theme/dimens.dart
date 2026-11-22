/// Spacing, shape and depth tokens for MyHealth Care (clinical bento v5).
///
/// Spec: DESIGN.md §4. 4dp base grid. Every gap, gutter, radius and shadow in
/// the app comes from here — no magic numbers in widgets.
library;

import 'package:flutter/material.dart';

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
  static const double maxFormWidth = 720;
}

/// Corner radii (DESIGN.md §4.2). No fully-circular buttons — they waste
/// horizontal space on dense clinical screens; [pill] is for status badges,
/// which are not buttons.
///
/// Nested surfaces step *down* by roughly the padding between them, so their
/// curves stay concentric: a [card] holding a [cardSmall] inset by 12–16dp
/// reads as one machined object rather than two stacked rectangles.
abstract final class Radii {
  static const BorderRadius card = BorderRadius.all(Radius.circular(24));
  static const BorderRadius cardLarge = BorderRadius.all(Radius.circular(28));
  static const BorderRadius cardSmall = BorderRadius.all(Radius.circular(16));
  static const BorderRadius hero = BorderRadius.all(Radius.circular(28));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(28),
  );
  static const BorderRadius field = BorderRadius.all(Radius.circular(16));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(12));
  static const BorderRadius button = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));

  /// Card radius for the ambient theme: the patient experience uses the
  /// approved larger rounding (22), staff/admin keep [card] (24).
  static BorderRadius cardOf(BuildContext context) =>
      _isPatient(context) ? const BorderRadius.all(Radius.circular(22)) : card;

  /// Hero radius for the ambient theme (patient 24, else [hero]).
  static BorderRadius heroOf(BuildContext context) =>
      _isPatient(context) ? const BorderRadius.all(Radius.circular(24)) : hero;

  static bool _isPatient(BuildContext context) =>
      Theme.of(context).cardTheme.shape is RoundedRectangleBorder &&
      (Theme.of(context).cardTheme.shape! as RoundedRectangleBorder)
              .borderRadius ==
          const BorderRadius.all(Radius.circular(22));
}

/// Small visual rules shared by clay surfaces.
abstract final class Clay {
  /// Light mode normally uses a near-white top-plane seam. High-contrast light
  /// replaces `outlineVariant` with black; keep that stronger token instead of
  /// hiding it behind the decorative highlight.
  static Color seam(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) return scheme.outlineVariant;
    if (scheme.outlineVariant.computeLuminance() < 0.25) {
      return scheme.outlineVariant;
    }
    return Colors.white.withValues(alpha: 0.88);
  }
}

/// The two depth models from DESIGN.md §4.3: low vertical bento shadows for
/// content, and paired top-left light / bottom-right clay depth for genuinely
/// floating docks and overlays.
abstract final class Shadows {
  static const List<BoxShadow> _lightBento = [
    BoxShadow(
      color: Color(0x165C677D),
      blurRadius: 18,
      offset: Offset(0, 7),
      spreadRadius: -6,
    ),
  ];

  static const List<BoxShadow> _lightBentoRaised = [
    BoxShadow(
      color: Color(0x285C677D),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  static const List<BoxShadow> _darkBento = [
    BoxShadow(
      color: Color(0x52001233),
      blurRadius: 18,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  static const List<BoxShadow> _darkBentoRaised = [
    BoxShadow(
      color: Color(0x85001233),
      blurRadius: 30,
      offset: Offset(0, 14),
      spreadRadius: -8,
    ),
  ];

  static const List<BoxShadow> _lightResting = [
    BoxShadow(color: Color(0xE8FFFFFF), blurRadius: 16, offset: Offset(-6, -6)),
    BoxShadow(color: Color(0x3D5C677D), blurRadius: 20, offset: Offset(7, 9)),
  ];

  static const List<BoxShadow> _lightRaised = [
    BoxShadow(color: Color(0xF2FFFFFF), blurRadius: 22, offset: Offset(-8, -8)),
    BoxShadow(color: Color(0x527D8597), blurRadius: 30, offset: Offset(10, 13)),
  ];

  static const List<BoxShadow> _darkResting = [
    BoxShadow(color: Color(0x6B33415C), blurRadius: 15, offset: Offset(-5, -5)),
    BoxShadow(color: Color(0x85001233), blurRadius: 20, offset: Offset(8, 10)),
  ];

  static const List<BoxShadow> _darkRaised = [
    BoxShadow(color: Color(0x805C677D), blurRadius: 22, offset: Offset(-7, -7)),
    BoxShadow(color: Color(0xA6001233), blurRadius: 30, offset: Offset(11, 14)),
  ];

  /// Resting card, icon medallion, or floating navigation surface.
  static List<BoxShadow> clay(ColorScheme scheme, {bool raised = false}) {
    final dark = scheme.brightness == Brightness.dark;
    if (dark) return raised ? _darkRaised : _darkResting;
    return raised ? _lightRaised : _lightResting;
  }

  /// Low, vertical depth for the modular bento surfaces. Unlike the paired
  /// clay light used by floating navigation, these cards should read as one
  /// quiet grid rather than a collection of separate soft objects.
  static List<BoxShadow> bento(ColorScheme scheme, {bool raised = false}) {
    final dark = scheme.brightness == Brightness.dark;
    if (dark) return raised ? _darkBentoRaised : _darkBento;
    return raised ? _lightBentoRaised : _lightBento;
  }

  /// A coloured bloom for the one brand surface per screen (the splash mark,
  /// the primary hero card). Reads as light coming *off* the surface.
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.30),
      blurRadius: 34,
      offset: const Offset(8, 14),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.22),
      blurRadius: 14,
      offset: const Offset(-5, -5),
    ),
  ];
}
