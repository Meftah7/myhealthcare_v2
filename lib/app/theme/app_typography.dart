/// Typography for MyHealth Care.
///
/// Spec: DESIGN.md §3. Lexend for display/headline (reduced reading friction),
/// Inter for body/label/UI (screen-optimised, full tabular-figure support).
/// Fonts are **bundled** (assets/fonts/, declared in pubspec) so the app works
/// offline — nothing is fetched at runtime.
library;

import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String display = 'Lexend';
  static const String body = 'Inter';

  /// Only where literal character alignment matters (extracted PDF text, debug).
  static const String mono = 'JetBrainsMono';
}

/// Tabular (monospaced) figures — digits align in columns so 98 never looks
/// smaller than 120. Use on every measured clinical value (DESIGN.md §1 rule 4).
const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];

/// The Material 3 [TextTheme], sizes overridden per DESIGN.md §3.2.
///
/// Colours are left unset — [ThemeData] applies them from the [ColorScheme].
/// Headlines use weight 400–500, never 700: this app doesn't shout.
TextTheme buildTextTheme() {
  return const TextTheme(
    // Onboarding / empty-state hero only. Large display type reads too loose at
    // default tracking — tighten it (apple-design §15).
    displaySmall: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 32,
      height: 38 / 32,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.8,
    ),
    // Screen titles (large windows).
    headlineMedium: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 26,
      height: 32 / 26,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.6,
    ),
    // Screen titles (compact), section heads.
    headlineSmall: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.4,
    ),
    // Card titles, dialog titles.
    titleLarge: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
    ),
    // List item primary, form section labels.
    titleMedium: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    // Dense list labels, tab labels.
    titleSmall: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
    ),
    // Primary reading text, record bodies.
    bodyLarge: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
    ),
    // Secondary text, list subtitles. Minimum on-screen body size.
    bodyMedium: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    ),
    // Captions, timestamps, metadata.
    bodySmall: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
    ),
    // Button labels.
    labelLarge: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
    ),
    // Chips, badges.
    labelMedium: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 13,
      height: 16 / 13,
      fontWeight: FontWeight.w600,
    ),
    // Overline, status badge text.
    labelSmall: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

/// Helpers for rendering clinical figures. DESIGN.md §3.3: "Clinical numbers
/// always get tabular figures. Provide a helper so this can't be forgotten."
abstract final class AppText {
  /// A [Text] for a measured value (lab result, vital, dose) with tabular
  /// figures applied. Pass [style] to pick the size role; defaults to
  /// `bodyMedium`.
  static Widget clinical(
    String data, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    String? semanticsLabel,
  }) {
    return Builder(
      builder: (context) {
        final base = style ?? Theme.of(context).textTheme.bodyMedium;
        return Text(
          data,
          textAlign: textAlign,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          style: (base ?? const TextStyle()).copyWith(
            fontFeatures: kTabularFigures,
          ),
        );
      },
    );
  }

  /// The tabular-figures variant of an arbitrary [style], for callers that
  /// need a [TextStyle] rather than a widget (e.g. `DataTable` cells).
  static TextStyle clinicalStyle(TextStyle style) =>
      style.copyWith(fontFeatures: kTabularFigures);
}
