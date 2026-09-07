/// The opening screen — shown once per app launch, on top of everything: the
/// brand mark centred, "Welcome" beneath it, a short entrance animation, then
/// it fades away to reveal the app (sign-in on a cold start).
///
/// Mounted in `MaterialApp.router`'s builder so it covers the first frame and
/// never fights the router.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..forward();

  bool _gone = false;

  // Timeline over 0..1:
  //   0.00–0.28  logo scales + fades in
  //   0.18–0.52  "Welcome" fades + rises
  //   0.52–0.74  hold
  //   0.74–1.00  everything fades out
  late final Animation<double> _logoIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.28, curve: Curves.easeOutBack),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.24, curve: Curves.easeOut),
  );
  late final Animation<double> _wordIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.18, 0.52, curve: Curves.easeOut),
  );
  late final Animation<double> _out = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.74, 1, curve: Curves.easeIn),
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
        final logoScale = reduce ? 1.0 : (0.86 + 0.14 * _logoIn.value);
        final logoOpacity = _logoFade.value * leaving;
        final wordOpacity = (reduce ? _logoFade.value : _wordIn.value) *
            leaving;
        final wordRise = reduce ? 0.0 : (1 - _wordIn.value) * 10;

        return IgnorePointer(
          // Purely decorative — it never intercepts input, so the screen
          // behind it (sign-in) is live from the first frame.
          child: ColoredBox(
            color: scheme.surface.withValues(alpha: leaving),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoOpacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: logoScale,
                      child: Container(
                        width: 104,
                        height: 104,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: AppColors.brandGradient,
                          boxShadow: Shadows.e2,
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/images/logo.png',
                          semanticLabel: 'MyHealth Care',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  Opacity(
                    opacity: wordOpacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, wordRise),
                      child: Text(
                        'Welcome',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          letterSpacing: 0.5,
                        ),
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
