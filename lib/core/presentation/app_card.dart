/// Shared surface components (DESIGN.md §5.2, redesign v2).
///
/// [AppCard] is the one card the whole app uses: flat, hairline-bordered, an
/// optional soft lift, optional press feedback. [MetricTile] is the honest
/// "one number + label + trend" used on every dashboard.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// The app's single card. Flat fill + hairline border by default; pass
/// [elevated] for [Shadows.e1]; pass [onTap] for press feedback.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.elevated = false,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // A Material surface so nested ListTiles / InkWells get an ink host and
    // their splashes stay visible.
    Widget surface = Material(
      type: MaterialType.card,
      color: color ?? theme.cardTheme.color ?? scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (elevated) {
      surface = DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: Radii.card,
          boxShadow: Shadows.e1,
        ),
        child: surface,
      );
    }
    if (onTap != null) {
      surface = Pressable(onTap: onTap, child: surface);
    }
    return surface;
  }
}

/// Heading for a group of content, with an optional trailing action.
///
/// Two looks: a clean small title (forms, detail screens — the default) and an
/// [overline] caps label (dashboards, at-a-glance sections).
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    this.action,
    this.onAction,
    this.overline = false,
    this.padding = const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool overline;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = overline
        ? Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          )
        : Text(title, style: theme.textTheme.titleSmall);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: label),
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                textStyle: theme.textTheme.labelMedium,
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// The header on a profile screen: a gradient-ringed monogram, name, email,
/// and a role pill.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.email,
    this.role,
    super.key,
  });

  final String name;
  final String email;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleLarge),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (role != null) ...[
                  const SizedBox(height: Space.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: Radii.pill,
                    ),
                    child: Text(
                      role!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-line inline message strip — for form errors, notices, empty hints
/// inside a section. Filled container + icon + text, WCAG-safe pairs.
class InlineBanner extends StatelessWidget {
  const InlineBanner._({
    required this.message,
    required this.icon,
    required this.tone,
    super.key,
  });

  const InlineBanner.error(String message, {Key? key})
    : this._(
        message: message,
        icon: Icons.error_outline,
        tone: BannerTone.error,
        key: key,
      );

  const InlineBanner.info(String message, {Key? key})
    : this._(
        message: message,
        icon: Icons.info_outline,
        tone: BannerTone.neutral,
        key: key,
      );

  final String message;
  final IconData icon;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (bg, fg) = switch (tone) {
      BannerTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      BannerTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.cardSmall),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

enum BannerTone { neutral, error }

/// Direction of a metric's change, for [MetricTile].
enum TrendDirection { up, down, flat }

/// One number, its label, and an optional trend chip. The honest dashboard
/// primitive — real counts, never a fabricated composite score.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.value,
    required this.label,
    this.caption,
    this.trend,
    this.trendLabel,
    this.trendIsGood,
    this.icon,
    this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final String? caption;
  final TrendDirection? trend;
  final String? trendLabel;

  /// When set, colours the trend chip green (good) / amber (bad) instead of
  /// neutral. Leave null for a neutral chip.
  final bool? trendIsGood;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null)
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFeatures: kTabularFigures,
            ),
          ),
          if (trend != null && trendLabel != null) ...[
            const SizedBox(height: Space.xs),
            _TrendChip(
              direction: trend!,
              label: trendLabel!,
              isGood: trendIsGood,
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: Space.xxs),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({
    required this.direction,
    required this.label,
    this.isGood,
  });

  final TrendDirection direction;
  final String label;
  final bool? isGood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ramp = theme.clinicalStatus;
    final style = switch (isGood) {
      true => ramp.riskLow,
      false => ramp.riskMedium,
      null => ramp.labNormal,
    };
    final icon = switch (direction) {
      TrendDirection.up => Icons.trending_up,
      TrendDirection.down => Icons.trending_down,
      TrendDirection.flat => Icons.trending_flat,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: Radii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: style.onContainer),
          const SizedBox(width: Space.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: style.onContainer,
            ),
          ),
        ],
      ),
    );
  }
}
