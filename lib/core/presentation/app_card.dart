/// Shared surface components (DESIGN.md §5.2, redesign v2).
///
/// [AppCard] is the one card the whole app uses: flat, hairline-bordered, an
/// optional soft lift, optional press feedback. [MetricTile] is the honest
/// "one number + label + trend" used on every dashboard.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// One size for every "this row opens something" chevron. Picked once here
/// because the app previously drew them at 17, 18 and 24 on rows that sit a few
/// pixels apart, which reads as sloppiness long before anyone can name it.
const double kTrailingChevronSize = 20;

/// The app's single card. Flat fill + hairline border by default; pass
/// [elevated] for [Shadows.e1]; pass [onTap] for press feedback.
///
/// The card colour comes one step above the page (white on the tinted light
/// page, lifted slate in dark), so the hairline is a definition line rather
/// than the only thing separating card from background.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.elevated = false,
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? color;

  /// Overrides the hairline — e.g. a tinted card that wants its own accent
  /// edge instead of the neutral one.
  final Color? borderColor;

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
        side: BorderSide(color: borderColor ?? scheme.outlineVariant),
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

/// The one saturated surface a screen is allowed (DESIGN.md §1): a brand
/// gradient card carrying an icon, a title, a supporting line and a chevron.
///
/// Everything on it is white-on-gradient, so it needs no colour-scheme roles —
/// which also means it looks identical in light and dark, deliberately: it is
/// the screen's anchor, not part of the neutral field.
class GradientHeroCard extends StatelessWidget {
  const GradientHeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: Radii.card,
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          // A soft highlight bloom in the top-right corner keeps the gradient
          // from reading as a flat two-stop fill.
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: Radii.cardSmall,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.xs),
                trailing ??
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      // The same chevron every other tappable row uses — an
                      // arrow here would make the hero look like a different
                      // kind of control than the cards under it.
                      child: const Icon(
                        Icons.chevron_right,
                        size: kTrailingChevronSize,
                        color: Colors.white,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );

    // Shadow outside the clip, gradient inside it — a ClipRRect wrapping the
    // shadow would eat the bloom.
    final lifted = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: Radii.card,
        boxShadow: Shadows.glow(AppColors.brandViolet),
      ),
      child: ClipRRect(borderRadius: Radii.card, child: surface),
    );
    return onTap == null ? lifted : Pressable(onTap: onTap, child: lifted);
  }
}

/// Heading for a group of content, with an optional trailing action.
///
/// Two looks: a clean small title (forms, detail screens — the default) and an
/// [overline] caps label (dashboards, at-a-glance sections).
///
/// The leading gap is **built in** (`Space.lg` above, `Space.xs` below). Callers
/// used to add their own `SizedBox(height: Space.lg)` before every header on top
/// of this padding, which is why the dashboards' sections sat 40dp apart
/// instead of 24. Pass [first] for the header that opens a screen, where there
/// is nothing above to separate from.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    this.action,
    this.onAction,
    this.overline = false,
    this.first = false,
    this.padding,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool overline;

  /// Drops the top gap — for the first header on a screen.
  final bool first;

  /// Overrides the built-in gap entirely. Rarely needed.
  final EdgeInsetsGeometry? padding;

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
      padding:
          padding ??
          EdgeInsets.only(top: first ? 0 : Space.lg, bottom: Space.xs),
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

/// A tappable row that opens something else — the shape behind the patient
/// quick actions, the profile hub rows, the "urgent or normal?" sheet choices
/// and the staff/admin shortcut tiles, all of which were separate private
/// widgets drawing the same thing at four different icon sizes.
///
/// [subtitle] is optional: with it the row is a two-line list item, without it
/// a compact single-line shortcut.
class NavRow extends StatelessWidget {
  const NavRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tinted = false,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Seats the icon in a filled primary medallion instead of leaving it a bare
  /// glyph — for grids of shortcuts, where the medallion is what makes the tile
  /// read as an object you can press.
  final bool tinted;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dense = subtitle == null;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Space.sm : Space.md,
        vertical: dense ? Space.sm : Space.md,
      ),
      child: Row(
        children: [
          if (tinted)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: Radii.chip,
              ),
              child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
            )
          else
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: dense ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          trailing ??
              Icon(
                Icons.chevron_right,
                size: kTrailingChevronSize,
                color: scheme.onSurfaceVariant,
              ),
        ],
      ),
    );
  }
}

/// A big two-up entry button — an icon over a title over a supporting line,
/// either filled (the primary way in) or bordered (the alternative).
///
/// Used for the Appointments screen's "Book now" / "Schedule" pair and
/// anywhere else a screen opens with a choice between two routes.
class EntryCard extends StatelessWidget {
  const EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filled = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = filled ? scheme.onPrimary : scheme.onSurface;

    return Pressable(
      onTap: onTap,
      child: Material(
        color: filled ? scheme.primary : scheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(
            // The filled card carries its own weight; the bordered one gets the
            // same hairline as every other surface, at full strength.
            color: filled ? Colors.transparent : scheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg),
              const SizedBox(height: Space.sm),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(color: fg),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: filled
                      ? scheme.onPrimary.withValues(alpha: 0.85)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that holds a list of rows separated by hairlines, with a friendly
/// single-row empty state when there is nothing to show.
///
/// The dashboards each had their own private copy of this; it is the shape of
/// every "today's queue / open flags / recent activity" block in the app.
class ListCard extends StatelessWidget {
  const ListCard({
    required this.children,
    this.emptyIcon,
    this.emptyText,
    super.key,
  });

  final List<Widget> children;
  final IconData? emptyIcon;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (children.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            Icon(
              emptyIcon ?? Icons.check_circle_outline,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                emptyText ?? 'Nothing here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: Space.md),
            children[i],
          ],
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
      BannerTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurface),
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
              if (icon != null) ...[
                const SizedBox(width: Space.xxs),
                // A seated chip, not a floating glyph — it keeps the tile's
                // top row weighted at both ends.
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: Radii.chip,
                  ),
                  child: Icon(icon, size: 15, color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: Space.xs),
          // A plain count rolls up to its figure; anything else (a date, a
          // percentage, an em dash) is written straight out. headlineSmall, not
          // Medium: these tiles sit three-up on a 360dp phone.
          Builder(
            builder: (context) {
              final style = theme.textTheme.headlineSmall;
              final number = int.tryParse(value);
              if (number == null) {
                return Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style?.copyWith(fontFeatures: kTabularFigures),
                );
              }
              return AppCountUp(number, style: style);
            },
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
  const _TrendChip({required this.direction, required this.label, this.isGood});

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
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
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
