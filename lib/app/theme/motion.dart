/// Motion tokens for MyHealth Care (redesign v2, DESIGN.md §7).
///
/// Motion here is **functional, not decorative**: it explains a change of
/// state, points where things came from and went, and gives instant feedback
/// on touch. Everything is short, eased-out, and interruptible, and every
/// helper honours the OS "reduce motion" setting.
library;

import 'package:flutter/material.dart';

abstract final class Motion {
  /// Press feedback, hover, tiny state flips.
  static const Duration fast = Duration(milliseconds: 120);

  /// The default: cards settling, switchers, list items, sheet content.
  static const Duration medium = Duration(milliseconds: 220);

  /// Page-level transitions, larger reveals.
  static const Duration slow = Duration(milliseconds: 320);

  /// Decelerate into rest — the house curve for entrances and settles.
  static const Curve standard = Curves.easeOutCubic;

  /// A touch more spring for momentum-driven moves (a flicked sheet, a FAB).
  static const Curve emphasized = Curves.easeOutBack;

  /// True when the OS asks for reduced motion — collapse slides to fades.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Scale a pressed surface settles to (§7). Subtle — you feel it, you don't
  /// watch it.
  static const double pressedScale = 0.97;
}

/// A tap target that dips slightly on press — the single most important piece
/// of "this feels alive" (apple-design §1: feedback on pointer-down, instant).
/// Wrap cards, tiles and custom buttons that need it. Falls back to a plain
/// [GestureDetector] with no scale when reduce-motion is on.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = Motion.pressedScale,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final reduce = Motion.reduced(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: enabled && !reduce ? (_) => _set(true) : null,
      onTapUp: enabled && !reduce ? (_) => _set(false) : null,
      onTapCancel: enabled && !reduce ? () => _set(false) : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.standard,
        child: widget.child,
      ),
    );
  }
}

/// Page transitions: a quiet fade-through (shared-axis Z). No slide, no
/// platform back-swipe theatrics — this app is used on desktop and web too.
class AppPageTransitions extends PageTransitionsBuilder {
  const AppPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.standard,
      reverseCurve: Motion.standard.flipped,
    );
    if (Motion.reduced(context)) {
      return FadeTransition(opacity: curved, child: child);
    }
    return FadeTransition(
      opacity: curved,
      child: FractionalTranslation(
        translation: Offset.lerp(
          const Offset(0, 0.012),
          Offset.zero,
          curved.value,
        )!,
        child: child,
      ),
    );
  }
}
