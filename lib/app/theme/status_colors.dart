/// Clinical status ramp — a [ThemeExtension] because Material 3 has no role for
/// clinical severity (DESIGN.md §2.2).
///
/// Every entry is a triple: **container** colour, **on-container** colour, and
/// an **icon**. Status is never colour alone (§1 rule 3, §8) — the [RiskBadge] /
/// [SeverityChip] / [AbnormalValueIndicator] components render colour + icon +
/// text together. Contrast for each container / on-container pair clears
/// WCAG AA 4.5:1; a test in test/ asserts this (P6-09).
library;

import 'package:flutter/material.dart';

/// One status style: a filled container, its foreground colour, and an icon.
@immutable
class ClinicalStatusStyle {
  const ClinicalStatusStyle({
    required this.container,
    required this.onContainer,
    required this.icon,
  });

  final Color container;
  final Color onContainer;
  final IconData icon;

  ClinicalStatusStyle _lerp(ClinicalStatusStyle other, double t) {
    return ClinicalStatusStyle(
      container: Color.lerp(container, other.container, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
      icon: t < 0.5 ? icon : other.icon,
    );
  }
}

/// The full ramp, carried on [ThemeData.extensions] so it travels with
/// `Theme.of(context)` and flips with the theme.
@immutable
class ClinicalStatusColors extends ThemeExtension<ClinicalStatusColors> {
  const ClinicalStatusColors({
    required this.riskLow,
    required this.riskMedium,
    required this.riskHigh,
    required this.labNormal,
    required this.labLow,
    required this.labHigh,
    required this.labCritical,
    required this.severityInfo,
    required this.severityWarning,
    required this.severityUrgent,
  });

  /// No-show risk < 0.33 (P4-14, P4-17, P5-05).
  final ClinicalStatusStyle riskLow;

  /// No-show risk 0.33–0.66.
  final ClinicalStatusStyle riskMedium;

  /// No-show risk > 0.66.
  final ClinicalStatusStyle riskHigh;

  /// Lab value within reference range (P2-10).
  final ClinicalStatusStyle labNormal;

  /// Lab value below reference low.
  final ClinicalStatusStyle labLow;

  /// Lab value above reference high.
  final ClinicalStatusStyle labHigh;

  /// Critical lab value (P2-10, P5-01).
  final ClinicalStatusStyle labCritical;

  /// Informational risk flag (P5-01).
  final ClinicalStatusStyle severityInfo;

  /// Risk flag that needs review (P5-01).
  final ClinicalStatusStyle severityWarning;

  /// Risk flag that needs action now (P5-01, P5-05).
  final ClinicalStatusStyle severityUrgent;

  /// Map a no-show probability (0–1) to its risk style (DESIGN.md §2.2).
  ClinicalStatusStyle riskFor(double probability) {
    if (probability > 0.66) return riskHigh;
    if (probability >= 0.33) return riskMedium;
    return riskLow;
  }

  static const ClinicalStatusColors light = ClinicalStatusColors(
    riskLow: ClinicalStatusStyle(
      container: Color(0xFFDCF2EE),
      onContainer: Color(0xFF0B3B39),
      icon: Icons.check_circle_outline,
    ),
    riskMedium: ClinicalStatusStyle(
      container: Color(0xFFFFF1D6),
      onContainer: Color(0xFF4A3209),
      icon: Icons.error_outline,
    ),
    riskHigh: ClinicalStatusStyle(
      container: Color(0xFFFCE4E4),
      onContainer: Color(0xFF5E1414),
      icon: Icons.warning_amber_rounded,
    ),
    labNormal: ClinicalStatusStyle(
      container: Color(0xFFE7E9E9),
      onContainer: Color(0xFF3F4948),
      icon: Icons.remove,
    ),
    labLow: ClinicalStatusStyle(
      container: Color(0xFFE1ECF7),
      onContainer: Color(0xFF0F3A5F),
      icon: Icons.south,
    ),
    labHigh: ClinicalStatusStyle(
      container: Color(0xFFFFF1D6),
      onContainer: Color(0xFF4A3209),
      icon: Icons.north,
    ),
    labCritical: ClinicalStatusStyle(
      container: Color(0xFFF4C7C7),
      onContainer: Color(0xFF5E1414),
      icon: Icons.priority_high,
    ),
    severityInfo: ClinicalStatusStyle(
      container: Color(0xFFE7E9E9),
      onContainer: Color(0xFF3F4948),
      icon: Icons.info_outline,
    ),
    severityWarning: ClinicalStatusStyle(
      container: Color(0xFFFFF1D6),
      onContainer: Color(0xFF4A3209),
      icon: Icons.error_outline,
    ),
    severityUrgent: ClinicalStatusStyle(
      container: Color(0xFFF4C7C7),
      onContainer: Color(0xFF5E1414),
      icon: Icons.notification_important,
    ),
  );

