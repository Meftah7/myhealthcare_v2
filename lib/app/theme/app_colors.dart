/// Brand colour and the [ColorScheme]s for MyHealth Care (redesign v3).
///
/// Spec: DESIGN.md §2. One indigo-violet seed drawn from the "MyHealth Care"
/// mark (magenta → violet → blue). Material 3 derives the accent roles from it
/// — but the **neutral ramp is hand-authored**, because M3's generated greys
/// carry the seed's violet cast into every surface and the container steps land
/// so close together that a card never separates from the page behind it.
///
/// The neutrals here are a cool near-achromatic slate: a lightly-tinted page,
/// pure-white cards in light mode, and a deep-slate elevation ramp in dark.
/// Contrast for every text pair clears WCAG AA; `test/features/accessibility_test.dart`
/// asserts it.
///
/// Status colours are NOT here — they live in [ClinicalStatusColors]
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

  /// Left-to-right brand gradient. Full saturation — reserve it for the mark.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandMagenta, brandViolet, brandBlue],
  );

  /// The calmer sibling of [brandGradient], for large hero surfaces where the
  /// full magenta→blue sweep would shout. Violet-to-blue, no magenta.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D5DF6), Color(0xFF4C43D9), Color(0xFF3F6FE0)],
  );

  /// Ambient glow behind the splash mark — the gradient at low alpha, used as a
  /// radial bloom rather than a fill.
  static const RadialGradient brandGlow = RadialGradient(
    colors: [Color(0x385B4FE9), Color(0x005B4FE9)],
  );

  // --- light ---------------------------------------------------------------

  /// Light scheme. M3 derives the accent families from [seed] with the
  /// *fidelity* variant (which keeps the seed's chroma instead of flattening it
  /// to a muted 36), then the neutral ramp and the brand containers are
  /// replaced with the hand-authored values above.
  static final ColorScheme light =
      ColorScheme.fromSeed(
        seedColor: seed,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: const Color(0xFF5B4FE9),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE7E3FF),
        onPrimaryContainer: const Color(0xFF251C71),

        secondary: const Color(0xFF5C5F80),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE5E3F8),
        onSecondaryContainer: const Color(0xFF2F2B58),

        tertiary: const Color(0xFF0E7C86),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFC5EFF3),
        onTertiaryContainer: const Color(0xFF00363B),

        error: const Color(0xFFBA1A2E),
        onError: Colors.white,
        errorContainer: const Color(0xFFFFDAD9),
        onErrorContainer: const Color(0xFF5E1014),

        // Page sits a step below the cards, so a white card lifts off it
        // without needing a heavy shadow.
        surface: const Color(0xFFF7F8FB),
        onSurface: const Color(0xFF161922),
        onSurfaceVariant: const Color(0xFF585F70),
        surfaceDim: const Color(0xFFE6E8EF),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFFBFBFD),
        surfaceContainer: const Color(0xFFF2F3F8),
        surfaceContainerHigh: const Color(0xFFECEEF4),
        surfaceContainerHighest: const Color(0xFFE5E8F0),

        outline: const Color(0xFF8C93A4),
        outlineVariant: const Color(0xFFDCDFE8),
        inverseSurface: const Color(0xFF262A34),
        onInverseSurface: const Color(0xFFF3F4F9),
        inversePrimary: const Color(0xFFB7ACFF),
        surfaceTint: Colors.transparent,
      );

  // --- dark ----------------------------------------------------------------

  /// Dark scheme — a first-class parity target, not an afterthought (§8). Deep
  /// cool slate rather than M3's violet-brown, with a genuine elevation ramp:
  /// the page is darker than the cards that sit on it.
  static final ColorScheme dark =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: const Color(0xFFB7ACFF),
        onPrimary: const Color(0xFF2C1E78),
        primaryContainer: const Color(0xFF413394),
        onPrimaryContainer: const Color(0xFFE7E3FF),

        secondary: const Color(0xFFC5C4DD),
        onSecondary: const Color(0xFF2E2F43),
        secondaryContainer: const Color(0xFF34315E),
        onSecondaryContainer: const Color(0xFFE5E3F8),

        tertiary: const Color(0xFF5BD5E0),
        onTertiary: const Color(0xFF00363B),
        tertiaryContainer: const Color(0xFF00505A),
        onTertiaryContainer: const Color(0xFFC5EFF3),

        error: const Color(0xFFFFB3B0),
        onError: const Color(0xFF5E1014),
        errorContainer: const Color(0xFF8C1A26),
        onErrorContainer: const Color(0xFFFFDAD9),

        surface: const Color(0xFF0E1015),
        onSurface: const Color(0xFFE8EAF1),
        onSurfaceVariant: const Color(0xFFA7AEC0),
        surfaceDim: const Color(0xFF0A0C10),
        surfaceBright: const Color(0xFF343842),
        surfaceContainerLowest: const Color(0xFF08090C),
        surfaceContainerLow: const Color(0xFF14161D),
        surfaceContainer: const Color(0xFF181B23),
        surfaceContainerHigh: const Color(0xFF1E2129),
        surfaceContainerHighest: const Color(0xFF262A34),

        outline: const Color(0xFF737A8B),
        outlineVariant: const Color(0xFF2E323C),
        inverseSurface: const Color(0xFFE8EAF1),
        onInverseSurface: const Color(0xFF1A1D25),
        inversePrimary: const Color(0xFF5B4FE9),
        surfaceTint: Colors.transparent,
      );
}
