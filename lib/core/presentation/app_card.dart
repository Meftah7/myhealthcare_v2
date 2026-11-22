/// Shared clinical-bento surface components (DESIGN.md §5.2, redesign v5).
///
/// [AppCard] is the one card the whole app uses: quiet, rounded, with optional
/// extra lift and press feedback. [MetricTile] is the honest
/// "one number + label + trend" used on every dashboard.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../utils/format.dart';
import 'readable_label.dart';

/// One size for every "this row opens something" chevron. Picked once here
/// because the app previously drew them at 17, 18 and 24 on rows that sit a few
/// pixels apart, which reads as sloppiness long before anyone can name it.
const double kTrailingChevronSize = 20;

/// The app's single card. Every card receives the low bento shadow; pass
/// [elevated] for the stronger raised state and [onTap] for press feedback.
///
/// The card colour comes one step above the page (white on the tinted light
/// page, lifted slate in dark), so the hairline is a definition line rather
/// than the only thing separating card from background.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Space.md),
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

    final seam = borderColor ?? Clay.seam(scheme);
    final fill =
        color ??
        (theme.brightness == Brightness.light
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerHigh);

    // A solid plane and one low, vertical shadow make neighbouring cards read
    // as a composed grid. Floating navigation keeps the stronger paired clay
    // light; content cards deliberately do not compete with it.
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: Radii.cardOf(context),
        border: Border.all(color: seam),
        boxShadow: Shadows.bento(scheme, raised: elevated),
      ),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: Radii.cardOf(context)),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap != null) {
      surface = Pressable(onTap: onTap, child: surface);
    }
    return surface;
  }
}

/// A labelled dashboard module. The title lives inside the surface so the
/// heading and its data remain one visual object when bento rows re-flow.
/// The small icon tab is the shared identifying detail across patient, staff,
/// and admin dashboards.
class BentoPanel extends StatelessWidget {
  const BentoPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
    this.onAction,
    this.color,
    this.contentPadding = const EdgeInsets.fromLTRB(
      Space.md,
      Space.xs,
      Space.md,
      Space.md,
    ),
    this.elevated = false,
    super.key,
  }) : assert(
         (action == null && onAction == null) ||
             (action != null && onAction != null),
       );

  final String title;
  final IconData icon;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;
  final Color? color;
  final EdgeInsetsGeometry contentPadding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget actionButton() => TextButton(
      onPressed: onAction,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        textStyle: theme.textTheme.labelMedium,
      ),
      child: Text(action!),
    );

    return AppCard(
      color: color,
      elevated: elevated,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.xs, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final actionBelow =
                    action != null && constraints.maxWidth < 360;
                final label = Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: Radii.chip,
                      ),
                      child: Icon(
                        icon,
                        size: 17,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      // Same treatment as SectionHeader: sentence case, and
                      // never clipped at enlarged text sizes.
                      child: ReadableLabel(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (action != null && !actionBelow) actionButton(),
                  ],
                );
                if (!actionBelow) return label;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: actionButton(),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(padding: contentPadding, child: child),
        ],
      ),
    );
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
    final surface = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 176),
      child: DecoratedBox(
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
            const Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(painter: _PulseTracePainter()),
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
                        ReadableLabel(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ReadableLabel(
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
      ),
    );

    // Shadow outside the clip, gradient inside it — a ClipRRect wrapping the
    // shadow would eat the bloom.
    final lifted = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: Radii.card,
        boxShadow: [
          ...Shadows.bento(theme.colorScheme, raised: true),
          ...Shadows.glow(AppColors.smartBlue),
        ],
      ),
      child: ClipRRect(borderRadius: Radii.card, child: surface),
    );
    return onTap == null ? lifted : Pressable(onTap: onTap, child: lifted);
  }
}