  /// Dark ramp — same hues, darkened containers, light on-container text
  /// (DESIGN.md §2.2).
  static const ClinicalStatusColors dark = ClinicalStatusColors(
    riskLow: ClinicalStatusStyle(
      container: Color(0xFF12352F),
      onContainer: Color(0xFFA6E9DD),
      icon: Icons.check_circle_outline,
    ),
    riskMedium: ClinicalStatusStyle(
      container: Color(0xFF3A2E12),
      onContainer: Color(0xFFF4D9A6),
      icon: Icons.error_outline,
    ),
    riskHigh: ClinicalStatusStyle(
      container: Color(0xFF4A2120),
      onContainer: Color(0xFFF6C9C7),
      icon: Icons.warning_amber_rounded,
    ),
    labNormal: ClinicalStatusStyle(
      container: Color(0xFF2A2F2F),
      onContainer: Color(0xFFC4C7C6),
      icon: Icons.remove,
    ),
    labLow: ClinicalStatusStyle(
      container: Color(0xFF152C3D),
      onContainer: Color(0xFFBBD4EC),
      icon: Icons.south,
    ),
    labHigh: ClinicalStatusStyle(
      container: Color(0xFF3A2E12),
      onContainer: Color(0xFFF4D9A6),
      icon: Icons.north,
    ),
    labCritical: ClinicalStatusStyle(
      container: Color(0xFF4A1F1E),
      onContainer: Color(0xFFF8C6C4),
      icon: Icons.priority_high,
    ),
    severityInfo: ClinicalStatusStyle(
      container: Color(0xFF2A2F2F),
      onContainer: Color(0xFFC4C7C6),
      icon: Icons.info_outline,
    ),
    severityWarning: ClinicalStatusStyle(
      container: Color(0xFF3A2E12),
      onContainer: Color(0xFFF4D9A6),
      icon: Icons.error_outline,
    ),
    severityUrgent: ClinicalStatusStyle(
      container: Color(0xFF4A1F1E),
      onContainer: Color(0xFFF8C6C4),
      icon: Icons.notification_important,
    ),
  );

  @override
  ClinicalStatusColors copyWith({
    ClinicalStatusStyle? riskLow,
    ClinicalStatusStyle? riskMedium,
    ClinicalStatusStyle? riskHigh,
    ClinicalStatusStyle? labNormal,
    ClinicalStatusStyle? labLow,
    ClinicalStatusStyle? labHigh,
    ClinicalStatusStyle? labCritical,
    ClinicalStatusStyle? severityInfo,
    ClinicalStatusStyle? severityWarning,
    ClinicalStatusStyle? severityUrgent,
  }) {
    return ClinicalStatusColors(
      riskLow: riskLow ?? this.riskLow,
      riskMedium: riskMedium ?? this.riskMedium,
      riskHigh: riskHigh ?? this.riskHigh,
      labNormal: labNormal ?? this.labNormal,
      labLow: labLow ?? this.labLow,
      labHigh: labHigh ?? this.labHigh,
      labCritical: labCritical ?? this.labCritical,
      severityInfo: severityInfo ?? this.severityInfo,
      severityWarning: severityWarning ?? this.severityWarning,
      severityUrgent: severityUrgent ?? this.severityUrgent,
    );
  }

  @override
  ClinicalStatusColors lerp(covariant ClinicalStatusColors? other, double t) {
    if (other == null) return this;
    return ClinicalStatusColors(
      riskLow: riskLow._lerp(other.riskLow, t),
      riskMedium: riskMedium._lerp(other.riskMedium, t),
      riskHigh: riskHigh._lerp(other.riskHigh, t),
      labNormal: labNormal._lerp(other.labNormal, t),
      labLow: labLow._lerp(other.labLow, t),
      labHigh: labHigh._lerp(other.labHigh, t),
      labCritical: labCritical._lerp(other.labCritical, t),
      severityInfo: severityInfo._lerp(other.severityInfo, t),
      severityWarning: severityWarning._lerp(other.severityWarning, t),
      severityUrgent: severityUrgent._lerp(other.severityUrgent, t),
    );
  }
}

/// `Theme.of(context).clinicalStatus` sugar.
extension ClinicalStatusThemeX on ThemeData {
  ClinicalStatusColors get clinicalStatus =>
      extension<ClinicalStatusColors>() ?? ClinicalStatusColors.light;
}
