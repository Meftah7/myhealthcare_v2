/// Admin → all appointments (ported from the FirstSemMyHealth admin
/// "Appointments" view): every appointment across all patients and staff,
/// filterable by status. Read-only — clinical actions live in the staff app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/admin_providers.dart';
import 'admin_top_actions.dart';

class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  ConsumerState<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState
    extends ConsumerState<AdminAppointmentsScreen> {
  AppointmentStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appts = ref.watch(allAppointmentsProvider);
    final patients =
        ref.watch(adminPatientNamesProvider).valueOrNull ?? const {};
    final staff = ref.watch(adminStaffNamesProvider).valueOrNull ?? const {};
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.allAppointmentsTitle),
        actions: const [AdminTopActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
            child: Row(
              children: [
                for (final (label, value) in <(String, AppointmentStatus?)>[
                  (t.allFilterChip, null),
                  for (final s in AppointmentStatus.values)
                    (s.label(context), s),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: FilterChip(
                      label: Text(label),
                      selected: _filter == value,
                      onSelected: (_) => setState(() => _filter = value),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: appts.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadAppointmentsAdmin,
          onRetry: () => ref.invalidate(allAppointmentsProvider),
        ),
        data: (all) {
          final list =
              (_filter == null
                    ? all
                    : all.where((a) => a.status == _filter).toList())
                ..sort((a, b) => b.slotStart.compareTo(a.slotStart));
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_month_outlined,
              message: t.noAppointmentsInView,
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.sm,
                  gutter,
                  Space.xxl,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
                itemBuilder: (context, i) {
                  final a = list[i];
                  return AppCard(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patients[a.patientId] ?? t.rolePatient,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              a.status.label(context),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.xxs),
                        Text(
                          [
                            fmtDateTime(a.slotStart),
                            staff[a.staffId] ?? t.unassignedLabel,
                            visitTypeLabel(a.visitType),
                            if (a.ticketTag != null) a.ticketTag!,
                            if (a.roomNumber != null)
                              t.roomNumber('${a.roomNumber}'),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
