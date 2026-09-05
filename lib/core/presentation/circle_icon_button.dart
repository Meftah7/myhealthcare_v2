/// A circular icon-only button for a top-bar action group (redesign v2
/// patient dashboard: notifications + theme toggle, sized to match).
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// Surface-filled, hairline-bordered circle around an icon — same look for
/// every top-bar icon action, so the theme toggle and notifications button
/// read as one family.
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

  static const double _diameter = 38;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xxs / 2),
      child: SizedBox(
        width: _diameter,
        height: _diameter,
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: tooltip,
            icon: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
