import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/result.dart';
import '../../core/utils/format.dart' show clinicianName;
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../staff_dashboard/application/staff_providers.dart';
import '../staff_dashboard/presentation/role_workspaces.dart';
import '../staff_dashboard/presentation/staff_chat_screen.dart';
import '../staff_dashboard/presentation/staff_patients_screen.dart';
import '../staff_dashboard/presentation/staff_schedule_screen.dart';
import '../workspace/workspace_repository.dart';
import '../workspace/workspace_widgets.dart';
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
        StaffRole.receptionist => const ReceptionPatientLookup(),
        StaffRole.pharmacist => const PharmacyPatients(),
        _ => const StaffPatientsScreen(),
      };
}

/// Chat is the fourth tab for every role; what each person may open is
/// decided by the repositories behind [StaffChatScreen].
class StaffRoleChat extends StatelessWidget {
  const StaffRoleChat({super.key});
  @override
  Widget build(BuildContext c) => const StaffChatScreen();
}

class StaffRoleSchedule extends ConsumerWidget {
  const StaffRoleSchedule({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) =>
      switch (ref.watch(currentStaffRoleProvider)) {
        StaffRole.receptionist => const DeskSchedule(),
        StaffRole.pharmacist => const PharmacyWorkSchedule(),
        _ => const StaffScheduleScreen(),
      };
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

/// "Patient name · Dr Clinician · 09:30" for a desk sheet — names from the
/// day's lookup, never raw record keys.
String _visitLine(BuildContext c, WidgetRef ref, Appointment visit) {
  final names =
      ref.watch(deskAppointmentNamesProvider).valueOrNull ??
      const <String, String>{};
  return [
    names[visit.patientId] ?? wt(c, 'Patient', 'مريض'),
    if (names[visit.staffId] != null) clinicianName(names[visit.staffId]!),
    '${clinicDateLabel(clinicDay(visit.slotStart))} ${wallTime(visit.slotStart.millisecondsSinceEpoch ~/ 1000)}',
  ].join(' · ');
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
        ref.invalidate(deskArrivalsProvider);
        ref.invalidate(workforceDataProvider('home'));
        // Show the moved booking on its new day.
        ref.read(workspaceDayProvider.notifier).state = clinicDay(
          selected!.start,
        );
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
            style: Theme.of(c).textTheme.titleLarge,
          ),
          ReadableLabel(_visitLine(c, ref, widget.visit)),
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
          ReadableLabel(
            wt(c, 'Assign nursing intake', 'إسناد تقييم تمريضي'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          ReadableLabel(_visitLine(c, ref, widget.visit)),
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
