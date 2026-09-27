/// My appointments (P4-16, P8-11): upcoming and past, grouped and labelled,
/// with cancel + reschedule on upcoming ones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../booking/presentation/booking_screen.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import 'slot_picker_sheet.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  static const _pageSize = 40;

  /// How many past visits to show — grows by [_pageSize] each time "Show
  /// more" is tapped, rather than silently hiding the rest with no way to
  /// see them.
  int _visiblePast = _pageSize;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appts = ref.watch(patientAppointmentsProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};

    return AppScaffold(
      title: t.appointmentsTitle,
      actions: const [PatientTopActions()],
      onRefresh: () async => ref.invalidate(patientAppointmentsProvider),
      children: [
        // The two ways in stay put while the list below them loads — there is
        // no reason to make someone wait on a query to book a visit.
        const _EntryButtons(),
        ...appts.when(
          loading: () => const [
            SizedBox(height: Space.md),
            SkeletonList(lines: 4),
          ],
          error: (e, _) => [
            const SizedBox(height: Space.xl),
            ErrorStateView(
              message: t.couldNotLoadAppointments,
              onRetry: () => ref.invalidate(patientAppointmentsProvider),
            ),
          ],
          data: (list) {
            final upcoming = list.where((a) => a.isUpcoming).toList()
              ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
            final past = list.where((a) => !a.isUpcoming).toList()
              ..sort((a, b) => b.slotStart.compareTo(a.slotStart));
            final visiblePast = past.take(_visiblePast).toList();
            final remaining = past.length - visiblePast.length;

            Widget card(Appointment a, {required bool upcoming}) => _ApptCard(
              a,
              upcoming: upcoming,
              doctor: doctors[a.staffId]?.name,
              department: departments[a.departmentId],
            );

            return [
              SectionHeader(t.upcomingCount(upcoming.length), overline: true),
              if (upcoming.isEmpty)
                _EmptyNote(t.nothingBookedNote)
              else
                CardColumns(
                  children: [for (final a in upcoming) card(a, upcoming: true)],
                ),

              SectionHeader(t.historyCount(past.length), overline: true),
              if (past.isEmpty)
                _EmptyNote(t.noPastVisitsNote)
              else ...[
                for (final entry in _byMonth(visiblePast).entries) ...[
                  _MonthLabel(entry.key),
                  CardColumns(
                    children: [
                      for (final a in entry.value) card(a, upcoming: false),
                    ],
                  ),
                ],
                if (remaining > 0) ...[
                  const SizedBox(height: Space.sm),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(
                        () => _visiblePast += _pageSize,
                      ),
                      child: Text(t.showOlderVisitsAction(remaining)),
                    ),
                  ),
                ],
              ],
            ];
          },
        ),
      ],
    );
  }

  static Map<DateTime, List<Appointment>> _byMonth(Iterable<Appointment> xs) {
    final out = <DateTime, List<Appointment>>{};
    for (final a in xs) {
      final key = DateTime(a.slotStart.year, a.slotStart.month);
      (out[key] ??= []).add(a);
    }
    return out;
  }
}

