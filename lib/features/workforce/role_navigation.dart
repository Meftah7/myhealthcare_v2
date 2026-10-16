import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/di.dart';
import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/feedback.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../care/presentation/staff_inbox_screen.dart';
import '../staff_dashboard/application/staff_providers.dart';
import '../staff_dashboard/presentation/role_workspaces.dart';
import '../staff_dashboard/presentation/staff_patients_screen.dart';
import '../staff_dashboard/presentation/staff_schedule_screen.dart';
import '../staff_dashboard/presentation/staff_top_actions.dart';
import '../workspace/workspace_repository.dart';
import '../workspace/workspace_widgets.dart';
import 'team_screens.dart';
import 'workforce_repository.dart';

final currentStaffRoleProvider = Provider(
  (ref) =>
      StaffRole.parse(ref.watch(staffProfileProvider).valueOrNull?.jobTitle),
);

class StaffRolePatients extends ConsumerWidget {
  const StaffRolePatients({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) =>
      switch (ref.watch(currentStaffRoleProvider)) {
        StaffRole.receptionist => const FrontDeskWorkspace(),
        StaffRole.pharmacist => const PharmacyWorkspace(),
        _ => const StaffPatientsScreen(),
      };
}

class StaffRoleChat extends ConsumerWidget {
  const StaffRoleChat({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final role = ref.watch(currentStaffRoleProvider);
    if (role == StaffRole.receptionist || role == StaffRole.pharmacist)
      return const TeamConversationsScreen();
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: wt(c, 'Patient care', 'رعاية المرضى')),
              Tab(text: wt(c, 'Team', 'الفريق')),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [StaffInboxScreen(), TeamConversationsScreen()],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffRoleSchedule extends ConsumerWidget {
  const StaffRoleSchedule({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) =>
      switch (ref.watch(currentStaffRoleProvider)) {
        StaffRole.receptionist => const DeskClinicSchedule(),
        StaffRole.pharmacist => const StaffShiftSchedule(),
        _ => const StaffScheduleScreen(),
      };
}

class StaffShiftSchedule extends ConsumerWidget {
  const StaffShiftSchedule({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => AppScaffold(
    title: wt(c, 'Work schedule', 'جدول العمل'),
    actions: const [StaffTopActions()],
    children: [
      WorkspaceAsync(
        value: ref.watch(workforceDataProvider('shifts')),
        retry: () => ref.invalidate(workforceDataProvider('shifts')),
        builder: (data) => Column(
          children: [
            if (rows(data['rows']).isEmpty)
              ReadableLabel(
                wt(
                  c,
                  'No shifts assigned. Contact the clinic administrator.',
                  'لم يتم تعيين مناوبات. تواصل مع مدير العيادة.',
                ),
              ),
            for (final shift in rows(data['rows']))
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: ReadableLabel(
                  DateFormat.EEEE(
                    Localizations.localeOf(c).languageCode,
                  ).format(
                    DateTime(2026, 1, 4 + (shift['weekday'] as num).toInt()),
                  ),
                ),
                subtitle: ReadableLabel(
                  '${_time(shift['start_minutes'])}–${_time(shift['end_minutes'])}',
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

String _time(dynamic n) {
  final value = (n as num).toInt();
  return '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
}

final deskDayAppointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) async {
      ref.watch(workspaceChangesProvider);
      final start = clinicStart(ref.watch(workspaceDayProvider));
      final result = await ref
          .watch(appointmentRepositoryProvider)
          .inRange(start, start.add(const Duration(days: 1)));
      return switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => throw failure,
      };
    });

final deskAppointmentNamesProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final visits = await ref.watch(deskDayAppointmentsProvider.future),
          names = <String, String>{};
      for (final id in visits.map((a) => a.patientId).toSet()) {
        final result = await ref.watch(patientRepositoryProvider).byId(id);
        if (result.isErr) throw result.failureOrNull!;
        names[id] = result.valueOrNull!.user.fullName;
      }
      for (final id in visits.map((a) => a.staffId).toSet()) {
        final result = await ref.watch(userRepositoryProvider).staffById(id);
        if (result.isErr) throw result.failureOrNull!;
        names[id] = result.valueOrNull!.user.fullName;
      }
      return names;
    });

class DeskClinicSchedule extends ConsumerWidget {
  const DeskClinicSchedule({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final day = ref.watch(workspaceDayProvider);
    final names =
        ref.watch(deskAppointmentNamesProvider).valueOrNull ??
        const <String, String>{};
    return AppScaffold(
      title: wt(c, 'Clinic appointments', 'مواعيد العيادة'),
      actions: const [StaffTopActions()],
      onRefresh: () async => ref.invalidate(deskDayAppointmentsProvider),
      children: [
        Wrap(
          spacing: 8,
          children: [
            IconButton(
              tooltip: wt(c, 'Previous day', 'اليوم السابق'),
              onPressed: () => ref.read(workspaceDayProvider.notifier).state =
                  day.subtract(const Duration(days: 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: c,
                  initialDate: day,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null)
                  ref.read(workspaceDayProvider.notifier).state = picked;
              },
              child: ReadableLabel(
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
              ),
            ),
            IconButton(
              tooltip: wt(c, 'Next day', 'اليوم التالي'),
              onPressed: () => ref.read(workspaceDayProvider.notifier).state =
                  day.add(const Duration(days: 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        ref
            .watch(deskDayAppointmentsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                children: [
                  ReadableLabel('$e'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(deskDayAppointmentsProvider),
                    child: Text(wt(c, 'Retry', 'إعادة المحاولة')),
                  ),
                ],
              ),
              data: (visits) => Column(
                children: [
                  if (visits.isEmpty)
                    ReadableLabel(
                      wt(
                        c,
                        'No clinic appointments on this day.',
                        'لا توجد مواعيد في العيادة في هذا اليوم.',
                      ),
                    ),
                  for (final visit in visits)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReadableLabel(
                              '${names[visit.patientId] ?? visit.patientId} · ${visit.patientId}\n${visit.id}',
                            ),
                            ReadableLabel(
                              '${wallTime(visit.slotStart.millisecondsSinceEpoch ~/ 1000)}–${wallTime(visit.slotEnd.millisecondsSinceEpoch ~/ 1000)} · ${wlabel(c, visit.status.name)}',
                            ),
                            ReadableLabel(
                              '${visit.reasonText ?? ''} · ${names[visit.staffId] ?? visit.staffId}',
                            ),
                            if (![
                              AppointmentStatus.completed,
                              AppointmentStatus.cancelled,
                              AppointmentStatus.noShow,
                            ].contains(visit.status))
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => showModalBottomSheet<void>(
                                      context: c,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (_) =>
                                          DeskRescheduleSheet(visit: visit),
                                    ),
                                    child: ReadableLabel(
                                      wt(c, 'Reschedule', 'تغيير الموعد'),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => showModalBottomSheet<void>(
                                      context: c,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (_) =>
                                          NursingAssignmentSheet(visit: visit),
                                    ),
                                    child: ReadableLabel(
                                      wt(
                                        c,
                                        'Assign nurse intake',
                                        'إسناد تقييم تمريضي',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if ([
                              AppointmentStatus.booked,
                              AppointmentStatus.confirmed,
                            ].contains(visit.status))
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton(
                                    onPressed: () async {
                                      final result = await ref
                                          .read(appointmentRepositoryProvider)
                                          .deskCheckIn(
                                            visit.id,
                                            at: DateTime.now(),
                                            expectedVersion: visit.version,
                                          );
                                      ref.invalidate(
                                        deskDayAppointmentsProvider,
                                      );
                                      if (c.mounted)
                                        showMutationFeedback(c, result);
                                    },
                                    child: ReadableLabel(
                                      wt(c, 'Confirm arrival', 'تأكيد الوصول'),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      final yes = await showDialog<bool>(
                                        context: c,
                                        builder: (dc) => AlertDialog(
                                          title: ReadableLabel(
                                            wt(
                                              c,
                                              'Cancel this appointment?',
                                              'إلغاء هذا الموعد؟',
                                            ),
                                          ),
                                          content: ReadableLabel(
                                            '${visit.patientId}\n${visit.id}',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dc, false),
                                              child: Text(
                                                wt(
                                                  c,
                                                  'Keep appointment',
                                                  'الاحتفاظ بالموعد',
                                                ),
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(dc, true),
                                              child: Text(
                                                wt(
                                                  c,
                                                  'Cancel appointment',
                                                  'إلغاء الموعد',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (yes != true) return;
                                      final result = await ref
                                          .read(appointmentRepositoryProvider)
                                          .cancel(
                                            visit.id,
                                            patientId: visit.patientId,
                                            expectedVersion: visit.version,
                                          );
                                      ref.invalidate(
                                        deskDayAppointmentsProvider,
                                      );
                                      if (c.mounted)
                                        showMutationFeedback(c, result);
                                    },
                                    child: ReadableLabel(
                                      wt(
                                        c,
                                        'Cancel appointment',
                                        'إلغاء الموعد',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class DeskRescheduleSheet extends ConsumerStatefulWidget {
  const DeskRescheduleSheet({required this.visit, super.key});
  final Appointment visit;
  @override
  ConsumerState<DeskRescheduleSheet> createState() => _RescheduleState();
}

class _RescheduleState extends ConsumerState<DeskRescheduleSheet> {
  DateTime day = DateTime.now();
  OpenSlot? selected;
  Future<Result<List<OpenSlot>>>? slots;
  bool checked = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    selected = null;
    slots = ref
        .read(appointmentRepositoryProvider)
        .openSlots(widget.visit.staffId, day);
  }

  Future<void> save() async {
    if (busy || selected == null || !checked) return;
    setState(() {
      busy = true;
      error = null;
    });
    final result = await ref
        .read(appointmentRepositoryProvider)
        .reschedule(
          id: widget.visit.id,
          patientId: widget.visit.patientId,
          newStart: selected!.start,
          newEnd: selected!.end,
          expectedVersion: widget.visit.version,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(deskDayAppointmentsProvider);
        ref.invalidate(workforceDataProvider('home'));
        Navigator.pop(context);
      case Err(:final failure):
        setState(() {
          busy = false;
          error = failure.message;
          load();
        });
    }
  }

  @override
  Widget build(BuildContext c) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      16,
      16,
      MediaQuery.viewInsetsOf(c).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadableLabel(
            wt(c, 'Reschedule clinic appointment', 'تغيير موعد العيادة'),
          ),
          ReadableLabel(
            '${widget.visit.patientId}\n${widget.visit.id} · ${widget.visit.staffId}',
          ),
          CheckboxListTile(
            value: checked,
            onChanged: busy
                ? null
                : (v) => setState(() => checked = v ?? false),
            title: ReadableLabel(
              wt(
                c,
                'Patient identity and appointment verified',
                'تم التحقق من هوية المريض والموعد',
              ),
            ),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: day,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && mounted)
                      setState(() {
                        day = picked;
                        load();
                      });
                  },
            child: ReadableLabel('${day.year}-${day.month}-${day.day}'),
          ),
          FutureBuilder<Result<List<OpenSlot>>>(
            future: slots,
            builder: (c, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return switch (snapshot.data!) {
                Err(:final failure) => Column(
                  children: [
                    ReadableLabel(failure.message),
                    TextButton(
                      onPressed: () => setState(load),
                      child: Text(
                        wt(
                          c,
                          'Retry available slots',
                          'إعادة تحميل الأوقات المتاحة',
                        ),
                      ),
                    ),
                  ],
                ),
                Ok(:final value) => Column(
                  children: [
                    if (value.isEmpty)
                      ReadableLabel(
                        wt(
                          c,
                          'No fresh slots on this day. Choose another day.',
                          'لا توجد أوقات متاحة في هذا اليوم. اختر يوماً آخر.',
                        ),
                      ),
                    for (final slot in value)
                      RadioListTile<OpenSlot>(
                        value: slot,
                        groupValue: selected,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => selected = v),
                        title: ReadableLabel(
                          '${wallTime(slot.start.millisecondsSinceEpoch ~/ 1000)}–${wallTime(slot.end.millisecondsSinceEpoch ~/ 1000)}',
                        ),
                      ),
                  ],
                ),
              };
            },
          ),
          if (error != null) ReadableLabel(error!),
          FilledButton(
            onPressed: busy || selected == null || !checked ? null : save,
            child: ReadableLabel(
              busy
                  ? wt(c, 'Saving…', 'جارٍ الحفظ…')
                  : wt(c, 'Confirm new appointment time', 'تأكيد الوقت الجديد'),
            ),
          ),
        ],
      ),
    ),
  );
}

class NursingAssignmentSheet extends ConsumerStatefulWidget {
  const NursingAssignmentSheet({required this.visit, super.key});
  final Appointment visit;
  @override
  ConsumerState<NursingAssignmentSheet> createState() => _AssignmentState();
}

class _AssignmentState extends ConsumerState<NursingAssignmentSheet> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.all(16),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadableLabel(wt(c, 'Assign nursing intake', 'إسناد تقييم تمريضي')),
          ReadableLabel('${widget.visit.patientId} · ${widget.visit.id}'),
          if (error != null) ReadableLabel(error!),
          WorkspaceAsync(
            value: ref.watch(workforceDataProvider('directory')),
            retry: () => ref.invalidate(workforceDataProvider('directory')),
            builder: (data) => Column(
              children: [
                for (final nurse in rows(data['rows']).where(
                  (p) =>
                      StaffRole.parse(p['role'] as String?) == StaffRole.nurse,
                ))
                  ListTile(
                    title: ReadableLabel(nurse['name'] as String),
                    subtitle: ReadableLabel(
                      nurse['department'] as String? ?? '',
                    ),
                    onTap: busy
                        ? null
                        : () async {
                            setState(() {
                              busy = true;
                              error = null;
                            });
                            try {
                              await ref
                                  .read(workforceRepositoryProvider)
                                  .assignIntake(
                                    widget.visit.id,
                                    nurse['id'] as String,
                                  );
                              ref.invalidate(workforceDataProvider('intakes'));
                              if (c.mounted) Navigator.pop(c);
                            } catch (e) {
                              if (mounted) setState(() => error = '$e');
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
