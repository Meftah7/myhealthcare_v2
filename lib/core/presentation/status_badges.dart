/// Clinical status widgets (DESIGN.md §5.2). Colour + icon + text, never one
/// alone.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../domain/enums.dart';

class _Pill extends StatelessWidget {
  const _Pill({required this.style, required this.label});

  final ClinicalStatusStyle style;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xxs,
      ),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: Radii.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 15, color: style.onContainer),
          const SizedBox(width: Space.xxs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: style.onContainer),
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
    return _Pill(style: style, label: label);
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
    return _Pill(style: style, label: label);
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
