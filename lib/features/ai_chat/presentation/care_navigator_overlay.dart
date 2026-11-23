/// The floating Care Navigator. Three states:
///   • docked: the mascot's head peeking in, flush against the left or right
///     edge of the page;
///   • floating: the round blue button with the full-body mascot, and a small
///     white "×" on its top-right corner to dock it;
///   • the chat panel.
///
/// The button can be dragged anywhere; on release it glides to the nearer side
/// at the height it was left. Docking slides it off to that same side and the
/// head slides in at that same height; tapping the head slides the button back
/// out on that side. The head can be slid along its edge, or dragged across
/// the screen to dock on the other side. The resting place is remembered per
/// device, and docking or restoring never touches the conversation.
///
/// Mounted as an `AppShell` overlay for signed-in patients, so it sits below
/// the router's Navigator and hides during full-screen flows. Everything
/// outside the button, its "×" and the head lets taps and scrolls through.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell/shell_insets.dart';
import '../../../app/theme/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../application/care_navigator.dart';
import 'care_navigator_mascot.dart';
import 'care_navigator_panel.dart';

class CareNavigatorOverlay extends ConsumerWidget {
  const CareNavigatorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isPatient) return const SizedBox.shrink();

    final view = ref.watch(careNavigatorViewProvider);
    void setView(CareNavView v) =>
        ref.read(careNavigatorViewProvider.notifier).state = v;
    // ScaleTransition.alignment only takes a resolved Alignment, not
    // AlignmentGeometry, so the RTL-aware bottom-end origin is resolved once
    // here rather than in the transitionBuilder closure below (which has no
    // BuildContext of its own).
    final panelScaleOrigin = AlignmentDirectional.bottomEnd.resolve(
      Directionality.of(context),
    );

    return Positioned.fill(
      child: Stack(
        children: [
          // Dim backdrop behind the open panel.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: view != CareNavView.panel,
              child: GestureDetector(
                onTap: () => setView(CareNavView.fab),
                child: AnimatedContainer(
                  duration: Motion.medium,
                  color: Colors.black.withValues(
                    alpha: view == CareNavView.panel ? 0.4 : 0,
                  ),
                ),
              ),
            ),
          ),

          // The panel.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: view != CareNavView.panel,
              child: AnimatedSwitcher(
                duration: Motion.medium,
                switchInCurve: Motion.emphasized,
                switchOutCurve: Motion.standard,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(anim),
                    alignment: panelScaleOrigin,
                    child: child,
                  ),
                ),
                child: view == CareNavView.panel
                    ? const _PanelHost(key: ValueKey('panel'))
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
          ),

          // The launcher: floating button and docked head.
          Positioned.fill(
            child: _Launcher(
              view: view,
              onOpen: () => setView(CareNavView.panel),
              onDock: () async {
                await ref
                    .read(careNavPlacementProvider.notifier)
                    .settle(snapToSide: true);
                setView(CareNavView.edge);
              },
              onRestore: () => setView(CareNavView.fab),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHost extends StatelessWidget {
  const _PanelHost({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 520;
    // `SafeArea` only insets for the notch / home indicator, not the on-screen
    // keyboard — without this, the keyboard covers the panel's input row
    // instead of the panel shrinking to sit above it.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: AnimatedPadding(
        duration: Motion.medium,
        curve: Motion.standard,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Align(
          alignment: compact
              ? Alignment.bottomCenter
              : AlignmentDirectional.bottomEnd,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight:
                    (size.height - keyboardInset) * (compact ? 0.8 : 0.72),
              ),
              child: const CareNavigatorPanel(),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared geometry
// ---------------------------------------------------------------------------

// The button lives in an oversized box so its dismiss "×" can sit exactly on
// the top-right corner (badge centre = circle corner) with a full 48dp tap
// target that clears the circle's centre and stays on screen.
const double _fabBox = 104;
const double _fabCircle = 56;
const double _mascotHeight = _fabCircle * CareNavigatorAvatar.mascotShare;
const double _headHeight = 68;
const double _edgeMargin = 6;

/// Docking and restoring: one short slide, out one side and in the other.
const Duration _dockDuration = Duration(milliseconds: 300);

/// Where the launcher may go on this screen: inside the safe area and clear
/// of the shell's navigation (bottom bar, rail or sidebar).
class _Geometry {
  factory _Geometry.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final nav = ShellInsets.navigationOf(context);
    // The page: the screen minus system insets and the shell's navigation.
    final page = Rect.fromLTRB(
      math.max(pad.left, nav.left),
      pad.top,
      size.width - math.max(pad.right, nav.right),
      size.height - math.max(pad.bottom, nav.bottom),
    );
    const inset = _edgeMargin + _fabBox / 2;
    final left = page.left + inset;
    final top = page.top + inset;
    return _Geometry._(
      page: page,
      free: Rect.fromLTRB(
        left,
        top,
        math.max(left, page.right - inset),
        math.max(top, page.bottom - inset),
      ),
    );
  }

  const _Geometry._({required this.page, required this.free});

  /// The visible page area the launcher lives in.
  final Rect page;

  /// The rectangle the button's centre may roam in.
  final Rect free;

  Offset centreOf(CareNavPlacement p) =>
      Offset(free.left + p.dx * free.width, free.top + p.dy * free.height);

  Offset fractionOf(Offset c) => Offset(
    free.width <= 0 ? 1 : ((c.dx - free.left) / free.width).clamp(0.0, 1.0),
    free.height <= 0 ? 1 : ((c.dy - free.top) / free.height).clamp(0.0, 1.0),
  );

  /// The page edges the head sits flush against.
  double get leftEdge => page.left;
  double get rightEdge => page.right;
}

// ---------------------------------------------------------------------------
// The launcher (button + head, with the dock slide between them)
// ---------------------------------------------------------------------------

class _Launcher extends StatefulWidget {
  const _Launcher({
    required this.view,
    required this.onOpen,
    required this.onDock,
    required this.onRestore,
  });

  final CareNavView view;
  final VoidCallback onOpen;
  final VoidCallback onDock;
  final VoidCallback onRestore;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher>
    with SingleTickerProviderStateMixin {
  /// 0 = floating button, 1 = docked head. Created eagerly: `build` skips it
  /// while the panel is open, and a lazy field first touched in `dispose()`
  /// would look up its TickerMode on a deactivated context.
  late final AnimationController _dock;

  @override
  void initState() {
    super.initState();
    _dock = AnimationController(
      vsync: this,
      duration: _dockDuration,
      value: widget.view == CareNavView.edge ? 1 : 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode all three pieces of art up front so the first dock / restore
    // doesn't slide in an empty box while the PNG loads.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    for (final (art, height) in [
      (mascotFullBody, _mascotHeight),
      (mascotHeadLeft, _headHeight),
      (mascotHeadRight, _headHeight),
    ]) {
      unawaited(precacheImage(art.provider(height, dpr), context));
    }
  }

  @override
  void didUpdateWidget(_Launcher old) {
    super.didUpdateWidget(old);
    if (old.view == widget.view || widget.view == CareNavView.panel) return;
    final target = widget.view == CareNavView.edge ? 1.0 : 0.0;
    // Coming back from the chat panel: the panel's own transition covers it,
    // so the button simply reappears where it was.
    if (old.view == CareNavView.panel || Motion.reduced(context)) {
      _dock.value = target;
    } else {
      unawaited(_dock.animateTo(target));
    }
  }

  @override
  void dispose() {
    _dock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.view == CareNavView.panel) return const SizedBox.shrink();
    final reduce = Motion.reduced(context);
    return AnimatedBuilder(
      animation: _dock,
      builder: (context, _) {
        final t = _dock.value;
        // The button leaves first, the head arrives last; they overlap in the
        // middle so the hand-off reads as one move toward the edge.
        final fabOut = Curves.easeInCubic.transform(
          const Interval(0, 0.6).transform(t),
        );
        final headIn = Motion.standard.transform(
          const Interval(0.4, 1).transform(t),
        );
        return Stack(
          children: [
            if (fabOut < 1)
              _FloatingButton(
                key: const ValueKey('floating'),
                interactive: widget.view == CareNavView.fab,
                exit: fabOut,
                slide: !reduce,
                onOpen: widget.onOpen,
                onDock: widget.onDock,
              ),
            if (headIn > 0)
              _DockedHead(
                key: const ValueKey('docked'),
                interactive: widget.view == CareNavView.edge,
                enter: headIn,
                slide: !reduce,
                onRestore: widget.onRestore,
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// The floating button
// ---------------------------------------------------------------------------

class _FloatingButton extends ConsumerStatefulWidget {
  const _FloatingButton({
    required this.interactive,
    required this.exit,
    required this.slide,
    required this.onOpen,
    required this.onDock,
    super.key,
  });

  /// False while it slides away (or before it has settled back).
  final bool interactive;

  /// 0 = in place, 1 = slid off to its side and faded out.
  final double exit;

  /// Whether docking moves it (false under reduce-motion: just a fade).
  final bool slide;

  final VoidCallback onOpen;
  final VoidCallback onDock;

  @override
  ConsumerState<_FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends ConsumerState<_FloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    // Eagerly created (not a lazy `late final` initializer): `build` skips
    // `_pulse` entirely under reduce-motion, so a lazy field would only be
    // first touched from `dispose()` — where `vsync: this` needs a live
    // context to find its TickerMode and throws "Looking up a deactivated
    // widget's ancestor is unsafe" instead.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_pulse.repeat());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final reduce = Motion.reduced(context);
    final geo = _Geometry.of(context);
    final placement = ref.watch(careNavPlacementProvider);
    final placer = ref.read(careNavPlacementProvider.notifier);
    final centre = geo.centreOf(placement);

    // While docking, the circle travels to the page edge on its side.
    final edgeX = placement.onRight ? geo.rightEdge : geo.leftEdge;
    final travel = widget.slide ? (edgeX - centre.dx) * widget.exit : 0.0;

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : Motion.medium,
      curve: Motion.standard,
      left: centre.dx - _fabBox / 2,
      top: centre.dy - _fabBox / 2,
      child: IgnorePointer(
        ignoring: !widget.interactive,
        child: Transform.translate(
          offset: Offset(travel, 0),
          child: Opacity(
            opacity: 1 - widget.exit,
            child: GestureDetector(
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (d) {
                // From the current placement, not this build's: several
                // moves can arrive before the next frame.
                final now = geo.centreOf(ref.read(careNavPlacementProvider));
                final next = geo.fractionOf(now + d.delta);
                placer.drag(dx: next.dx, dy: next.dy);
              },
              onPanEnd: (_) {
                setState(() => _dragging = false);
                unawaited(placer.settle(snapToSide: true));
              },
              child: SizedBox(
                width: _fabBox,
                height: _fabBox,
                child: Stack(
                  children: [
                    // The button, centred in the box.
                    Center(
                      child: SizedBox(
                        width: _fabCircle,
                        height: _fabCircle,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            if (!reduce && !_dragging && widget.exit == 0)
                              // Isolated so the 60fps pulse repaints only
                              // itself, not the screen it floats over.
                              RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, _) {
                                    final p = Curves.easeOut.transform(
                                      _pulse.value,
                                    );
                                    return Container(
                                      width: _fabCircle + 20 * p,
                                      height: _fabCircle + 20 * p,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: scheme.primary.withValues(
                                          alpha: 0.25 * (1 - p),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            Semantics(
                              button: true,
                              label: t.openCareNavigator,
                              excludeSemantics: true,
                              child: GestureDetector(
                                onTap: widget.onOpen,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: Shadows.glow(scheme.primary),
                                  ),
                                  // Same avatar as the chat panel header.
                                  // (Its default size is the 56dp circle.)
                                  child: const CareNavigatorAvatar(
                                    key: ValueKey('care-nav-fab'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // The dock "×" — a small white badge on the button's
                    // top-right corner. Its 48dp tap target fills the box's
                    // top-right and does not reach the button's centre, so it
                    // never eats an "open" tap.
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Semantics(
                        button: true,
                        label: t.hideCareNavigator,
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: const ValueKey('care-nav-dock'),
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onDock,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: Shadows.clay(scheme),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 13,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The docked head
// ---------------------------------------------------------------------------

class _DockedHead extends ConsumerStatefulWidget {
  const _DockedHead({
    required this.interactive,
    required this.enter,
    required this.slide,
    required this.onRestore,
    super.key,
  });

  /// False while it slides in or out.
  final bool interactive;

  /// 0 = hidden past its edge, 1 = peeking in.
  final double enter;

  /// Whether docking moves it (false under reduce-motion: just a fade).
  final bool slide;

  final VoidCallback onRestore;

  @override
  ConsumerState<_DockedHead> createState() => _DockedHeadState();
}

class _DockedHeadState extends ConsumerState<_DockedHead> {
  /// Horizontal offset of an in-progress drag across the screen, or null.
  double? _dragX;

  /// The geometry of the last build. Gesture callbacks read it (and the
  /// current placement) at call time: several pointer moves, or a move and
  /// the release, can arrive before the next frame rebuilds the closures.
  late _Geometry _geo;

  static double _widthOf(MascotArt art) => _headHeight * art.aspect;

  /// The head's left edge: at rest flush with its side, while dragged
  /// following the finger.
  double _left(bool onRight) {
    final rest = onRight
        ? _geo.rightEdge - _widthOf(mascotHeadRight)
        : _geo.leftEdge;
    final drag = _dragX;
    if (drag == null) return rest;
    return (rest + drag).clamp(
      _geo.leftEdge,
      math.max(_geo.leftEdge, _geo.rightEdge - _widthOf(mascotHeadRight)),
    );
  }

  /// Which side the head is docked to — while dragged, whichever half of the
  /// screen it is over, so it turns to face into the page from there.
  bool _facesFromRight(bool onRight) => _dragX == null
      ? onRight
      : _left(onRight) + _widthOf(mascotHeadRight) / 2 > _geo.page.center.dx;

  void _endDrag() {
    final placer = ref.read(careNavPlacementProvider.notifier);
    final right = _facesFromRight(ref.read(careNavPlacementProvider).onRight);
    setState(() => _dragX = null);
    placer.drag(dx: right ? 1 : 0);
    unawaited(placer.settle(snapToSide: true));
  }

  @override
  Widget build(BuildContext context) {
    final geo = _geo = _Geometry.of(context);
    final placement = ref.watch(careNavPlacementProvider);
    final onRight = placement.onRight;

    // Level with where the button's circle is (or would be).
    final centre = geo.centreOf(placement);
    final dragging = _dragX != null;
    final left = _left(onRight);
    final facesFromRight = _facesFromRight(onRight);
    final art = facesFromRight ? mascotHeadRight : mascotHeadLeft;
    final width = _widthOf(art);

    // Sliding in from (and out past) its own edge.
    final hidden = facesFromRight ? width : -width;
    final slide = widget.slide ? hidden * (1 - widget.enter) : 0.0;

    return AnimatedPositioned(
      duration: dragging ? Duration.zero : Motion.medium,
      curve: Motion.standard,
      left: left,
      top: centre.dy - _headHeight / 2,
      child: IgnorePointer(
        ignoring: !widget.interactive,
        child: Transform.translate(
          offset: Offset(slide, 0),
          child: Opacity(
            opacity: widget.slide ? 1 : widget.enter,
            child: Semantics(
              button: true,
              label: AppLocalizations.of(context)!.showCareNavigator,
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('care-nav-head'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onRestore,
                onPanStart: (_) => setState(() => _dragX = 0),
                onPanUpdate: (d) {
                  setState(() => _dragX = (_dragX ?? 0) + d.delta.dx);
                  final now = _geo.centreOf(ref.read(careNavPlacementProvider));
                  ref
                      .read(careNavPlacementProvider.notifier)
                      .drag(
                        dy: _geo.fractionOf(now + Offset(0, d.delta.dy)).dy,
                      );
                },
                onPanEnd: (_) => _endDrag(),
                onPanCancel: () {
                  if (_dragX != null) _endDrag();
                },
                child: MascotImage(art, height: _headHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
