/// The opening screen — shown once per app launch, on top of everything: the
/// brand mark centred inside a soft brand bloom, "Welcome" beneath it, then it
/// fades away to reveal the app (sign-in on a cold start).
///
/// Mounted in `MaterialApp.router`'s builder so it covers the first frame and
/// never fights the router.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// How long the opening screen holds before it dissolves. Long enough to read
/// as a deliberate welcome rather than a flash of branding.
const kSplashDuration = Duration(milliseconds: 3150);

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: kSplashDuration,
  )..forward();

  bool _gone = false;

  // Timeline over 0..1 (≈3.15s):
  //   0.00–0.16  mark scales + fades in
  //   0.06–0.30  the bloom behind it blooms
  //   0.12–0.30  "Welcome" fades + rises
  //   0.30–0.85  hold — the bloom breathes so the pause isn't a freeze-frame
  //   0.85–1.00  everything dissolves
  late final Animation<double> _markIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.16, curve: Curves.easeOutBack),
  );
  late final Animation<double> _markFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.14, curve: Curves.easeOut),
  );
  late final Animation<double> _bloomIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.06, 0.30, curve: Curves.easeOut),
  );
  late final Animation<double> _wordIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.12, 0.30, curve: Curves.easeOut),
  );
  late final Animation<double> _breathe = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.30, 0.85, curve: Curves.easeInOut),
  );
  late final Animation<double> _out = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.85, 1, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _gone = true);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduce = Motion.reduced(context);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final leaving = (1 - _out.value).clamp(0.0, 1.0);
        final markScale = reduce ? 1.0 : (0.88 + 0.12 * _markIn.value);
        final markOpacity = _markFade.value * leaving;
        final wordOpacity = (reduce ? _markFade.value : _wordIn.value) * leaving;
        final wordRise = reduce ? 0.0 : (1 - _wordIn.value) * 12;

        // One slow in-and-out swell across the hold — 4% of scale, invisible as
        // motion, but it keeps the frame alive.
        final swell = reduce
            ? 0.0
            : (_breathe.value <= 0.5
                  ? _breathe.value * 2
                  : (1 - _breathe.value) * 2);
        final bloomScale = 0.82 + 0.18 * _bloomIn.value + 0.04 * swell;

        return IgnorePointer(
          // Purely decorative — it never intercepts input, so the screen
          // behind it (sign-in) is live from the first frame.
          child: ColoredBox(
            color: scheme.surface.withValues(alpha: leaving),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Brand bloom: a wide radial wash that makes the mark
                        // feel lit rather than pasted onto the surface.
                        Opacity(
                          opacity:
                              (_bloomIn.value * 0.9 * leaving).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: bloomScale,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.brandGlow,
                              ),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: markOpacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: markScale,
                            child: Container(
                              width: 104,
                              height: 104,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: AppColors.brandGradient,
                                boxShadow: Shadows.glow(AppColors.brandViolet),
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Image.asset(
                                'assets/images/logo.png',
                                semanticLabel: 'MyHealth Care',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: wordOpacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, wordRise),
                      child: Column(
                        children: [
                          Text(
                            'Welcome',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: scheme.onSurface,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            'MyHealth Care',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
