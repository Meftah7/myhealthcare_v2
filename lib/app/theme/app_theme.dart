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

    // The hairline is the whole border story: full-strength outlineVariant is
    // already a whisper (#DCDFE8 / #2E323C), so it needs no further alpha.
    final hairline = scheme.outlineVariant;

    // Cards sit one step *above* the page in both themes — white on a tinted
    // page in light, a lifted slate on near-black in dark. That single step is
    // what lets a card read as a card without a heavy shadow.
    final cardColor = isLight
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainerHigh;

    // Inset fields: a filled well with its own hairline, so a text field is
    // legible whether it sits on a white card or on the tinted page.
    final fieldFill = isLight
        ? scheme.surfaceContainer
        : scheme.surfaceContainerHigh;

    // Bars, rails and sheets share the card's plane.
    final navSurface = isLight
        ? scheme.surfaceContainerLowest
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
        // Content scrolling underneath tints the bar a step darker instead of
        // dropping a shadow — a quieter separation that survives dark mode.
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
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardSmall),
        selectedColor: scheme.onSecondaryContainer,
        selectedTileColor: scheme.secondaryContainer,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.md,
        ),
        // A hairline at rest so the field has an edge on a white card as well
        // as on the tinted page; the focus ring is the only saturated stroke.
        border: fieldBorder(hairline),
        enabledBorder: fieldBorder(hairline),
        focusedBorder: fieldBorder(scheme.primary, 2),
        disabledBorder: fieldBorder(hairline),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, 2),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        // Persistent, visible label — never placeholder-only (§8).
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: text.labelLarge?.copyWith(color: scheme.primary),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
        backgroundColor: cardColor,
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
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
          backgroundColor: isLight
              ? scheme.surfaceContainer
              : scheme.surfaceContainerLow,
          foregroundColor: scheme.onSurfaceVariant,
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          // Hairline, not full outline — a segmented control is a single
          // object, not three bordered buttons.
          side: BorderSide(color: hairline),
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: isLight ? scheme.surfaceContainerLowest : cardColor,
        dragHandleColor: scheme.outlineVariant,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheet),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? scheme.surfaceContainerLowest : cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: hairline),
        ),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? scheme.surfaceContainerLowest : cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardSmall,
          side: BorderSide(color: hairline),
        ),
        textStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
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

      // Navigation surfaces sit one step above the page (white on the tinted
      // light page, lifted slate in dark) so the chrome reads as a frame around
      // the content rather than more of the same field.
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: navSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: navSurface,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: navSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
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
