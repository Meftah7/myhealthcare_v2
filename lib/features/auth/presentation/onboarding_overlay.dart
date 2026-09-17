/// The intro carousel — shown once per device, after the splash mark
/// dissolves and only for a signed-out visitor. Three cards explain what the
/// app actually does (AI summaries, risk-ranked booking, one app for every
/// role), then it steps aside for sign-in like the splash before it.
///
/// Timed off [kSplashDuration] rather than a cross-widget signal: the splash
/// is purely decorative and exposes nothing to listen to, and re-using the
/// same constant keeps the two overlays from fighting over the reveal.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';
import 'splash_overlay.dart';

/// The hero panel's frame — a thin tinted border around the artwork rather
/// than the page's own `primaryContainer`, per the design pass on
/// 2026-09-17: the standard container tint read too washed-out at this size.
abstract final class _OnboardingFrame {
  static const Color lightFill = Color(0xFFDEDAFB);
  static const Color lightBorder = Color(0xFFCDC6F8);
  static const Color darkFill = Color(0xFF342E64);
  static const Color darkBorder = Color(0xFF504896);

  /// Dark mode only: the artwork was designed against a light background, so
  /// it's dimmed to ~85% brightness (not desaturated) rather than shown at
  /// full brightness against the surrounding dark frame.
  static const dimInDark = ColorFilter.matrix([
    0.85, 0, 0, 0, 0, //
    0, 0.85, 0, 0, 0, //
    0, 0, 0.85, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.asset,
    required this.title,
    required this.body,
  });

  /// A cropped illustration graphic (no text/logo/buttons baked in).
  final String asset;

  final String title;
  final String body;
}

class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  bool _ready = false;
  int _page = 0;
  late final _controller = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(kSplashDuration, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    unawaited(ref.read(hasSeenOnboardingProvider.notifier).markSeen());
  }

  @override
  Widget build(BuildContext context) {
    final hasSeen = ref.watch(hasSeenOnboardingProvider);
    final signedIn = ref.watch(currentUserProvider) != null;
    if (!_ready || hasSeen || signedIn) return const SizedBox.shrink();

    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pages = [
      _OnboardingPage(
        asset: 'assets/images/onboarding_1.png',
        title: t.onboardingPage1Title,
        body: t.onboardingPage1Body,
      ),
      _OnboardingPage(
        asset: 'assets/images/onboarding_2.png',
        title: t.onboardingPage2Title,
        body: t.onboardingPage2Body,
      ),
      _OnboardingPage(
        asset: 'assets/images/onboarding_3.png',
        title: t.onboardingPage3Title,
        body: t.onboardingPage3Body,
      ),
    ];
    final last = _page == pages.length - 1;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Space.lg,
                Space.xs,
                Space.xs,
                Space.xs,
              ),
              child: Row(
                children: [
                  // Expanded (not a bare child + Spacer) so the lockup's own
                  // ellipsis actually gets a bounded width to shrink against
                  // — on a 360dp-wide phone the wordmark otherwise reports
                  // its full natural width and overflows past the toggles.
                  Expanded(child: AppBrandLockup()),
                  _OnboardingThemeToggle(),
                  _OnboardingLanguageToggle(),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final page in pages)
                    _OnboardingPageView(page: page),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                0,
                Space.lg,
                Space.lg,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (i, _) in pages.indexed)
                        AnimatedContainer(
                          duration: Motion.fast,
                          margin: const EdgeInsets.symmetric(
                            horizontal: Space.xxs,
                          ),
                          width: i == _page ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: Radii.pill,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _finish,
                        child: Text(t.onboardingSkip),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: last
                            ? _finish
                            : () => unawaited(
                                _controller.nextPage(
                                  duration: Motion.medium,
                                  curve: Motion.standard,
                                ),
                              ),
                        style: FilledButton.styleFrom(
                          // The theme's dark-mode primary is a pale lavender
                          // (meant for text-on-dark contrast) — too weak for
                          // a filled CTA, so this one button pins a stronger
                          // purple with white text instead.
                          backgroundColor: theme.brightness == Brightness.dark
                              ? const Color(0xFF6C5AF5)
                              : null,
                          foregroundColor: theme.brightness == Brightness.dark
                              ? Colors.white
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.lg,
                            vertical: Space.sm,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(last ? t.onboardingGetStarted : t.nextLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same look as [ThemeModeIconToggle], minus the tooltip: this overlay sits
/// outside the router's Navigator (a sibling in `_AppFrame`'s Stack), so a
/// `Tooltip`-wrapping `IconButton` has no `Overlay` ancestor to pop into.
class _OnboardingThemeToggle extends ConsumerWidget {
  const _OnboardingThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mode = ref.watch(themeModeProvider);
    final platformIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformIsDark);

    return _IconCircle(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      onTap: () => ref
          .read(themeModeProvider.notifier)
          .set(isDark ? ThemeMode.light : ThemeMode.dark),
      scheme: scheme,
    );
  }
}

/// Same look as [LanguageIconToggle], minus the tooltip — see
/// [_OnboardingThemeToggle].
class _OnboardingLanguageToggle extends ConsumerWidget {
  const _OnboardingLanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final next = isArabic ? const Locale('en') : const Locale('ar');

    return _IconCircle(
      label: isArabic ? 'EN' : 'ع',
      onTap: () => ref.read(localeProvider.notifier).set(next),
      scheme: scheme,
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.onTap,
    required this.scheme,
    this.icon,
    this.label,
  });

  final VoidCallback onTap;
  final ColorScheme scheme;
  final IconData? icon;
  final String? label;

  static const double _diameter = 40;
  static const double _target = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _target,
      height: _target,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Container(
              width: _diameter,
              height: _diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: icon != null
                  ? Icon(icon, size: 19, color: scheme.onSurfaceVariant)
                  : Text(
                      label!,
                      style: TextStyle(
                        fontSize: label == 'EN' ? 13 : 17,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                        height: 1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Column(
        children: [
          // A thin tinted frame behind the card — turns a floating image
          // into a composed "hero" moment instead of a picture pasted on the
          // page. Expanded so it fills the available height. The artwork
          // itself (1080x1520, with its own soft gradient background baked
          // in) sits inset by 8dp so the frame reads as a border, then fills
          // the rest edge-to-edge via fit:cover — no letterboxing.
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.xs),
              decoration: BoxDecoration(
                color: isDark
                    ? _OnboardingFrame.darkFill
                    : _OnboardingFrame.lightFill,
                border: Border.all(
                  color: isDark
                      ? _OnboardingFrame.darkBorder
                      : _OnboardingFrame.lightBorder,
                ),
                borderRadius: Radii.cardLarge,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox.expand(
                  child: isDark
                      ? ColorFiltered(
                          colorFilter: _OnboardingFrame.dimInDark,
                          child: Image.asset(page.asset, fit: BoxFit.cover),
                        )
                      : Image.asset(page.asset, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Space.sm),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.md),
        ],
      ),
    );
  }
}

