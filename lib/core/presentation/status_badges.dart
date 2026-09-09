/// Clinical status widgets (DESIGN.md §5.2). Colour + icon + text, never one
/// alone.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../domain/enums.dart';

/// The one status badge in the app: a filled container carrying an icon **and**
/// a word (DESIGN.md §1 rule 3 — status is never colour alone, because ~8% of
/// men can't separate red from green).
///
/// Every badge in the app is built from this — the clinical ones below from the
/// status ramp, the workflow ones ([AppointmentStatusPill]) from `ColorScheme`
/// roles — so a chip means the same thing and looks the same everywhere.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.icon,
    required this.container,
    required this.onContainer,
    this.dense = false,
    super.key,
  });

  /// Builds one from a clinical ramp entry.
  StatusPill.clinical(
    ClinicalStatusStyle style, {
    required this.label,
    this.dense = false,
    super.key,
  }) : icon = style.icon,
       container = style.container,
       onContainer = style.onContainer;

  final String label;
  final IconData icon;
  final Color container;
  final Color onContainer;

  /// Tightens the padding for use inside a dense list row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Space.xs : Space.sm,
        vertical: Space.xxs,
      ),
      decoration: BoxDecoration(color: container, borderRadius: Radii.chip),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: onContainer),
          const SizedBox(width: Space.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: onContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// No-show risk band (P4-17, P5-05).
class RiskBadge extends StatelessWidget {
  const RiskBadge(this.band, {super.key});

  final RiskBand band;

  @override
  Widget build(BuildContext context) {
    final ramp = Theme.of(context).clinicalStatus;
    final (style, label) = switch (band) {
      RiskBand.low => (ramp.riskLow, 'Low risk'),
      RiskBand.medium => (ramp.riskMedium, 'Medium risk'),
      RiskBand.high => (ramp.riskHigh, 'High risk'),
    };
    return StatusPill.clinical(style, label: label);
  }
}

/// Where an appointment sits in its workflow (booked → confirmed → completed,
/// or cancelled / no-show).
///
/// Not a *clinical* status, so it draws from `ColorScheme` roles rather than
/// the risk ramp — but it is still colour **plus icon plus word**, and still a
/// [StatusPill], so it reads as the same kind of object as a risk badge.
class AppointmentStatusPill extends StatelessWidget {
  const AppointmentStatusPill(this.status, {this.dense = false, super.key});

  final AppointmentStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, bg, fg) = switch (status) {
      AppointmentStatus.booked => (
        'Booked',
        Icons.event_outlined,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppointmentStatus.confirmed => (
        'Confirmed',
        Icons.event_available_outlined,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppointmentStatus.completed => (
        'Completed',
        Icons.check_circle_outline,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      AppointmentStatus.cancelled => (
        'Cancelled',
        Icons.cancel_outlined,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      AppointmentStatus.noShow => (
        'No-show',
        Icons.person_off_outlined,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return StatusPill(
      label: label,
      icon: icon,
      container: bg,
      onContainer: fg,
      dense: dense,
    );
  }
}

/// Risk-flag severity (P5-01).
class SeverityChip extends StatelessWidget {
  const SeverityChip(this.severity, {super.key});

  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final ramp = Theme.of(context).clinicalStatus;
    final (style, label) = switch (severity) {
      Severity.info => (ramp.severityInfo, 'Info'),
      Severity.warning => (ramp.severityWarning, 'Review'),
      Severity.urgent => (ramp.severityUrgent, 'Urgent'),
    };
    return StatusPill.clinical(style, label: label);
  }
}

/// Inline indicator for a lab value relative to its reference range (P2-10).
class AbnormalValueIndicator extends StatelessWidget {
  const AbnormalValueIndicator({
    required this.flag,
    required this.valueText,
    this.referenceText,
    super.key,
  });

  final AbnormalFlag flag;
  final String valueText;
  final String? referenceText;

  @override
  Widget build(BuildContext context) {
    final ramp = Theme.of(context).clinicalStatus;
    final style = switch (flag) {
      AbnormalFlag.normal => ramp.labNormal,
      AbnormalFlag.low => ramp.labLow,
      AbnormalFlag.high => ramp.labHigh,
      AbnormalFlag.critical => ramp.labCritical,
    };
    final semantic = switch (flag) {
      AbnormalFlag.normal => 'Normal',
      AbnormalFlag.low => 'Low',
      AbnormalFlag.high => 'High',
      AbnormalFlag.critical => 'Critical',
    };
    return Semantics(
      label:
          '$semantic: $valueText'
          '${referenceText == null ? '' : ', reference $referenceText'}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flag != AbnormalFlag.normal)
            Icon(style.icon, size: 15, color: style.onContainer),
          if (flag != AbnormalFlag.normal) const SizedBox(width: Space.xxs),
          AppText.clinical(
            valueText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: flag == AbnormalFlag.normal ? null : style.onContainer,
              fontWeight: flag == AbnormalFlag.normal ? null : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The AI-generated disclaimer strip (P3-13). Lives here so every AI surface
/// can drop it in; it uses `tertiaryContainer`, not a status colour.
class AiDisclaimerBanner extends StatelessWidget {
  const AiDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.sm),
      color: theme.colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              'AI-generated — informational only, not medical advice. '
              'Verify with your clinician.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
