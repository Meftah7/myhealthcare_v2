/// Home/Services building blocks driven by [PatientCatalog]: the paged quick
/// tools, the service-promotion carousel and the Quick Access grid.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../application/catalog_dispatcher.dart';
import '../domain/patient_catalog.dart';

/// A rounded icon tile with a short label under it.
class QuickAccessTile extends ConsumerWidget {
  const QuickAccessTile({required this.item, super.key});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final guest = ref.watch(currentUserProvider) == null;
    final locked = guest && item.access == CatalogAccess.signedIn;
    final title = item.title(t);
    final hint = !item.isAvailable
        ? t.paNotAvailableBadge
        : locked
        ? t.paSignInBadge
        : null;

    return Semantics(
      button: true,
      label: hint == null ? title : '$title, $hint',
      excludeSemantics: true,
      child: Material(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('catalog-${item.id}'),
          onTap: () => openCatalogItem(context, ref, item),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 104),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.xxs,
                vertical: Space.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconTile(
                        icon: item.icon,
                        accent: item.isAvailable
                            ? item.accent
                            : PatientAccent.neutral,
                        size: 44,
                      ),
                      if (locked)
                        PositionedDirectional(
                          end: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: palette.card,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  ReadableLabel(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                      height: 1.25,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A responsive grid of [QuickAccessTile]s: 2 columns on narrow phones or
/// large text, 3 on phones, 4 where there is room.
class CatalogGrid extends StatelessWidget {
  const CatalogGrid({required this.items, super.key});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final width = constraints.maxWidth;
        var columns = width >= 560 ? 4 : (width >= 300 ? 3 : 2);
        if (scale > 1.3) columns = columns > 2 ? columns - 1 : 2;
        if (scale > 1.7) columns = 2;
        // Never narrower than a readable tile; one column only when even two
        // would be too narrow (very large text on a small phone).
        final minTile = 96 * scale.clamp(1.0, 3.0);
        while (columns > 1 && width / columns < minTile) {
          columns--;
        }
        const gap = Space.sm;
        final tileWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: QuickAccessTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

/// Home "Quick Access": every relocated patient feature, grouped, directly
/// below the Services carousel.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    String groupTitle(QuickAccessGroup g) => switch (g) {
      QuickAccessGroup.records => t.paGroupRecords,
      QuickAccessGroup.care => t.paGroupCare,
      QuickAccessGroup.account => t.paGroupAccount,
    };
    return Column(
      key: const ValueKey('quick-access'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(t.paQuickAccess, subtitle: t.paQuickAccessSubtitle),
        for (final entry in PatientCatalog.quickAccess.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: Space.xs, bottom: Space.sm),
            child: Text(
              groupTitle(entry.key),
              style: theme.textTheme.titleSmall?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CatalogGrid(items: entry.value),
          const SizedBox(height: Space.sm),
        ],
      ],
    );
  }
}

/// Four quick tools per page with a small active-page indicator.
class QuickToolsPager extends StatefulWidget {
  const QuickToolsPager({required this.pages, super.key});

  final List<List<CatalogItem>> pages;

  @override
  State<QuickToolsPager> createState() => _QuickToolsPagerState();
}

class _QuickToolsPagerState extends State<QuickToolsPager> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final height = 120 * scale.clamp(1.0, 1.8);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final page in widget.pages)
                Row(
                  children: [
                    for (final (i, item) in page.indexed) ...[
                      if (i > 0) const SizedBox(width: Space.xs),
                      Expanded(child: _ToolTile(item: item)),
                    ],
                  ],
                ),
            ],
          ),
        ),
        if (widget.pages.length > 1) ...[
          const SizedBox(height: Space.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.pages.length; i++)
                Semantics(
                  label: '${i + 1} / ${widget.pages.length}',
                  selected: i == _page,
                  button: true,
                  child: GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: Motion.reduced(context)
                          ? Duration.zero
                          : Motion.medium,
                      curve: Motion.standard,
                    ),
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? palette.action : palette.divider,
                        borderRadius: Radii.pill,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ToolTile extends ConsumerWidget {
  const _ToolTile({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return Semantics(
      button: true,
      label: item.isAvailable
          ? item.title(t)
          : '${item.title(t)}, ${t.paNotAvailableBadge}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('tool-${item.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => openCatalogItem(context, ref, item),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTile(
              icon: item.icon,
              accent: item.isAvailable ? item.accent : PatientAccent.neutral,
              size: 56,
            ),
            const SizedBox(height: Space.xs),
            ReadableLabel(
              item.title(t),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: item.isAvailable ? palette.text : palette.textMuted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A large rounded service card: artwork band, small icon, title, two-line
/// description and an action.
class ServicePromotionCard extends ConsumerWidget {
  const ServicePromotionCard({required this.item, this.width, super.key});

  final CatalogItem item;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final (fg, bg) = item.accent.colors(palette);
    return SizedBox(
      width: width,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        onTap: () => openCatalogItem(context, ref, item),
        semanticLabel: item.title(t),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original vector artwork: a soft gradient band with the
            // service glyph — no screenshot crops or third-party media.
            Container(
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [bg, Color.alphaBlend(fg.withValues(alpha: .18), bg)],
                ),
              ),
              child: Stack(
                children: [
                  PositionedDirectional(
                    end: -12,
                    bottom: -18,
                    child: Icon(
                      item.icon,
                      size: 120,
                      color: fg.withValues(alpha: .16),
                    ),
                  ),
                  PositionedDirectional(
                    start: Space.md,
                    top: Space.md,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: fg, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!(t),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.xs),
                  Row(
                    children: [
                      Text(
                        item.isAvailable
                            ? t.paOpenAction
                            : t.paNotAvailableBadge,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: item.isAvailable
                              ? palette.link
                              : palette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back
                            : Icons.arrow_forward,
                        size: 16,
                        color: palette.link,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One horizontal carousel of [ServicePromotionCard]s — never auto-moving;
/// the next card peeks in so it reads as swipeable. Every card is also a
/// normal focusable button, so it works without swiping.
class ServiceCarousel extends StatelessWidget {
  const ServiceCarousel({required this.items, super.key});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * .78).clamp(220.0, 340.0);
        return SizedBox(
          height: 250 * scale.clamp(1.0, 1.6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
            itemBuilder: (_, i) =>
                ServicePromotionCard(item: items[i], width: cardWidth),
          ),
        );
      },
    );
  }
}
