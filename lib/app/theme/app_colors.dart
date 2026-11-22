/// Brand colours and the clay [ColorScheme]s for MyHealth Care (redesign v4).
///
/// Spec: DESIGN.md §2. The identity uses a single blue-to-slate scale. Material
/// 3 derives supporting accent roles from [smartBlue], while the neutral ramps
/// are hand-authored so cards remain distinct from the page in both themes.
///
/// Clinical status colours are intentionally separate in
/// `status_colors.dart`; warning, risk and success hues must keep their
/// established meaning.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- identity palette ----------------------------------------------------

  static const Color smartBlue = Color(0xFF0466C8);
  static const Color sapphire = Color(0xFF0353A4);
  static const Color regalNavy = Color(0xFF023E7D);
  static const Color prussianBlue = Color(0xFF002855);
  static const Color prussianBlue2 = Color(0xFF001845);
  static const Color prussianBlue3 = Color(0xFF001233);
  static const Color twilightIndigo = Color(0xFF33415C);
  static const Color blueSlate = Color(0xFF5C677D);
  static const Color slateGrey = Color(0xFF7D8597);
  static const Color lavenderGrey = Color(0xFF979DAC);

  /// Smart blue is the visual centre of the identity and the Material seed.
  static const Color seed = smartBlue;

  /// Left-to-right brand gradient. Reserve it for the mark and small identity
  /// moments rather than using it as page decoration.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [smartBlue, sapphire, regalNavy],
  );

  /// A deeper version of [brandGradient] for large hero surfaces.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [smartBlue, sapphire, prussianBlue],
  );

  /// Ambient glow behind the splash mark, using smart blue at low alpha.
  static const RadialGradient brandGlow = RadialGradient(
    colors: [Color(0x380466C8), Color(0x000466C8)],
  );

  /// The quiet ambient field behind every transparent scaffold. Light-mode
  /// stops are pale tints of the supplied blue/slate palette; dark mode uses
  /// the Prussian-blue steps directly.
  static LinearGradient pageGradient(Brightness brightness) =>
      brightness == Brightness.light
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F7FC), Color(0xFFEEF2F7), Color(0xFFE9EDF3)],
          stops: [0, 0.58, 1],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [prussianBlue2, prussianBlue3, prussianBlue],
          stops: [0, 0.6, 1],
        );

  /// A small highlight shift across neutral cards. Shadows provide the depth;
  /// this gradient supplies the softly moulded top plane.
  static LinearGradient claySurfaceGradient(Brightness brightness) =>
      brightness == Brightness.light
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F5F8)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [prussianBlue, prussianBlue2],
        );

  // --- light ---------------------------------------------------------------

  static final ColorScheme light =
      ColorScheme.fromSeed(
        seedColor: seed,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: smartBlue,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFDCEAF8),
        onPrimaryContainer: prussianBlue3,

        secondary: sapphire,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFD8E2EE),
        onSecondaryContainer: prussianBlue3,

        tertiary: regalNavy,
        onTertiary: Colors.white,
        tertiaryContainer: lavenderGrey,
        onTertiaryContainer: prussianBlue3,

        // Errors remain semantic red rather than being folded into the brand
        // palette. The same rule applies to the clinical status extension.
        error: const Color(0xFFBA1A2E),
        onError: Colors.white,
        errorContainer: const Color(0xFFFFDAD9),
        onErrorContainer: const Color(0xFF5E1014),

        surface: const Color(0xFFEEF2F7),
        onSurface: prussianBlue3,
        onSurfaceVariant: twilightIndigo,
        surfaceDim: const Color(0xFFDDE2EA),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF7F9FC),
        surfaceContainer: const Color(0xFFF0F3F8),
        surfaceContainerHigh: const Color(0xFFE8ECF3),
        surfaceContainerHighest: const Color(0xFFDDE2EA),

        outline: blueSlate,
        outlineVariant: lavenderGrey,
        inverseSurface: prussianBlue3,
        onInverseSurface: Colors.white,
        inversePrimary: lavenderGrey,
        shadow: prussianBlue3,
        scrim: prussianBlue3,
        surfaceTint: Colors.transparent,
      );

  // --- dark ----------------------------------------------------------------

  static final ColorScheme dark =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        // The lightest palette step becomes the dark-theme action colour so
        // text links and selected controls retain WCAG AA contrast on navy.
        primary: lavenderGrey,
        onPrimary: prussianBlue3,
        primaryContainer: regalNavy,
        onPrimaryContainer: Colors.white,

        secondary: slateGrey,
        onSecondary: prussianBlue3,
        secondaryContainer: twilightIndigo,
        onSecondaryContainer: Colors.white,

        tertiary: smartBlue,
        onTertiary: Colors.white,
        tertiaryContainer: sapphire,
        onTertiaryContainer: Colors.white,

        error: const Color(0xFFFFB3B0),
        onError: const Color(0xFF5E1014),
        errorContainer: const Color(0xFF8C1A26),
        onErrorContainer: const Color(0xFFFFDAD9),

        surface: prussianBlue3,
        onSurface: Colors.white,
        onSurfaceVariant: lavenderGrey,
        surfaceDim: prussianBlue3,
        surfaceBright: prussianBlue,
        surfaceContainerLowest: prussianBlue3,
        surfaceContainerLow: prussianBlue2,
        surfaceContainer: const Color(0xFF001F4D),
        surfaceContainerHigh: prussianBlue,
        surfaceContainerHighest: prussianBlue,

        outline: slateGrey,
        outlineVariant: blueSlate,
        inverseSurface: lavenderGrey,
        onInverseSurface: prussianBlue3,
        inversePrimary: prussianBlue,
        shadow: prussianBlue3,
        scrim: prussianBlue3,
        surfaceTint: Colors.transparent,
      );

  // --- legacy aliases ------------------------------------------------------
  //
  // Screens written against the earlier patient-blue palette keep compiling
  // and inherit the clay identity through these names.

  static const Color brandMagenta = smartBlue;
  static const Color brandViolet = sapphire;
  static const Color brandBlue = smartBlue;
  static const Color patientBlue = smartBlue;
  static const LinearGradient patientBrandGradient = brandGradient;
  static const RadialGradient patientBrandGlow = brandGlow;

  /// Every role now shares one scheme; the patient names alias it.
  static ColorScheme get patientLight => light;
  static ColorScheme get patientDark => dark;
}
