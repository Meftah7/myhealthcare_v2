import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import 'app_card.dart';

/// A profile or settings destination, with optional supporting context.
class ProfileNavigationItem {
  const ProfileNavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
}

/// The same readable, keyboard-accessible menu across all workspaces.
class ProfileNavigationGroup extends StatelessWidget {
  const ProfileNavigationGroup({required this.items, super.key});

  final List<ProfileNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListCard(
      elevated: false,
      children: [
        for (final item in items)
          ListTile(
            minTileHeight: 56,
            minVerticalPadding: Space.sm,
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.md),
            leading: Icon(
              item.icon,
              color: item.destructive ? scheme.error : scheme.primary,
            ),
            title: Text(
              item.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: item.destructive ? scheme.error : scheme.onSurface,
              ),
            ),
            subtitle: item.subtitle == null ? null : Text(item.subtitle!),
            trailing: Icon(
              Icons.chevron_right,
              size: kTrailingChevronSize,
              color: scheme.onSurfaceVariant,
            ),
            onTap: item.onTap,
          ),
      ],
    );
  }
}
