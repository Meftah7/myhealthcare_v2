import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/presentation/feedback.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/result.dart';
import '../../core/ui/patient/patient_components.dart';
import '../staff_dashboard/presentation/staff_chat_screen.dart';
import '../staff_dashboard/presentation/staff_home.dart';
import '../../core/utils/ids.dart';
import '../../domain/enums.dart';
import '../workspace/workspace_repository.dart';
import '../workspace/workspace_widgets.dart';
import 'workforce_repository.dart';

/// The nurse's Home: the next assigned intake as the primary card (Begin
/// nursing intake opens the authorized intake form), today's figures, the
/// assigned queue, unread conversations and the role tools.
class NurseWorkspace extends ConsumerWidget {
  const NurseWorkspace({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final home = ref.watch(workforceDataProvider('home'));
    final stats = workspaceStat;
    final data = home.valueOrNull;
    return StaffHomeScaffold(
      onRefresh: () async {
        ref
          ..invalidate(workforceDataProvider('home'))
          ..invalidate(workforceDataProvider('intakes'))
          ..invalidate(workforceDataProvider('conversations'));
      },
      children: [
        _NextIntakeCard(home: home),
        const SizedBox(height: 16),
        StaffFigureGrid([
          StaffFigure(
            label: wt(c, 'Assigned today', 'المسندون اليوم'),
            value: '${stats(data, 'assignedToday') ?? '—'}',
            icon: Icons.people_outline,
          ),
          StaffFigure(
            label: wt(c, 'Intakes completed', 'التقييمات المكتملة'),
            value: '${stats(data, 'completedToday') ?? '—'}',
            icon: Icons.task_alt,
            accent: PatientAccent.green,
          ),
          StaffFigure(
            label: wt(c, 'Observations due', 'الملاحظات المطلوبة'),
            value: '${stats(data, 'observationsDue') ?? '—'}',
            icon: Icons.monitor_heart_outlined,
            accent: PatientAccent.amber,
          ),
          StaffFigure(
            label: wt(c, 'Handover work', 'عمل التسليم'),
            value: '${stats(data, 'handover') ?? '—'}',
            icon: Icons.swap_horiz,
            onTap: () => c.push('${AppRoutes.staffTasks}/handover'),
          ),
        ]),
        SectionHeading(wt(c, 'Assigned patients', 'المرضى المسندون')),
        WorkspaceAsync(
          value: ref.watch(workforceDataProvider('intakes')),
          retry: () => ref.invalidate(workforceDataProvider('intakes')),
          builder: (data) {
            final queue = rows(data['rows']);
            return StaffListCard(
              emptyIcon: Icons.monitor_heart_outlined,
              emptyMessage: wt(
                c,
                'No assigned intakes. The responsible clinician or front desk can assign an active visit.',
                'لا توجد تقييمات مسندة. يمكن للممارس المسؤول أو الاستقبال إسناد زيارة نشطة.',
              ),
              children: [
                for (final intake in queue)
                  StaffRow(
                    leadingText: wallTime(intake['slot_start']),
                    muted: intake['status'] == 'completed',
                    title: '${intake['patient_name']}',
                    subtitle: [
                      wallDate(intake['slot_start']),
                      if (intake['department'] != null)
                        '${intake['department']}',
                      wlabel(c, intake['appointment_status']),
                    ].join(' · '),
                    status: intake['urgent'] == 1
                        ? StaffStatus(
                            wt(
                              c,
                              'Urgent clinical review',
                              'مراجعة سريرية عاجلة',
                            ),
                            accent: PatientAccent.red,
                            icon: Icons.priority_high,
                          )
                        : intake['status'] == 'completed'
                        ? StaffStatus(
                            wt(c, 'Intake saved', 'تم حفظ التقييم'),
                            accent: PatientAccent.green,
                            icon: Icons.check,
                          )
                        : StaffStatus(
                            wt(c, 'Observations due', 'الملاحظات مطلوبة'),
                            accent: PatientAccent.amber,
                            icon: Icons.schedule,
                          ),
                    onTap: () => showNursingIntake(c, ref, intake),
                  ),
              ],
            );
          },
        ),
        const StaffUnreadConversations(),
        StaffToolsCard(staffTools(c, StaffRole.nurse)),
      ],
    );
  }
}

class _NextIntakeCard extends ConsumerWidget {
  const _NextIntakeCard({required this.home});

