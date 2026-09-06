/// A titled card whose body collapses behind a tap target.
///
/// Same surface as [AppCard] — rounded, hairline-bordered — with a header row
/// (icon, title, optional one-line summary while collapsed, a chevron that
/// turns) and an animated reveal that honours the OS reduce-motion setting.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    required this.title,
    required this.child,
    this.icon,
    this.summary,
    this.initiallyExpanded = false,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      Space.md,
      0,
      Space.md,
      Space.md,
    ),
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  /// Shown to the right of the title only while collapsed — a value preview
  /// like "O+" or "3 linked".
  final String? summary;

  final bool initiallyExpanded;
  final EdgeInsetsGeometry bodyPadding;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: _expanded ? 1 : 0,
  );
  late final Animation<double> _turns = Tween<double>(
    begin: 0,
    end: 0.5,
  ).animate(CurvedAnimation(parent: _controller, curve: Motion.standard));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      // Rebuild once the collapse finishes so the body leaves the tree.
      unawaited(
        _controller.reverse().whenComplete(() {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduce = Motion.reduced(context);

    return Material(
      type: MaterialType.card,
      color: theme.cardTheme.color ?? scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Space.sm),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (!_expanded && widget.summary != null) ...[
                    const SizedBox(width: Space.sm),
                    Flexible(
                      child: Text(
                        widget.summary!,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: Space.xs),
                  reduce
                      ? Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: scheme.onSurfaceVariant,
                        )
                      : RotationTransition(
                          turns: _turns,
                          child: Icon(
                            Icons.expand_more,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ],
              ),
            ),
          ),
          // Fully collapsed → the body is out of the tree entirely (no live
          // subscriptions, nothing focusable behind a closed panel).
          if (_expanded || _controller.value > 0)
            if (reduce)
              Padding(padding: widget.bodyPadding, child: widget.child)
            else
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: Curves.easeOut.transform(_controller.value),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: widget.bodyPadding,
                  child: widget.child,
                ),
              ),
        ],
      ),
    );
  }
}
