/// Adaptive navigation shell (DESIGN.md §6).
///
/// One widget tree, re-flowed by window size class: `NavigationBar` at the
/// bottom on compact, an icon `NavigationRail` on medium, and an **extended**
/// rail from expanded up. Used by every role shell in router.dart.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/app_scaffold.dart';
import '../theme/theme.dart';

/// Navigation labels remain meaningful through the supported 200% text size.
/// The bar grows with them instead of silently shrinking accessibility text.
const double _navMaxTextScale = 2;

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
    final size = WindowSize.of(context);
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

    if (size.isCompact) {
      final navScaler = MediaQuery.textScalerOf(
        context,
      ).clamp(maxScaleFactor: _navMaxTextScale);
      return Scaffold(
        body: body,
        // Labels follow the user's text size through the supported 2x tier;
        // the bar grows taller so a
        // long label like "Appointments" can wrap to a second line.
        bottomNavigationBar: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: navScaler),
          child: DecoratedBox(
            // The bar is flat (DESIGN.md §4.3); the hairline is what separates
            // it from the content, not a shadow strip.
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: hairline)),
            ),
            child: NavigationBar(
              height: 64 + 32 * navScaler.scale(1),
              selectedIndex: current,
              onDestinationSelected: _go,
              destinations: [
                for (final d in widget.destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                    tooltip: d.label,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Extended from `expanded` up (DESIGN.md §6.4) — at 840dp there is room for
    // a 256dp labelled rail and a full content column beside it.
    final extended = size.isExpanded || size.isLarge;

    return Scaffold(
      body: Row(
        children: [
          _Rail(
            destinations: widget.destinations,
            currentIndex: current,
            onSelected: _go,
            extended: extended,
          ),
          VerticalDivider(width: 1, color: hairline),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The rail, with the brand lockup on top and room to scroll.
///
/// A plain [NavigationRail] overflows on a short landscape window (a 600×420
/// tablet with five destinations); the scroll view plus [IntrinsicHeight] is
/// the documented fix, and costs nothing when everything already fits.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    required this.extended,
  });

  final List<AppDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    if (extended) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return SizedBox(
        width: 248,
        child: ColoredBox(
          color: scheme.surfaceContainerLowest,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                const AppBrandLockup(),
                const SizedBox(height: Space.xl),
                for (final (i, destination) in destinations.indexed) ...[
                  Material(
                    color: currentIndex == i
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: Radii.cardSmall,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Space.sm,
                      ),
                      selected: currentIndex == i,
                      selectedColor: scheme.primary,
                      selectedTileColor: Colors.transparent,
                      leading: Icon(
                        currentIndex == i
                            ? destination.selectedIcon
                            : destination.icon,
                        size: 20,
                        color: currentIndex == i
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      title: Text(
                        destination.label,
                        style: theme.textTheme.labelLarge,
                      ),
                      onTap: () => onSelected(i),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                ],
              ],
            ),
          ),
        ),
      );
    }
    // Same supported 2x ceiling as the compact bottom bar. The rail scrolls,
    // so taller wrapped labels remain reachable.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(maxScaleFactor: _navMaxTextScale),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onSelected,
                extended: extended,
                // An extended rail draws its own inline labels, so the label
                // type must be `none` there; the icon rail stacks them
                // underneath.
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.sm,
                    Space.md,
                    Space.sm,
                    Space.lg,
                  ),
                  child: extended
                      ? const SizedBox(
                          width: 200,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: AppBrandLockup(),
                          ),
                        )
                      : const AppLogo(height: 28),
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
            ),
          ),
        ),
      ),
    );
  }
}
