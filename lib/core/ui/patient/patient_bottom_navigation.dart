/// The patient bottom bar: Home | Weather | Appointments | News | Services,
/// with Appointments emphasised as a rounded blue centre tile.
///
/// The selected destination always gets its own indicator (a short bar above
/// the icon and a bold label) — including the centre tile, which is blue
/// whether or not it is selected.
library;

import 'package:flutter/material.dart';

import '../../../app/shell/app_shell.dart';
import '../../../app/theme/theme.dart';
import 'patient_components.dart';

class PatientBottomNavigation extends StatelessWidget {
  const PatientBottomNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.centerIndex = 2,
    super.key,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Which destination renders as the blue centre tile.
  final int centerIndex;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Labels are never shrunk: when five full labels cannot fit (large
          // text, narrow phone) the bar becomes the shared destination menu.
          final scaler = MediaQuery.textScalerOf(context);
          final style = Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          );
          final slot = constraints.maxWidth / destinations.length - 2;
          var fits = scaler.scale(11) / 11 <= 1.5;
          double measure(String text, TextStyle? s) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: s),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout();
            final w = painter.width;
            painter.dispose();
            return w;
          }

          for (final d in destinations) {
            fits = fits && measure(d.label, style) <= slot;
            // A scope badge must fit whole too (pill padding included).
            if (d.badge != null) {
              fits =
                  fits &&
                  measure(d.badge!, NavScopeBadge.styleOf(context)) + 14 <=
                      slot;
            }
          }
          if (!fits) {
            return CompactNavigation(
              destinations: destinations,
              currentIndex: selectedIndex,
              onSelected: onSelected,
            );
          }
          return SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 78),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, d) in destinations.indexed)
                      Expanded(
                        child: _NavItem(
                          destination: d,
                          selected: i == selectedIndex,
                          center: i == centerIndex,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.center,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final bool center;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final fg = selected ? palette.link : palette.textMuted;
    final icon = selected ? destination.selectedIcon : destination.icon;

    final Widget glyph = center
        ? AnimatedContainer(
            duration: Motion.fast,
            width: 50,
            height: 40,
            decoration: BoxDecoration(
              color: palette.action,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? palette.onSoftAccent : Colors.transparent,
                width: 2,
              ),
              boxShadow: Shadows.glow(palette.action),
            ),
            child: Icon(icon, color: palette.onAction, size: 22),
          )
        : SizedBox(height: 40, child: Icon(icon, color: fg, size: 24));

    return Semantics(
      selected: selected,
      button: true,
      label: destination.semanticLabel,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Selection indicator — present on every tab, centre included.
            AnimatedContainer(
              duration: Motion.fast,
              width: selected ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: palette.link,
                borderRadius: Radii.pill,
              ),
            ),
            glyph,
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: center && !selected ? palette.text : fg,
                ),
              ),
            ),
            if (destination.badge != null) ...[
              const SizedBox(height: 2),
              NavScopeBadge(destination.badge!),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
