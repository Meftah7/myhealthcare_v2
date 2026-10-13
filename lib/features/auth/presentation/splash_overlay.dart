/// The opening screen — the MyHealth mark on the patient surface while the
/// app opens storage and restores the session. It is driven by readiness, not
/// a timer: it dissolves as soon as bootstrap finishes and the session is
/// known. A startup that stalls switches to a retry state; a startup that
/// fails steps aside for the router's error screen.
///
/// Mounted in `MaterialApp.router`'s builder so it covers the first frame and
/// never fights the router.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';

/// Upper bound on the dissolve once the app is ready. Tests pump this long to
/// get past the splash; users never wait on it before startup completes.
const kSplashDuration = Duration(milliseconds: 400);

/// How long startup may run before the splash offers a retry.
const kSplashSlowAfter = Duration(seconds: 8);

/// Whether storage is open and the persisted session has been read — the
/// point at which sign-in or onboarding can be shown.
final appReadyProvider = Provider<bool>((ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  final restoring = ref.watch(sessionProvider.select((s) => s.isRestoring));
  return bootstrap.hasValue && !bootstrap.isLoading && !restoring;
});

class SplashOverlay extends ConsumerStatefulWidget {
  const SplashOverlay({super.key});

  @override
  ConsumerState<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends ConsumerState<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
  );
  Timer? _slowTimer;
  bool _slow = false;
  bool _gone = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _armSlowTimer();
  }

  void _armSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = Timer(kSplashSlowAfter, () {
      if (mounted && !_gone) setState(() => _slow = true);
    });
  }

  void _dismiss({required bool animate}) {
    _slowTimer?.cancel();
    if (!animate) {
      setState(() => _gone = true);
      return;
    }
    unawaited(
      _fade.reverse().whenComplete(() {
        if (mounted) setState(() => _gone = true);
      }),
    );
  }

  void _retry() {
    setState(() {
      _slow = false;
      _dismissing = false;
    });
    ref.invalidate(appBootstrapProvider);
    _armSlowTimer();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();

    final ready = ref.watch(appReadyProvider);
    // A failed bootstrap: the router's retry screen beneath says what went
    // wrong, so the splash gets out of its way at once.
    final failed = ref.watch(
      appBootstrapProvider.select((b) => b.hasError && !b.isLoading),
    );
    if ((ready || failed) && !_dismissing) {
      _dismissing = true;
      final animate = ready && !Motion.reduced(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dismiss(animate: animate);
      });
    }

    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: IgnorePointer(
        // Only the slow-start retry is interactive.
        ignoring: !_slow,
        child: ColoredBox(
          color: scheme.surface,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SplashBrandMark(),
                      const SizedBox(height: Space.lg),
                      if (!_slow)
                        Semantics(
                          label: t.splashLoadingLabel,
                          liveRegion: true,
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else ...[
                        Text(
                          t.splashSlowTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          t.splashSlowBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Space.lg),
                        FilledButton(
                          onPressed: _retry,
                          child: Text(t.tryAgain),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The MyHealth mark inside its soft blue bloom, with the wordmark beneath.
/// Shared by the splash overlay and the router's own loading screen so a
/// retried startup looks the same as a cold one.
class SplashBrandMark extends StatelessWidget {
  const SplashBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.patientBrandGlow,
                ),
                child: SizedBox.expand(),
              ),
              const AppLogo(height: 112),
            ],
          ),
        ),
        ExcludeSemantics(
          child: Text(
            kBrandName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}
