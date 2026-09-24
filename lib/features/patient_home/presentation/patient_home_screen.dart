/// Patient home (P2-07, redesign v3 — patient dashboard rebuild): a calm
/// at-a-glance screen — greeting, quick appointment, a health snapshot,
/// quick actions, live appointment ticket(s).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../booking/application/appointment_confirmation.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../../quick_appointment/application/quick_appointment_providers.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final t = AppLocalizations.of(context)!;
    final firstName = (user?.fullName ?? t.greetingFallbackName)
        .split(' ')
        .first;

    return AppScaffold(
      titleWidget: const AppBrandLockup(),
      actions: const [PatientTopActions()],
      onRefresh: () async {
        ref
          ..invalidate(patientAppointmentsProvider)
          ..invalidate(patientMedicationsProvider)
          ..invalidate(patientVitalsProvider);
      },
      children: [
        PageGreeting(
          overline: fmtDate(DateTime.now()),
          greeting: greeting(firstName),
        ),
        const SizedBox(height: Space.lg),

        const _AllergyAlert(),

        // The screen's one saturated surface, and on a wide window the anchor
        // that spans both columns below it (DESIGN.md §1).
        const _QuickAppointmentAction(),

        // Split so the narrow reading order is unchanged — what's happening
        // (figures, then the ticket carousel) before what you can do.
        SectionColumns(
          primary: [
            SectionHeader(t.sectionYourHealth, overline: true),
            _HealthSnapshot(),
            SectionHeader(t.sectionUpcomingAppointments, overline: true),
            const _UpcomingCarousel(),
          ],
          secondary: [
            SectionHeader(t.sectionQuickActions, overline: true),
            const _QuickActions(),
          ],
        ),
      ],
    );
  }
}

enum _QuickChoice { urgent, normal }

/// The Home "Quick Appointment" action: choose Urgent (auto-routed to the
/// nearest — i.e. soonest-available — doctor, any department) or Normal
/// (the standard booking flow).
class _QuickAppointmentAction extends ConsumerWidget {
  const _QuickAppointmentAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return GradientHeroCard(
      icon: Icons.bolt,
      title: t.quickAppointmentTitle,
      subtitle: t.quickAppointmentSubtitle,
      onTap: () => _chooseUrgency(context, ref),
    );
  }

  Future<void> _chooseUrgency(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_QuickChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final t = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.quickAppointmentTitle,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        t.quickAppointmentSheetQuestion,
                        style: Theme.of(sheetContext).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                AppEntrance(
                  index: 1,
                  child: NavRow(
                    icon: Icons.bolt,
                    title: t.urgencyUrgentTitle,
                    subtitle: t.urgencyUrgentSubtitle,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_QuickChoice.urgent),
                  ),
                ),
                const SizedBox(height: Space.sm),
                AppEntrance(
                  index: 2,
                  child: NavRow(
                    icon: Icons.event_available_outlined,
                    title: t.urgencyNormalTitle,
                    subtitle: t.urgencyNormalSubtitle,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_QuickChoice.normal),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;

    if (choice == _QuickChoice.normal) {
      context.go(AppRoutes.patientAppointments);
      return;
    }
    await _bookUrgent(context, ref);
  }

  Future<void> _bookUrgent(BuildContext context, WidgetRef ref) async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
    final result = await ref
        .read(quickAppointmentControllerProvider)
        .bookUrgent();
    if (!context.mounted) return;
    // The loader sits on the root navigator — close it there, not on the shell
    // branch's navigator (which would pop Home and leave a blank screen).
    Navigator.of(context, rootNavigator: true).pop();

    switch (result) {
      case Ok():
        ref.invalidate(patientAppointmentsProvider);
        ref
            .read(appointmentConfirmationProvider.notifier)
            .show(AppLocalizations.of(context)!.onSchedule);
      case Err(:final failure):
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _HealthSnapshot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final appts = ref.watch(patientAppointmentsProvider);
    final meds = ref.watch(patientMedicationsProvider);

    final all = appts.valueOrNull ?? const <Appointment>[];

    // Ticket — how many upcoming appointments the patient is holding.
    final ticketCount = all.where((a) => a.isUpcoming).length;

    final activeMeds = meds.valueOrNull?.where((m) => m.isCurrent).length ?? 0;

    // Last visit — the most recent appointment that has actually happened.
    final lastVisit =
        (all
                .where(
                  (a) =>
                      a.status == AppointmentStatus.completed ||
                      (a.slotEnd.isBefore(DateTime.now()) &&
                          a.status != AppointmentStatus.cancelled &&
                          a.status != AppointmentStatus.noShow),
                )
                .toList()
              ..sort((a, b) => b.slotStart.compareTo(a.slotStart)))
            .firstOrNull;
    final lastVisitLabel = lastVisit == null
        ? t.none
        : fmtShortDate(lastVisit.slotStart);

    return AppReveal(
      child: appts.isLoading && meds.isLoading
          ? const LoadingSkeleton(key: ValueKey('loading'), height: 92)
          : MetricRow(
              key: const ValueKey('data'),
              children: [
                MetricTile(
                  value: '$ticketCount',
                  label: t.metricTicket,
                  icon: Icons.confirmation_number_outlined,
                  onTap: () => context.go(AppRoutes.patientAppointments),
                ),
                MetricTile(
                  value: '$activeMeds',
                  label: t.metricMedicine,
                  icon: Icons.medication_outlined,
                  onTap: () => context.go(AppRoutes.patientMedications),
                ),
                MetricTile(
                  value: lastVisitLabel,
                  label: t.metricLastVisit,
                  icon: Icons.event_available_outlined,
                  onTap: () => context.go(AppRoutes.patientAppointments),
                ),
              ],
            ),
    );
  }
}

