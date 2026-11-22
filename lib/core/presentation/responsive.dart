/// Layout primitives that re-flow with the window size class (DESIGN.md §6.4).
///
/// One widget tree, re-flowed — never a separate phone build and desktop build.
/// Dashboards use unequal bento rows, long collections use columns, and compact
/// actions use a grid whose row height is driven by text instead of a fixed
/// pixel height.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// Keeps filters reachable without letting enlarged text consume the body.
class ScrollableHeaderBody extends StatelessWidget {
  const ScrollableHeaderBody({
    required this.header,
    required this.body,
    super.key,
  });

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * .4),
          child: SingleChildScrollView(child: header),
        ),
        Expanded(child: body),
      ],
    ),
  );
}

/// One cell in a [BentoRow]. [flex] is its share of the row on wide windows;
/// compact layouts ignore it and preserve the source order.
class BentoCell {
  const BentoCell({required this.child, this.flex = 1}) : assert(flex > 0);

  final Widget child;
  final int flex;
}

/// A dashboard made from deliberately asymmetric rows rather than two endless
/// columns. Each row owns a meaningful group (hero + summary, actions + queue),
/// while [BentoRow] handles the responsive re-flow.
class BentoGrid extends StatelessWidget {
  const BentoGrid({required this.rows, this.gap = Space.sm, super.key});

  final List<BentoRow> rows;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        rows[i],
      ],
    ],
  );
}

/// One horizontal bento band. Modules keep their natural heights: forcing equal
/// heights makes shrink-wrapped grids and pagers report unreliable intrinsic
/// sizes, and can leave visible controls outside their hit-test bounds.
///
/// The row stacks when its actual content pane is narrow (rather than relying
/// only on the full-window size class) and when text is enlarged. That keeps
/// the bento composition useful without making 200% text compete for width.
class BentoRow extends StatelessWidget {
  const BentoRow({
    required this.cells,
    this.stackedChildren,
    this.gap = Space.sm,
    this.minWideWidth = 720,
    super.key,
  });

  final List<BentoCell> cells;

  /// Optional compact composition when the wide cells contain nested groups.
  /// This lets a phone preserve the true priority order without forcing the
  /// desktop row to use the same grouping.
  final List<Widget>? stackedChildren;
  final double gap;
  final double minWideWidth;

  @override
  Widget build(BuildContext context) {
    assert(cells.isNotEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stacked =
            cells.length == 1 ||
            constraints.maxWidth < minWideWidth ||
            textScale > 1.6;

        if (stacked) {
          final children =
              stackedChildren ?? [for (final cell in cells) cell.child];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(flex: cells[i].flex, child: cells[i].child),
            ],
          ],
        );
      },
    );
  }
}

/// Splits a screen's sections into two columns once the window is `expanded`
/// or wider, and stacks them in one column below that.
///
/// On a narrow window the output is exactly `[...primary, ...secondary]`, so
/// the compact reading order is whatever the caller wrote — which is why the
/// lists are ordered rather than slotted.
///
/// Both lists should begin with a [SectionHeader]; the header supplies its own
/// leading gap, so two columns that each start with one line up at the top.
/// Anything that must sit above the split (a hero card) belongs in the parent's
/// child list, not in here.
class SectionColumns extends StatelessWidget {
  const SectionColumns({
    required this.primary,
    required this.secondary,
    this.gap = Space.lg,
    super.key,
  });

  /// The left column on wide windows, the top block on narrow ones.
  final List<Widget> primary;

  /// The right column on wide windows, the bottom block on narrow ones.
  final List<Widget> secondary;

  final double gap;

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);

    if (!size.usesPanes) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...primary, ...secondary],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: primary,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: secondary,
          ),
        ),
      ],
    );
  }
}

/// A list of variable-height cards that flows into columns on wide windows.
///
/// Cards are dealt round-robin, so the first row reads left-to-right and each
/// column stays roughly the same length without measuring anything — the
/// dependency-free version of a masonry grid. On a narrow window it is just a
/// stack, in the original order.
///
/// Use it wherever a screen is a list of self-contained cards (appointments,
/// records, notifications): a single 1120dp-wide column of cards on a desktop
/// is mostly empty card.
class CardColumns extends StatelessWidget {
  const CardColumns({required this.children, this.gap = Space.sm, super.key});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final columns = WindowSize.of(context).usesPanes ? 2 : 1;

    if (columns == 1 || children.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }

    final lanes = List.generate(columns, (_) => <Widget>[]);
    for (var i = 0; i < children.length; i++) {
      lanes[i % columns].add(children[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lanes[c].length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  lanes[c][i],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A grid of short tiles — quick actions, shortcuts — whose row height is
/// measured from the current text scale instead of pinned to an aspect ratio.
///
/// The old `childAspectRatio: 2.6` was the source of a whole class of bugs: at
/// the OS's 2× text setting the label needs roughly twice the height, the tile
/// doesn't grow, and the row overflows. [rowHeight] asks the text scaler how
/// tall a line actually is and sizes the row to fit it.
class TileGrid extends StatelessWidget {
  const TileGrid({required this.children, this.minTileWidth = 168, super.key});

  final List<Widget> children;

  /// Below this the grid drops a column rather than squeezing labels.
  final double minTileWidth;

  /// Height of one [NavRow]-shaped tile at the current text scale: the card's
  /// vertical padding, plus whichever is taller — the icon medallion or a line
  /// of `titleSmall` — plus a little slack.
  static double rowHeight(BuildContext context) {
    const verticalPadding = Space.sm * 2;
    const medallion = 34.0;
    const titleSmallLineHeight = 20.0;
    final line = MediaQuery.textScalerOf(context).scale(titleSmallLineHeight);
    return verticalPadding + math.max(medallion, line * 2) + Space.xxs;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveColumns(
      minChildWidth: minTileWidth,
      maxColumns: WindowSize.of(context).tileColumns,
      children: children,
    );
  }
}

/// A row of [MetricTile]s that stays readable at every width: evenly divided,
/// but capped so three figures don't stretch to 370dp each on a desktop.
class MetricRow extends StatelessWidget {
  const MetricRow({
    required this.children,
    this.maxTileWidth = 260,
    this.divided = false,
    super.key,
  });

  final List<Widget> children;
  final double maxTileWidth;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return AdaptiveColumns(
      minChildWidth: 156,
      maxColumns: children.length,
      children: children,
    );
  }
}

/// Content-height columns: narrow windows and enlarged text reduce the column
/// count. Unlike aspect-ratio grids, cards grow to fit their actual contents.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({
    required this.children,
    this.minChildWidth = 180,
    this.maxColumns = 3,
    this.gap = Space.sm,
    super.key,
  });

  final List<Widget> children;
  final double minChildWidth;
  final int maxColumns;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = math.max(
        1.0,
        MediaQuery.textScalerOf(context).scale(16) / 16,
      );
      final count =
          ((constraints.maxWidth + gap) / (minChildWidth * scale + gap))
              .floor()
              .clamp(1, math.max(1, maxColumns));
      final width = (constraints.maxWidth - gap * (count - 1)) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// Equal-width controls reflow into full-width rows before labels are cramped.
class AdaptiveFormRow extends StatelessWidget {
  const AdaptiveFormRow({
    required this.children,
    this.minChildWidth = 200,
    super.key,
  });

  final List<Widget> children;
  final double minChildWidth;

  @override
  Widget build(BuildContext context) => AdaptiveColumns(
    minChildWidth: minChildWidth,
    maxColumns: children.length,
    children: children,
  );
}
