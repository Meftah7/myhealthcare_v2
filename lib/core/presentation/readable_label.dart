import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wraps at word boundaries. A word wider than the available space stays
/// intact in a horizontal scroll view rather than being split or shrunk.
/// Use in content-driven layouts, not inside intrinsic-size table columns.
class ReadableLabel extends StatelessWidget {
  const ReadableLabel(
    this.data, {
    this.style,
    this.textAlign = TextAlign.start,
    this.semanticsLabel,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final TextAlign textAlign;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget text() => Text(
          data,
          style: style,
          textAlign: textAlign,
          semanticsLabel: semanticsLabel,
        );
        if (!constraints.hasBoundedWidth) return text();
        final painter = TextPainter(
          text: TextSpan(text: data, style: effectiveStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        )..layout();
        final wordWidth = painter.minIntrinsicWidth.ceilToDouble() + 1;
        painter.dispose();
        if (wordWidth <= constraints.maxWidth) return text();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(wordWidth, constraints.maxWidth),
            child: text(),
          ),
        );
      },
    );
  }
}
