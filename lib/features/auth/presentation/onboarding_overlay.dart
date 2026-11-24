/// The intro carousel — shown once per device (stored independently of the
/// session) to a signed-out visitor, as soon as the app is ready (storage open,
/// session restored). Two pages: booking an appointment, then health records
/// with the AI report explanation. Skip / Get started save completion and
/// reveal the sign-in screen already routed underneath, so a protected deep
/// link's `?from=` destination survives.
///
/// Designed phone-first (320 × 568): one centred column — header, artwork,
/// text, page indicator and buttons — capped at [_maxContentWidth] on larger
/// screens. Both pages share one artwork height, so the heading and the
/// buttons stay put when paging. The height is what is left after the longer
/// page's text at the reader's text size: a short screen shrinks the artwork
/// first, and only when it would get too small (large accessibility text)
/// does the page scroll, with the buttons always on screen below it.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';
import 'splash_overlay.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.art,
    required this.title,
    required this.body,
  });

  /// The page's illustration asset, drawn whole with [BoxFit.contain] and
  /// never mirrored.
  final String art;
  final String title;
  final String body;
}

/// The column's width cap on tablets and desktops.
const double _maxContentWidth = 480;

/// Side padding of the text and buttons.
const double _gutter = 20;

/// Artwork height limits: it never grows past [_maxArt]; below [_minArt]
/// the page scrolls instead of shrinking it further.
const double _maxArt = 300;
const double _minArt = 120;

/// Space above the artwork and between it and the heading.
const double _artTop = Space.xs;
const double _artGap = Space.md;

TextStyle _headingStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: PatientPalette.of(context).text,
    );

TextStyle _bodyStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: 16,
      height: 1.5,
      color: PatientPalette.of(context).textMuted,
    );

class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  int _page = 0;
  late final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    // Completion is a device preference, independent of authentication: it
    // survives sign-out. Sign-in (already underneath) remains.
    unawaited(ref.read(hasSeenOnboardingProvider.notifier).markSeen());
  }

  void _go(int page) => unawaited(
    _controller.animateToPage(
      page,
      duration: Motion.reduced(context) ? Duration.zero : Motion.medium,
      curve: Motion.standard,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(appReadyProvider);
    final hasSeen = ref.watch(hasSeenOnboardingProvider);
    final signedIn = ref.watch(currentUserProvider) != null;
    if (!ready || hasSeen || signedIn) return const SizedBox.shrink();

    final t = AppLocalizations.of(context)!;
    final pages = [
      _OnboardingPage(
        art: 'assets/images/doctor-appointment-legs-uncrossed',
        title: t.paOnboardBookTitle,
        body: t.paOnboardBookBody,
      ),
      _OnboardingPage(
        // The MyHealth AI character holding a report.
        art: 'assets/images/explain-report-illustration.png',
        title: t.paOnboardRecordsTitle,
        body: t.paOnboardRecordsBody,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.pageGradient(Theme.of(context).brightness),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    _gutter,
                    Space.xxs,
                    Space.xxs,
                    0,
                  ),
                  child: Row(
                    children: [
                      // Expanded (not a bare child + Spacer) so the
                      // lockup's own ellipsis gets a bounded width to shrink
                      // against on a narrow phone.
                      Expanded(child: AppBrandLockup()),
                      _OnboardingThemeToggle(),
                      _OnboardingLanguageToggle(),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final art = _artHeight(context, box, pages);
                      return PageView(
                        controller: _controller,
                        onPageChanged: (i) => setState(() => _page = i),
                        children: [
                          for (final page in pages)
                            _OnboardingPageView(page: page, artHeight: art),
                        ],
                      );
                    },
                  ),
                ),
                _OnboardingNav(
                  page: _page,
                  count: pages.length,
                  onSkip: _finish,
                  onNext: () => _go(_page + 1),
                  onBack: () => _go(_page - 1),
                  onDone: _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One artwork height for both pages: the space left once the longer
  /// page's text is laid out at the reader's text size, within
  /// [_minArt]–[_maxArt].
  static double _artHeight(
    BuildContext context,
    BoxConstraints box,
    List<_OnboardingPage> pages,
  ) {
    final width = box.maxWidth - 2 * _gutter;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: width);
      final h = painter.height;
      painter.dispose();
      return h;
    }

    final heading = _headingStyle(context);
    final body = _bodyStyle(context);
    var text = 0.0;
    for (final p in pages) {
      text = math.max(
        text,
        measure(p.title, heading) + Space.xs + measure(p.body, body),
      );
    }
    // A few pixels of slack: laid-out text can round a little taller than
    // its measurement.
    final room = box.maxHeight - _artTop - _artGap - text - Space.sm - 8;
    return room.clamp(_minArt, _maxArt);
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
                border: Border.all(color: Clay.seam(scheme)),
                boxShadow: Shadows.clay(scheme),
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

/// One page: the artwork centred in its area, then the heading and body
/// aligned to the reading start. Scrolls only when the text alone needs more
/// room than the screen has (large accessibility text).
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page, required this.artHeight});

  final _OnboardingPage page;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: _gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: _artTop),
          SizedBox(
            height: artHeight,
            child: ExcludeSemantics(
              // The whole picture, in its original orientation in both
              // languages (images are never mirrored unless asked).
              child: Image.asset(
                page.art,
                key: ValueKey('onboarding-art-${page.art}'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: _artGap),
          Text(page.title, style: _headingStyle(context)),
          const SizedBox(height: Space.xs),
          Text(page.body, style: _bodyStyle(context)),
          const SizedBox(height: Space.sm),
        ],
      ),
    );
  }
}

