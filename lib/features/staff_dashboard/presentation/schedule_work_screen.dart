import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../auth/application/session.dart';
import '../../tasks/presentation/task_detail_screen.dart';
import '../application/staff_providers.dart';

final scheduleWorkProvider = FutureProvider.autoDispose((ref) async {
  final id = ref.watch(currentUserProvider)!.id;
  await ref.watch(accessPolicyProvider).actAsStaff(id, Permission.manageTasks);
  final from = DateTime.now().subtract(const Duration(days: 1));
  final to = from.add(const Duration(days: 90));
  final repo = ref.watch(appointmentRepositoryProvider);
  final exceptions = await repo.availabilityExceptions(id, from, to);
  final appointments = await repo.forStaffInRange(id, from, to);
  if (exceptions.isErr) throw exceptions.failureOrNull!;
  if (appointments.isErr) throw appointments.failureOrNull!;
  final db = ref.watch(appDatabaseProvider);
  final notices = await (db.select(
    db.notifications,
  )..where((n) => n.sourceEventId.like('availability:%'))).get();
  final ids = exceptions.valueOrNull!.map((e) => e.id).toSet();
  return (
    exceptions: exceptions.valueOrNull!,
    appointments: appointments.valueOrNull!,
    notices: notices
        .where(
          (n) =>
              ids.any((id) => n.sourceEventId!.startsWith('availability:$id:')),
        )
        .toList(),
  );
});

class ScheduleWorkScreen extends ConsumerStatefulWidget {
  const ScheduleWorkScreen({super.key});
  @override
  ConsumerState<ScheduleWorkScreen> createState() => _ScheduleWorkScreenState();
}

class _ScheduleWorkScreenState extends ConsumerState<ScheduleWorkScreen> {
  DateTime? start, end;
  final reason = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<DateTime?> choose(DateTime? initial) async {
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 89)),
      initialDate: initial ?? DateTime.now(),
    );
    if (day == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    return time == null
        ? null
        : DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(scheduleWorkProvider);
    final work = ref.watch(staffWorkProvider);
    return AppScaffold(
      title: workText(
        context,
        'Cover, time off and conflicts',
        'التغطية والإجازات والتعارضات',
      ),
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextButton.icon(
            onPressed: () => context.push('/staff/tasks/handover'),
            icon: const Icon(Icons.swap_horiz),
            label: Text(
              workText(context, 'Arrange accepted cover', 'ترتيب تغطية مقبولة'),
            ),
          ),
          work.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (tasks) => Column(
              children: [
                for (final t in tasks.where(
                  (t) => t.isOpen && t.coverageStaffId != null,
                ))
                  ListTile(
                    title: Text(t.title),
                    subtitle: Text('${t.staffId} → ${t.coverageStaffId}'),
                    onTap: () => context.push(
                      '/staff/tasks/${Uri.encodeComponent(t.id)}',
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Text(
            workText(context, 'Record time off', 'تسجيل الإجازة'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    final selected = await choose(start);
                    if (mounted && selected != null) {
                      setState(() => start = selected);
                    }
                  },
            child: Text(
              start == null
                  ? workText(context, 'Start', 'البداية')
                  : fmtDateTime(start!),
            ),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    final selected = await choose(end ?? start);
                    if (mounted && selected != null) {
                      setState(() => end = selected);
                    }
                  },
            child: Text(
              end == null
                  ? workText(context, 'End', 'النهاية')
                  : fmtDateTime(end!),
            ),
          ),
          TextField(
            controller: reason,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: workText(context, 'Internal reason', 'السبب الداخلي'),
            ),
          ),
          value.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (data) {
              final active = data.appointments
                  .where(
                    (a) => !{
                      AppointmentStatus.cancelled,
                      AppointmentStatus.completed,
                      AppointmentStatus.noShow,
                    }.contains(a.status),
                  )
                  .toList();
              final affected = start == null || end == null
                  ? <Appointment>[]
                  : active
                        .where(
                          (a) =>
                              a.slotStart.isBefore(end!) &&
                              a.slotEnd.isAfter(start!),
                        )
                        .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    workText(
                      context,
                      '${affected.length} bookings affected. Ownership stays assigned until an accepted transfer. Saving delivers an in-app schedule-review notice to each affected patient.',
                      '${affected.length} حجوزات متأثرة. تبقى المسؤولية مسندة حتى قبول النقل. يرسل الحفظ إشعاراً داخل التطبيق لكل مريض متأثر.',
                    ),
                  ),
                  for (final a in affected)
                    ListTile(
                      title: Text(
                        '${a.patientId} · ${fmtDateTime(a.slotStart)}',
                      ),
                    ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (start == null || end == null) return;
                            setState(() => busy = true);
                            final Result<AvailabilityException> result =
                                await ref
                                    .read(appointmentRepositoryProvider)
                                    .addAvailabilityException(
                                      staffId: ref
                                          .read(currentUserProvider)!
                                          .id,
                                      start: start!,
                                      end: end!,
                                      reason: reason.text,
                                    );
                            ref.invalidate(scheduleWorkProvider);
                            ref.invalidate(staffMonthProvider);
                            if (context.mounted) {
                              setState(() => busy = false);
                              showMutationFeedback(context, result);
                            }
                          },
                    child: Text(
                      workText(
                        context,
                        'Save and notify affected bookings',
                        'حفظ وإشعار الحجوزات المتأثرة',
                      ),
                    ),
                  ),
                  const Divider(),
                  for (final e in data.exceptions)
                    ListTile(
                      title: Text(
                        '${fmtDateTime(e.start)} — ${fmtDateTime(e.end)}',
                      ),
                      subtitle: Text(
                        '${e.reason ?? ''}\n${active.where((a) => a.slotStart.isBefore(e.end) && a.slotEnd.isAfter(e.start)).length} ${workText(context, 'booking conflicts', 'تعارضات حجز')}',
                      ),
                    ),
                  Text(
                    workText(
                      context,
                      'Notification delivery (in-app)',
                      'تسليم الإشعارات داخل التطبيق',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final n in data.notices)
                    ListTile(
                      title: Text(n.recipientId),
                      subtitle: Text(
                        '${fmtDateTime(n.createdAt)} · ${n.readAt == null ? workText(context, 'Delivered; unread', 'تم التسليم؛ غير مقروء') : workText(context, 'Read', 'مقروء')}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
