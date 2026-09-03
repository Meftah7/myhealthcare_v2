/// Shared empty / error / loading widgets (P2-18). One of each, reused
/// everywhere — DESIGN.md §5.2.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// Icon + one line + an optional single action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: icon,
      title: message,
      tone: _StateTone.neutral,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// A failure message with a retry affordance.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_rounded,
      title: message,
      tone: _StateTone.error,
      actionLabel: onRetry == null ? null : 'Try again',
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}

enum _StateTone { neutral, error }

/// The shared layout for empty / error screens: a softly-tinted icon medallion,
/// one line of copy, and at most one action.
class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.tone,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final _StateTone tone;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = tone == _StateTone.error ? scheme.error : scheme.onSurfaceVariant;
    final bg = (tone == _StateTone.error
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest)
        .withValues(alpha: tone == _StateTone.error ? 0.5 : 1);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 28, color: fg),
              ),
              const SizedBox(height: Space.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Space.lg),
                if (actionIcon != null)
                  OutlinedButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon),
                    label: Text(actionLabel!),
                  )
                else
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A shimmering placeholder block for content that is loading.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = Radii.chip,
    super.key,
  });

  final double height;
  final double width;
  final BorderRadius borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    if (Motion.reduced(context)) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: base,
          borderRadius: widget.borderRadius,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(base, scheme.surfaceContainer, _c.value),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

/// A stack of card-shaped placeholders that mirror the list they stand in for.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.lines = 5, super.key});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.sm),
      child: Column(
        children: [
          for (var i = 0; i < lines; i++)
            Container(
              margin: const EdgeInsets.only(bottom: Space.sm),
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                borderRadius: Radii.card,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoadingSkeleton(width: 160),
                  const SizedBox(height: Space.sm),
                  LoadingSkeleton(
                    height: 12,
                    width: MediaQuery.sizeOf(context).width * 0.5,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