/// A slim red strip shown only when the patient has allergies on file — it
/// rides above the fold so a clinician glancing at the phone can't miss it.
class _AllergyAlert extends ConsumerWidget {
  const _AllergyAlert();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allergies =
        ref.watch(patientProfileProvider).valueOrNull?.allergies ??
        const <String>[];
    if (allergies.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: AppCard(
        onTap: () => context.push(AppRoutes.patientAllergies),
        color: scheme.errorContainer,
        borderColor: scheme.error.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.allergiesInline(allergies.join(', ')),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: kTrailingChevronSize,
              color: scheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // (icon, label, route, push) — `push` keeps the nav bar and adds a back
    // button for section screens that aren't a nav destination of their own.
    final items = [
      (
        Icons.favorite_outline,
        t.quickActionVitals,
        AppRoutes.patientVitals,
        false,
      ),
      (
        Icons.medication_outlined,
        t.quickActionMedications,
        AppRoutes.patientMedications,
        false,
      ),
      (
        Icons.forum_outlined,
        t.quickActionAskDoctor,
        AppRoutes.patientMessages,
        true,
      ),
      (
        Icons.groups_outlined,
        t.quickActionVisitedDoctors,
        AppRoutes.patientVisitedDoctors,
        true,
      ),
      (
        Icons.event_busy_outlined,
        t.quickActionSickLeave,
        AppRoutes.patientSickLeave,
        true,
      ),
      (
        Icons.add_home_outlined,
        t.quickActionHomeCare,
        AppRoutes.patientHomeVisit,
        true,
      ),
      (
        Icons.payments_outlined,
        t.paymentsTitle,
        AppRoutes.patientBilling,
        false,
      ),
    ];

    return TileGrid(
      children: [
        for (final (icon, label, route, push) in items)
          NavRow(
            icon: icon,
            title: label,
            tinted: true,
            onTap: () {
              if (push) {
                unawaited(context.push(route));
              } else {
                context.go(route);
              }
            },
          ),
      ],
    );
  }
}

/// The patient's booked appointments as an auto-advancing card carousel
/// (redesign v3, matching the FirstSemMyHealth "active ticket" strip): a
/// prominent ticket number, the room, date/time and doctor, with page dots
/// and a "1 of N" count. Slides on its own every 5 seconds.
class _UpcomingCarousel extends ConsumerStatefulWidget {
  const _UpcomingCarousel();

  @override
  ConsumerState<_UpcomingCarousel> createState() => _UpcomingCarouselState();
}

class _UpcomingCarouselState extends ConsumerState<_UpcomingCarousel> {
  static const _slideEvery = Duration(seconds: 5);

  // A large mid-point so the PageView can scroll forever in both directions;
  // the real card is `rawPage % count`, so advancing past the last one brings
  // the first back in from the right instead of snapping backwards.
  static const _origin = 100000;