  final AsyncValue<WorkspaceData> home;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    if (home.hasError && !home.hasValue) {
      return PatientStateView(
        kind: PatientStateKind.error,
        message: wt(c, 'Your work could not be loaded.', 'تعذّر تحميل عملك.'),
        actionLabel: wt(c, 'Retry', 'إعادة المحاولة'),
        onAction: () => ref.invalidate(workforceDataProvider('home')),
      );
    }
    if (!home.hasValue) {
      return const PatientStateView(kind: PatientStateKind.loading);
    }
    final next = rows(
      home.requireValue['queue'],
    ).where((n) => n['status'] == 'pending').firstOrNull;
    return StaffWorkCard(
      key: const ValueKey('staff-work-card'),
      overline: wt(c, 'Next assigned intake', 'التقييم التمريضي التالي'),
      icon: Icons.monitor_heart_outlined,
      title: next == null ? null : '${next['patient_name']}',
      lines: next == null
          ? const []
          : [
              '${wallDate(next['slot_start'])} · ${wallTime(next['slot_start'])}–${wallTime(next['slot_end'])}',
              [
                if (next['department'] != null) '${next['department']}',
                wlabel(c, next['appointment_status']),
              ].join(' · '),
            ],
      status: next == null
          ? null
          : next['urgent'] == 1
          ? StaffStatus(
              wt(c, 'Urgent clinical review', 'مراجعة سريرية عاجلة'),
              accent: PatientAccent.red,
              icon: Icons.priority_high,
            )
          : StaffStatus(
              wt(c, 'Observations due', 'الملاحظات مطلوبة'),
              accent: PatientAccent.amber,
              icon: Icons.schedule,
            ),
      primaryLabel: wt(c, 'Begin nursing intake', 'بدء التقييم التمريضي'),
      onPrimary: next == null
          ? null
          : () => unawaited(showNursingIntake(c, ref, next)),
      secondaryLabel: wt(c, 'Full schedule', 'الجدول الكامل'),
      onSecondary: () => c.go(AppRoutes.staffSchedule),
      emptyMessage: wt(
        c,
        'No pending intakes in your authorized queue.',
        'لا توجد تقييمات معلقة في قائمتك المصرح بها.',
      ),
    );
  }
}

Future<void> showNursingIntake(
  BuildContext c,
  WidgetRef ref,
  WorkspaceData intake,
) => showModalBottomSheet<void>(
  context: c,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => NursingIntakeForm(intake: intake),
);

class NursingIntakeForm extends ConsumerStatefulWidget {
  const NursingIntakeForm({required this.intake, super.key});
  final WorkspaceData intake;
  @override
  ConsumerState<NursingIntakeForm> createState() => _NursingIntakeFormState();
}

class _NursingIntakeFormState extends ConsumerState<NursingIntakeForm> {
  final form = GlobalKey<FormState>();
  late final temperature = TextEditingController(
    text: widget.intake['temp_c']?.toString(),
  );
  late final pulse = TextEditingController(
    text: widget.intake['heart_rate']?.toString(),
  );
  late final oxygen = TextEditingController(
    text: widget.intake['spo2']?.toString(),
  );
  late final note = TextEditingController(
    text: widget.intake['observation_note'] as String?,
  );
  final requestKey = newId('intake-save');
  bool busy = false, saved = false;
  String? error;
  String normalized(String s) {
    const a = '٠١٢٣٤٥٦٧٨٩', p = '۰۱۲۳۴۵۶۷۸۹';
    return s
        .trim()
        .split('')
        .map(
          (c) => a.contains(c)
              ? a.indexOf(c).toString()
              : p.contains(c)
              ? p.indexOf(c).toString()
              : c == '٫'
              ? '.'
              : c,
        )
        .join();
  }

