/// Staff week schedule grid (P5-12).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../application/staff_providers.dart';

class StaffScheduleScreen extends ConsumerWidget {
  const StaffScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(staffWeekProvider);
    final weekStart = ref.watch(scheduleWeekStartProvider);
    final offset = ref.watch(scheduleWeekOffsetProvider);
    final fmt = DateFormat('d MMM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My schedule'),
        actions: const [SignOutAction()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    ref.read(scheduleWeekOffsetProvider.notifier).state =
                        offset - 1,
              ),
              Text(
                '${fmt.format(weekStart)} – '
                '${fmt.format(weekStart.add(const Duration(days: 6)))}',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    ref.read(scheduleWeekOffsetProvider.notifier).state =
                        offset + 1,
              ),
              if (offset != 0)
                TextButton(
                  onPressed: () =>
                      ref.read(scheduleWeekOffsetProvider.notifier).state = 0,
                  child: const Text('Today'),
                ),
            ],
          ),
        ),
      ),
      body: week.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your schedule.',
          onRetry: () => ref.invalidate(staffWeekProvider),
        ),
        data: (appts) {
          final byDay = <int, List<Appointment>>{};
          for (final a in appts) {
            final d = a.slotStart.weekday;
            (byDay[d] ??= []).add(a);
          }
          return ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              for (var i = 0; i < 7; i++)
                _DayColumn(
                  date: weekStart.add(Duration(days: i)),
                  appts: [...?byDay[i + 1]]
                    ..sort((a, b) => a.slotStart.compareTo(b.slotStart)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.date, required this.appts});

  final DateTime date;
  final List<Appointment> appts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE d MMM').format(date),
            style: theme.textTheme.titleSmall?.copyWith(
              color: isToday ? theme.colorScheme.primary : null,
            ),
          ),
          const SizedBox(height: Space.xxs),
          if (appts.isEmpty)
            Text(
              'No appointments',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final a in appts)
                    ListTile(
                      dense: true,
                      leading: Text(
                        fmtTime(a.slotStart),
                        style: theme.textTheme.bodyMedium,
                      ),
                      title: Text(visitTypeLabel(a.visitType)),
                      subtitle: a.reasonText == null
                          ? null
                          : Text(
                              a.reasonText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: Text(
                        a.status.name,
                        style: theme.textTheme.labelSmall,
                      ),
                      onTap: () =>
                          context.go(AppRoutes.staffPatientChart(a.patientId)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
