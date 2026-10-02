/// Patient home (P2-07, redesign v3, Phase 6): a calm at-a-glance screen in
/// priority order — greeting, allergy alert, what needs the patient's
/// attention, the next appointment ticket(s) as the anchor, a health
/// snapshot, then booking and quick actions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/quick_actions.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../billing/application/billing_providers.dart';
import '../../care/application/care_providers.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import 'needs_attention_strip.dart';

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
      stagger: true,
      hero: true,
      heroOverline: greeting(firstName),
      title: user?.fullName ?? t.greetingFallbackName,
      actions: const [PatientTopActions()],
      onRefresh: () async {
        ref
          ..invalidate(patientThreadsProvider)
          ..invalidate(patientInvoicesProvider)
          ..invalidate(patientPaymentsProvider)
          ..invalidate(incomingFamilyRequestsProvider)
          ..invalidate(patientAppointmentsProvider)
          ..invalidate(patientMedicationsProvider)
          ..invalidate(patientVitalsProvider);
      },
      children: [
        // Urgent clinical information first, then what is waiting on the
        // patient (hidden when nothing is, shown as an error when it could
        // not be checked).
        const _AllergyAlert(),
        const NeedsAttentionStrip(),

        // The screen's anchor (Phase 6): the next appointment, stable and
        // first — what's happening before what you can do.
        SectionHeader(t.sectionUpcomingAppointments, overline: true),
        const _UpcomingAppointment(),

        SectionColumns(
          primary: [
            SectionHeader(t.sectionQuickActions, overline: true),
            const _QuickActions(),
          ],
          secondary: [
            SectionHeader(t.sectionYourHealth, overline: true),
            _HealthSnapshot(),
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
    return NavRow(
      icon: Icons.bolt,
      title: t.quickAppointmentTitle,
      subtitle: t.quickAppointmentSubtitle,
      onTap: () => _chooseUrgency(context),
    );
  }

  Future<void> _chooseUrgency(BuildContext context) async {
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
    await _bookUrgent(context);
  }

  Future<void> _bookUrgent(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final schedule = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.urgencyUrgentTitle),
        content: Text(t.sendNonUrgentQuestionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.backButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.continueButton),
          ),
        ],
      ),
    );
    if (schedule == true && context.mounted) {
      context.go(AppRoutes.patientAppointments);
    }
    // The loader sits on the root navigator — close it there, not on the shell
    // branch's navigator (which would pop Home and leave a blank screen).
  }
}

class _HealthSnapshot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final appts = ref.watch(patientAppointmentsProvider);
    final meds = ref.watch(patientMedicationsProvider);

    if (appts.hasError || meds.hasError) {
      return ErrorStateView(
        message: appts.hasError
            ? t.couldNotLoadAppointments
            : t.couldNotLoadMedications,
        onRetry: () {
          ref.invalidate(patientAppointmentsProvider);
          ref.invalidate(patientMedicationsProvider);
        },
      );
    }
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
      child: appts.isLoading || meds.isLoading
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
        Icons.calendar_month_outlined,
        t.bookAppointmentAction,
        AppRoutes.patientBook,
        true,
      ),
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

    Widget tile((IconData, String, String, bool) item) {
      final (icon, label, route, push) = item;
      return QuickActionTile(
        icon: icon,
        label: label,
        onTap: () {
          if (push) {
            unawaited(context.push(route));
          } else {
            context.go(route);
          }
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuickActionGrid(
          children: [
            for (final i in [0, 3, 6]) tile(items[i]),
          ],
        ),
        const SizedBox(height: Space.xs),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: Space.sm),
          title: Text(
            t.moreActionsTooltip,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          children: [
            QuickActionGrid(
              children: [
                for (final (i, item) in items.indexed)
                  if (![0, 3, 6].contains(i)) tile(item),
              ],
            ),
            const SizedBox(height: Space.sm),
            const _QuickAppointmentAction(),
          ],
        ),
      ],
    );
  }
}

/// The patient's booked appointments as an auto-advancing card carousel
/// (redesign v3, matching the FirstSemMyHealth "active ticket" strip): a
/// prominent ticket number, the room, date/time and doctor, with page dots
/// and a "1 of N" count. It never moves on its own — an appointment card
/// has to stay put long enough to read; the user swipes or uses the arrows.
class _UpcomingAppointment extends ConsumerWidget {
  const _UpcomingAppointment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return ref
        .watch(patientAppointmentsProvider)
        .when(
          loading: () => const LoadingSkeleton(height: 180),
          error: (e, _) => ErrorStateView(
            message: t.couldNotLoadAppointments,
            onRetry: () => ref.invalidate(patientAppointmentsProvider),
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
            if (active.isEmpty) {
              return NavRow(
                icon: Icons.event_available_outlined,
                title: t.noUpcomingAppointments,
                subtitle: t.tapToBookVisit,
                onTap: () => context.push(AppRoutes.patientBook),
              );
            }
            final appointment = active.first;
            final detail = AppRoutes.patientAppointmentDetail(appointment.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  color: scheme.brightness == Brightness.light
                      ? AppColors.seed
                      : AppColors.brandBlue,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.sectionUpcomingAppointments,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        doctors[appointment.staffId]?.name ??
                            visitTypeLabel(appointment.visitType),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        '${fmtRelativeDay(appointment.slotStart)} · ${fmtTime(appointment.slotStart)} · ${t.roomNumber(appointment.roomNumber ?? t.none)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      if (appointment.bookedForName != null) ...[
                        const SizedBox(height: Space.xs),
                        Text(
                          t.bookedForName(appointment.bookedForName!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                      const SizedBox(height: Space.md),
                      Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.push(detail),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            icon: const Icon(
                              Icons.confirmation_number_outlined,
                              size: 18,
                            ),
                            label: Text(t.ticketOverline),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.go(AppRoutes.patientAppointments),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text(t.appointmentsTitle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.sm),
              ],
            );
          },
        );
  }
}
