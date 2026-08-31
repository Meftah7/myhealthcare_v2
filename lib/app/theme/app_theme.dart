/// Assembles [ThemeData] for MyHealth Care from the design tokens.
///
/// Spec: DESIGN.md §9. `MaterialApp` consumes [AppTheme.light] / [AppTheme.dark]
/// with `themeMode: ThemeMode.system`.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'dimens.dart';
import 'status_colors.dart';

abstract final class AppTheme {
  static ThemeData get light =>
      _build(AppColors.light, ClinicalStatusColors.light);

  static ThemeData get dark =>
      _build(AppColors.dark, ClinicalStatusColors.dark);

  static ThemeData _build(ColorScheme scheme, ClinicalStatusColors status) {
    final text = buildTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      colorScheme: scheme,
      textTheme: text,
      extensions: [status],
      scaffoldBackgroundColor: scheme.surface,

      // Accessibility defaults (DESIGN.md §8): 48dp tap targets, standard
      // density on every platform so targets stay predictable.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      // Tonal elevation is the primary depth cue (§4.3); keep real shadows low.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),

      cardTheme: const CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: Radii.card),
        margin: EdgeInsets.zero,
      ),

      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: const OutlineInputBorder(
          borderRadius: Radii.field,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: Radii.field,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.field,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        // Persistent, visible label — never placeholder-only (§8).
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
        ),
      ),

      chipTheme: ChipThemeData(
        labelStyle: text.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: Radii.chip),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: Radii.sheet),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 1,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 3,
        selectedLabelTextStyle: text.labelMedium,
        unselectedLabelTextStyle: text.labelMedium,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
