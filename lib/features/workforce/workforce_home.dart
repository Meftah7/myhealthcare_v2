import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/feedback.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/result.dart';
import '../../core/ui/patient/workspace_home.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/format.dart' show visitTypeLabel;
import '../../domain/enums.dart';
import '../auth/application/session.dart';
import '../staff_dashboard/presentation/staff_top_actions.dart';
import '../workspace/workspace_repository.dart';
import '../workspace/workspace_widgets.dart';
import 'workforce_repository.dart';

String _visitLabel(Object? value) {
  final type = VisitType.values.where((t) => t.name == value).firstOrNull;
  return type == null ? '—' : visitTypeLabel(type);
}

class WorkforceOverview extends ConsumerWidget {
  const WorkforceOverview({this.showStatistics = true, super.key});
  final bool showStatistics;
  @override
  Widget build(BuildContext c, WidgetRef ref) => WorkspaceAsync(
    value: ref.watch(workforceDataProvider('home')),
    retry: () => ref.invalidate(workforceDataProvider('home')),
    builder: (data) {
      final role = data['role'] as String,
          stats = Map<String, dynamic>.from(data['stats'] as Map);
      final queue = rows(data['queue']);
      final pending = role == 'nurse'
          ? queue.where((n) => n['status'] == 'pending').toList()
          : queue;
      final next = pending.firstOrNull;
      final title = role == 'nurse'
          ? wt(c, 'Next assigned intake', 'التقييم التمريضي التالي')
          : role == 'receptionist'
          ? wt(c, 'Next arrival', 'الوصول التالي')
          : role == 'pharmacist'
          ? wt(c, 'Next signed prescription', 'الوصفة الموقعة التالية')
          : role == 'dentist'
          ? wt(c, 'Your next dental visit', 'زيارة الأسنان التالية')
          : wt(c, 'Your next consultation', 'الاستشارة التالية');
      void open() {
        if (next == null) return;
        if (role == 'nurse') {
          unawaited(showNursingIntake(c, ref, next));
          return;
        }
        if (role == 'pharmacist') {
          c.go(AppRoutes.staffPatients);
          return;
        }
        if (role == 'receptionist') {
          ref.read(workspaceDayProvider.notifier).state = clinicDay(
            DateTime.fromMillisecondsSinceEpoch(
              (next['slot_start'] as num).toInt() * 1000,
              isUtc: true,
            ),
          );
          c.go(AppRoutes.staffSchedule);
          return;
        }
        c.push(AppRoutes.staffConsultation(next['id'] as String));
      }

      final labels = role == 'nurse'
          ? [
              (
                'assignedToday',
                wt(c, 'Assigned patients', 'المرضى المسندون'),
                wt(c, 'Unique · today', 'فريدون · اليوم'),
              ),
              (
                'completedToday',
                wt(c, 'Completed intakes', 'التقييمات المكتملة'),
                wt(c, 'Saved today', 'المحفوظة اليوم'),
              ),
              (
                'observationsDue',
                wt(c, 'Observations due', 'الملاحظات المطلوبة'),
                wt(c, 'Assigned pending intakes', 'التقييمات المسندة المعلقة'),
              ),
              (
                'handover',
                wt(c, 'Handover work', 'عمل التسليم'),
                wt(c, 'Open assigned work', 'العمل المسند المفتوح'),
              ),
            ]
          : role == 'pharmacist'
          ? [
              (
                'pendingOrders',
                wt(c, 'Pending orders', 'الطلبات المعلقة'),
                wt(c, 'Signed and active', 'موقعة وسارية'),
              ),
              (
                'dispensedToday',
                wt(c, 'Dispensed today', 'المصروف اليوم'),
                wt(c, 'Clinic · distinct orders', 'العيادة · طلبات فريدة'),
              ),
              (
                'clarifications',
                wt(c, 'Clarifications', 'الاستيضاحات'),
                wt(c, 'Unresolved', 'غير المحسومة'),
              ),
              (
                'stockAlerts',
                wt(c, 'Stock alerts', 'تنبيهات المخزون'),
                wt(
                  c,
                  '≤5 units or expiry within 30 days',
                  '٥ وحدات أو أقل، أو انتهاء خلال ٣٠ يوماً',
                ),
              ),
            ]
          : role == 'receptionist'
          ? [
              (
                'appointmentsToday',
                wt(c, 'Arrivals today', 'وصول اليوم'),
                wt(c, 'All clinic appointments', 'كل مواعيد العيادة'),
              ),
              (
                'checkedIn',
                wt(c, 'Checked in', 'تم تسجيل الوصول'),
                wt(c, 'Confirmed arrival · today', 'وصول مؤكد · اليوم'),
              ),
              (
                'waiting',
                wt(c, 'Waiting arrivals', 'الوصول المنتظر'),
                wt(c, 'Not checked in · today', 'لم يسجل الوصول · اليوم'),
              ),
              (
                'pendingCopies',
                wt(c, 'Issued-copy checks', 'فحص النسخ الصادرة'),
                wt(c, 'Not yet confirmed', 'لم يتم التأكيد بعد'),
              ),
            ]
          : <(String, String, String)>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadableLabel(
            '${wlabel(c, role)} · ${data['department'] ?? wt(c, 'Department not assigned', 'القسم غير مسند')}',
          ),
          const SizedBox(height: 12),
          NavyFeatureCard(
            navy: true,
            title: title,
            icon: role == 'nurse'
                ? Icons.monitor_heart_outlined
                : role == 'pharmacist'
                ? Icons.medication_outlined
                : Icons.calendar_today_outlined,
            body: next == null
                ? wt(
                    c,
                    'No pending work in your authorized queue.',
                    'لا يوجد عمل معلق في قائمتك المصرح بها.',
                  )
                : '${next['patient_name']} · ${next['patient_id']}\n${role == 'pharmacist' ? '${next['medication_name']} · ${next['dose'] ?? ''}' : '${wallDate(next['slot_start'])} · ${wallTime(next['slot_start'])}–${wallTime(next['slot_end'])}'}${role == 'doctor' || role == 'dentist' ? '\n${_visitLabel(next['visit_type'])} · ${next['room_number'] ?? wt(c, 'Room pending', 'الغرفة غير محددة')}\n${wlabel(c, next['status'])} · ${next['reason_text'] ?? ''}' : ''}',
            actionLabel: next == null
                ? null
                : role == 'nurse'
                ? wt(c, 'Begin nursing intake', 'بدء التقييم التمريضي')
                : role == 'pharmacist'
                ? wt(c, 'Open prescription queue', 'فتح قائمة الوصفات')
                : role == 'receptionist'
                ? wt(c, 'Open arrivals', 'فتح الوصول')
                : wt(c, 'Open consultation', 'فتح الاستشارة'),
            onAction: next == null ? null : open,
          ),
          if (showStatistics && labels.isNotEmpty) ...[
            const SizedBox(height: 16),
            ShortcutGrid(
              items: [
                ShortcutItem(
                  icon: role == 'pharmacist'
                      ? Icons.medication_outlined
                      : Icons.people_outline,
                  label: role == 'pharmacist'
                      ? wt(c, 'Prescriptions', 'الوصفات')
                      : role == 'receptionist'
                      ? wt(c, 'Patient Lookup', 'البحث عن مريض')
                      : wt(c, 'Patient history', 'سجل المرضى'),
                  onTap: () => c.go(AppRoutes.staffPatients),
                ),
                ShortcutItem(
                  icon: Icons.calendar_month_outlined,
                  label: wt(c, 'Schedule', 'الجدول'),
                  onTap: () => c.go(AppRoutes.staffSchedule),
                ),
                ShortcutItem(
                  icon: Icons.chat_bubble_outline,
                  label: wt(c, 'Chat', 'المحادثات'),
                  onTap: () => c.go(AppRoutes.staffChat),
                ),
                ShortcutItem(
                  icon: Icons.assignment_outlined,
                  label: wt(c, 'My work', 'عملي'),
                  onTap: () => c.push(AppRoutes.staffTasks),
                ),
              ],
            ),
            const SizedBox(height: 16),
            WorkspaceSection(
              wt(c, 'Quick Statistics', 'إحصاءات سريعة'),
              child: WorkspaceMetrics([
                for (final (key, label, caption) in labels)
                  (label, '${stats[key] ?? 0}', caption),
              ]),
            ),
          ],
          if (role == 'doctor' || role == 'dentist')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ReadableLabel(
                '${wt(c, 'Open follow-up tasks', 'مهام المتابعة المفتوحة')}: ${stats['followUp'] ?? 0} · ${wt(c, role == 'dentist' ? 'Unsigned dental notes' : 'Unsigned notes', role == 'dentist' ? 'ملاحظات الأسنان غير الموقعة' : 'الملاحظات غير الموقعة')}: ${stats['unsignedNotes'] ?? 0}',
              ),
            ),
        ],
      );
    },
  );
}

