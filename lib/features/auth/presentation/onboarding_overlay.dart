/// The intro carousel — shown once per device (stored independently of the
/// session) to a signed-out visitor, as soon as the app is ready (storage open,
/// session restored). Two pages: finding a doctor and booking, then records,
/// documents and PDF report explanations. Skip / Get Started save completion
/// and reveal the sign-in screen already routed underneath, so a protected
/// deep link's `?from=` destination survives.
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

class _OnboardingPage {
  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.body,
  });

  final _Illustration illustration;
  final String title;
  final String body;
}

/// Readable content width on tablets and desktops.
const double _maxContentWidth = 560;

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

  void _next() => unawaited(
    _controller.nextPage(
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
    final scheme = Theme.of(context).colorScheme;
    final palette = PatientPalette.of(context);
    final pages = [
      _OnboardingPage(
        illustration: const _Illustration(
          center: _BookingArt(),
          chips: [
            (Icons.person_search_rounded, AlignmentDirectional(-.92, -.78)),
            (Icons.calendar_month_rounded, AlignmentDirectional(.9, -.62)),
            (Icons.schedule_rounded, AlignmentDirectional(.86, .74)),
          ],
        ),
        title: t.paOnboardBookTitle,
        body: t.paOnboardBookBody,
      ),
      _OnboardingPage(
        illustration: const _Illustration(
          center: _RecordsArt(),
          chips: [
            (Icons.science_outlined, AlignmentDirectional(-.9, -.7)),
            (Icons.medication_outlined, AlignmentDirectional(-.2, -.96)),
            (Icons.picture_as_pdf_outlined, AlignmentDirectional(.6, -.9)),
            (Icons.auto_awesome_rounded, AlignmentDirectional(.92, -.2)),
          ],
        ),
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
                  // ellipsis gets a bounded width to shrink against on a
                  // 360dp-wide phone.
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
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    Space.sm,
                    Space.lg,
                    Space.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        container: true,
                        label: t.onboardingProgress(_page + 1, pages.length),
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            for (final (i, _) in pages.indexed)
                              AnimatedContainer(
                                duration: Motion.fast,
                                margin: const EdgeInsetsDirectional.only(
                                  end: Space.xxs + 2,
                                ),
                                width: i == _page ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _page
                                      ? palette.action
                                      : scheme.outlineVariant,
                                  borderRadius: Radii.pill,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.lg),
                      if (last)
                        FilledButton(
                          key: const ValueKey('onboarding-get-started'),
                          onPressed: _finish,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                          child: Text(t.onboardingGetStarted),
                        )
                      else
                        Row(
                          children: [
                            Flexible(
                              child: FilledButton(
                                key: const ValueKey('onboarding-skip'),
                                onPressed: _finish,
                                style: FilledButton.styleFrom(
                                  backgroundColor: palette.softAccent,
                                  foregroundColor: palette.onSoftAccent,
                                  minimumSize: const Size(112, 56),
                                ),
                                child: Text(t.onboardingSkip),
                              ),
                            ),
                            const Spacer(),
                            Semantics(
                              button: true,
                              label: t.nextLabel,
                              excludeSemantics: true,
                              onTap: _next,
                              child: FilledButton(
                                key: const ValueKey('onboarding-next'),
                                onPressed: _next,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(64, 56),
                                  padding: EdgeInsets.zero,
                                ),
                                // arrow_forward mirrors itself in RTL.
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
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
    return LayoutBuilder(
      builder: (context, c) {
        // The art takes up to half the height but never squeezes the text:
        // on a short screen or at large text sizes the page scrolls instead.
        final artHeight = (c.maxHeight * .5).clamp(140.0, 340.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Space.md),
                  SizedBox(
                    height: artHeight,
                    width: double.infinity,
                    child: ExcludeSemantics(child: page.illustration),
                  ),
                  const SizedBox(height: Space.xl),
                  Text(
                    page.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    page.body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: Space.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Original MyHealth artwork: a soft blue panel, a central motif and small
/// floating icon tiles. Built from vectors so it follows the theme, mirrors
/// in RTL and scales without assets.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.center, required this.chips});

  final Widget center;
  final List<(IconData, AlignmentDirectional)> chips;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.softAccent.withValues(alpha: .55),
        borderRadius: Radii.cardLarge,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final unit = c.biggest.shortestSide;
          final chip = (unit * .2).clamp(36.0, 60.0);
          return Stack(
            children: [
              Center(
                child: SizedBox.square(dimension: unit * .72, child: center),
              ),
              for (final (icon, align) in chips)
                Align(
                  alignment: align,
                  child: Container(
                    width: chip,
                    height: chip,
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(chip * .3),
                      border: Border.all(color: palette.divider),
                      boxShadow: Shadows.e1,
                    ),
                    child: Icon(icon, size: chip * .5, color: palette.action),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A phone-like card listing appointment slots, one picked and confirmed.
class _BookingArt extends StatelessWidget {
  const _BookingArt();

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final w = h * .62;
        Widget slot({required bool picked}) => Container(
          height: h * .11,
          margin: EdgeInsets.only(top: h * .045),
          padding: EdgeInsets.symmetric(horizontal: w * .08),
          decoration: BoxDecoration(
            color: picked ? palette.action : palette.softAccent,
            borderRadius: BorderRadius.circular(h * .04),
          ),
          alignment: AlignmentDirectional.centerEnd,
          child: picked
              ? Icon(
                  Icons.check_circle_rounded,
                  color: palette.onAction,
                  size: h * .075,
                )
              : null,
        );
        return Center(
          child: Container(
            width: w,
            height: h,
            padding: EdgeInsets.all(w * .1),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(h * .1),
              border: Border.all(color: palette.divider, width: 2),
              boxShadow: Shadows.e2,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: h * .1,
                  backgroundColor: palette.softAccent,
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: palette.action,
                    size: h * .1,
                  ),
                ),
                slot(picked: false),
                slot(picked: true),
                slot(picked: false),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A records folder holding a document.
class _RecordsArt extends StatelessWidget {
  const _RecordsArt();

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.biggest.shortestSide;
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.folder_rounded, size: s, color: palette.action),
            Padding(
              padding: EdgeInsets.only(top: s * .12),
              child: Container(
                width: s * .34,
                height: s * .34,
                decoration: BoxDecoration(
                  color: palette.card,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: s * .2,
                  color: palette.action,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
