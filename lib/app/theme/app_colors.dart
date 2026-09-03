/// Brand colour and generated [ColorScheme]s for MyHealth Care (redesign v2).
///
/// Spec: DESIGN.md §2. One indigo-violet seed drawn from the "MyHealth Care"
/// mark (magenta → violet → blue); Material 3 derives every role. Status
/// colours are NOT here — they live in [ClinicalStatusColors]
/// (status_colors.dart), because M3 has no role for clinical severity.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Indigo-violet — the visual centre of the brand gradient. Sits far from
  /// every clinical status hue (amber / orange / red / green), holds WCAG
  /// contrast in both themes, and reads as considered rather than clinical-cold.
  static const Color seed = Color(0xFF5B4FE9);

  /// The three brand-gradient stops (mark: magenta → violet → blue). Used
  /// *sparingly and with intent* — the login mark, one hero surface per role,
  /// the empty-state call to action. Never as page decoration (DESIGN.md §1).
  static const Color brandMagenta = Color(0xFFEC4899);
  static const Color brandViolet = Color(0xFF7C5CFC);
  static const Color brandBlue = Color(0xFF3B82F6);

  /// Left-to-right brand gradient.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandMagenta, brandViolet, brandBlue],
  );

  /// Light scheme — let M3 contrast-check the tonal palette; do not hand-pick
  /// roles (DESIGN.md §2.1).
  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed);

  /// Dark scheme — first-class parity target, not an afterthought (§8).
  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}
