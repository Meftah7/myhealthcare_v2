/// My appointments, filtered by upcoming, past and cancelled visits.
/// Appointment details own the cancel and reschedule actions.
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
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import 'slot_picker_sheet.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

enum _AppointmentFilter { all, upcoming, past, cancelled }

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  static const _pageSize = 40;

  /// Pagination applies to the currently selected filter.
  int _visiblePast = _pageSize;
  _AppointmentFilter _filter = _AppointmentFilter.all;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appts = ref.watch(patientAppointmentsProvider);
    ref.watch(appointmentStatusRefreshProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};

    return AppScaffold(
      hero: true,
      title: t.appointmentHistoryTitle,
      actions: const [PatientTopActions()],
      onRefresh: () async => ref.invalidate(patientAppointmentsProvider),
      children: [
        // Filters stay available while the list loads; booking remains below.
        PillSegmented<_AppointmentFilter>(
          segments: [
            (_AppointmentFilter.all, t.allAppointmentsTitle),
            (_AppointmentFilter.upcoming, t.upcomingLabel),
            (_AppointmentFilter.past, t.pastSectionLabel),
            (
              _AppointmentFilter.cancelled,
              AppointmentStatus.cancelled.label(context),
            ),
          ],
          selected: _filter,
          onChanged: (value) => setState(() {
            _filter = value;
            _visiblePast = _pageSize;
          }),
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
            final now = DateTime.now();
            final filtered =
                list
                    .where(
                      (a) => switch (_filter) {
                        _AppointmentFilter.all => true,
                        _AppointmentFilter.upcoming => isCurrentAppointment(
                          a,
                          now,
                        ),
                        _AppointmentFilter.past =>
                          !isCurrentAppointment(a, now) &&
                              a.status != AppointmentStatus.cancelled,
                        _AppointmentFilter.cancelled =>
                          a.status == AppointmentStatus.cancelled,
                      },
                    )
                    .toList()
                  ..sort((a, b) {
                    final date = _filter == _AppointmentFilter.upcoming
                        ? a.slotStart.compareTo(b.slotStart)
                        : b.slotStart.compareTo(a.slotStart);
                    return date == 0 ? a.id.compareTo(b.id) : date;
                  });
            final visible = filtered.take(_visiblePast).toList();
            final remaining = filtered.length - visible.length;
            return [
              const SizedBox(height: Space.md),
              if (filtered.isEmpty)
                _EmptyNote(
                  _filter == _AppointmentFilter.upcoming
                      ? t.nothingBookedNote
                      : t.noAppointmentsInView,
                )
              else ...[
                CardColumns(
                  children: [
                    for (final a in visible)
                      PatientAppointmentCard(
                        a,
                        upcoming: isCurrentAppointment(a, now),
                        doctor: doctors[a.staffId]?.name,
                        department:
                            departments[a.departmentId ??
                                doctors[a.staffId]?.departmentId],
                      ),
                  ],
                ),
                if (remaining > 0)
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _visiblePast += _pageSize),
                      child: Text(t.showOlderVisitsAction(remaining)),
                    ),
                  ),
              ],
            ];
          },
        ),
      ],
    );
  }
}

bool isCurrentAppointment(Appointment a, DateTime now) =>
    a.isInProgress ||
    a.status == AppointmentStatus.checkedIn ||
    ((a.status == AppointmentStatus.booked ||
            a.status == AppointmentStatus.confirmed) &&
        !a.slotEnd.isBefore(now));

class UpcomingBookingAppointments extends ConsumerWidget {
  const UpcomingBookingAppointments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};
    ref.watch(appointmentStatusRefreshProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.upcomingLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Space.sm),
        ref
            .watch(patientAppointmentsProvider)
            .when(
              loading: () => const SkeletonList(lines: 2),
              error: (_, _) => ErrorStateView(
                message: t.couldNotLoadAppointments,
                onRetry: () => ref.invalidate(patientAppointmentsProvider),
              ),
              data: (appointments) {
                final now = DateTime.now();
                final current =
                    appointments
                        .where((a) => isCurrentAppointment(a, now))
                        .toList()
                      ..sort((a, b) {
                        final date = a.slotStart.compareTo(b.slotStart);
                        return date == 0 ? a.id.compareTo(b.id) : date;
                      });
                if (current.isEmpty) return _EmptyNote(t.nothingBookedNote);
                return CardColumns(
                  children: [
                    for (final a in current)
                      PatientAppointmentCard(
                        a,
                        upcoming: true,
                        doctor: doctors[a.staffId]?.name,
                        department:
                            departments[a.departmentId ??
                                doctors[a.staffId]?.departmentId],
                      ),
                  ],
                );
              },
            ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.patientAppointmentHistory),
            child: Text(t.viewAllAppointments),
          ),
        ),
      ],
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

class PatientAppointmentCard extends ConsumerWidget {
  const PatientAppointmentCard(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: Radii.cardSmall,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor ?? visitTypeLabel(appt.visitType),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: Space.xxs),
                ReadableLabel(
                  [
                    ?department,
                    fmtRelativeDay(appt.slotStart),
                    fmtTime(appt.slotStart),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (appt.bookedForName != null)
                  Text(
                    t.bookedForName(appt.bookedForName!),
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xxs,
                  children: [
                    AppointmentStatusPill(appt.status, dense: true),
                    if (upcoming && appt.riskBand != null)
                      RiskBadge(appt.riskBand!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The reschedule/cancel buttons, split out from [PatientAppointmentCard] so they can own
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
        ref.invalidate(patientAppointmentByIdProvider(appt.id));
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
        ref.invalidate(patientAppointmentByIdProvider(appt.id));
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
