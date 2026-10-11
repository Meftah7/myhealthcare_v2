/// Patient Home (approved blue rebuild). Required order:
///   1. header (guest sign-in pill, or greeting + account actions)
///   2. compact care alerts / upcoming appointments (signed in only)
///   3. the assistance / report hero card
///   4. paged quick tools
///   5. Services heading + View All + horizontal service cards
///   6. Quick Access — every relocated patient feature, in this same scroll.
///
/// Guests never trigger patient-specific providers: the private sections are
/// only built when a patient is signed in.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../billing/application/billing_providers.dart';
import '../../care/application/care_providers.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../service_catalog/application/catalog_dispatcher.dart';
import '../../service_catalog/domain/patient_catalog.dart';
import '../../service_catalog/presentation/catalog_widgets.dart';
import '../../settings/presentation/language_icon_toggle.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';
import 'needs_attention_strip.dart';
import 'notifications_button.dart';
import 'upcoming_appointment_carousel.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final _scroll = ScrollController();
  ValueNotifier<int>? _signal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-tapping the Home tab scrolls back to the top (shell signal).
    final signal = ScrollToTopSignal.maybeOf(context);
    if (identical(signal, _signal)) return;
    _signal?.removeListener(_toTop);
    _signal = signal?..addListener(_toTop);
  }

  @override
  void dispose() {
    _signal?.removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (!_scroll.hasClients) return;
    if (Motion.reduced(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: Motion.slow, curve: Motion.standard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final signedIn = user != null && user.role == UserRole.patient;

    return PatientPageScaffold(
      controller: _scroll,
      onRefresh: signedIn
          ? () async {
              ref
                ..invalidate(patientThreadsProvider)
                ..invalidate(patientInvoicesProvider)
                ..invalidate(patientPaymentsProvider)
                ..invalidate(incomingFamilyRequestsProvider)
                ..invalidate(patientAppointmentsProvider)
                ..invalidate(patientProfileProvider);
            }
          : null,
      header: signedIn ? const _SignedInHeader() : const _GuestHeader(),
      children: [
        // 2. Care alerts — private, signed-in only.
        if (signedIn) ...[
          const _AllergyAlert(),
          const NeedsAttentionStrip(),
          const _UpcomingAppointments(),
        ],

        // 3. Hero.
        const SizedBox(height: Space.md),
        _HeroCard(signedIn: signedIn),

        // 4. Quick tools.
        const SizedBox(height: Space.lg),
        QuickToolsPager(
          pages: [PatientCatalog.quickTools, PatientCatalog.moreTools],
        ),

        // 5. Services.
        SectionHeading(
          t.paServices,
          actionLabel: t.paViewAll,
          onAction: () => context.go(AppRoutes.patientServices),
        ),
        ServiceCarousel(items: PatientCatalog.promotions),

        // 6. Quick Access — directly below the Services carousel.
        const SizedBox(height: Space.sm),
        const QuickAccessSection(),
      ],
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final palette = PatientPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const ValueKey('guest-login'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.softAccent,
                  foregroundColor: palette.onSoftAccent,
                  minimumSize: const Size(0, 48),
                ),
                onPressed: () => goToSignIn(context),
                icon: const Icon(Icons.person_outline),
                label: Text(
                  t.paLoginOrRegister,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const LanguageIconToggle(),
          const ThemeModeIconToggle(),
        ],
      ),
    );
  }
}

class _SignedInHeader extends ConsumerWidget {
  const _SignedInHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final user = ref.watch(currentUserProvider);
    final name = user?.fullName ?? t.greetingFallbackName;
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: t.paMyProfile,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go(AppRoutes.patientSettings),
              child: SizedBox.square(
                dimension: 48,
                child: CircleAvatar(
                  backgroundColor: palette.softAccent,
                  foregroundColor: palette.onSoftAccent,
                  child: Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting(name.split(' ').first),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
          const NotificationsButton(),
          const LanguageIconToggle(),
          const ThemeModeIconToggle(),
        ],
      ),
    );
  }
}

/// The white hero card. Guests get care discovery (specialty guidance);
/// signed-in patients get the PDF report explanation. The two stay separate
/// use cases — report chat is never presented as symptom diagnosis.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final title = signedIn ? t.paHeroReportTitle : t.paHeroGuestTitle;
    final body = signedIn ? t.paHeroReportBody : t.paHeroGuestBody;
    final cta = signedIn ? t.paHeroReportCta : t.paHeroGuestCta;
    return SurfaceCard(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.md),
              _HeroArt(
                icon: signedIn
                    ? Icons.document_scanner_outlined
                    : Icons.health_and_safety_outlined,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          PrimaryActionButton(
            label: cta,
            onPressed: () => signedIn
                ? startReportExplanation(context, ref)
                : context.push(AppRoutes.patientSpecialtyGuide),
          ),
        ],
      ),
    );
  }
}

/// Original vector illustration: layered soft-blue shapes around a glyph.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = PatientPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.softAccent,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            PositionedDirectional(
              top: 6,
              end: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: palette.successContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.card, width: 2),
                ),
              ),
            ),
            Icon(icon, size: 42, color: palette.action),
          ],
        ),
      ),
    );
  }
}

/// A compact allergy strip, shown only when allergies are on file.
class _AllergyAlert extends ConsumerWidget {
  const _AllergyAlert();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allergies =
        ref.watch(patientProfileProvider).valueOrNull?.allergies ??
        const <String>[];
    if (allergies.isEmpty) return const SizedBox.shrink();
    final palette = PatientPalette.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: SurfaceCard(
        onTap: () => context.go(AppRoutes.patientAllergies),
        color: palette.dangerContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: palette.danger),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.allergiesInline(allergies.join(', ')),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Upcoming appointments, shown only when there are any (Quick Access and
/// the Appointments tab cover the empty case).
class _UpcomingAppointments extends ConsumerWidget {
  const _UpcomingAppointments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    return ref
        .watch(patientAppointmentsProvider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: Space.sm),
            child: LoadingSkeleton(height: 120),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: ErrorStateView(
              message: t.couldNotLoadAppointments,
              onRetry: () => ref.invalidate(patientAppointmentsProvider),
            ),
          ),
          data: (list) {
            final active =
                list
                    .where(
                      (a) =>
                          (a.status == AppointmentStatus.booked ||
                              a.status == AppointmentStatus.confirmed) &&
                          a.slotEnd.isAfter(DateTime.now()),
                    )
                    .toList()
                  ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
            if (active.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(
                  t.sectionUpcomingAppointments,
                  actionLabel: t.paViewAll,
                  onAction: () => context.go(AppRoutes.patientAppointments),
                ),
                UpcomingAppointmentCarousel(
                  appointments: active,
                  doctorNames: {
                    for (final entry in doctors.entries)
                      entry.key: entry.value.name,
                  },
                ),
              ],
            );
          },
        );
  }
}
