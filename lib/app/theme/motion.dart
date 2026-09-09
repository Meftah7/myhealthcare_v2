/// Motion tokens and helpers for MyHealth Care (redesign v2, DESIGN.md §7).
///
/// Motion here is **functional, not decorative**: it explains a change of
/// state, points where things came from and went, and gives instant feedback
/// on touch. Everything is short, eased-out, and interruptible, and every
/// helper honours the OS "reduce motion" setting — slides and scales collapse
/// to an opacity cross-fade, or to nothing at all where a fade would only
/// delay the content.
///
/// The helpers deliberately avoid `Timer`s and hand-rolled
/// [AnimationController]s: they are built on [TweenAnimationBuilder] and
/// [AnimatedSwitcher], which own their controllers and dispose them with the
/// element. That keeps widget tests free of pending-timer failures when a tree
/// is torn down mid-animation.
library;

import 'package:flutter/material.dart';

abstract final class Motion {
  /// Press feedback, hover, tiny state flips.
  static const Duration fast = Duration(milliseconds: 120);

  /// The default: cards settling, switchers, list items, sheet content.
  static const Duration medium = Duration(milliseconds: 220);

  /// Page-level transitions, larger reveals.
  static const Duration slow = Duration(milliseconds: 320);

  /// Numeric roll-ups — long enough to read as counting, short enough that the
  /// figure is settled before the eye asks for it.
  static const Duration count = Duration(milliseconds: 520);

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

  /// Distance an entering element rises through (§7).
  static const double riseDistance = 8;

  /// Delay added per sibling in a staggered entrance.
  static const Duration staggerStep = Duration(milliseconds: 40);

  /// Stagger is capped at this index so a long list doesn't cascade for
  /// seconds — everything past it enters with the same delay (§7).
  static const int staggerCap = 6;
}