/// The page indicator and the buttons, always on screen below the page:
/// "Skip" and "Next" on the first page, "Back" and "Get started" on the
/// last. The row follows the reading direction, so in Arabic it — and its
/// arrows — mirror.
class _OnboardingNav extends StatelessWidget {
  const _OnboardingNav({
    required this.page,
    required this.count,
    required this.onSkip,
    required this.onNext,
    required this.onBack,
    required this.onDone,
  });

  final int page;
  final int count;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = PatientPalette.of(context);
    final last = page == count - 1;
    const height = Size(0, 48);
    final secondary = FilledButton.styleFrom(
      backgroundColor: palette.softAccent,
      foregroundColor: palette.onSoftAccent,
      minimumSize: height,
    );
    final primary = FilledButton.styleFrom(minimumSize: height);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, Space.xs, _gutter, Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: t.onboardingProgress(page + 1, count),
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 0; i < count; i++)
                  AnimatedContainer(
                    duration: Motion.fast,
                    margin: const EdgeInsetsDirectional.only(
                      end: Space.xxs + 2,
                    ),
                    width: i == page ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == page ? palette.action : scheme.outlineVariant,
                      borderRadius: Radii.pill,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          // Side by side when they fit; stacked (still in reading order) when
          // large text makes them too wide for the row.
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            spacing: Space.sm,
            overflowSpacing: Space.xs,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              if (!last)
                FilledButton(
                  key: const ValueKey('onboarding-skip'),
                  onPressed: onSkip,
                  style: secondary,
                  child: Text(t.onboardingSkip),
                )
              else
                FilledButton.icon(
                  key: const ValueKey('onboarding-back'),
                  onPressed: onBack,
                  style: secondary,
                  // arrow_back mirrors itself in RTL.
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: Text(t.backButton),
                ),
              if (!last)
                FilledButton.icon(
                  key: const ValueKey('onboarding-next'),
                  onPressed: onNext,
                  style: primary,
                  iconAlignment: IconAlignment.end,
                  // arrow_forward mirrors itself in RTL.
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(t.nextLabel),
                )
              else
                FilledButton(
                  key: const ValueKey('onboarding-get-started'),
                  onPressed: onDone,
                  style: primary,
                  child: Text(t.onboardingGetStarted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