class NurseWorkspace extends ConsumerWidget {
  const NurseWorkspace({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return AppScaffold(
      title: wt(
        c,
        'Hello, ${user?.fullName.split(' ').first ?? ''}',
        'مرحباً، ${user?.fullName.split(' ').first ?? ''}',
      ),
      actions: const [StaffTopActions()],
      onRefresh: () async {
        ref.invalidate(workforceDataProvider('home'));
        ref.invalidate(workforceDataProvider('intakes'));
      },
      children: [
        const WorkforceOverview(),
        WorkspaceSection(
          wt(c, 'Assigned patient queue', 'قائمة المرضى المسندين'),
          child: WorkspaceAsync(
            value: ref.watch(workforceDataProvider('intakes')),
            retry: () => ref.invalidate(workforceDataProvider('intakes')),
            builder: (data) {
              final queue = rows(data['rows']);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final intake in queue)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: ReadableLabel(
                        '${intake['patient_name']} · ${intake['national_id'] ?? intake['patient_id']}',
                      ),
                      subtitle: ReadableLabel(
                        '${intake['department'] ?? ''}\n${wallDate(intake['slot_start'])} ${wallTime(intake['slot_start'])} · ${wlabel(c, intake['appointment_status'])}\n${intake['status'] == 'completed' ? wt(c, 'Intake saved', 'تم حفظ التقييم') : wt(c, 'Observations due', 'الملاحظات مطلوبة')}${intake['urgent'] == 1 ? ' · ${wt(c, 'Urgent clinical review', 'مراجعة سريرية عاجلة')}' : ''}',
                      ),
                      onTap: () => showNursingIntake(c, ref, intake),
                    ),
                  if (queue.isEmpty)
                    ReadableLabel(
                      wt(
                        c,
                        'No assigned intakes. The responsible clinician or front desk can assign an active visit.',
                        'لا توجد تقييمات مسندة. يمكن للممارس المسؤول أو الاستقبال إسناد زيارة نشطة.',
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        WorkforceQuickAccess(),
        WorkspaceSection(
          wt(c, 'Needs your attention', 'يحتاج إلى انتباهك'),
          child: ReadableLabel(
            wt(
              c,
              'Review pending observations and your assigned handover work. Missing measurements remain unrecorded.',
              'راجع الملاحظات المعلقة وعمل التسليم المسند إليك. تبقى القياسات المفقودة غير مسجلة.',
            ),
          ),
        ),
      ],
    );
  }
}

class WorkforceQuickAccess extends ConsumerWidget {
  const WorkforceQuickAccess({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final conversations = ref
        .watch(workforceDataProvider('conversations'))
        .valueOrNull;
    final unread = conversations == null
        ? null
        : rows(
            conversations['rows'],
          ).fold<int>(0, (sum, row) => sum + (row['unread'] as num).toInt());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceCardGrid(
          items: [
            WorkspaceItem(
              icon: Icons.swap_horiz,
              title: wt(c, 'Shift handover', 'تسليم المناوبة'),
              description: wt(
                c,
                'Offer owned work and explicitly accept incoming cover.',
                'عرض العمل المملوك وقبول التغطية الواردة صراحةً.',
              ),
              onTap: () => c.push('${AppRoutes.staffTasks}/handover'),
            ),
            WorkspaceItem(
              icon: Icons.work_history_outlined,
              title: wt(c, 'Cover and Time Off', 'التغطية والإجازة'),
              description: wt(
                c,
                'Record availability changes and review conflicts.',
                'تسجيل تغييرات التوفر ومراجعة التعارضات.',
              ),
              onTap: () => c.push('${AppRoutes.staffSchedule}/work'),
            ),
            WorkspaceItem(
              icon: Icons.groups_outlined,
              title: wt(c, 'Team directory', 'دليل الفريق'),
              description: wt(
                c,
                'Find colleagues by name, role and department.',
                'البحث عن الزملاء بالاسم والدور والقسم.',
              ),
              onTap: () => c.push('/staff/team'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        WorkspaceSection(
          wt(c, 'Quick Access', 'وصول سريع'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, ar, route) in [
                (
                  unread == null ? 'Chat' : 'Chat · $unread unread',
                  unread == null
                      ? 'المحادثات'
                      : 'المحادثات · $unread غير مقروءة',
                  AppRoutes.staffChat,
                ),
                ('Schedule', 'الجدول', AppRoutes.staffSchedule),
                (
                  'Documents and records',
                  'الوثائق والسجلات',
                  '/staff/documents',
                ),
                ('Care tools', 'أدوات الرعاية', '/staff/care-tools'),
                ('My activity', 'نشاطي', '/staff/activity'),
                ('Help', 'المساعدة', '/staff/help'),
                ('Handover', 'التسليم', '${AppRoutes.staffTasks}/handover'),
                (
                  'Cover and Time Off',
                  'التغطية والإجازة',
                  '${AppRoutes.staffSchedule}/work',
                ),
                ('Team directory', 'دليل الفريق', '/staff/team'),
                (
                  'Profile and preferences',
                  'الملف والتفضيلات',
                  AppRoutes.staffProfile,
                ),
              ])
                OutlinedButton(
                  onPressed: () => c.push(route),
                  child: ReadableLabel(wt(c, label, ar)),
                ),
            ],
          ),
        ),
      ],
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