/// A tap target that dips slightly on press — the single most important piece
/// of "this feels alive" (apple-design §1: feedback on pointer-down, instant).
/// Wrap cards, tiles and custom buttons that need it. Falls back to a plain
/// [GestureDetector] with no scale when reduce-motion is on.
///
/// On desktop and web it also carries the pointer cursor and a whisper of
/// hover lift, so a card reads as pressable before it is pressed.
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
  bool _hover = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  void _setHover(bool v) {
    if (_hover != v) setState(() => _hover = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final reduce = Motion.reduced(context);

    // Hover barely lifts (1.005) where the press clearly dips — enough for a
    // mouse to find the target without the page breathing as the cursor moves.
    final scale = !enabled || reduce
        ? 1.0
        : _down
        ? widget.scale
        : _hover
        ? 1.005
        : 1.0;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => _setHover(true) : null,
      onExit: enabled ? (_) => _setHover(false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: enabled && !reduce ? (_) => _setDown(true) : null,
        onTapUp: enabled && !reduce ? (_) => _setDown(false) : null,
        onTapCancel: enabled && !reduce ? () => _setDown(false) : null,
        child: AnimatedScale(
          scale: scale,
          duration: Motion.fast,
          curve: Motion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fades and rises its child into place once, on first build.
///
/// Give siblings an ascending [index] to stagger them — the delay is
/// [Motion.staggerStep] per index, capped at [Motion.staggerCap] so a long
/// list never cascades. Under reduce-motion the child is returned untouched
/// (a delayed fade only postpones content the user asked to see sooner).
///
/// One [TweenAnimationBuilder] per child, so nothing needs disposing and the
/// animation cannot outlive the element.
class AppEntrance extends StatelessWidget {
  const AppEntrance({
    required this.child,
    this.index = 0,
    this.rise = Motion.riseDistance,
    this.duration = Motion.medium,
    super.key,
  });

  final Widget child;

  /// Position among staggered siblings. 0 starts immediately.
  final int index;

  /// Distance the child travels up into place. 0 for a pure fade.
  final double rise;

  /// How long the move itself takes, before the stagger delay is added.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;

    final steps = index.clamp(0, Motion.staggerCap);
    final delay = Motion.staggerStep * steps;
    final total = duration + delay;
    // The delay is expressed as a flat leading segment of one tween rather
    // than a Timer, so there is no pending callback if the tree goes away.
    final start = delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Motion.standard),
      builder: (context, t, child) {
        // Opacity short-circuits its layer at 1.0, so a settled entrance costs
        // nothing to keep in the tree.
        return Opacity(
          opacity: t,
          child: rise == 0
              ? child
              : Transform.translate(
                  offset: Offset(0, rise * (1 - t)),
                  child: child,
                ),
        );
      },
      child: child,
    );
  }
}

/// Cross-fades between states of the same region — loading → data, empty →
/// list, one filter's results → another's.
///
/// Children must carry distinct [Key]s for the switch to be detected; a
/// [ValueKey] on whatever identifies the state is usually enough. The incoming
/// and outgoing children are stacked **top-aligned**, not centred like a bare
/// [AnimatedSwitcher], so a taller replacement grows downwards instead of
/// shunting the whole region up as it arrives.
class AppReveal extends StatelessWidget {
  const AppReveal({
    required this.child,
    this.duration = Motion.medium,
    this.alignment = Alignment.topCenter,
    this.animateSize = true,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Alignment alignment;

  /// Also animate the height change between states. Off for regions inside a
  /// scroll view that already have a fixed extent.
  final bool animateSize;

  @override
  Widget build(BuildContext context) {
    final reduce = Motion.reduced(context);
    final switcher = AnimatedSwitcher(
      duration: reduce ? Duration.zero : duration,
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      child: child,
    );
    if (!animateSize || reduce) return switcher;
    return AnimatedSize(
      duration: duration,
      curve: Motion.standard,
      alignment: alignment,
      child: switcher,
    );
  }
}

/// A number that rolls up to its value instead of snapping to it.
///
/// Always renders with tabular figures (DESIGN.md §1 rule 4) so the width
/// doesn't jitter as the digits change. Under reduce-motion the final value is
/// painted immediately.
///
/// [value] may be fractional; [fractionDigits] controls how it is written.
class AppCountUp extends StatelessWidget {
  const AppCountUp(
    this.value, {
    this.style,
    this.fractionDigits = 0,
    this.prefix = '',
    this.suffix = '',
    this.textAlign,
    this.semanticsLabel,
    super.key,
  });

  final num value;
  final TextStyle? style;
  final int fractionDigits;
  final String prefix;
  final String suffix;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  String _format(num v) => '$prefix${v.toStringAsFixed(fractionDigits)}$suffix';

  @override
  Widget build(BuildContext context) {
    final resolved = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (Motion.reduced(context)) {
      return Text(
        _format(value),
        style: resolved,
        textAlign: textAlign,
        semanticsLabel: semanticsLabel,
      );
    }

    return TweenAnimationBuilder<double>(
      // A changed `end` re-runs the tween from wherever it currently sits, so
      // a live-updating figure eases to its new value rather than restarting.
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: Motion.count,
      curve: Motion.standard,
      builder: (context, v, _) => Text(
        _format(v),
        style: resolved,
        textAlign: textAlign,
        semanticsLabel: semanticsLabel ?? _format(value),
      ),
    );
  }
}

/// Page transitions: a quiet fade-through (shared-axis Z). No slide, no
/// platform back-swipe theatrics — this app is used on desktop and web too.
///
/// The outgoing page is faded and pushed a hair *back* by the secondary
/// animation, so a push reads as one surface replacing another in depth rather
/// than a cut. Under reduce-motion both halves collapse to a plain opacity
/// cross-fade.
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
    final reduce = Motion.reduced(context);

    final incoming = CurvedAnimation(
      parent: animation,
      curve: Motion.standard,
      reverseCurve: Motion.standard.flipped,
    );

    if (reduce) return FadeTransition(opacity: incoming, child: child);

    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Motion.standard,
      reverseCurve: Motion.standard.flipped,
    );

    return AnimatedBuilder(
      animation: outgoing,
      builder: (context, inner) {
        // While this page is being covered it dims and recedes very slightly;
        // 0.98 is the smallest step that still reads as depth.
        final t = outgoing.value;
        return Opacity(
          opacity: 1 - (t * 0.4),
          child: Transform.scale(scale: 1 - (t * 0.02), child: inner),
        );
      },
      child: FadeTransition(
        opacity: incoming,
        child: AnimatedBuilder(
          animation: incoming,
          builder: (context, inner) => Transform.scale(
            // Enters from a hair back — the Z axis of a shared-axis
            // transition, with none of the horizontal slide that would fight
            // a desktop window.
            scale: 0.98 + (incoming.value * 0.02),
            child: inner,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A horizontal shared-axis transition, for moving *within* one section —
/// list → detail, wizard step → next step. Forward moves left, back moves
/// right; reduce-motion collapses it to a fade.
///
/// Use as the `transitionsBuilder` of a `CustomTransitionPage` in go_router,
/// or directly with [AnimatedSwitcher] via [sharedAxisSwitcher].
Widget sharedAxisTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child, {
  double distance = 24,
}) {
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
    child: AnimatedBuilder(
      animation: curved,
      builder: (context, inner) => Transform.translate(
        offset: Offset(distance * (1 - curved.value), 0),
        child: inner,
      ),
      child: child,
    ),
  );
}

/// [AppReveal]'s sibling for content that moves sideways rather than fading in
/// place — the detail pane of a two-pane layout swapping records, or a wizard
/// advancing a step. Children need distinct keys, same as [AppReveal].
class SharedAxisSwitcher extends StatelessWidget {
  const SharedAxisSwitcher({
    required this.child,
    this.duration = Motion.medium,
    this.reverse = false,
    super.key,
  });

  final Widget child;
  final Duration duration;

  /// True when moving backwards, so the incoming child arrives from the left.
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final distance = reverse ? -24.0 : 24.0;
    return AnimatedSwitcher(
      duration: Motion.reduced(context) ? Duration.zero : duration,
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => sharedAxisTransition(
        context,
        animation,
        kAlwaysDismissedAnimation,
        child,
        distance: distance,
      ),
      child: child,
    );
  }
}
