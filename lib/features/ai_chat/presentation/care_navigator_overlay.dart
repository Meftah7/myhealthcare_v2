/// The floating Care Navigator — a pulsing FAB bottom-right that expands into
/// a chat panel. Mounted above the router from `MaterialApp.router`'s builder,
/// so it rides along on every signed-in screen (like the confirmation overlay).
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
    // Only for signed-in patients.
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isPatient) return const SizedBox.shrink();

    final open = ref.watch(careNavigatorOpenProvider);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            if (open)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => ref
                      .read(careNavigatorOpenProvider.notifier)
                      .state = false,
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    color: Colors.black.withValues(alpha: open ? 0.4 : 0),
                  ),
                ),
              ),

            // The panel (animated open/close).
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !open,
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
                  child: open
                      ? const _PanelHost(key: ValueKey('panel'))
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            ),

            if (!open)
              const Positioned(right: 20, bottom: 24, child: _NavigatorFab()),
          ],
        ),
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

/// A gently pulsing round button with the assistant glyph.
class _NavigatorFab extends ConsumerStatefulWidget {
  const _NavigatorFab();

  @override
  ConsumerState<_NavigatorFab> createState() => _NavigatorFabState();
}

class _NavigatorFabState extends ConsumerState<_NavigatorFab>
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

    return GestureDetector(
      onTap: () =>
          ref.read(careNavigatorOpenProvider.notifier).state = true,
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
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
            Material(
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
          ],
        ),
      ),
    );
  }
}
