/// The intro carousel — shown once per device (stored independently of the
/// session), after the splash mark dissolves and only for a signed-out
/// visitor. Two pages: appointment booking, then records and report
/// explanations. Skip / Get Started land on guest Home.
///
/// Timed off [kSplashDuration] rather than a cross-widget signal: the splash
/// is purely decorative and exposes nothing to listen to, and re-using the
/// same constant keeps the two overlays from fighting over the reveal.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';
import 'splash_overlay.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.accentIcon,
    required this.title,
    required this.body,
  });

  /// Original vector illustration: a large glyph plus a small accent glyph.
  final IconData icon;
  final IconData accentIcon;

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
    // Public browsing is enabled: land on guest Home rather than sign-in.
    // The overlay sits outside the router's Navigator, so use the router.
    ref.read(routerProvider).go(AppRoutes.patientHome);
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
        icon: Icons.calendar_month_rounded,
        accentIcon: Icons.check_rounded,
        title: t.paOnboardBookTitle,
        body: t.paOnboardBookBody,
      ),
      _OnboardingPage(
        icon: Icons.description_rounded,
        accentIcon: Icons.auto_awesome_rounded,
        title: t.paOnboardRecordsTitle,
        body: t.paOnboardRecordsBody,
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
                  for (final page in pages) _OnboardingPageView(page: page),
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
                                ? PatientPalette.of(context).action
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.lg,
                            vertical: Space.sm,
                          ),
                        ),
                        child: Text(
                          last ? t.onboardingGetStarted : t.nextLabel,
                        ),
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
    final palette = PatientPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Column(
        children: [
          Expanded(
            child: ExcludeSemantics(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: palette.softAccent,
                  borderRadius: Radii.cardLarge,
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = (c.biggest.shortestSide * .42).clamp(
                      72.0,
                      180.0,
                    );
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft concentric rings behind the glyph.
                        for (final f in const [1.9, 1.45])
                          Container(
                            width: size * f,
                            height: size * f,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.card.withValues(
                                alpha: f > 1.5 ? .35 : .6,
                              ),
                            ),
                          ),
                        Icon(page.icon, size: size, color: palette.action),
                        PositionedDirectional(
                          top: c.maxHeight / 2 - size * .75,
                          end: c.maxWidth / 2 - size * .8,
                          child: Container(
                            width: size * .42,
                            height: size * .42,
                            decoration: BoxDecoration(
                              color: palette.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.card, width: 3),
                            ),
                            child: Icon(
                              page.accentIcon,
                              color: Colors.white,
                              size: size * .24,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: Space.md),
        ],
      ),
    );
  }
}
