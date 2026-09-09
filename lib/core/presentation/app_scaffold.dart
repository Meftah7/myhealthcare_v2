/// The one screen shell (DESIGN.md §5.2).
///
/// Before this existed every screen hand-rolled the same five layers —
/// `Scaffold` → `AppBar` → `RefreshIndicator` → `Center` + `ConstrainedBox`
/// → `ListView` + padding — and drifted a little each time: nine screens
/// forgot the max-width centring, the scroll padding came in two flavours, and
/// only a handful wired pull-to-refresh. [AppScaffold] owns all of it, so a
/// screen declares *what* is on it and nothing about how the page is framed.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// Bumped by the shell when the active navigation destination is tapped a
/// second time; every [AppScaffold] below it scrolls back to the top.
///
/// An [InheritedNotifier] rather than a callback registry so a screen picks the
/// signal up just by being in the tree, and drops it just by leaving.
class ScrollToTopSignal extends InheritedNotifier<ValueNotifier<int>> {
  const ScrollToTopSignal({
    required ValueNotifier<int> super.notifier,
    required super.child,
    super.key,
  });

  static ValueNotifier<int>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScrollToTopSignal>()?.notifier;
}

/// The app's screen shell. Supply exactly one of [children], [slivers] or
/// [body].
///
/// * [children] — the common case: a vertical list of sections, gutter and
///   scroll padding applied, entrance stagger for free.
/// * [slivers] — when a screen needs a sticky header, a `SliverGrid`, or a
///   `SliverList.builder` for a long list. Horizontal gutter is applied to each
///   sliver; vertical padding is added as leading/trailing spacers.
/// * [body] — the escape hatch for screens that manage their own scrolling
///   (a calendar grid, a chat thread). Only the `Scaffold` + `AppBar` are
///   provided; centring and padding are the caller's.
class AppScaffold extends StatefulWidget {
  const AppScaffold({
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onRefresh,
    this.children,
    this.slivers,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.padding,
    this.maxContentWidth = Space.maxContentWidth,
    this.stagger = true,
    this.centerBody = true,
    super.key,
  }) : assert(
         (children != null ? 1 : 0) +
                 (slivers != null ? 1 : 0) +
                 (body != null ? 1 : 0) ==
             1,
         'Supply exactly one of children, slivers or body.',
       );

  /// Screen title. Rendered with the AppBar's `titleLarge` — deliberately not
  /// scaled up on wide windows: the toolbar is chrome, and a screen that wants
  /// a large heading puts one in its content (see the dashboards' greeting).
  final String? title;

  /// Replaces [title] entirely — e.g. [AppBrandLockup] on the role home
  /// screens, or a title plus a status line.
  final Widget? titleWidget;

  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// Wires pull-to-refresh. Ignored in [body] mode, where the caller owns the
  /// scrollable.
  final Future<void> Function()? onRefresh;

  final List<Widget>? children;
  final List<Widget>? slivers;
  final Widget? body;

  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Overrides the standard scroll padding. Leave null for the house value:
  /// the window-size gutter on both sides, `Space.md` above and `Space.xxl`
  /// below (room for the bottom nav bar and the FAB).
  final EdgeInsets? padding;

  final double maxContentWidth;

  /// Fade-and-rise the [children] into place on first build. Off for screens
  /// whose content is already animated by something else.
  final bool stagger;

