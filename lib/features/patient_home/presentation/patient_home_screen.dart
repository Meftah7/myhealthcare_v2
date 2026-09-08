/// Patient home (P2-07, redesign v3 — patient dashboard rebuild): a calm
/// at-a-glance screen — greeting, quick appointment, a health snapshot,
/// quick actions, live appointment ticket(s).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import '../../booking/application/appointment_confirmation.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../../quick_appointment/application/quick_appointment_providers.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    final size = WindowSize.of(context);
    final gutter = size.gutter;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: gutter,
        title: const _AppBarLockup(),
        actions: const [PatientTopActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(patientAppointmentsProvider)
            ..invalidate(patientMedicationsProvider)
            ..invalidate(patientVitalsProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                Space.md,
                gutter,
                Space.xxl,
              ),
              children: [
                // Date above the greeting: the small line sets context, the
                // big line is the thing you actually read.
                Text(
                  fmtDate(DateTime.now()).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  greeting(firstName),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: Space.lg),

                const _AllergyAlert(),

                const _QuickAppointmentAction(),
                const SizedBox(height: Space.lg),

                const SectionHeader('Your health', overline: true),
                _HealthSnapshot(),
                const SizedBox(height: Space.lg),

                const SectionHeader('Upcoming appointments', overline: true),
                const _UpcomingCarousel(),
                const SizedBox(height: Space.lg),

                const SectionHeader('Quick actions', overline: true),
                const _QuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarLockup extends StatelessWidget {
  const _AppBarLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 26),
        const SizedBox(width: Space.xs),
        // Flexible so the wordmark ellipsises on a narrow phone rather than
        // colliding with the three action buttons.
        Flexible(
          child: Text(
            'MyHealth Care',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
    // The screen's one saturated surface — the primary action gets the brand
    // gradient, everything below it stays neutral (DESIGN.md §1).
    return GradientHeroCard(
      icon: Icons.bolt,
      title: 'Quick appointment',
      subtitle: 'Urgent or normal — get seen sooner',
      onTap: () => _chooseUrgency(context, ref),
    );
  }

  Future<void> _chooseUrgency(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_QuickChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick appointment',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: Space.xs),
              Text(
                'How urgent is this visit?',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.lg),
              _ChoiceTile(
                icon: Icons.bolt,
                title: 'Urgent',
                subtitle: 'Auto-route me to the soonest available doctor',
                onTap: () => Navigator.of(sheetContext).pop(_QuickChoice.urgent),
              ),
              const SizedBox(height: Space.sm),
              _ChoiceTile(
                icon: Icons.event_available_outlined,
                title: 'Normal',
                subtitle: 'Choose a department, doctor and time myself',
                onTap: () => Navigator.of(sheetContext).pop(_QuickChoice.normal),
              ),
            ],
          ),
        ),
      ),
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
    final result = await ref.read(quickAppointmentControllerProvider).bookUrgent();
    if (!context.mounted) return;
    // The loader sits on the root navigator — close it there, not on the shell
    // branch's navigator (which would pop Home and leave a blank screen).
    Navigator.of(context, rootNavigator: true).pop();

    switch (result) {
      case Ok():
        ref.invalidate(patientAppointmentsProvider);
        ref
            .read(appointmentConfirmationProvider.notifier)
            .show("You're on the schedule");
      case Err(:final failure):
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _HealthSnapshot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ? '—'
        : fmtShortDate(lastVisit.slotStart);

    if (appts.isLoading && meds.isLoading) {
      return const LoadingSkeleton(height: 92);
    }

    return Row(
      children: [
        Expanded(
          child: MetricTile(
            value: '$ticketCount',
            label: 'Ticket',
            icon: Icons.confirmation_number_outlined,
            onTap: () => context.go(AppRoutes.patientAppointments),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: MetricTile(
            value: '$activeMeds',
            label: 'Medicine',
            icon: Icons.medication_outlined,
            onTap: () => context.go(AppRoutes.patientMedications),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: MetricTile(
            value: lastVisitLabel,
            label: 'Last visit',
            icon: Icons.event_available_outlined,
            onTap: () => context.go(AppRoutes.patientAppointments),
          ),
        ),
      ],
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
                'Allergies: ${allergies.join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onErrorContainer),
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
    // (icon, label, route, push) — `push` keeps the nav bar and adds a back
    // button for section screens that aren't a nav destination of their own.
    const items = [
      (Icons.favorite_outline, 'Vitals', AppRoutes.patientVitals, false),
      (
        Icons.medication_outlined,
        'Medications',
        AppRoutes.patientMedications,
        false,
      ),
      (
        Icons.forum_outlined,
        'Ask your doctor',
        AppRoutes.patientMessages,
        true,
      ),
      (
        Icons.groups_outlined,
        'Visited doctors',
        AppRoutes.patientVisitedDoctors,
        true,
      ),
      (
        Icons.event_busy_outlined,
        'Sick leave',
        AppRoutes.patientSickLeave,
        true,
      ),
      (
        Icons.add_home_outlined,
        'Home care',
        AppRoutes.patientHomeVisit,
        true,
      ),
      (Icons.receipt_long_outlined, 'Billing', AppRoutes.patientBilling, false),
    ];
    // Two tiles per row on a phone, three once there's room for them.
    return GridView.count(
      crossAxisCount: WindowSize.of(context).isCompact ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.sm,
      crossAxisSpacing: Space.sm,
      childAspectRatio: 2.6,
      children: [
        for (final (icon, label, route, push) in items)
          _ActionTile(icon: icon, label: label, route: route, push: push),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.route,
    this.push = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool push;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.sm,
      ),
      onTap: () {
        if (push) {
          unawaited(context.push(route));
        } else {
          context.go(route);
        }
      },
      child: Row(
        children: [
          // A tinted medallion rather than a bare glyph — it anchors the row
          // and reads as an object you can press.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: Radii.chip,
            ),
            child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              label.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
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

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_count <= 1) return;
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
    final appts = ref.watch(patientAppointmentsProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};

    return appts.when(
      loading: () => const LoadingSkeleton(height: 200),
      error: (e, _) => const InlineBanner.error('Could not load appointments.'),
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
          return AppCard(
            onTap: () => context.go(AppRoutes.patientBook),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming appointments',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Tap to book a visit',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
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
                  '${_index + 1} of ${active.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: kTabularFigures,
                  ),
                ),
                const Spacer(),
                if (active.length > 1) ...[
                  IconButton(
                    tooltip: 'Previous appointment',
                    onPressed: () => _step(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Next appointment',
                    onPressed: () => _step(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Space.xs),
            SizedBox(
              height: 208,
              // The auto-advancing pager animates on its own; keep its repaints
              // off the rest of Home.
              child: RepaintBoundary(
                child: PageView.builder(
                controller: _controller,
                // No itemCount → scrolls forever; the card shown is
                // `rawPage % count`, so the list wraps in either direction.
                onPageChanged: (raw) {
                  setState(
                    () => _index = ((raw % _count) + _count) % _count,
                  );
                  _restartTimer();
                },
                itemBuilder: (context, raw) {
                  if (_count == 0) return const SizedBox.shrink();
                  final i = ((raw % _count) + _count) % _count;
                  final appt = active[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: Space.sm),
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
                        margin: const EdgeInsets.symmetric(horizontal: 3),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (statusLabel, statusStyle) = switch (appt.status) {
      AppointmentStatus.confirmed => (
        'Confirmed',
        theme.clinicalStatus.riskLow,
      ),
      _ => ('Booked', null),
    };

    return AppCard(
      elevated: true,
      color: scheme.primaryContainer,
      // Tinted edge, not the neutral hairline — a grey line around a lavender
      // card reads as a mistake.
      borderColor: scheme.onPrimaryContainer.withValues(alpha: 0.12),
      onTap: () => context.go(AppRoutes.patientAppointments),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The number, large.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TICKET',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                appt.ticketTag ?? '—',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontFeatures: kTabularFigures,
                  height: 1,
                ),
              ),
              const SizedBox(height: Space.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusStyle?.container ?? scheme.surface,
                  borderRadius: Radii.pill,
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusStyle?.onContainer ?? scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: Space.md),
          Container(
            width: 1,
            height: 120,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.2),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                  'Room ${appt.roomNumber ?? '—'}',
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
                    'For ${appt.bookedForName}',
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
