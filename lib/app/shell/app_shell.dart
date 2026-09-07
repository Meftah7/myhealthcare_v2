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

/// A standalone nav-bar action that doesn't correspond to a shell branch —
/// e.g. the "+" quick-booking button, which launches a flow rather than
/// switching tabs (DESIGN.md §6, patient dashboard rebuild).
class AppCenterAction {
  const AppCenterAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.destinations,
    this.centerAction,
    this.overlay,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppDestination> destinations;

  /// An extra action rendered between the destinations — e.g. patient "+"
  /// (quick booking). Never becomes the selected/active tab.
  final AppCenterAction? centerAction;

  /// A widget stacked over the whole shell — e.g. the patient Care Navigator
  /// FAB. Sits below the router's Navigator, so tooltips / text selection
  /// work; hidden on full-screen pushes over the shell.
  final Widget? overlay;

  void _go(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the current tab again pops it to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = _content(context);
    return overlay == null
        ? scaffold
        : Stack(children: [scaffold, overlay!]);
  }

  Widget _content(BuildContext context) {
    final size = WindowSize.of(context);
    final current = navigationShell.currentIndex;
    final action = centerAction;

    final scheme = Theme.of(context).colorScheme;
    final hairline = scheme.outlineVariant.withValues(alpha: 0.7);

    if (size.isCompact) {
      final half = (destinations.length / 2).ceil();
      Widget destinationButton(AppDestination d, int index) {
        final selected = index == current;
        return Expanded(
          child: InkWell(
            onTap: () => _go(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? d.selectedIcon : d.icon,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        body: navigationShell,
        floatingActionButton: action == null
            ? null
            : FloatingActionButton(
                tooltip: action.tooltip,
                onPressed: action.onPressed,
                child: Icon(action.icon),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: action == null
            ? DecoratedBox(
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
              )
            : BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: Space.xs,
                child: Row(
                  children: [
                    for (final (i, d) in destinations.indexed) ...[
                      destinationButton(d, i),
                      if (i == half - 1) const SizedBox(width: 56),
                    ],
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
            leading: action == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: FloatingActionButton(
                      tooltip: action.tooltip,
                      onPressed: action.onPressed,
                      child: Icon(action.icon),
                    ),
                  ),
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
