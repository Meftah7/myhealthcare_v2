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
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppDestination> destinations;

  /// A widget stacked over the whole shell — e.g. the patient Care Navigator
  /// FAB. Sits below the router's Navigator, so tooltips / text selection
  /// work; hidden on full-screen pushes over the shell.
  final Widget? overlay;

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

    final body = ScrollToTopSignal(
      notifier: _scrollToTop,
      child: widget.navigationShell,
    );

    if (size.isCompact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: DecoratedBox(
          // The bar is flat (DESIGN.md §4.3); the hairline is what separates it
          // from the content, not a shadow strip.
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: hairline)),
          ),
          child: NavigationBar(
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
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onSelected,
              extended: extended,
              // An extended rail draws its own inline labels, so the label type
              // must be `none` there; the icon rail stacks them underneath.
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
                    : Image.asset('assets/images/logo.png', height: 28),
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
    );
  }
}
