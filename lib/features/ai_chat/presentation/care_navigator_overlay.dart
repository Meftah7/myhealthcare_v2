/// The floating Care Navigator. Three states, matching the FirstSemMyHealth
/// widget:
///   • a slim tab tucked against the nearest side once dismissed;
///   • the round button (with a small "×" on its top-right corner to dismiss);
///   • the chat panel.
///
/// The button can be dragged anywhere; on release it glides to the nearer side
/// at the height it was left. Dismissing it drops the edge tab on that same
/// side at that same height, and the tab itself can be slid up and down its
/// edge. The resting place is remembered per device.
///
/// Mounted as an `AppShell` overlay for signed-in patients, so it sits below
/// the router's Navigator and hides during full-screen flows.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../auth/application/session.dart';
import '../application/care_navigator.dart';
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
                    alignment: Alignment.bottomRight,
                    child: child,
                  ),
                ),
                child: view == CareNavView.panel
                    ? const _PanelHost(key: ValueKey('panel'))
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
          ),

          if (view == CareNavView.fab)
            _DraggableFab(
              onOpen: () => setView(CareNavView.panel),
              onDismiss: () async {
                await ref
                    .read(careNavPlacementProvider.notifier)
                    .settle(snapToSide: true);
                setView(CareNavView.edge);
              },
            ),

          if (view == CareNavView.edge)
            _EdgeTab(onOpen: () => setView(CareNavView.fab)),
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
    return SafeArea(
      child: Align(
        alignment: compact ? Alignment.bottomCenter : Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: size.height * (compact ? 0.8 : 0.72),
            ),
            child: const CareNavigatorPanel(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The draggable round button
// ---------------------------------------------------------------------------

// The button lives in an oversized box so its dismiss "×" can sit exactly on
// the top-right corner (badge centre = circle corner) with a full 48dp tap
// target that clears the circle's centre and stays on screen.
const double _fabBox = 104;
const double _fabCircle = 56;
const double _edgeMargin = 6;

class _DraggableFab extends ConsumerStatefulWidget {
  const _DraggableFab({required this.onOpen, required this.onDismiss});

  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  ConsumerState<_DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends ConsumerState<_DraggableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  bool _dragging = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = Motion.reduced(context);
    // Read only the size / padding aspects — not the whole MediaQuery — so the
    // button doesn't rebuild every time the keyboard changes the view insets.
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final placement = ref.watch(careNavPlacementProvider);
    final placer = ref.read(careNavPlacementProvider.notifier);

    // The rectangle the button centre may roam in.
    final free = Rect.fromLTRB(
      pad.left + _edgeMargin + _fabBox / 2,
      pad.top + _edgeMargin + _fabBox / 2,
      size.width - pad.right - _edgeMargin - _fabBox / 2,
      size.height - pad.bottom - _edgeMargin - _fabBox / 2,
    );
    final centre = Offset(
      free.left + placement.dx * free.width,
      free.top + placement.dy * free.height,
    );

    Offset toFraction(Offset c) => Offset(
      ((c.dx - free.left) / free.width).clamp(0.0, 1.0),
      ((c.dy - free.top) / free.height).clamp(0.0, 1.0),
    );

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : Motion.medium,
      curve: Motion.standard,
      left: centre.dx - _fabBox / 2,
      top: centre.dy - _fabBox / 2,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (d) {
          final next = toFraction(centre + d.delta);
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
                      if (!reduce && !_dragging)
                        // Isolated so the 60fps pulse repaints only itself,
                        // not the screen it floats over.
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) {
                              final t =
                                  Curves.easeOut.transform(_pulse.value);
                              return Container(
                                width: _fabCircle + 20 * t,
                                height: _fabCircle + 20 * t,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(
                                    alpha: 0.25 * (1 - t),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Semantics(
                        button: true,
                        label: 'Open Care Navigator',
                        child: GestureDetector(
                          onTap: widget.onOpen,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: Shadows.glow(scheme.primary),
                            ),
                            child: Material(
                              color: scheme.primary,
                              shape: const CircleBorder(),
                              child: const SizedBox(
                                width: _fabCircle,
                                height: _fabCircle,
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  color: Colors.white,
                                  size: 26,
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

              // The dismiss "×" — a 22dp badge on the button's top-right
              // corner. Its 48dp tap target fills the box's top-right and does
              // not reach the button's centre, so it never eats an "open" tap.
              Positioned(
                right: 0,
                top: 0,
                child: Semantics(
                  button: true,
                  label: 'Hide Care Navigator',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDismiss,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.outlineVariant),
                            boxShadow: Shadows.e1,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 13,
                            color: scheme.onSurfaceVariant,
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
    );
  }
}

// ---------------------------------------------------------------------------
// The slim edge tab
// ---------------------------------------------------------------------------

class _EdgeTab extends ConsumerStatefulWidget {
  const _EdgeTab({required this.onOpen});

  final VoidCallback onOpen;

  @override
  ConsumerState<_EdgeTab> createState() => _EdgeTabState();
}

class _EdgeTabState extends ConsumerState<_EdgeTab> {
  static const double _w = 30;
  static const double _h = 64;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final placement = ref.watch(careNavPlacementProvider);
    final placer = ref.read(careNavPlacementProvider.notifier);
    final onRight = placement.onRight;

    final minY = pad.top + _edgeMargin;
    final maxY = size.height - pad.bottom - _edgeMargin - _h;
    final top = (minY + placement.dy * (maxY - minY)).clamp(minY, maxY);

    final radius = onRight
        ? const BorderRadius.only(
            topLeft: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          );

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : Motion.medium,
      curve: Motion.standard,
      top: top,
      left: onRight ? null : 0,
      right: onRight ? 0 : null,
      child: Semantics(
        button: true,
        label: 'Show Care Navigator',
        child: GestureDetector(
          onTap: widget.onOpen,
          onVerticalDragStart: (_) => setState(() => _dragging = true),
          onVerticalDragUpdate: (d) {
            final span = (maxY - minY).clamp(1.0, double.infinity);
            placer.drag(dy: placement.dy + d.delta.dy / span);
          },
          onVerticalDragEnd: (_) {
            setState(() => _dragging = false);
            unawaited(placer.settle());
          },
          child: Material(
            color: scheme.primary,
            elevation: 4,
            borderRadius: radius,
            child: SizedBox(
              width: _w,
              height: _h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.drag_indicator,
                    color: scheme.onPrimary.withValues(alpha: 0.6),
                    size: 12,
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.smart_toy_outlined,
                    color: scheme.onPrimary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
