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
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/presentation/feedback.dart';
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

enum _AppointmentFilter { upcoming, past, cancelled }

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  static const _pageSize = 40;

  /// How many past visits to show — grows by [_pageSize] each time "Show
  /// more" is tapped, rather than silently hiding the rest with no way to
  /// see them.
  int _visiblePast = _pageSize;
  _AppointmentFilter _filter = _AppointmentFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appts = ref.watch(patientAppointmentsProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};

    return AppScaffold(
      hero: true,
      title: t.appointmentsTitle,
      actions: const [PatientTopActions()],
      onRefresh: () async => ref.invalidate(patientAppointmentsProvider),
      children: [
        // Filters stay available while the list loads; booking remains below.
        PillSegmented<_AppointmentFilter>(
          segments: [
            (_AppointmentFilter.upcoming, t.upcomingLabel),
            (_AppointmentFilter.past, t.pastSectionLabel),
            (_AppointmentFilter.cancelled, AppointmentStatus.cancelled.label(context)),
          ],
          selected: _filter,
          onChanged: (value) => setState(() { _filter = value; _visiblePast = _pageSize; }),
        ),
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
            final filtered = list.where((a) => switch (_filter) {
              _AppointmentFilter.upcoming => a.isUpcoming,
              _AppointmentFilter.past => !a.isUpcoming && a.status != AppointmentStatus.cancelled,
              _AppointmentFilter.cancelled => a.status == AppointmentStatus.cancelled,
            }).toList()..sort((a, b) => _filter == _AppointmentFilter.upcoming
                ? a.slotStart.compareTo(b.slotStart) : b.slotStart.compareTo(a.slotStart));
            final visible = filtered.take(_visiblePast).toList();
            final remaining = filtered.length - visible.length;
            return [
              const SizedBox(height: Space.md),
              if (filtered.isEmpty)
                _EmptyNote(_filter == _AppointmentFilter.upcoming ? t.nothingBookedNote : t.noAppointmentsInView)
              else ...[
                CardColumns(children: [for (final a in visible) _ApptCard(a,
                  upcoming: a.isUpcoming, doctor: doctors[a.staffId]?.name,
                  department: departments[a.departmentId])]),
                if (remaining > 0) Center(child: TextButton(
                  onPressed: () => setState(() => _visiblePast += _pageSize),
                  child: Text(t.showOlderVisitsAction(remaining)))),
              ],
            ];
          },
        ),
        const SizedBox(height: Space.lg),
        const _EntryButtons(),
      ],
    );
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
    return AppCard(
      onTap: () => context.push(AppRoutes.patientAppointmentDetail(appt.id)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: Radii.cardSmall),
          child: Icon(Icons.calendar_today_outlined, size: 20, color: theme.colorScheme.primary)),
        const SizedBox(width: Space.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doctor ?? visitTypeLabel(appt.visitType), style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text([?department, fmtRelativeDay(appt.slotStart), fmtTime(appt.slotStart)].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (appt.bookedForName != null) Text(t.bookedForName(appt.bookedForName!), style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.xs),
          Wrap(spacing: Space.xs, runSpacing: Space.xxs, children: [
            AppointmentStatusPill(appt.status, dense: true),
            if (upcoming && appt.riskBand != null) RiskBadge(appt.riskBand!),
          ]),
        ])),
      ]),
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
        .cancel(
          appt.id,
          patientId: appt.patientId,
          expectedVersion: appt.version,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        ref.invalidate(patientAppointmentsProvider);
      case Err(:final failure):
        _showError(
          describeFailure(AppLocalizations.of(context)!, failure).message,
        );
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
          newEnd: slot.start.add(appt.duration),
          enabledChannels: ref.read(notificationPrefsProvider).enabledChannels,
          expectedVersion: appt.version,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        ref.invalidate(patientAppointmentsProvider);
      case Err(:final failure):
        _showError(
          describeFailure(AppLocalizations.of(context)!, failure).message,
        );
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
