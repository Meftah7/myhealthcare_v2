/// List-detail layout for wide windows (DESIGN.md §6.4).
///
/// On a phone a list and its detail are two screens: you tap a row, the detail
/// pushes over it, you come back. On a laptop that is a waste — the window is
/// wide enough to hold both, and losing the list every time you open a record
/// makes comparing two of them needlessly slow.
///
/// [TwoPane] keeps exactly one widget tree for both: below `expanded` it renders
/// the list alone and leaves navigation to the caller's `push`; from `expanded`
/// up it puts the list in a fixed-width column with the detail beside it, and
/// selection becomes state rather than a route.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import 'states.dart';

class TwoPane extends StatelessWidget {
  const TwoPane({
    required this.list,
    required this.detail,
    this.listWidth = 380,
    this.placeholderIcon = Icons.article_outlined,
    this.placeholderMessage = 'Select an item to see its details.',
    super.key,
  });

  /// The list pane. Rendered alone on narrow windows.
  final Widget list;

  /// The detail pane, or null when nothing is selected. Only ever built on
  /// wide windows — on narrow ones the caller pushes a route instead.
  final Widget? detail;

  /// Width of the list column once both panes are showing. 380 keeps a
  /// two-line list row readable without starving the detail beside it.
  final double listWidth;

  final IconData placeholderIcon;
  final String placeholderMessage;

  /// True when this window is showing both panes — callers use it to decide
  /// between setting selection state and pushing a route.
  static bool isSplit(BuildContext context) => WindowSize.of(context).usesPanes;

  @override
  Widget build(BuildContext context) {
    if (!isSplit(context)) return list;

    final hairline = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        SizedBox(width: listWidth, child: list),
        VerticalDivider(width: 1, color: hairline),
        Expanded(
          child: SharedAxisSwitcher(
            child:
                detail ??
                EmptyState(
                  key: const ValueKey('two-pane-placeholder'),
                  icon: placeholderIcon,
                  message: placeholderMessage,
                ),
          ),
        ),
      ],
    );
  }
}

/// The selected-row treatment inside a [TwoPane] list — a tinted fill matching
/// the navigation indicator, so "where I am" reads the same in the rail and in
/// the list.
///
/// A no-op on narrow windows, where nothing stays selected after the push.
class PaneSelection extends StatelessWidget {
  const PaneSelection({required this.selected, required this.child, super.key});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!selected || !TwoPane.isSplit(context)) return child;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: Radii.card,
      ),
      child: child,
    );
  }
}