/// A restrained ECG trace gives the single saturated tile a healthcare-native
/// signature without adding another colour or an ambient animation.
class _PulseTracePainter extends CustomPainter {
  const _PulseTracePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final y = size.height * 0.72;
    final path = Path()
      ..moveTo(0, y)
      ..lineTo(size.width * 0.48, y)
      ..lineTo(size.width * 0.53, y)
      ..lineTo(size.width * 0.56, y - size.height * 0.08)
      ..lineTo(size.width * 0.59, y + size.height * 0.13)
      ..lineTo(size.width * 0.63, y - size.height * 0.24)
      ..lineTo(size.width * 0.67, y + size.height * 0.06)
      ..lineTo(size.width * 0.70, y)
      ..lineTo(size.width, y);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PulseTracePainter oldDelegate) => false;
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
    final label = ReadableLabel(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontSize: overline ? 16 : 15,
        color: theme.colorScheme.onSurface,
      ),
    );
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
                minimumSize: const Size(0, 48),
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
    this.embedded = false,
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

  /// Uses a quiet inset plane instead of another full card. Dashboard bento
  /// panels use this for their internal action grids.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dense = subtitle == null;

    final padding = EdgeInsets.symmetric(
      horizontal: dense ? Space.sm : Space.md,
      vertical: dense ? Space.sm : Space.md,
    );
    final content = Row(
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
              ReadableLabel(title, style: theme.textTheme.titleSmall),
              if (subtitle != null)
                ReadableLabel(
                  subtitle!,
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
    );

    if (embedded) {
      return Pressable(
        onTap: onTap,
        borderRadius: Radii.cardSmall,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: Radii.cardSmall,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(padding: padding, child: content),
        ),
      );
    }

    return AppCard(onTap: onTap, padding: padding, child: content);
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

    final card = Pressable(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled ? scheme.primary : scheme.surfaceContainerLowest,
          borderRadius: Radii.cardOf(context),
          border: Border.all(
            color: filled
                ? scheme.primary.withValues(alpha: 0.82)
                : Clay.seam(scheme),
          ),
          boxShadow: Shadows.bento(scheme),
        ),
        child: Material(
          type: MaterialType.transparency,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: Radii.cardOf(context)),
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
      ),
    );
    return card;
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
    this.elevated = false,
    this.embedded = false,
    super.key,
  });

  final List<Widget> children;
  final IconData? emptyIcon;
  final String? emptyText;
  final bool elevated;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (children.isEmpty) {
      final empty = Row(
        children: [
          Icon(
            emptyIcon ?? Icons.check_circle_outline,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              emptyText ?? AppLocalizations.of(context)!.nothingHere,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
      if (embedded) {
        return Padding(padding: const EdgeInsets.all(Space.sm), child: empty);
      }
      return AppCard(padding: const EdgeInsets.all(Space.md), child: empty);
    }
    final list = Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: Space.md),
          children[i],
        ],
      ],
    );
    if (embedded) return list;
    return AppCard(padding: EdgeInsets.zero, elevated: elevated, child: list);
  }
}

/// A stored avatar is either a local file path (native platforms) or a
/// base64 data URI (web, which has no file system to point a path at).
ImageProvider<Object>? _avatarImage(String? avatarPath) {
  if (avatarPath == null) return null;
  try {
    if (avatarPath.startsWith('data:')) {
      final separator = avatarPath.indexOf(',');
      if (separator < 0) return null;
      return MemoryImage(base64Decode(avatarPath.substring(separator + 1)));
    }
    return FileImage(File(avatarPath));
  } on FormatException {
    return null;
  }
}