  final _controller = PageController(
    initialPage: _origin,
    viewportFraction: 0.92,
  );
  Timer? _timer;
  int _index = 0;
  int _count = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cached here (not read inside `_restartTimer`) because that runs from a
    // post-frame callback, which can fire after this element is deactivated
    // (e.g. mid teardown) — looking up an InheritedWidget at that point
    // throws "Looking up a deactivated widget's ancestor is unsafe".
    _reduceMotion = Motion.reduced(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_count <= 1) return;
    // An auto-advancing carousel is motion the user didn't ask for; when the
    // OS says "reduce motion", it stops advancing and the arrows take over.
    if (_reduceMotion) return;
    _timer = Timer.periodic(_slideEvery, (_) => _step(1));
  }

  int _rawPage() =>
      _controller.hasClients ? (_controller.page ?? _origin).round() : _origin;

  /// Move [delta] cards in that direction — always animates the way you'd
  /// expect (next = slide left, first-after-last comes from the right).
  void _step(int delta) {
    if (_count == 0 || !_controller.hasClients) return;
    unawaited(
      _controller.animateToPage(
        _rawPage() + delta,
        duration: Motion.medium,
        curve: Motion.standard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final appts = ref.watch(patientAppointmentsProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};

    return appts.when(
      loading: () => const LoadingSkeleton(height: 200),
      error: (e, _) => InlineBanner.error(t.couldNotLoadAppointments),
      data: (list) {
        final active =
            list
                .where(
                  (a) =>
                      a.status == AppointmentStatus.booked ||
                      a.status == AppointmentStatus.confirmed,
                )
                .toList()
              ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

        if (active.isEmpty) {
          _timer?.cancel();
          return NavRow(
            icon: Icons.event_available_outlined,
            title: t.noUpcomingAppointments,
            subtitle: t.tapToBookVisit,
            onTap: () => context.go(AppRoutes.patientBook),
          );
        }

        if (active.length != _count) {
          _count = active.length;
          if (_index >= _count) _index = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _restartTimer();
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  t.carouselPosition(_index + 1, active.length),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: kTabularFigures,
                  ),
                ),
                const Spacer(),
                if (active.length > 1) ...[
                  // The chevrons point toward where the card actually is —
                  // "previous" is against reading direction, "next" with it —
                  // so they swap in RTL rather than staying fixed left/right.
                  IconButton(
                    tooltip: t.previousAppointment,
                    onPressed: () => _step(-1),
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_right
                          : Icons.chevron_left,
                    ),
                  ),
                  IconButton(
                    tooltip: t.nextAppointment,
                    onPressed: () => _step(1),
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Space.xs),
            SizedBox(
              height: _BigTicketCard.heightFor(
                context,
                active,
                doctorName: (a) => doctors[a.staffId]?.name,
              ),
              // The auto-advancing pager animates on its own; keep its repaints
              // off the rest of Home.
              child: RepaintBoundary(
                child: PageView.builder(
                  controller: _controller,
                  // No itemCount → scrolls forever; the card shown is
                  // `rawPage % count`, so the list wraps in either direction.
                  onPageChanged: (raw) {
                    setState(() => _index = ((raw % _count) + _count) % _count);
                    _restartTimer();
                  },
                  itemBuilder: (context, raw) {
                    if (_count == 0) return const SizedBox.shrink();
                    final i = ((raw % _count) + _count) % _count;
                    final appt = active[i];
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.sm),
                      child: _BigTicketCard(
                        appt: appt,
                        doctorName: doctors[appt.staffId]?.name,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (active.length > 1) ...[
              const SizedBox(height: Space.sm),
              // Position readout, not a control: a 7dp dot can never carry a
              // 48dp tap target, and the arrows above plus the swipe already
              // move the carousel. The "n of m" line above is the accessible
              // equivalent, so these are hidden from semantics.
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < active.length; i++)
                      AnimatedContainer(
                        duration: Motion.medium,
                        curve: Motion.standard,
                        margin: const EdgeInsets.symmetric(
                          horizontal: Space.xxs / 2,
                        ),
                        width: i == _index ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: Radii.pill,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// One slide of [_UpcomingCarousel] — the ticket number is the headline.
class _BigTicketCard extends StatelessWidget {
  const _BigTicketCard({required this.appt, this.doctorName});

  final Appointment appt;
  final String? doctorName;

  /// The tallest card in [appts], measured at the current text scale.
  ///
  /// A `PageView` needs one height for every page, and the old fixed 208dp
  /// clipped as soon as the OS text size went up. This sizes to the tallest
  /// card instead.
  ///
  /// The line heights are **measured from the actual strings the card will
  /// render** — same style, same [TextScaler], same font resolution as the
  /// real render — not assumed from nominal font sizes. The bundled
  /// Lexend/Inter carry no Arabic glyphs, so Arabic falls back to platform
  /// fonts with different line metrics; measuring the real text keeps the
  /// height exact in every locale, on every platform, at every text scale.
  static double heightFor(
    BuildContext context,
    List<Appointment> appts, {
    String? Function(Appointment appt)? doctorName,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final direction = Directionality.of(context);

    // Height of [text] on one line, laid out exactly as the card will lay it
    // out (this is the same style resolution RenderParagraph performs).
    double textHeight(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );

    // A detail row never renders shorter than its 16dp leading icon.
    double rowHeight(String text) =>
        math.max(16.0, textHeight(text, bodyStyle));

    double detailFor(Appointment a) {
      final doctor = doctorName?.call(a) ?? visitTypeLabel(a.visitType);
      final rows = [
        fmtRelativeDay(a.slotStart),
        fmtTime(a.slotStart),
        t.roomNumber(a.roomNumber ?? t.none),
        doctor,
        if (a.bookedForName != null) t.bookedForName(a.bookedForName!),
      ];
      var height = 0.0;
      for (final (i, row) in rows.indexed) {
        if (i > 0) height += Space.xs;
        height += rowHeight(row);
      }
      return height;
    }

    // The ticket column: overline + the big number + the status pill (whose
    // own vertical padding is Space.xxs on each side, and whose 15dp icon
    // can outgrow its label).
    double ticketFor(Appointment a) {
      final pillLabel = math.max(
        15.0,
        textHeight(a.status.label(context), theme.textTheme.labelMedium),
      );
      return textHeight(
            t.ticketOverline,
            theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
          ) +
          2 +
          textHeight(
            a.ticketTag ?? '—',
            theme.textTheme.displaySmall?.copyWith(
              fontFeatures: kTabularFigures,
              height: 1,
            ),
          ) +
          Space.xs +
          pillLabel +
          Space.xxs * 2;
    }

    var height = 0.0;
    for (final a in appts) {
      height = math.max(height, math.max(detailFor(a), ticketFor(a)));
    }
    return Space.lg * 2 + height;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;

    return AppCard(
      elevated: true,
      color: scheme.primaryContainer,
      // Tinted edge, not the neutral hairline — a grey line around a lavender
      // card reads as a mistake.
      borderColor: scheme.onPrimaryContainer.withValues(alpha: 0.12),
      onTap: () => context.go(AppRoutes.patientAppointments),
      child: Row(
        // Stretch so the rule between the two halves is exactly as tall as the
        // card, at any text scale, instead of a hard-coded 120dp.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.ticketOverline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                appt.ticketTag ?? '—',
                // w500 is the ceiling for display type (DESIGN.md §3.3) — this
                // app doesn't shout, and the size is already doing the work.
                style: theme.textTheme.displaySmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontFeatures: kTabularFigures,
                  height: 1,
                ),
              ),
              const SizedBox(height: Space.xs),
              AppointmentStatusPill(appt.status, dense: true),
            ],
          ),
          const SizedBox(width: Space.md),
          Container(
            width: 1,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.2),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _line(
                  context,
                  Icons.calendar_today_outlined,
                  fmtRelativeDay(appt.slotStart),
                ),
                const SizedBox(height: Space.xs),
                _line(
                  context,
                  Icons.schedule_outlined,
                  fmtTime(appt.slotStart),
                ),
                const SizedBox(height: Space.xs),
                _line(
                  context,
                  Icons.meeting_room_outlined,
                  t.roomNumber(appt.roomNumber ?? t.none),
                ),
                const SizedBox(height: Space.xs),
                _line(
                  context,
                  Icons.person_outline,
                  doctorName ?? visitTypeLabel(appt.visitType),
                ),
                if (appt.bookedForName != null) ...[
                  const SizedBox(height: Space.xs),
                  _line(
                    context,
                    Icons.people_outline,
                    t.bookedForName(appt.bookedForName!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onPrimaryContainer;
    return Row(
      children: [
        Icon(icon, size: 16, color: fg.withValues(alpha: 0.8)),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
