/// A linked family account, viewed through the access the owner granted:
/// their appointments (cancel/reschedule if "manage") and a read-only health
/// summary (records, vitals, medications).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/family_link_providers.dart';
import '../application/patient_data_providers.dart';

enum _View { appointments, health }

class LinkedAccountScreen extends ConsumerStatefulWidget {
  const LinkedAccountScreen({required this.ownerPatientId, super.key});

  final String ownerPatientId;

  @override
  ConsumerState<LinkedAccountScreen> createState() =>
      _LinkedAccountScreenState();
}

class _LinkedAccountScreenState extends ConsumerState<LinkedAccountScreen> {
  _View _view = _View.appointments;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final patient = ref.watch(linkedPatientProvider(widget.ownerPatientId));
    final permission = ref.watch(
      linkedPermissionProvider(widget.ownerPatientId),
    );

    return AppScaffold(
      title: patient.valueOrNull?.fullName ?? '…',
      onRefresh: () async {
        ref
          ..invalidate(linkedAppointmentsProvider(widget.ownerPatientId))
          ..invalidate(linkedTimelineProvider(widget.ownerPatientId))
          ..invalidate(linkedVitalsProvider(widget.ownerPatientId))
          ..invalidate(linkedMedicationsProvider(widget.ownerPatientId));
      },
      children: [
        if (patient.hasError)
          ErrorStateView(
            message: t.noAccessToThisAccount,
            onRetry: () =>
                ref.invalidate(linkedPatientProvider(widget.ownerPatientId)),
          )
        else ...[
          if (permission.valueOrNull == FamilyLinkPermission.viewOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: InlineBanner.info(t.viewOnlyAccessNote),
            ),
          PillSegmented<_View>(
            segments: [
              (_View.appointments, t.linkedAccountAppointmentsTitle),
              (_View.health, t.linkedAccountHealthTitle),
            ],
            selected: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
          const SizedBox(height: Space.md),
          if (_view == _View.appointments)
            _AppointmentsView(
              ownerPatientId: widget.ownerPatientId,
              canManage: permission.valueOrNull == FamilyLinkPermission.manage,
            )
          else
            _HealthView(ownerPatientId: widget.ownerPatientId),
        ],
      ],
    );
  }
}

class _AppointmentsView extends ConsumerWidget {
  const _AppointmentsView({
    required this.ownerPatientId,
    required this.canManage,
  });

  final String ownerPatientId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final appts = ref.watch(linkedAppointmentsProvider(ownerPatientId));
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};

    return appts.when(
      loading: () => const SkeletonList(lines: 4),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadAppointments,
        onRetry: () => ref.invalidate(linkedAppointmentsProvider(ownerPatientId)),
      ),
      data: (list) {
        final upcoming = list.where((a) => a.isUpcoming).toList()
          ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
        final past = list.where((a) => !a.isUpcoming).toList()
          ..sort((a, b) => b.slotStart.compareTo(a.slotStart));

        Widget card(Appointment a, {required bool upcoming}) => _LinkedApptCard(
          a,
          upcoming: upcoming,
          doctor: doctors[a.staffId]?.name,
          department: departments[a.departmentId],
          ownerPatientId: ownerPatientId,
          canManage: canManage,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canManage) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.patientBook}?for=$ownerPatientId',
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(t.bookAppointmentAction),
                ),
              ),
              const SizedBox(height: Space.md),
            ],
            SectionHeader(t.upcomingCount(upcoming.length), overline: true),
            if (upcoming.isEmpty)
              _EmptyNote(t.nothingBookedNote)
            else
              CardColumns(children: [for (final a in upcoming) card(a, upcoming: true)]),
            const SizedBox(height: Space.md),
            SectionHeader(t.historyCount(past.length), overline: true),
            if (past.isEmpty)
              _EmptyNote(t.noPastVisitsNote)
            else
              CardColumns(
                children: [for (final a in past.take(40)) card(a, upcoming: false)],
              ),
          ],
        );
      },
    );
  }
}

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

class _LinkedApptCard extends ConsumerWidget {
  const _LinkedApptCard(
    this.appt, {
    required this.upcoming,
    required this.ownerPatientId,
    required this.canManage,
    this.doctor,
    this.department,
  });

