/// A stand-in screen for routes whose real UI is built in a later phase (P0-06).
///
/// Every route in the app resolves to a real widget from day one so navigation,
/// deep links and the shells can be exercised before any feature exists.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    this.task,
    this.showAppBar = true,
    super.key,
  });

  /// Screen name, shown in the app bar and body.
  final String title;

  /// The task ID that will build this screen for real (e.g. `P2-08`).
  final String? task;

  /// Shells provide their own app bar; standalone routes want one.
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: Space.md),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xs),
              Text(
                task == null ? 'Coming soon' : 'Coming soon · $task',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
