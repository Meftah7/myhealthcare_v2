/// Assembles [ThemeData] for MyHealth Care from the design tokens
/// (clinical bento redesign v5).
///
/// Spec: DESIGN.md §9. `MaterialApp` consumes [AppTheme.light] / [AppTheme.dark]
/// with the device theme-mode preference. The look: modular blue-slate bento
/// surfaces, low vertical depth, one smart-blue accent, and saturated colour
/// reserved for clinical risk.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'dimens.dart';
import 'motion.dart';
import 'patient_palette.dart';
import 'status_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    AppColors.light,
    ClinicalStatusColors.light,
    Brightness.light,
    patient: PatientPalette.light,
  );

  static ThemeData get dark => _build(
    AppColors.dark,
    ClinicalStatusColors.dark,
    Brightness.dark,
    patient: PatientPalette.dark,
  );

  /// High-contrast variants (Preferences → Accessibility): the same palette
  /// with full-strength text and borders, for low-vision users for whom the
  /// default hairline + tinted-surface separation is too subtle.
  static ThemeData get lightHighContrast => _build(
    _highContrast(AppColors.light, Brightness.light),
    ClinicalStatusColors.light,
    Brightness.light,
    patient: PatientPalette.light,
  );

  static ThemeData get darkHighContrast => _build(
    _highContrast(AppColors.dark, Brightness.dark),
    ClinicalStatusColors.dark,
    Brightness.dark,
    patient: PatientPalette.dark,
  );

  /// Patient geometry with the same shared colours as staff/admin.
  static ThemeData get patientLight => _build(
    AppColors.light,
    ClinicalStatusColors.light,
    Brightness.light,
    patient: PatientPalette.light,
    patientGeometry: true,
  );

  static ThemeData get patientDark => _build(
    AppColors.dark,
    ClinicalStatusColors.dark,
    Brightness.dark,
    patient: PatientPalette.dark,
    patientGeometry: true,
  );

  static ThemeData get patientLightHighContrast => _build(
    _highContrast(AppColors.light, Brightness.light),
    ClinicalStatusColors.light,
    Brightness.light,
    patient: PatientPalette.light,
    patientGeometry: true,
  );

  static ThemeData get patientDarkHighContrast => _build(
    _highContrast(AppColors.dark, Brightness.dark),
    ClinicalStatusColors.dark,
    Brightness.dark,
    patient: PatientPalette.dark,
    patientGeometry: true,
  );

  static ColorScheme _highContrast(ColorScheme s, Brightness b) {
    final isLight = b == Brightness.light;
    final ink = isLight ? Colors.black : Colors.white;
    return s.copyWith(
      onSurface: ink,
      onSurfaceVariant: ink,
      outline: ink,
      outlineVariant: isLight
          ? AppColors.twilightIndigo
          : AppColors.lavenderGrey,
    );
  }

  static ThemeData _build(
    ColorScheme scheme,
    ClinicalStatusColors status,
    Brightness brightness, {
    PatientPalette? patient,
    bool patientGeometry = false,
  }) {
    final text = buildTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamilyFallback: AppFonts.fallback,
    );
    final isLight = brightness == Brightness.light;

    // Borders are quiet seams between clay planes, never the primary source of
    // depth. Paired highlights and shadows carry that job.
    final hairline = scheme.outlineVariant;

    // Cards sit one step above the page in both themes. AppCard adds the low
    // bento shadow; Material Card stays flat so arbitrary M3 cards do not float
    // above the intentional dashboard modules.
    final cardColor = isLight
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainerHigh;

    // Inset fields: a filled well with its own hairline, so a text field is
    // legible whether it sits on a white card or on the tinted page.
    final fieldFill = isLight
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainerHigh;

    // Bars, rails and sheets share the card's plane.
    final navSurface = isLight
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainerLow;

    // Patient screens use the larger rounded shapes of the approved preview
    // (cards 22, buttons 14) and keep filled actions on #246BFD in both
    // modes. Staff/admin share these colours and keep the denser radii.
    final cardRadius = !patientGeometry
        ? Radii.card
        : const BorderRadius.all(Radius.circular(22));
    final buttonRadius = !patientGeometry
        ? Radii.button
        : const BorderRadius.all(Radius.circular(14));
    final action = patient?.action ?? scheme.primary;
    final onAction = patient?.onAction ?? scheme.onPrimary;

    OutlineInputBorder fieldBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: Radii.field,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      colorScheme: scheme,
      // Also covers primaryTextTheme and styles built outside [text].
      fontFamilyFallback: AppFonts.fallback,
      textTheme: text,
      // Every role shares the patient colour extension, retuned to the clay
      // palette so newer screens built on it follow the same identity.
      extensions: [status, ?patient],
      // Opaque by default so a screen remains accessible when hosted outside
      // MyHealthCareApp (tests, previews, embedded flows). The app frame opts
      // its routed subtree into transparency over the ambient clay gradient.
      scaffoldBackgroundColor: scheme.surface,
      // InkRipple is deterministic across Skia/Impeller and reads more like a
      // soft compression on clay than the glittery shader-based sparkle.
      splashFactory: InkRipple.splashFactory,

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
        backgroundColor: Colors.transparent,
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
          borderRadius: cardRadius,
          side: BorderSide(color: Clay.seam(scheme)),
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
        // Fields are shallow clay wells. The seam stays quiet until focus,
        // where the saturated two-pixel ring remains unmistakable.
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
        errorMaxLines: 4,
        helperMaxLines: 4,
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: action,
          foregroundColor: onAction,
          minimumSize: Size(0, patientGeometry ? 52 : 50),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          textStyle: text.labelLarge,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          textStyle: text.labelLarge,
          backgroundColor: cardColor,
          side: BorderSide(color: hairline),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.sm,
          ),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        focusElevation: 8,
        hoverElevation: 12,
        highlightElevation: 6,
        backgroundColor: action,
        foregroundColor: onAction,
        extendedTextStyle: text.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardSmall),
      ),

      chipTheme: ChipThemeData(
        labelStyle: text.labelMedium?.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? onAction
                : scheme.onSurfaceVariant,
          ),
        ),
        side: BorderSide(color: hairline),
        backgroundColor: cardColor,
        selectedColor: action,
        checkmarkColor: onAction,
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
          selectedBackgroundColor: action,
          selectedForegroundColor: onAction,
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
        elevation: 10,
        modalElevation: 14,
        shadowColor: isLight
            ? const Color(0x527D8597)
            : const Color(0xA6001233),
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheet),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? scheme.surfaceContainerLowest : cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 14,
        shadowColor: isLight
            ? const Color(0x527D8597)
            : const Color(0xA6001233),
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: hairline),
        ),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? scheme.surfaceContainerLowest : cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: isLight
            ? const Color(0x527D8597)
            : const Color(0xA6001233),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardSmall,
          side: BorderSide(color: hairline),
        ),
        textStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardSmall),
        insetPadding: const EdgeInsets.all(Space.md),
      ),

      // The shell rounds and shadows these into floating clay docks.
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: navSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: Radii.button,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontSize: 11,
            height: 16 / 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: navSurface,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: Radii.button,
        ),
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.primary,
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

      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),

      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(fieldFill),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Radii.field),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: hairline)),
        textStyle: WidgetStatePropertyAll(text.bodyMedium),
        hintStyle: WidgetStatePropertyAll(
          text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
