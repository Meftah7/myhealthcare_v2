/// Brand colour and generated [ColorScheme]s for MyHealth Care.
///
/// Spec: DESIGN.md §2. One original deep-teal seed; Material 3 derives every
/// role. Status colours are NOT here — they live in [ClinicalStatusColors]
/// (status_colors.dart), because M3 has no role for clinical severity.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Deep teal — "clinical calm". Reads as medical without the over-used
  /// hospital blue, and sits far from every status hue.
  static const Color seed = Color(0xFF00696E);

  /// Light scheme — let M3 contrast-check the tonal palette; do not hand-pick
  /// roles (DESIGN.md §2.1).
  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: seed,
  );

  /// Dark scheme — first-class parity target, not an afterthought (§8).
  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}
