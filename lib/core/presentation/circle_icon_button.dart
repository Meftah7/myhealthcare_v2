/// A circular icon-only button for a top-bar action group (redesign v3:
/// notifications + theme toggle + profile, sized to match).
library;

import 'package:flutter/material.dart';

/// Surface-filled, hairline-bordered circle around an icon — same look for
/// every top-bar icon action, so the toggle, notifications and profile buttons
/// read as one family.
///
/// The circle draws at [_diameter], but `MaterialTapTargetSize.padded` grows
/// the hit area to the 48dp minimum (DESIGN.md §8) without inflating the mark.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  static const double _diameter = 40;

  /// The 48dp minimum tap target (DESIGN.md §8) the circle is centred in.
  static const double _target = 48;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The circle is the *icon* of a 48dp button rather than the button itself,
    // which is what keeps the drawn mark at 40dp while the tappable — and the
    // semantics node the a11y guidelines measure — stays at 48dp.
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _target,
        height: _target,
      ),
      icon: Container(
        width: _diameter,
        height: _diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
