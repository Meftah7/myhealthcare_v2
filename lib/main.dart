import 'package:flutter/material.dart';

import 'app/theme/theme.dart';

void main() {
  runApp(const MyHealthCareApp());
}

/// Root of the app. P0-06 replaces the placeholder [home] with
/// `MaterialApp.router` + go_router.
class MyHealthCareApp extends StatelessWidget {
  const MyHealthCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyHealth Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _ScaffoldPlaceholder(),
    );
  }
}

/// Temporary landing screen — a small showcase that the DESIGN.md theme is
/// wired up (colours, type ramp, clinical status ramp, tabular figures).
class _ScaffoldPlaceholder extends StatelessWidget {
  const _ScaffoldPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.clinicalStatus;

    return Scaffold(
      appBar: AppBar(title: const Text('MyHealth Care')),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text('Screen title', style: theme.textTheme.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(
            'Calm by default, loud only for risk. This placeholder confirms the '
            'theme from DESIGN.md is in place; P0-06 brings the router.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest reading', style: theme.textTheme.titleMedium),
                  const SizedBox(height: Space.xs),
                  AppText.clinical(
                    'HbA1c  7.9 %',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              _StatusPill(style: status.riskLow, label: 'Low risk'),
              _StatusPill(style: status.riskMedium, label: 'Medium risk'),
              _StatusPill(style: status.riskHigh, label: 'High risk'),
              _StatusPill(style: status.labCritical, label: 'Critical'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.style, required this.label});

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
          Icon(style.icon, size: 16, color: style.onContainer),
          const SizedBox(width: Space.xxs),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: style.onContainer),
          ),
        ],
      ),
    );
  }
}
