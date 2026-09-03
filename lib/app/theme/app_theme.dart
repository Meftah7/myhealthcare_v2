/// Assembles [ThemeData] for MyHealth Care from the design tokens
/// (redesign v2).
///
/// Spec: DESIGN.md §9. `MaterialApp` consumes [AppTheme.light] / [AppTheme.dark]
/// with the device theme-mode preference. The look: flat neutral surfaces,
/// hairline borders, whisper-soft shadows on the surfaces that lift, one
/// indigo-violet accent, and saturated colour reserved for clinical risk.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'dimens.dart';
import 'motion.dart';
import 'status_colors.dart';

abstract final class AppTheme {
  static ThemeData get light =>
      _build(AppColors.light, ClinicalStatusColors.light, Brightness.light);

  static ThemeData get dark =>
      _build(AppColors.dark, ClinicalStatusColors.dark, Brightness.dark);

  static ThemeData _build(
    ColorScheme scheme,
    ClinicalStatusColors status,
    Brightness brightness,
  ) {
    final text = buildTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final isLight = brightness == Brightness.light;
    final hairline = scheme.outlineVariant.withValues(alpha: isLight ? 0.7 : 0.5);
    final cardColor = isLight
        ? scheme.surface
        : scheme.surfaceContainerLow;

    OutlineInputBorder fieldBorder(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: Radii.field,
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      colorScheme: scheme,
      textTheme: text,
      extensions: [status],
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,

      // Accessibility defaults (DESIGN.md §8): 48dp tap targets, standard
      // density everywhere so targets stay predictable.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitions(),
          TargetPlatform.iOS: AppPageTransitions(),
          TargetPlatform.macOS: AppPageTransitions(),
          TargetPlatform.windows: AppPageTransitions(),
          TargetPlatform.linux: AppPageTransitions(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: Space.md,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: hairline),
        ),
        margin: EdgeInsets.zero,
      ),

      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.md,
        ),
        border: fieldBorder(Colors.transparent),
        enabledBorder: fieldBorder(Colors.transparent),
        focusedBorder: fieldBorder(scheme.primary, 2),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, 2),
        // Persistent, visible label — never placeholder-only (§8).
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: text.labelLarge?.copyWith(color: scheme.primary),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          textStyle: text.labelLarge,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outline),
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

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 4,
        highlightElevation: 2,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: text.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: Radii.button),
      ),

      chipTheme: ChipThemeData(
        labelStyle: text.labelMedium,
        side: BorderSide(color: hairline),
        backgroundColor: scheme.surface,
        selectedColor: scheme.secondaryContainer,
        showCheckmark: false,
        shape: const RoundedRectangleBorder(borderRadius: Radii.chip),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: text.labelMedium,
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          side: BorderSide(color: scheme.outline),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheet),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: hairline),
        ),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardSmall),
        insetPadding: const EdgeInsets.all(Space.md),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.labelMedium,
      ),

      tabBarTheme: TabBarThemeData(
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: hairline,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: Radii.chip,
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),

      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
