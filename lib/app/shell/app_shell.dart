/// Adaptive navigation shell (DESIGN.md §6).
///
/// One widget tree, re-flowed by window size class: `NavigationBar` at the
/// bottom on compact, an icon `NavigationRail` on medium, and an **extended**
/// rail from expanded up. Used by every role shell in router.dart.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/readable_label.dart';
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
    this.contextHeader,
    this.compactLeadingCount,
    this.keepCompactSectionsVisible = false,
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
  final int? compactLeadingCount;
  final bool keepCompactSectionsVisible;

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
      final leading = widget.compactLeadingCount;
      final compact = leading == null
          ? widget.destinations
          : [
              ...widget.destinations.take(leading),
              AppDestination(
                icon: Icons.more_horiz,
                selectedIcon: Icons.more_horiz,
                label: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'المزيد'
                    : 'More',
              ),
            ];
      void selectCompact(int index) {
        if (leading == null || index < leading) {
          _go(index);
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var i = leading; i < widget.destinations.length; i++)
                  ListTile(
                    leading: Icon(widget.destinations[i].icon),
                    title: Text(widget.destinations[i].label),
                    selected: current == i,
                    onTap: () {
                      Navigator.pop(sheet);
                      _go(i);
                    },
                  ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        body: body,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: hairline)),
          ),
          child: CompactNavigation(
            destinations: compact,
            currentIndex: leading == null ? current : current.clamp(0, leading),
            onSelected: selectCompact,
            keepSectionsVisible: widget.keepCompactSectionsVisible,
          ),
        ),
      );
    }

    // Extended from `expanded` up (DESIGN.md §6.4) — at 840dp there is room for
    // a 256dp labelled rail and a full content column beside it.
    final extended =
        size.isExpanded ||
        size.isLarge ||
        MediaQuery.textScalerOf(context).scale(13) / 13 > 1.3;

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
                      title: ReadableLabel(
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
    return LayoutBuilder(
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
    this.keepSectionsVisible = false,
    super.key,
  });

  final List<AppDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool keepSectionsVisible;

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
      if (fits || (keepSectionsVisible && scaler.scale(11) / 11 <= 1.3)) {
        Widget destination(AppDestination d) {
          final item = NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
            tooltip: d.label,
          );
          return keepSectionsVisible
              ? DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: item,
                )
              : item;
        }

        return NavigationBar(
          height: 80,
          selectedIndex: currentIndex,
          onDestinationSelected: onSelected,
          destinations: [for (final d in destinations) destination(d)],
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
