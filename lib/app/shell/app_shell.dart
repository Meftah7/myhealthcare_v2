/// Adaptive navigation shell (DESIGN.md §6).
///
/// One widget tree, re-flowed by window size class: `NavigationBar` at the
/// bottom on compact, an icon `NavigationRail` on medium, and an **extended**
/// rail from expanded up for admin. Patient and staff shells use width-based
/// bottom tabs (the patient bar), a rail, and an expanded sidebar — the
/// patient's with account access, the staff's with the same five tabs.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/ui/patient/patient_components.dart';
import '../../l10n/app_localizations.dart';
import '../theme/theme.dart';
import 'shell_insets.dart';

/// One navigation destination in a role shell.
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// A visible scope label shown with the destination wherever it appears
  /// (bottom bar, destination menu, rail) and read after the label.
  final String? badge;

  String get semanticLabel => badge == null ? label : '$label, $badge';
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.navigationShell,
    required this.destinations,
    this.overlay,
    this.contextHeader,
    this.compactLeadingCount,
    this.keepCompactSectionsVisible = false,
    this.selectedDestinationFor,
    this.resetBranchesOnSelect = const {},
    this.compactBarBuilder,
    this.drawer,
    this.expandedAccountBuilder,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// A native navigation drawer on the shell's outer Scaffold (patient
  /// account / settings). Pages open it through [ShellDrawerScope].
  final Widget? drawer;

  /// Opts the shell into the patient app's adaptive layout — patient bar
  /// below 600, rail to 1024, sidebar from 1024 — and builds that sidebar
  /// around the destination entries. Used by the patient and staff shells.
  final Widget Function(List<Widget> primaryEntries)? expandedAccountBuilder;

  /// Maps the active branch to the highlighted destination. Lets a shell keep
  /// extra branches (routes retained for deep links) that have no tab of
  /// their own — they highlight the destination they are reached from.
  final int Function(int branchIndex)? selectedDestinationFor;
  final Set<int> resetBranchesOnSelect;

  /// Replaces the stock compact bar (the patient shell's centre-tile bar).
  final Widget Function(
    BuildContext context,
    int selected,
    ValueChanged<int> onSelected,
  )?
  compactBarBuilder;
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _drawerOpen = false;

  /// Where the shell's navigation is, for the floating overlay to stay clear
  /// of it: the bottom bar's measured height and whether the current layout
  /// builds one at all, and the width of the patient rail / sidebar. The last
  /// two are set by [_content] on every build, before the overlay is wrapped.
  final _bottomBarHeight = ValueNotifier<double>(0);
  bool _hasBottomBar = false;
  double _sideNavWidth = 0;

  @override
  void dispose() {
    _scrollToTop.dispose();
    _bottomBarHeight.dispose();
    super.dispose();
  }

  void _go(int index) {
    final reselected = index == widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(
      index,
      // Tapping the current tab again pops it to its root...
      initialLocation:
          reselected || widget.resetBranchesOnSelect.contains(index),
    );
    // ...and, if it was already at its root, sends it back to the top.
    if (reselected) _scrollToTop.value++;
  }

  void _drawerChanged(bool open) {
    if (open != _drawerOpen) setState(() => _drawerOpen = open);
  }

  @override
  Widget build(BuildContext context) {
    _hasBottomBar = false;
    _sideNavWidth = 0;
    final scaffold = _content(context);
    if (widget.overlay == null) return scaffold;
    final hasBar = _hasBottomBar;
    // The rail / sidebar sits on the start side: the right in RTL.
    final navOnLeft = Directionality.of(context) == TextDirection.ltr;
    final side = _sideNavWidth;
    // The floating overlay steps aside while the drawer is open, and is told
    // where the shell's navigation is so it never parks on top of it.
    return Stack(
      children: [
        scaffold,
        if (!_drawerOpen)
          ValueListenableBuilder<double>(
            valueListenable: _bottomBarHeight,
            builder: (context, height, overlay) => ShellInsets(
              navigation: EdgeInsets.only(
                left: navOnLeft ? side : 0,
                right: navOnLeft ? 0 : side,
                bottom: hasBar ? height : 0,
              ),
              child: overlay!,
            ),
            child: widget.overlay,
          ),
      ],
    );
  }

  /// Wraps a bottom bar so its height reaches [_bottomBarHeight].
  Widget _bottomBar(Widget bar) {
    _hasBottomBar = true;
    return MeasureHeight(
      onHeight: (h) {
        if (mounted) _bottomBarHeight.value = h;
      },
      child: bar,
    );
  }

  Widget _content(BuildContext context) {
    final size = WindowSize.of(context);
    final branch = widget.navigationShell.currentIndex;
    final current = widget.selectedDestinationFor?.call(branch) ?? branch;
    final hairline = Theme.of(context).colorScheme.outlineVariant;
    final patientAdaptive = widget.expandedAccountBuilder != null;
    final width = MediaQuery.sizeOf(context).width;
    final patientRailWidth =
        (128 * MediaQuery.textScalerOf(context).scale(13) / 13).clamp(
          128.0,
          248.0,
        );

    Widget body = ScrollToTopSignal(
      notifier: _scrollToTop,
      child: widget.navigationShell,
    );
    if (widget.drawer != null) {
      body = ShellDrawerScope(
        open: () => _scaffoldKey.currentState?.openDrawer(),
        showMenu: !patientAdaptive || width < 600,
        child: body,
      );
    }
    if (widget.contextHeader != null) {
      body = Column(
        children: [
          widget.contextHeader!,
          Expanded(child: body),
        ],
      );
    }

    if (patientAdaptive) {
      final compact = width < 600;
      final expanded = width >= 1024;
      final t = AppLocalizations.of(context)!;
      // Rail or sidebar, plus the sidebar's 1px hairline.
      _sideNavWidth = compact
          ? 0
          : expanded
          ? 273
          : patientRailWidth;
      final entries = <Widget>[
        for (final (i, destination) in widget.destinations.indexed)
          ListTile(
            key: ValueKey('patient-destination-$i'),
            minTileHeight: 56,
            selected: current == i,
            leading: Icon(
              current == i ? destination.selectedIcon : destination.icon,
            ),
            title: ReadableLabel(destination.label),
            subtitle: destination.badge == null
                ? null
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: NavScopeBadge(destination.badge!),
                  ),
            onTap: () => _go(i),
          ),
      ];
      return Scaffold(
        key: _scaffoldKey,
        drawer: expanded ? null : widget.drawer,
        onDrawerChanged: _drawerChanged,
        // The patient bar stays full width: its five labels and centre tile
        // need the whole row, so it does not sit in the inset clay dock.
        bottomNavigationBar: compact
            ? _bottomBar(widget.compactBarBuilder!(context, current, _go))
            : null,
        body: Row(
          children: [
            SizedBox(
              width: compact
                  ? 0
                  : expanded
                  ? 272
                  : patientRailWidth,
              child: compact
                  ? null
                  : expanded
                  ? widget.expandedAccountBuilder!(entries)
                  : _ClayDock.rail(
                      child: Column(
                        children: [
                          Expanded(
                            child: _Rail(
                              destinations: widget.destinations,
                              currentIndex: current,
                              onSelected: _go,
                              extended: false,
                              // 24 for rail padding + 16 for the clay dock inset.
                              labelWidth: patientRailWidth - 40,
                            ),
                          ),
                          if (widget.drawer != null)
                            SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Tooltip(
                                  message: t.paDrawerAccount,
                                  child: TextButton(
                                    key: const ValueKey('patient-rail-account'),
                                    onPressed: () =>
                                        _scaffoldKey.currentState?.openDrawer(),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.manage_accounts_outlined,
                                        ),
                                        Text(
                                          t.paDrawerAccount,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            SizedBox(
              width: compact || !expanded ? 0 : 1,
              child: VerticalDivider(width: 1, color: hairline),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    if (size.isCompact && widget.compactBarBuilder != null) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: widget.drawer,
        onDrawerChanged: _drawerChanged,
        body: body,
        bottomNavigationBar: _bottomBar(
          widget.compactBarBuilder!(context, current, _go),
        ),
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
        // The floating clay dock is the redesign's signature element.
        bottomNavigationBar: _bottomBar(
          _ClayDock(
            child: CompactNavigation(
              destinations: compact,
              currentIndex: leading == null
                  ? current
                  : current.clamp(0, leading),
              onSelected: selectCompact,
              keepSectionsVisible: widget.keepCompactSectionsVisible,
            ),
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
      key: widget.drawer == null ? null : _scaffoldKey,
      drawer: widget.drawer,
      onDrawerChanged: widget.drawer == null ? null : _drawerChanged,
      body: Row(
        children: [
          _ClayDock.rail(
            child: _Rail(
              destinations: widget.destinations,
              currentIndex: current,
              onSelected: _go,
              extended: extended,
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// A rounded, raised clay object that hosts navigation: compact bottom bars
/// float above the content, and rails sit inset from the window edge.
class _ClayDock extends StatelessWidget {
  const _ClayDock({required this.child}) : _rail = false;
  const _ClayDock.rail({required this.child}) : _rail = true;

  final Widget child;
  final bool _rail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dock = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: Radii.cardLarge,
        border: Border.all(color: Clay.seam(scheme)),
        boxShadow: Shadows.clay(scheme, raised: true),
      ),
      child: ClipRRect(borderRadius: Radii.cardLarge, child: child),
    );
    if (_rail) {
      return Padding(padding: const EdgeInsets.all(Space.sm), child: dock);
    }
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        Space.sm,
        Space.xxs,
        Space.sm,
        Space.sm,
      ),
      child: dock,
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
    this.labelWidth,
  });

  final List<AppDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool extended;
  final double? labelWidth;

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
                        semanticsLabel: destination.semanticLabel,
                      ),
                      subtitle: destination.badge == null
                          ? null
                          : Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: NavScopeBadge(destination.badge!),
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
                    label: labelWidth != null
                        ? SizedBox(
                            width: labelWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(d.label, textAlign: TextAlign.center),
                                if (d.badge != null) NavScopeBadge(d.badge!),
                              ],
                            ),
                          )
                        : d.badge == null
                        ? Text(d.label)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(d.label),
                              const SizedBox(height: 2),
                              NavScopeBadge(d.badge!),
                            ],
                          ),
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
              semanticsLabel: selected.semanticLabel,
            ),
            subtitle: selected.badge == null
                ? null
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: NavScopeBadge(selected.badge!),
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
                            title: ReadableLabel(
                              destination.label,
                              semanticsLabel: destination.semanticLabel,
                            ),
                            // The scope label stays visible in the menu too.
                            subtitle: destination.badge == null
                                ? null
                                : Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: NavScopeBadge(destination.badge!),
                                  ),
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
