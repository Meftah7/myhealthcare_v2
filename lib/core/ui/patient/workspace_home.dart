/// Home-dashboard building blocks shared by the staff and admin workspaces,
/// in the patient app's visual language: an action feature card, four compact
/// shortcut tiles and rounded workspace cards. Colours come from the patient
/// palette; nothing here hardcodes a separate enterprise style.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../presentation/readable_label.dart';
import 'patient_components.dart';

/// The one most useful next action, using the patient's action colour.
class NavyFeatureCard extends StatelessWidget {
  const NavyFeatureCard({
    required this.title,
    required this.body,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.overline,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? overline;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final fg = palette.onAction;
    final muted = fg;
    return Semantics(
      container: true,
      child: Material(
        color: palette.action,
        shape: const RoundedRectangleBorder(borderRadius: kPatientCardRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: LayoutBuilder(
            builder: (context, c) {
              final iconBox = ExcludeSemantics(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: fg, size: 28),
                ),
              );
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overline != null)
                    ReadableLabel(
                      overline!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                  ReadableLabel(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  ReadableLabel(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: Space.md),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.card,
                        foregroundColor: palette.link,
                        minimumSize: const Size(48, 44),
                      ),
                      onPressed: onAction,
                      child: ReadableLabel(actionLabel!),
                    ),
                  ],
                ],
              );
              // With large text on a narrow screen the icon moves above the
              // text, so the words keep the full width.
              final narrow =
                  c.maxWidth < MediaQuery.textScalerOf(context).scale(320);
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconBox,
                    const SizedBox(height: Space.sm),
                    text,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: text),
                  const SizedBox(width: Space.md),
                  iconBox,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ShortcutItem {
  const ShortcutItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// A real count (e.g. unread); `null` hides the badge.
  final int? badge;
}

/// Four compact shortcut tiles; two per row on very narrow screens.
class ShortcutGrid extends StatelessWidget {
  const ShortcutGrid({required this.items, super.key});

  final List<ShortcutItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Fewer columns as text grows: a tile needs ~84 dp at 1x text.
        final fit = (c.maxWidth / MediaQuery.textScalerOf(context).scale(84))
            .floor();
        final columns = fit >= 4
            ? 4
            : fit >= 2
            ? 2
            : 1;
        final width = (c.maxWidth - Space.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _ShortcutTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.item});

  final ShortcutItem item;

  @override
  Widget build(BuildContext context) {
    final badge = item.badge;
    return SurfaceCard(
      onTap: item.onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xs,
        vertical: Space.md,
      ),
      semanticLabel: badge == null || badge == 0
          ? item.label
          : '${item.label}, $badge',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge != null && badge > 0,
              label: Text('${badge ?? ''}'),
              child: IconTile(icon: item.icon),
            ),
            const SizedBox(height: Space.xs),
            ReadableLabel(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceItem {
  const WorkspaceItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.futureWorkLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  /// Shown as a visible badge when the item is outside current scope.
  final String? futureWorkLabel;
}

/// Rounded workspace cards: 1, 2 or 3 per row by available width.
class WorkspaceCardGrid extends StatelessWidget {
  const WorkspaceCardGrid({required this.items, super.key});

  final List<WorkspaceItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final unit = MediaQuery.textScalerOf(context).scale(290);
        final columns = (c.maxWidth / unit).floor().clamp(1, 3);
        final width = (c.maxWidth - Space.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: SurfaceCard(
                  onTap: item.onTap,
                  semanticLabel: item.title,
                  child: ExcludeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconTile(icon: item.icon),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReadableLabel(
                                item.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              ReadableLabel(
                                item.description,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: PatientPalette.of(
                                        context,
                                      ).textMuted,
                                    ),
                              ),
                              if (item.futureWorkLabel != null) ...[
                                const SizedBox(height: Space.xs),
                                FutureWorkBadge(label: item.futureWorkLabel!),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
