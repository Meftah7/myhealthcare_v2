/// Dashboard shortcuts from the Figma review, sized by their actual content.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import 'app_card.dart';

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(Space.sm),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: Radii.cardSmall,
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(height: Space.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final columns = (constraints.maxWidth / (100 * scale)).floor().clamp(
        1,
        3,
      );
      final width = (constraints.maxWidth - Space.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