  /// Centre and cap [body] the way [children] is centred and capped. Off when
  /// the body genuinely wants the full window (a two-pane split, a calendar).
  final bool centerBody;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final _controller = ScrollController();
  ValueNotifier<int>? _signal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = ScrollToTopSignal.maybeOf(context);
    if (identical(signal, _signal)) return;
    _signal?.removeListener(_scrollToTop);
    _signal = signal?..addListener(_scrollToTop);
  }

  @override
  void dispose() {
    _signal?.removeListener(_scrollToTop);
    _controller.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_controller.hasClients || _controller.offset <= 0) return;
    if (Motion.reduced(context)) {
      _controller.jumpTo(0);
      return;
    }
    _controller.animateTo(0, duration: Motion.slow, curve: Motion.standard);
  }

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final gutter = size.gutter;
    final pad =
        widget.padding ??
        EdgeInsets.fromLTRB(gutter, Space.md, gutter, Space.xxl);

    Widget content;
    if (widget.body != null) {
      content = widget.centerBody ? _capped(widget.body!) : widget.body!;
    } else {
      content = _capped(
        CustomScrollView(
          controller: _controller,
          // Always scrollable so pull-to-refresh works on a short page.
          physics: widget.onRefresh == null
              ? null
              : const AlwaysScrollableScrollPhysics(),
          slivers: _slivers(pad),
        ),
      );
    }

    if (widget.onRefresh != null && widget.body == null) {
      content = RefreshIndicator(onRefresh: widget.onRefresh!, child: content);
    }

    final hasAppBar =
        widget.title != null ||
        widget.titleWidget != null ||
        widget.actions != null ||
        widget.bottom != null ||
        widget.leading != null;

    return Scaffold(
      appBar: !hasAppBar
          ? null
          : AppBar(
              titleSpacing: gutter,
              title:
                  widget.titleWidget ??
                  (widget.title == null
                      ? null
                      : Text(
                          widget.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
              leading: widget.leading,
              automaticallyImplyLeading: widget.automaticallyImplyLeading,
              actions: widget.actions,
              bottom: widget.bottom,
            ),
      body: content,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  Widget _capped(Widget child) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
      child: child,
    ),
  );

  List<Widget> _slivers(EdgeInsets pad) {
    if (widget.slivers != null) {
      final horizontal = EdgeInsets.symmetric(horizontal: pad.left);
      return [
        SliverToBoxAdapter(child: SizedBox(height: pad.top)),
        for (final sliver in widget.slivers!)
          SliverPadding(padding: horizontal, sliver: sliver),
        SliverToBoxAdapter(child: SizedBox(height: pad.bottom)),
      ];
    }
    return [
      SliverPadding(
        padding: pad,
        sliver: SliverList.list(children: _staggered(widget.children!)),
      ),
    ];
  }

  /// Wraps each child in an [AppEntrance] with an ascending index. Spacers are
  /// passed through untouched and don't consume a stagger slot — otherwise the
  /// `SizedBox`es between sections would eat the whole cascade before the
  /// second card ever moved.
  List<Widget> _staggered(List<Widget> children) {
    if (!widget.stagger) return children;
    var index = 0;
    return [
      for (final child in children)
        if (child is SizedBox)
          child
        else
          AppEntrance(index: index++, child: child),
    ];
  }
}

/// The product mark — logo plus wordmark — for the role home screens' app bar.
///
/// Shared so the patient, staff and admin dashboards open with the same
/// lockup instead of one showing the brand and the other two repeating the
/// word "Dashboard" above an in-content greeting that already says it.
class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({this.subtitle, super.key});

  /// An optional second line — the role, or the signed-in department.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 26),
        const SizedBox(width: Space.xs),
        // Flexible so the wordmark ellipsises on a narrow phone rather than
        // colliding with the top-bar action buttons.
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MyHealth Care',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The date overline + greeting that opens each role's home screen.
///
/// One component so the three dashboards can't drift apart, and so the
/// heading scales with the window instead of being pinned to one size.
class PageGreeting extends StatelessWidget {
  const PageGreeting({
    required this.greeting,
    required this.overline,
    super.key,
  });

  final String greeting;
  final String overline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = WindowSize.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The small line sets context, the big line is the thing you read.
        Text(
          overline.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          greeting,
          style: size.isCompact
              ? theme.textTheme.headlineSmall
              : theme.textTheme.headlineMedium,
        ),
      ],
    );
  }
}
