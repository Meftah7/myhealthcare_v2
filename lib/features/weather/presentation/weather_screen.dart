/// Weather tab. No weather provider or location service is integrated in this
/// build, so the tab shows an explicit "not connected" state instead of
/// invented readings or disease-risk indices. When a sourced provider is
/// added, [WeatherSummaryCard] / [WeatherIndicatorCard] render its data with
/// the observed-at time and source.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PatientPageScaffold(
      header: PatientPageTitle(t.paWeather),
      children: [
        const SizedBox(height: Space.md),
        PatientStateView(
          kind: PatientStateKind.unavailable,
          icon: Icons.cloud_off_outlined,
          title: t.paWeatherUnavailableTitle,
          message: t.paWeatherUnavailableBody,
        ),
      ],
    );
  }
}

/// Large weather summary: location, temperature, condition, observed-at.
class WeatherSummaryCard extends StatelessWidget {
  const WeatherSummaryCard({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.observedAt,
    required this.source,
    this.stale = false,
    super.key,
  });

  final String location;
  final String temperature;
  final String condition;
  final String observedAt;
  final String source;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: palette.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(location, style: theme.textTheme.titleSmall),
              ),
              if (stale)
                const StatusBadge(
                  '!',
                  accent: PatientAccent.amber,
                  icon: Icons.history_toggle_off,
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            temperature,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          Text(condition, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.xs),
          Text(
            '$observedAt · $source',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// One weather indicator: soft icon tile, flexible text and a text badge.
/// A bar is drawn only when [fraction] (a defined scale) is supplied.
class WeatherIndicatorCard extends StatelessWidget {
  const WeatherIndicatorCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.badge,
    this.accent = PatientAccent.blue,
    this.fraction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String badge;
  final PatientAccent accent;
  final double? fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final (fg, _) = accent.colors(palette);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(icon: icon, accent: accent, size: 44),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              StatusBadge(badge, accent: accent),
            ],
          ),
          if (fraction != null) ...[
            const SizedBox(height: Space.sm),
            ClipRRect(
              borderRadius: Radii.pill,
              child: LinearProgressIndicator(
                value: fraction!.clamp(0, 1),
                minHeight: 6,
                color: fg,
                backgroundColor: palette.divider,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