  @override
  void dispose() {
    temperature.dispose();
    pulse.dispose();
    oxygen.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || saved || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final result = await Result.guardAsync(
      () => ref
          .read(workforceRepositoryProvider)
          .saveIntake(
            intake: widget.intake,
            note: note.text,
            requestKey: requestKey,
            temperature: temperature.text.trim().isEmpty
                ? null
                : double.parse(normalized(temperature.text)),
            pulse: pulse.text.trim().isEmpty
                ? null
                : int.parse(normalized(pulse.text)),
            oxygen: oxygen.text.trim().isEmpty
                ? null
                : int.parse(normalized(oxygen.text)),
          ),
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      saved = result.isOk;
      error = result.failureOrNull?.message;
    });
    if (result.isOk) {
      ref.invalidate(workforceDataProvider('home'));
      ref.invalidate(workforceDataProvider('intakes'));
    }
  }

  @override
  Widget build(BuildContext c) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.viewInsetsOf(c).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReadableLabel(
              wt(c, 'Nursing intake', 'التقييم التمريضي'),
              style: Theme.of(c).textTheme.titleLarge,
            ),
            ReadableLabel(
              '${widget.intake['patient_name']} · ${widget.intake['patient_id']}\n${wallDate(widget.intake['slot_start'])} · ${widget.intake['appointment_id']}',
            ),
            const SizedBox(height: 16),
            for (final (controller, label, ar, kind) in [
              (
                temperature,
                'Temperature (°C)',
                'الحرارة (درجة مئوية)',
                'temperature',
              ),
              (pulse, 'Pulse (beats/min)', 'النبض (نبضة/دقيقة)', 'pulse'),
              (oxygen, 'Oxygen saturation (%)', 'تشبع الأكسجين (%)', 'oxygen'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: controller,
                  enabled: !busy && !saved,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: wt(c, label, ar)),
                  validator: (raw) {
                    if (raw == null || raw.trim().isEmpty) return null;
                    final value = num.tryParse(normalized(raw));
                    if (value == null ||
                        !value.isFinite ||
                        kind != 'temperature' && value != value.round() ||
                        kind == 'pulse' && value <= 0 ||
                        kind == 'oxygen' && (value < 0 || value > 100))
                      return wt(
                        c,
                        'Check the value and units.',
                        'تحقق من القيمة والوحدة.',
                      );
                    return null;
                  },
                ),
              ),
            TextFormField(
              controller: note,
              enabled: !busy && !saved,
              minLines: 2,
              maxLines: 5,
              maxLength: 5000,
              decoration: InputDecoration(
                labelText: wt(
                  c,
                  'Nursing observation note',
                  'ملاحظة المراقبة التمريضية',
                ),
              ),
            ),
            ReadableLabel(
              wt(
                c,
                'Leave missing measurements blank. This records observations, without a diagnosis or doctor signature.',
                'اترك القياسات غير المتوفرة فارغة. يسجل هذا الملاحظات دون تشخيص أو توقيع طبيب.',
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ReadableLabel(
                  '${wt(c, 'Save failed', 'فشل الحفظ')}: $error',
                ),
              ),
            if (saved)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ReadableLabel(
                  wt(
                    c,
                    'Saved. Your identity, observations and care participation are recorded.',
                    'تم الحفظ. سجلت هويتك وملاحظاتك ومشاركتك في الرعاية.',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy
                  ? null
                  : saved
                  ? () => Navigator.pop(c)
                  : save,
              child: ReadableLabel(
                busy
                    ? wt(c, 'Saving…', 'جارٍ الحفظ…')
                    : saved
                    ? wt(c, 'Done', 'تم')
                    : error == null
                    ? wt(c, 'Save intake', 'حفظ التقييم')
                    : wt(c, 'Retry save', 'إعادة محاولة الحفظ'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PrescriptionClarifications extends ConsumerWidget {
  const PrescriptionClarifications({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => WorkspaceSection(
    wt(c, 'Medication questions needing you', 'استفسارات الدواء التي تحتاجك'),
    child: WorkspaceAsync(
      value: ref.watch(workforceDataProvider('clarifications')),
      retry: () => ref.invalidate(workforceDataProvider('clarifications')),
      builder: (data) => Column(
        children: [
          for (final item in rows(data['rows']))
            ListTile(
              title: ReadableLabel(
                '${item['patient_name']} · ${item['medication_name']}',
              ),
              subtitle: ReadableLabel(item['question'] as String),
              onTap: () async {
                final response = TextEditingController();
                final confirmed = await showDialog<bool>(
                  context: c,
                  builder: (dc) => AlertDialog(
                    title: ReadableLabel(
                      wt(c, 'Respond as prescriber', 'الرد بصفتك الواصف'),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReadableLabel(
                            '${item['medication_name']} · ${item['dose'] ?? ''}\n${item['question']}',
                          ),
                          TextField(
                            controller: response,
                            minLines: 2,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: wt(
                                c,
                                'Clarification response',
                                'الرد على الاستيضاح',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dc, false),
                        child: Text(wt(c, 'Cancel', 'إلغاء')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dc, true),
                        child: Text(wt(c, 'Record response', 'تسجيل الرد')),
                      ),
                    ],
                  ),
                );
                final text = response.text;
                response.dispose();
                if (confirmed != true) return;
                final result = await Result.guardAsync(
                  () => ref
                      .read(workforceRepositoryProvider)
                      .resolveClarification(item, text, newId('clarification')),
                );
                ref.invalidate(workforceDataProvider('clarifications'));
                ref.invalidate(workforceDataProvider('home'));
                if (c.mounted) showMutationFeedback(c, result);
              },
            ),
          if (rows(data['rows']).isEmpty)
            ReadableLabel(
              wt(
                c,
                'No unresolved prescription questions.',
                'لا توجد استفسارات وصفات غير محسومة.',
              ),
            ),
        ],
      ),
    ),
  );
}

class PharmacyDispensingHistory extends ConsumerWidget {
  const PharmacyDispensingHistory({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => WorkspaceSection(
    wt(c, 'Dispensing history', 'سجل الصرف'),
    child: WorkspaceAsync(
      value: ref.watch(workforceDataProvider('dispensing-history')),
      retry: () => ref.invalidate(workforceDataProvider('dispensing-history')),
      builder: (data) => Column(
        children: [
          if (rows(data['rows']).isEmpty)
            ReadableLabel(
              wt(
                c,
                'No pharmacy outcomes recorded yet.',
                'لم يتم تسجيل نتائج صيدلية بعد.',
              ),
            ),
          for (final item in rows(data['rows']))
            ListTile(
              title: ReadableLabel(
                '${item['patient_name']} · ${item['medication_name']}',
              ),
              subtitle: ReadableLabel(
                '${wlabel(c, item['outcome'])} · ${item['quantity'] ?? ''}\n${item['pharmacist_name']} · ${wallDate(item['recorded_at'])} ${wallTime(item['recorded_at'])}\n${item['note'] ?? ''}',
              ),
            ),
        ],
      ),
    ),
  );
}
