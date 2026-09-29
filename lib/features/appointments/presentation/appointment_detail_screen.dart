/// One appointment's full detail: date/time, clinician, department, room,
/// ticket, visit type, reason, status, calendar export, and the same
/// reschedule/cancel actions the list card offers — reached by tapping a
/// card instead of only being able to act from the list.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/ics.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../../patient/application/patient_data_providers.dart';
import 'appointments_screen.dart' show ApptActions;

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(patientAppointmentByIdProvider(appointmentId));
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};

    return AppScaffold(
      title: t.appointmentDetailTitle,
      onRefresh: () async => ref.invalidate(patientAppointmentsProvider),
      children: async.when(
        loading: () => const [SkeletonList()],
        error: (e, _) => [
          ErrorStateView(
            message: t.couldNotLoadAppointments,
            onRetry: () => ref.invalidate(patientAppointmentsProvider),
          ),
        ],
        data: (appt) {
          if (appt == null) {
            return [
              EmptyState(
                icon: Icons.event_busy_outlined,
                message: t.appointmentNotFoundNote,
              ),
            ];
          }
          final theme = Theme.of(context);
          final doctorName = doctors[appt.staffId]?.name;
          final departmentName = departments[appt.departmentId];
          final canManage =
              appt.isUpcoming &&
              (appt.status == AppointmentStatus.booked ||
                  appt.status == AppointmentStatus.confirmed);

          return [
            AppCard(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fmtDate(appt.slotStart),
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    fmtTime(appt.slotStart),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  AppointmentStatusPill(appt.status),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _DetailRow(t.doctorLabel, doctorName ?? t.none),
                  _DetailRow(t.departmentLabel, departmentName ?? t.none),
                  _DetailRow(t.roomNumber(appt.roomNumber ?? t.none), null),
                  _DetailRow(t.ticketLabel(appt.ticketTag ?? t.none), null),
                  _DetailRow(
                    t.visitTypeFieldLabel,
                    visitTypeLabel(appt.visitType),
                  ),
                  if (appt.reasonText != null &&
                      appt.reasonText!.trim().isNotEmpty)
                    _DetailRow(t.reasonOptionalLabel, appt.reasonText!),
                  _DetailRow(t.bookedOn(fmtDate(appt.bookedAt)), null),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            AppCard(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.appointmentCheckInInstructions,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    t.inAppAlwaysOnNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: () => _exportToCalendar(
                context,
                title: [t.visitTypeFieldLabel, ?doctorName].join(' — '),
                start: appt.slotStart,
                end: appt.slotEnd,
                location: departmentName,
                description: appt.reasonText,
                appointmentId: appt.id,
              ),
              icon: const Icon(Icons.event_outlined),
              label: Text(t.addToCalendarAction),
            ),
            const SizedBox(height: Space.xs),
            OutlinedButton.icon(
              onPressed: () => showFeedbackSheet(context, ref),
              icon: const Icon(Icons.help_outline),
              label: Text(t.contactSupportAction),
            ),
            if (canManage) ...[
              const SizedBox(height: Space.lg),
              ApptActions(appt: appt),
            ],
          ];
        },
      ),
    );
  }

  Future<void> _exportToCalendar(
    BuildContext context, {
    required String title,
    required DateTime start,
    required DateTime end,
    required String appointmentId,
    String? location,
    String? description,
  }) async {
    final t = AppLocalizations.of(context)!;
    final ics = buildAppointmentIcs(
      uid: appointmentId,
      title: title,
      start: start,
      end: end,
      location: location,
      description: description,
    );
    try {
      final saved = await FilePicker.saveFile(
        fileName: 'appointment.ics',
        bytes: Uint8List.fromList(utf8.encode(ics)),
        mimeType: 'text/calendar',
      );
      if (!context.mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.calendarFileSavedMessage)));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.couldNotCreateDocument)));
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (value != null)
            Expanded(
              child: Text(
                value!,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