/// The Appointments entry point (redesign v2): "Book Now" jumps straight to
/// today's (or the soonest) open slots; "Schedule" keeps the date-picking
/// step for a later visit.
class _EntryButtons extends StatelessWidget {
  const _EntryButtons();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: EntryCard(
              icon: Icons.bolt_outlined,
              title: t.bookNowTitle,
              subtitle: t.bookNowSubtitle,
              filled: true,
              onTap: () =>
                  context.push(AppRoutes.patientBook, extra: BookingMode.now),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: EntryCard(
              icon: Icons.calendar_month_outlined,
              title: t.scheduleTitle,
              subtitle: t.scheduleSubtitle,
              onTap: () => context.push(
                AppRoutes.patientBook,
                extra: BookingMode.schedule,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel(this.month);
  final DateTime month;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
    child: Text(
      fmtMonthYear(month),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// A one-line "nothing here yet" note inside a section — the quiet sibling of
/// [EmptyState], which owns a whole screen.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _ApptCard extends ConsumerWidget {
  const _ApptCard(
    this.appt, {
    required this.upcoming,
    this.doctor,
    this.department,
  });

  final Appointment appt;
  final bool upcoming;
  final String? doctor;
  final String? department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final meta = [
      visitTypeLabel(appt.visitType),
      ?doctor,
      ?department,
    ].join('  ·  ');
    final ticketMeta = [
      t.ticketLabel(appt.ticketTag ?? t.none),
      t.roomNumber(appt.roomNumber ?? t.none),
    ].join('  ·  ');

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      onTap: () => context.push(AppRoutes.patientAppointmentDetail(appt.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upcoming
                          ? '${fmtRelativeDay(appt.slotStart)} · '
                                '${fmtTime(appt.slotStart)}'
                          : fmtDate(appt.slotStart),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (!upcoming)
                      Text(
                        fmtTime(appt.slotStart),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              AppointmentStatusPill(appt.status, dense: true),
            ],
          ),
          if (appt.bookedForName != null) ...[
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Space.xxs),
                Text(
                  t.bookedForName(appt.bookedForName!),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
          // Space.xs between the detail lines, not xxs: at 4dp the block read
          // as one dense paragraph rather than four separate facts.
          const SizedBox(height: Space.xs),
          Text(
            meta,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            ticketMeta,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (appt.reasonText != null) ...[
            const SizedBox(height: Space.xs),
            Text(appt.reasonText!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: Space.xs),
          Text(
            t.bookedOn(fmtDate(appt.bookedAt)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (upcoming && appt.riskBand != null) ...[
            const SizedBox(height: Space.sm),
            RiskBadge(appt.riskBand!),
          ],
          if (upcoming &&
              (appt.status == AppointmentStatus.booked ||
                  appt.status == AppointmentStatus.confirmed)) ...[
            const SizedBox(height: Space.sm),
            ApptActions(appt: appt),
          ],
        ],
      ),
    );
  }
}

/// The reschedule/cancel buttons, split out from [_ApptCard] so they can own
/// their own busy/error state — a card built by a stateless widget has
/// nowhere to hold "this request is in flight" or "it just failed".
class ApptActions extends ConsumerStatefulWidget {
  const ApptActions({required this.appt, super.key});

  final Appointment appt;

  @override
  ConsumerState<ApptActions> createState() => _ApptActionsState();
}

class _ApptActionsState extends ConsumerState<ApptActions> {
  bool _busy = false;

  Appointment get appt => widget.appt;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancel() async {
    if (_busy) return;
    final t = AppLocalizations.of(context)!;
    final ok = await confirm(
      context,
      title: t.cancelAppointmentTitle,
      message: t.cancelAppointmentMessage,
      confirmLabel: t.cancelItLabel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(appointmentRepositoryProvider)
        .cancel(appt.id, patientId: appt.patientId);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        ref.invalidate(patientAppointmentsProvider);
      case Err(:final failure):
        _showError(failure.message);
    }
  }

  Future<void> _reschedule() async {
    if (_busy) return;
    // A picked, listed slot — not a free-form date/time — so it's already
    // on the clinician's real schedule grid; the repository still checks it
    // itself, since another booking can land on it between picking and
    // confirming.
    final slot = await pickOpenSlot(
      context,
      staffId: appt.staffId,
      initialDate: appt.slotStart.isAfter(DateTime.now())
          ? appt.slotStart
          : null,
    );
    if (slot == null || !mounted) return;
    setState(() => _busy = true);
    // The original appointment is left untouched unless this actually
    // succeeds — a rejected slot (already taken, in the past) surfaces as a
    // message, not a silently-unchanged screen.
    final result = await ref
        .read(appointmentRepositoryProvider)
        .reschedule(
          id: appt.id,
          patientId: appt.patientId,
          newStart: slot.start,
          newEnd: slot.end,
          enabledChannels: ref.read(notificationPrefsProvider).enabledChannels,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        ref.invalidate(patientAppointmentsProvider);
      case Err(:final failure):
        _showError(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    // Outlined for the tertiary action and error-outlined for the
    // destructive one — the same pair the rest of the app uses
    // (DESIGN.md §5.1). Wrap so they stack instead of overflowing when
    // the card is narrow or the text is scaled up.
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: Space.xs,
        runSpacing: Space.xs,
        children: [
          OutlinedButton(
            onPressed: _busy ? null : _reschedule,
            child: Text(t.reschedule),
          ),
          OutlinedButton(
            onPressed: _busy ? null : _cancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            child: Text(t.cancel),
          ),
        ],
      ),
    );
  }
}
