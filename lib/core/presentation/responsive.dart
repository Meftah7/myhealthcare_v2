/// Layout primitives that re-flow with the window size class (DESIGN.md §6.4).
///
/// One widget tree, re-flowed — never a separate phone build and desktop build.
/// These are the two shapes the app actually needs: a dashboard that splits
/// into columns when there is room, and a grid of tiles whose row height is
/// driven by the text, not by a fixed aspect ratio.
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
  const MetricRow({required this.children, this.maxTileWidth = 260, super.key});

  final List<Widget> children;
  final double maxTileWidth;

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
