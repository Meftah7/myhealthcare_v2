/// The floating Care Navigator. Three states, matching the FirstSemMyHealth
/// widget:
///   • a slim tab against the right edge once dismissed;
///   • the round button (with a small "×" to dismiss it);
///   • the chat panel.
/// Mounted as an `AppShell` overlay for signed-in patients, so it sits below
/// the router's Navigator and hides during full-screen flows.
library;

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

          // The round button, with its dismiss "×".
          if (view == CareNavView.fab)
            Positioned(
              right: 16,
              bottom: 20,
              child: _NavigatorFab(
                onOpen: () => setView(CareNavView.panel),
                onDismiss: () => setView(CareNavView.edge),
              ),
            ),

          // The edge tab that brings the button back.
          if (view == CareNavView.edge)
            Positioned(
              right: 0,
              bottom: 36,
              child: _EdgeTab(onTap: () => setView(CareNavView.fab)),
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

/// A gently pulsing round button with a small dismiss badge.
class _NavigatorFab extends StatefulWidget {
  const _NavigatorFab({required this.onOpen, required this.onDismiss});

  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  State<_NavigatorFab> createState() => _NavigatorFabState();
}

class _NavigatorFabState extends State<_NavigatorFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = Motion.reduced(context);

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (!reduce)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_pulse.value);
                return Container(
                  width: 56 + 20 * t,
                  height: 56 + 20 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.25 * (1 - t)),
                  ),
                );
              },
            ),
          GestureDetector(
            onTap: widget.onOpen,
            child: Material(
              color: scheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: scheme.onError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The slim tab against the right edge — tap to bring the button back.
class _EdgeTab extends StatelessWidget {
  const _EdgeTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: scheme.primary,
        elevation: 4,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
        child: SizedBox(
          width: 30,
          height: 64,
          child: Icon(
            Icons.smart_toy_outlined,
            color: scheme.onPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
