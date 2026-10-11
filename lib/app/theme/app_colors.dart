/// Softer blue brand palette with hand-authored neutral surfaces.
///
/// Light action blue retains contrast with white labels; pale containers and
/// dark-mode accents carry the lighter sky-blue palette. See DESIGN.md.
/// Clinical status colours live separately in status_colors.dart.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Softer blue seed that retains readable white foregrounds.
  static const Color seed = Color(0xFF4275A3);

  /// Softer blue gradient stops. Legacy token names preserve existing callers.
  static const Color brandMagenta = Color(0xFF5B8FB9);
  static const Color brandViolet = Color(0xFF477AA6);
  static const Color brandBlue = Color(0xFF4275A3);

  /// Left-to-right brand gradient. Reserve the brighter sweep — reserve it for the mark.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandMagenta, brandViolet, brandBlue],
  );

  /// A restrained blue gradient with readable white foregrounds.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF477AA6), Color(0xFF4275A3), Color(0xFF3D719F)],
  );

  /// Ambient glow behind the splash mark — the gradient at low alpha, used as a
  /// radial bloom rather than a fill.
  static const RadialGradient brandGlow = RadialGradient(
    colors: [Color(0x386FA5D2), Color(0x006FA5D2)],
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
        primary: const Color(0xFF4275A3),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFEDF5FC),
        onPrimaryContainer: const Color(0xFF152C49),

        secondary: const Color(0xFF4F6280),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE6EDF7),
        onSecondaryContainer: const Color(0xFF1C2D47),

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
        surface: const Color(0xFFF3F6FB),
        onSurface: const Color(0xFF152C49),
        onSurfaceVariant: const Color(0xFF586A81),
        surfaceDim: const Color(0xFFE6E8EF),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFFBFBFD),
        surfaceContainer: const Color(0xFFEEF4FC),
        surfaceContainerHigh: const Color(0xFFECEEF4),
        surfaceContainerHighest: const Color(0xFFE5E8F0),

        outline: const Color(0xFF8C93A4),
        outlineVariant: const Color(0xFFDFE7F1),
        inverseSurface: const Color(0xFF262A34),
        onInverseSurface: const Color(0xFFF3F4F9),
        inversePrimary: const Color(0xFFB8D5ED),
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
        primary: const Color(0xFFB8D5ED),
        onPrimary: const Color(0xFF0B2A52),
        primaryContainer: const Color(0xFF2D5070),
        onPrimaryContainer: const Color(0xFFEDF5FC),

        secondary: const Color(0xFFC0CCDD),
        onSecondary: const Color(0xFF2E2F43),
        secondaryContainer: const Color(0xFF2A3A52),
        onSecondaryContainer: const Color(0xFFE6EDF7),

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
        inversePrimary: const Color(0xFF4275A3),
        surfaceTint: Colors.transparent,
      );

  // --- patient (approved blue rebuild) ------------------------------------

  /// The patient-facing action blue (#246BFD). Staff/admin keep [seed].
  static const Color patientBlue = Color(0xFF246BFD);

  /// The patient splash/brand-mark gradient — the approved action blue.
  static const LinearGradient patientBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C86FF), patientBlue, Color(0xFF1A56D6)],
  );

  /// Soft blue bloom behind the patient splash mark.
  static const RadialGradient patientBrandGlow = RadialGradient(
    colors: [Color(0x38246BFD), Color(0x00246BFD)],
  );

  /// Patient light scheme: soft-grey canvas, white cards, charcoal text and
  /// the bright action blue. Tokens: PatientPalette.light.
  static final ColorScheme patientLight =
      ColorScheme.fromSeed(
        seedColor: patientBlue,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        // Text/icon blue: #246BFD measures 4.27:1 on the #F7F7F8 canvas, so
        // links use a slightly deeper blue (≈5.2:1). Filled actions keep
        // #246BFD via the patient theme's button overrides.
        primary: const Color(0xFF1F5FE0),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE9F0FF),
        onPrimaryContainer: const Color(0xFF0B2E7A),

        secondary: const Color(0xFF4E5D73),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE9F0FF),
        onSecondaryContainer: const Color(0xFF1B3A7A),

        tertiary: const Color(0xFF0E8F65),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFE6F7F0),
        onTertiaryContainer: const Color(0xFF0B4D37),

        error: const Color(0xFFBA1A2E),
        onError: Colors.white,
        errorContainer: const Color(0xFFFDE8EA),
        onErrorContainer: const Color(0xFF5E1014),

        surface: const Color(0xFFF7F7F8),
        onSurface: const Color(0xFF2D333C),
        onSurfaceVariant: const Color(0xFF5F6770),
        surfaceDim: const Color(0xFFE4E7EB),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFFBFBFC),
        surfaceContainer: const Color(0xFFF0F2F5),
        surfaceContainerHigh: const Color(0xFFEBEDF0),
        surfaceContainerHighest: const Color(0xFFE4E7EB),

        outline: const Color(0xFF8B929A),
        outlineVariant: const Color(0xFFEBEDF0),
        inverseSurface: const Color(0xFF2D333C),
        onInverseSurface: const Color(0xFFF7F7F8),
        inversePrimary: const Color(0xFFA9C4FF),
        surfaceTint: Colors.transparent,
      );

  /// Patient dark scheme: navy canvas (#111B28) with lifted cards (#1C2839).
  /// `primary` is a lighter blue so links/icons stay readable on navy; filled
  /// buttons still use #246BFD via the patient theme's button overrides.
  static final ColorScheme patientDark =
      ColorScheme.fromSeed(
        seedColor: patientBlue,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: const Color(0xFF8AB2FF),
        onPrimary: const Color(0xFF08244F),
        primaryContainer: const Color(0xFF213858),
        onPrimaryContainer: const Color(0xFFDCE7FF),

        secondary: const Color(0xFFA4B1C2),
        onSecondary: const Color(0xFF1A2433),
        secondaryContainer: const Color(0xFF213858),
        onSecondaryContainer: const Color(0xFFDCE7FF),

        tertiary: const Color(0xFF4FD1A5),
        onTertiary: const Color(0xFF003826),
        tertiaryContainer: const Color(0xFF163C36),
        onTertiaryContainer: const Color(0xFFBDF2DD),

        error: const Color(0xFFFF8A8F),
        onError: const Color(0xFF4A0B10),
        errorContainer: const Color(0xFF5C1A22),
        onErrorContainer: const Color(0xFFFFDADA),

        surface: const Color(0xFF111B28),
        onSurface: const Color(0xFFEEF3F9),
        onSurfaceVariant: const Color(0xFFA4B1C2),
        surfaceDim: const Color(0xFF0B131D),
        surfaceBright: const Color(0xFF2A3850),
        surfaceContainerLowest: const Color(0xFF0D1622),
        surfaceContainerLow: const Color(0xFF1C2839),
        surfaceContainer: const Color(0xFF19253A),
        surfaceContainerHigh: const Color(0xFF1C2839),
        surfaceContainerHighest: const Color(0xFF26344A),

        outline: const Color(0xFF6F7D90),
        outlineVariant: const Color(0xFF2C394A),
        inverseSurface: const Color(0xFFEEF3F9),
        onInverseSurface: const Color(0xFF1C2839),
        inversePrimary: patientBlue,
        surfaceTint: Colors.transparent,
      );
}
