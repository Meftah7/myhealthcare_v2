/// Adaptive navigation shell (DESIGN.md §6).
///
/// One widget tree, re-flowed by window size class: `NavigationBar` at the
/// bottom on compact, `NavigationRail` (extended on large) from medium up.
/// Used by every role shell in router.dart.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

/// One navigation destination in a role shell.
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.destinations,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppDestination> destinations;

  void _go(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the current tab again pops it to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final current = navigationShell.currentIndex;

    final scheme = Theme.of(context).colorScheme;
    final hairline = scheme.outlineVariant.withValues(alpha: 0.7);

    if (size.isCompact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: hairline)),
          ),
          child: NavigationBar(
            selectedIndex: current,
            onDestinationSelected: _go,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: current,
            onDestinationSelected: _go,
            extended: size.isLarge,
            labelType: size.isLarge
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: hairline),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