/// Profile identity with a photo or monogram and an accessible edit action.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.email,
    this.role,
    this.phone,
    this.avatarPath,
    this.avatarSize = 56,
    this.elevated = false,
    this.onEditAvatar,
    super.key,
  });

  final String name;
  final String email;
  final String? role;
  final String? phone;

  /// Local file path to the account's photo, or null for the generated
  /// monogram.
  final String? avatarPath;
  final double avatarSize;
  final bool elevated;

  /// When set, a small tappable badge overlaps the avatar's bottom-right
  /// corner — the profile screen's "edit" affordance on the identity photo.
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final image = _avatarImage(avatarPath);
    final monogram = Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: theme.textTheme.titleLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
    return AppCard(
      elevated: elevated,
      child: Flex(
        direction: MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3
            ? Axis.vertical
            : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: avatarSize + (onEditAvatar == null ? 0 : 12),
            height: avatarSize + (onEditAvatar == null ? 0 : 12),
            child: Stack(
              children: [
                ClipOval(
                  child: ColoredBox(
                    color: scheme.primaryContainer,
                    child: SizedBox(
                      width: avatarSize,
                      height: avatarSize,
                      child: image == null
                          ? monogram
                          : Image(
                              image: image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => monogram,
                            ),
                    ),
                  ),
                ),
                if (onEditAvatar != null)
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: IconButton.filledTonal(
                      tooltip: AppLocalizations.of(context)!.profilePhotoTitle,
                      onPressed: onEditAvatar,
                      icon: const Icon(Icons.photo_camera_outlined, size: 20),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Space.md, height: Space.sm),
          Flexible(
            flex: MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3 ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReadableLabel(name, style: theme.textTheme.titleLarge),
                if (role != null) ...[
                  const SizedBox(height: Space.xxs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: Radii.pill,
                    ),
                    child: ReadableLabel(
                      role!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Space.xxs),
                ReadableLabel(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    return Semantics(
      container: true,
      liveRegion: tone == BannerTone.error,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(color: bg, borderRadius: Radii.cardSmall),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: Space.xs),
              Expanded(
                child: ReadableLabel(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small caption above a [PillSegmented] control — e.g. "Language", "Theme".
class PillLabel extends StatelessWidget {
  const PillLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A rounded pill-track segmented control: every option in one row inside a
/// filled track, the selected one a solid pill, everything else transparent.
/// The house look for a small mutually-exclusive choice (theme mode,
/// language) — in place of Material's boxier [SegmentedButton].
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  final List<(T value, String label)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Pinned screen filters use a menu when enlarged labels cannot share a row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget option((T, String) item) => Semantics(
      button: true,
      selected: item.$1 == selected,
      child: Pressable(
        onTap: () => onChanged(item.$1),
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.standard,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: item.$1 == selected
                ? scheme.primary
                : scheme.surfaceContainerLowest,
            borderRadius: Radii.chip,
            border: Border.all(
              color: item.$1 == selected
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          ),
          alignment: Alignment.center,
          child: ReadableLabel(
            item.$2,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: item.$1 == selected
                  ? scheme.onPrimary
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
        var widest = 0.0;
        for (final item in segments) {
          final painter = TextPainter(
            text: TextSpan(text: item.$2, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          if (painter.width > widest) widest = painter.width;
          painter.dispose();
        }
        final needsStack =
            (widest + Space.sm * 2) * segments.length +
                Space.xs * (segments.length - 1) >
            constraints.maxWidth;
        if (needsStack && compact) {
          return DropdownButtonFormField<T>(
            key: ValueKey(selected),
            initialValue: selected,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            items: [
              for (final item in segments)
                DropdownMenuItem(
                  value: item.$1,
                  child: ReadableLabel(item.$2, style: style),
                ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          );
        }
        if (needsStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, item) in segments.indexed) ...[
                if (index > 0) const SizedBox(height: Space.xs),
                option(item),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final (index, item) in segments.indexed) ...[
              if (index > 0) const SizedBox(width: Space.xs),
              Expanded(child: option(item)),
            ],
          ],
        );
      },
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
    this.embedded = false,
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
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ReadableLabel(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
                localizeDigits(value),
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
    );
    if (embedded) {
      final padded = Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: content,
      );
      return onTap == null ? padded : Pressable(onTap: onTap, child: padded);
    }
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md),
      child: content,
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
