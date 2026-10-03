/// Persistent bottom section navigation for every role shell in router.dart.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/readable_label.dart';

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

class AppShell extends StatefulWidget {
  const AppShell({
    required this.navigationShell,
    required this.destinations,
    this.overlay,
    this.contextHeader,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppDestination> destinations;

  /// A widget stacked over the whole shell — e.g. the patient Care Navigator
  /// FAB. Sits below the router's Navigator, so tooltips / text selection
  /// work; hidden on full-screen pushes over the shell.
  final Widget? overlay;

  /// Optional role context that remains visible while switching branches.
  final Widget? contextHeader;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Bumped when the already-selected destination is tapped again, which every
  /// [AppScaffold] below listens for to scroll its content back to the top.
  final _scrollToTop = ValueNotifier<int>(0);

  @override
  void dispose() {
    _scrollToTop.dispose();
    super.dispose();
  }

  void _go(int index) {
    final reselected = index == widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(
      index,
      // Tapping the current tab again pops it to its root...
      initialLocation: reselected,
    );
    // ...and, if it was already at its root, sends it back to the top.
    if (reselected) _scrollToTop.value++;
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = _content(context);
    return widget.overlay == null
        ? scaffold
        : Stack(children: [scaffold, widget.overlay!]);
  }

  Widget _content(BuildContext context) {
    final current = widget.navigationShell.currentIndex;
    final hairline = Theme.of(context).colorScheme.outlineVariant;

    Widget body = ScrollToTopSignal(
      notifier: _scrollToTop,
      child: widget.navigationShell,
    );
    if (widget.contextHeader != null) {
      body = Column(
        children: [
          widget.contextHeader!,
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: hairline)),
        ),
        child: CompactNavigation(
          destinations: widget.destinations,
          currentIndex: current,
          onSelected: _go,
        ),
      ),
    );
  }
}

/// Full-size navigation labels: when five labels cannot fit, a single labelled
/// destination button opens the complete navigation list instead of shrinking.
class CompactNavigation extends StatelessWidget {
  const CompactNavigation({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<AppDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final style = theme.textTheme.labelMedium?.copyWith(fontSize: 11);
      final slotWidth = constraints.maxWidth / destinations.length - 8;
      var fits = scaler.scale(11) / 11 <= 1.3;
      for (final destination in destinations) {
        final painter = TextPainter(
          text: TextSpan(text: destination.label, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        fits = fits && painter.width <= slotWidth;
        painter.dispose();
      }
      if (fits) {
        return NavigationBar(
          height: 80,
          selectedIndex: currentIndex,
          onDestinationSelected: onSelected,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
                tooltip: d.label,
              ),
          ],
        );
      }
      final selected = destinations[currentIndex];
      return Material(
        color: theme.colorScheme.surfaceContainerLowest,
        child: SafeArea(
          top: false,
          child: ListTile(
            minTileHeight: 64,
            leading: Icon(
              selected.selectedIcon,
              color: theme.colorScheme.primary,
            ),
            title: ReadableLabel(
              selected.label,
              style: theme.textTheme.titleSmall,
            ),
            trailing: const Icon(Icons.unfold_more),
            onTap: () async {
              final index = await showModalBottomSheet<int>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (context) => SafeArea(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .7,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final (i, destination) in destinations.indexed)
                          ListTile(
                            minTileHeight: 56,
                            selected: i == currentIndex,
                            leading: Icon(destination.icon),
                            title: ReadableLabel(destination.label),
                            trailing: i == currentIndex
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.of(context).pop(i),
                          ),
                      ],
                    ),
                  ),
                ),
              );
              if (index != null) onSelected(index);
            },
          ),
        ),
      );
    },
  );
}
