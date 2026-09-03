/// The shell every screen sits in (DESIGN.md §5.2, §6).
///
/// One consistent frame: a flat app bar, the standard responsive gutter, the
/// reading column capped and centred on wide windows, and optional
/// pull-to-refresh. Screens pass a `body` (usually a scroll view) and get
/// consistent padding + width behaviour for free.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.onRefresh,
    this.scrollable = true,
    this.padded = true,
    this.leading,
    this.titleWidget,
    super.key,
  });

  final String title;

  /// Overrides [title] as the app-bar title (e.g. a logo lockup).
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Widget? leading;

  /// When set, wraps the body in a [RefreshIndicator].
  final Future<void> Function()? onRefresh;

  /// Wrap the body in a scroll view. Turn off for screens that manage their
  /// own scrolling (lists, custom scroll views).
  final bool scrollable;

  /// Apply the responsive screen gutter to the body.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final gutter = size.isCompact ? Space.md : Space.lg;

    Widget content = body;
    if (padded) {
      content = Padding(
        padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.xxl),
        child: content,
      );
    }
    if (scrollable) {
      content = SingleChildScrollView(
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }
    // Cap the reading column on wide windows and centre it.
    content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
        child: content,
      ),
    );
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: titleWidget ?? Text(title),
        leading: leading,
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}