  final Appointment appt;
  final bool upcoming;
  final String ownerPatientId;
  final bool canManage;
  final String? doctor;
  final String? department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final meta = [visitTypeLabel(appt.visitType), ?doctor, ?department].join('  ·  ');

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
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
                          ? '${fmtRelativeDay(appt.slotStart)} · ${fmtTime(appt.slotStart)}'
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
          const SizedBox(height: Space.xs),
          Text(
            meta,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (appt.reasonText != null) ...[
            const SizedBox(height: Space.xs),
            Text(appt.reasonText!, style: theme.textTheme.bodySmall),
          ],
          if (upcoming && canManage) ...[
            const SizedBox(height: Space.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  OutlinedButton(
                    onPressed: () => _reschedule(context, ref),
                    child: Text(t.reschedule),
                  ),
                  OutlinedButton(
                    onPressed: () => _cancel(context, ref),
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
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final ok = await confirm(
      context,
      title: t.cancelAppointmentTitle,
      message: t.cancelAppointmentMessage,
      confirmLabel: t.cancelItLabel,
      destructive: true,
    );
    if (!ok) return;
    final result = await ref
        .read(familyLinkControllerProvider)
        .cancelForLinkedAccount(
          ownerPatientId: ownerPatientId,
          appointmentId: appt.id,
        );
    if (context.mounted && result.isErr) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.message)));
    }
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final schedule = ref.read(clinicScheduleProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final base = appt.slotStart.isAfter(now) ? appt.slotStart : today;
    final date = await showDatePicker(
      context: context,
      initialDate: isClinicDay(base, schedule) ? base : nextClinicDay(today, schedule),
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: (d) => isClinicDay(d, schedule),
      helpText: t.clinicDaysHelp,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.slotStart),
      helpText: t.clinicHoursHelp,
    );
    if (time == null) return;
    if (time.hour < schedule.openHour || time.hour >= schedule.closeHour) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.pickTimeInRange)));
      }
      return;
    }
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final result = await ref
        .read(familyLinkControllerProvider)
        .rescheduleForLinkedAccount(
          ownerPatientId: ownerPatientId,
          appointmentId: appt.id,
          newStart: newStart,
          newEnd: newStart.add(appt.duration),
        );
    if (context.mounted && result.isErr) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.message)));
    }
  }
}

class _HealthView extends ConsumerWidget {
  const _HealthView({required this.ownerPatientId});
  final String ownerPatientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final records = ref.watch(linkedTimelineProvider(ownerPatientId));
    final vitals = ref.watch(linkedVitalsProvider(ownerPatientId));
    final meds = ref.watch(linkedMedicationsProvider(ownerPatientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(t.vitalsTitle, overline: true),
        vitals.when(
          loading: () => const LoadingSkeleton(height: 56),
          error: (e, _) => InlineBanner.error(t.couldNotLoadVitals),
          data: (list) {
            if (list.isEmpty) return _EmptyNote(t.noVitalsRecordedYet);
            final latest = list.reduce(
              (a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b,
            );
            final parts = [
              if (latest.hasBloodPressure)
                '${latest.systolic}/${latest.diastolic}',
              if (latest.heartRate != null) '${latest.heartRate} bpm',
              if (latest.weightKg != null) '${latest.weightKg} kg',
              if (latest.tempC != null) '${latest.tempC}°C',
            ];
            return AppCard(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fmtDate(latest.recordedAt), style: theme.textTheme.labelMedium),
                  const SizedBox(height: Space.xxs),
                  Text(parts.join('  ·  '), style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: Space.md),
        SectionHeader(t.quickActionMedications, overline: true),
        meds.when(
          loading: () => const LoadingSkeleton(height: 56),
          error: (e, _) => InlineBanner.error(t.couldNotLoadMedications),
          data: (list) {
            final current = list.where((m) => m.isCurrent).toList();
            if (current.isEmpty) return _EmptyNote(t.noActiveMedications);
            return Column(
              children: [
                for (final m in current)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.medication_outlined),
                    title: Text(m.name),
                    subtitle: [m.dose, m.frequency].whereType<String>().isEmpty
                        ? null
                        : Text(
                            [m.dose, m.frequency].whereType<String>().join('  ·  '),
                          ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: Space.md),
        SectionHeader(t.recordsTitle, overline: true),
        records.when(
          loading: () => const SkeletonList(lines: 3),
          error: (e, _) => ErrorStateView(
            message: t.couldNotLoadRecords,
            onRetry: () => ref.invalidate(linkedTimelineProvider(ownerPatientId)),
          ),
          data: (list) {
            if (list.isEmpty) return _EmptyNote(t.noRecordsYet);
            return Column(
              children: [
                for (final r in list.take(30))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(r.title),
                    subtitle: Text(
                      '${r.recordType.label(context)}  ·  ${fmtDate(r.occurredAt)}',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
