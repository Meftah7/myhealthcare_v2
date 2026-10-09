import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../data/repositories/task_workflow.dart';
import '../../../domain/entities/staff_task.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import '../../patient_chart/presentation/result_review_sheet.dart';
import '../../staff_dashboard/application/staff_providers.dart';

String workText(BuildContext c, String en, String ar) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;

/// The pop result precedes the closing animation. Keep form controllers alive
/// until the route has removed its widgets before the caller disposes them.
Future<T?> showWorkDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}

final taskContextProvider = FutureProvider.autoDispose
    .family<TaskContext, String>((ref, id) async {
      final actor = ref.watch(currentUserProvider)!.id;
      // Scope changes invalidate even an already-open detail screen.
      ref.watch(staffWorkProvider);
      return ref.watch(taskWorkflowProvider).context(id, actor);
    });
final teamWorkProvider = FutureProvider.autoDispose<List<StaffTask>>((ref) {
  final actor = ref.watch(currentUserProvider)!.id;
  ref.watch(staffWorkProvider);
  return ref.watch(taskWorkflowProvider).team(actor);
});

Future<void> changeTask(
  BuildContext context,
  WidgetRef ref,
  StaffTask task,
  TaskStatus status, {
  String? draft,
}) async {
  String? outcome;
  DateTime? reviewAt;
  if ({
    TaskStatus.done,
    TaskStatus.dismissed,
    TaskStatus.waiting,
    TaskStatus.blocked,
  }.contains(status)) {
    final reason = TextEditingController(text: draft);
    var hours = 24;
    final form = GlobalKey<FormState>();
    final accepted = await showWorkDialog<bool>(
      context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(
            workText(c, 'Record outcome / reason', 'تسجيل النتيجة / السبب'),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: reason,
                    minLines: 2,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: workText(
                        c,
                        'Outcome or reason',
                        'النتيجة أو السبب',
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? workText(c, 'Required', 'مطلوب')
                        : null,
                  ),
                  if (status == TaskStatus.waiting ||
                      status == TaskStatus.blocked) ...[
                    Text(
                      workText(
                        c,
                        'Owner remains accountable. Review in:',
                        'يبقى المسؤول مكلفاً بالعمل. المراجعة خلال:',
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: hours,
                      items: [
                        for (final h in [1, 4, 24, 48, 72])
                          DropdownMenuItem(
                            value: h,
                            child: Text('$h ${workText(c, 'hours', 'ساعة')}'),
                          ),
                      ],
                      onChanged: (v) => set(() => hours = v!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(workText(c, 'Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(c, true);
              },
              child: Text(workText(c, 'Save', 'حفظ')),
            ),
          ],
        ),
      ),
    );
    outcome = reason.text.trim();
    reason.dispose();
    if (accepted != true || !context.mounted) return;
    if (status == TaskStatus.waiting || status == TaskStatus.blocked) {
      reviewAt = DateTime.now().add(Duration(hours: hours));
    }
  }
  final result = await ref
      .read(staffOpsProvider)
      .setTaskStatus(
        task.id,
        status,
        expectedVersion: task.version,
        outcome: outcome,
        reviewAt: reviewAt,
      );
  ref.invalidate(taskContextProvider(task.id));
  if (context.mounted) {
    showMutationFeedback(
      context,
      result,
      onRetry: () => changeTask(context, ref, task, status, draft: outcome),
      onReload: () => ref.invalidate(taskContextProvider(task.id)),
    );
  }
}

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(taskContextProvider(id));
    return AppScaffold(
      title: workText(context, 'Work details', 'تفاصيل العمل'),
      centerBody: false,
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e'),
              TextButton(
                onPressed: () => ref.invalidate(taskContextProvider(id)),
                child: Text(workText(context, 'Reload', 'إعادة التحميل')),
              ),
            ],
          ),
        ),
        data: (data) {
          final task = data.task;
          final patient = task.patientId == null
              ? null
              : ref.watch(taskPatientNameProvider(task.patientId!));
          return ListView(
            key: PageStorageKey('work-detail-$id'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${workText(context, 'Patient', 'المريض')}: ${patient?.valueOrNull ?? task.patientId ?? '—'}',
              ),
              Text('${workText(context, 'Owner', 'المسؤول')}: ${data.owner}'),
              if (data.cover != null)
                Text('${workText(context, 'Cover', 'التغطية')}: ${data.cover}'),
              Text('${workText(context, 'Reason', 'السبب')}: ${data.reason}'),
              Text(
                '${workText(context, 'Deadline', 'الموعد النهائي')}: ${task.dueAt == null ? '—' : fmtDateTime(task.dueAt!)}',
              ),
              Text(
                '${workText(context, 'Status', 'الحالة')}: ${task.status.label(context)}',
              ),
              const SizedBox(height: 12),
              Text(
                workText(
                  context,
                  'Next action: open the source, review it and record your decision. Completing this task does not sign notes, release results or issue documents.',
                  'الخطوة التالية: افتح المصدر وراجعه وسجل قرارك. إكمال المهمة لا يوقع الملاحظات ولا ينشر النتائج ولا يصدر الوثائق.',
                ),
              ),
              if (task.patientId != null)
                TextButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.staffPatientChart(task.patientId!),
                  ),
                  icon: const Icon(Icons.person_outline),
                  label: Text(workText(context, 'Patient chart', 'ملف المريض')),
                ),
              for (final source in data.sources)
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text('${source.sourceType}: ${source.sourceId}'),
                  onTap: () => context.push(
                    '/staff/tasks/${Uri.encodeComponent(id)}/source/${Uri.encodeComponent(source.sourceType)}/${Uri.encodeComponent(source.sourceId)}',
                  ),
                ),
              if (task.isOpen)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in [
                      TaskStatus.inProgress,
                      TaskStatus.done,
                      TaskStatus.dismissed,
                      TaskStatus.waiting,
                      TaskStatus.blocked,
                    ])
                      OutlinedButton(
                        onPressed: () => changeTask(context, ref, task, status),
                        child: Text(switch (status) {
                          TaskStatus.inProgress => workText(
                            context,
                            'Start / resume',
                            'بدء / استئناف',
                          ),
                          TaskStatus.done => workText(
                            context,
                            'Complete',
                            'إكمال',
                          ),
                          TaskStatus.dismissed => workText(
                            context,
                            'Dismiss',
                            'استبعاد',
                          ),
                          TaskStatus.waiting => workText(
                            context,
                            'Waiting',
                            'انتظار',
                          ),
                          _ => workText(context, 'Blocked', 'متعطل'),
                        }),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => offerWork(context, ref, [task]),
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(
                        workText(
                          context,
                          'Cover / escalate / reassign',
                          'تغطية / تصعيد / إعادة إسناد',
                        ),
                      ),
                    ),
                  ],
                ),
              const Divider(),
              Text(
                workText(context, 'History and reasons', 'السجل والأسباب'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (data.history.isEmpty)
                Text(
                  workText(
                    context,
                    'Legacy work: no recorded history.',
                    'عمل سابق: لا يوجد سجل محفوظ.',
                  ),
                ),
              for (final h in data.history)
                ListTile(
                  title: Text(historyLabel(context, h.action)),
                  subtitle: Text(
                    '${fmtDateTime(h.at)} · ${h.actorAccountId}\n${h.outcome ?? ''}\n${historyDetail(context, h.afterJson)}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String historyLabel(BuildContext context, String action) => switch (action) {
  'task.transition' => workText(context, 'Status changed', 'تغيير الحالة'),
  'task.offer' => workText(
    context,
    'Responsibility offered',
    'طلب تسليم المسؤولية',
  ),
  'task.offer.accepted' => workText(
    context,
    'Responsibility accepted',
    'قبول المسؤولية',
  ),
  'task.offer.declined' => workText(
    context,
    'Responsibility declined',
    'رفض المسؤولية',
  ),
  _ => workText(context, 'Work created', 'إنشاء العمل'),
};
String historyDetail(BuildContext context, String value) {
  final data = jsonDecode(value) as Map<String, dynamic>;
  return [
    if (data['status'] != null)
      '${workText(context, 'Status', 'الحالة')}: ${data['status']}',
    if (data['owner'] != null)
      '${workText(context, 'Owner', 'المسؤول')}: ${data['owner']}',
    if (data['recipient'] != null)
      '${workText(context, 'Recipient', 'المستلم')}: ${data['recipient']}',
    if (data['reviewAt'] != null)
      '${workText(context, 'Review at', 'المراجعة في')}: ${fmtDateTime(DateTime.parse(data['reviewAt'] as String))}',
    if (data['expires'] != null)
      '${workText(context, 'Cover expiry', 'نهاية التغطية')}: ${fmtDateTime(DateTime.parse(data['expires'] as String))}',
  ].join('\n');
}

Future<void> offerWork(
  BuildContext context,
  WidgetRef ref,
  List<StaffTask> tasks,
) async {
  final actor = ref.read(currentUserProvider)!.id;
  final people = await Result.guardAsync(
    () => ref.read(taskWorkflowProvider).recipients(actor),
  );
  if (!context.mounted) return;
  if (people.isErr) {
    showMutationFeedback(context, people);
    return;
  }
  final reason = TextEditingController();
  String? recipient;
  var hours = 24;
  var mode = 'cover';
  final form = GlobalKey<FormState>();
  final ok = await showWorkDialog<bool>(
    context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(workText(c, 'Offer responsibility', 'طلب قبول المسؤولية')),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  workText(
                    c,
                    '${tasks.length} items. Responsibility stays with the owner until acceptance. Cover access expires; reassignment access lasts until the work closes.',
                    '${tasks.length} مهام. تبقى المسؤولية مع المسؤول حتى القبول. تنتهي صلاحية التغطية؛ وتبقى صلاحية إعادة الإسناد حتى إغلاق العمل.',
                  ),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: workText(c, 'Colleague', 'الزميل'),
                  ),
                  items: [
                    for (final p in people.valueOrNull!)
                      DropdownMenuItem(value: p.id, child: Text(p.fullName)),
                  ],
                  onChanged: (v) => recipient = v,
                  validator: (v) =>
                      v == null ? workText(c, 'Required', 'مطلوب') : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  items: [
                    for (final m in ['cover', 'escalate', 'reassign'])
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => set(() => mode = v!),
                ),
                DropdownButtonFormField<int>(
                  initialValue: hours,
                  decoration: InputDecoration(
                    labelText: workText(
                      c,
                      'Cover expires in hours',
                      'تنتهي التغطية خلال ساعات',
                    ),
                  ),
                  items: [
                    for (final h in [4, 12, 24, 48, 72])
                      DropdownMenuItem(value: h, child: Text('$h')),
                  ],
                  onChanged: (v) => hours = v!,
                ),
                TextFormField(
                  controller: reason,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: workText(
                      c,
                      'Reason / handover instructions',
                      'السبب / تعليمات التسليم',
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? workText(c, 'Required', 'مطلوب')
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(workText(c, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(c, true);
            },
            child: Text(workText(c, 'Send offer', 'إرسال الطلب')),
          ),
        ],
      ),
    ),
  );
  final note = reason.text;
  reason.dispose();
  if (ok != true || !context.mounted) return;
  final result = await Result.guardAsync(
    () => ref
        .read(taskWorkflowProvider)
        .offer(
          actor: actor,
          tasks: {for (final t in tasks) t.id: t.version},
          recipient: recipient!,
          reason: note,
          expires: DateTime.now().add(Duration(hours: hours)),
          reassign: mode == 'reassign',
          urgent: mode == 'escalate',
        ),
  );
  ref.invalidate(staffWorkProvider);
  if (context.mounted) showMutationFeedback(context, result);
}

final pendingHandoverProvider = FutureProvider.autoDispose(
  (ref) => ref
      .watch(taskWorkflowProvider)
      .pending(ref.watch(currentUserProvider)!.id),
);

final taskSourceProvider = FutureProvider.autoDispose
    .family<
      ({String text, String? route, String? recordId}),
      ({String task, String type, String source})
    >((ref, key) async {
      final context = await ref.watch(taskContextProvider(key.task).future);
      if (!context.sources.any(
        (s) => s.sourceType == key.type && s.sourceId == key.source,
      )) {
        throw StateError('Source is not linked to this work.');
      }
      final db = ref.watch(appDatabaseProvider);
      final patient = context.task.patientId!;
      Future<void> validate(String subject) async {
        if (subject != patient) {
          throw const AccessDeniedFailure(
            'Source patient does not match this work.',
          );
        }
        await ref.read(accessPolicyProvider).readPatient(subject);
      }

      if (key.type == 'visit') {
        final visit = await (db.select(
          db.appointments,
        )..where((a) => a.id.equals(key.source))).getSingle();
        await validate(visit.patientId);
        final draft = await (db.select(
          db.encounterDrafts,
        )..where((d) => d.appointmentId.equals(key.source))).getSingleOrNull();
        if (draft != null) await validate(draft.patientId);
        return (
          text: draft?.note ?? 'Draft unavailable',
          route: AppRoutes.staffConsultation(key.source),
          recordId: null,
        );
      }
      if (key.type == 'document') {
        final request = await (db.select(
          db.documentRequests,
        )..where((d) => d.id.equals(key.source))).getSingle();
        await validate(request.patientId);
        return (
          text: '${request.status}\n${request.id}',
          route:
              '${AppRoutes.staffPatients}/$patient/documents?appointmentId=${request.appointmentId ?? ''}',
          recordId: null,
        );
      }
      if (key.type == 'reply') {
        final message = await (db.select(
          db.careMessages,
        )..where((m) => m.id.equals(key.source))).getSingle();
        await validate(message.patientId);
        return (
          text: '${fmtDateTime(message.sentAt)}\n${message.body}',
          route: AppRoutes.staffInboxThread(patient, ownerId: message.staffId),
          recordId: null,
        );
      }
      if (key.type == 'referral_request') {
        final request = await (db.select(
          db.referralRequests,
        )..where((r) => r.id.equals(key.source))).getSingle();
        await validate(request.patientId);
        return (
          text:
              '${request.reason}\n${request.status.name}\n${request.handoverNote ?? ''}\n${request.decisionNote ?? ''}',
          route: AppRoutes.staffPatientChart(patient),
          recordId: null,
        );
      }
      var recordId = key.source;
      if (key.type == 'result') {
        recordId = (await (db.select(
          db.resultReviews,
        )..where((r) => r.id.equals(key.source))).getSingle()).recordId;
      }
      if (key.type == 'risk') {
        final risk = await (db.select(
          db.riskFlags,
        )..where((r) => r.id.equals(key.source))).getSingle();
        await validate(risk.patientId);
        return (
          text: '${risk.kind.name}\n${risk.rationale}\n${risk.source}',
          route: AppRoutes.staffPatientChart(patient),
          recordId: null,
        );
      }
      final record = await (db.select(
        db.medicalRecords,
      )..where((r) => r.id.equals(recordId))).getSingle();
      await validate(record.patientId);
      return (
        text:
            '${record.title}\n${fmtDateTime(record.occurredAt)}\n${record.body ?? ''}',
        route: AppRoutes.staffPatientChart(patient),
        recordId: recordId,
      );
    });

class TaskSourceScreen extends ConsumerWidget {
  const TaskSourceScreen({
    required this.task,
    required this.type,
    required this.source,
    super.key,
  });
  final String task, type, source;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: workText(context, 'Source', 'المصدر'),
    body: ref
        .watch(taskSourceProvider((task: task, type: type, source: source)))
        .when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (value) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SelectableText(value.text),
              if (value.recordId != null)
                TextButton(
                  onPressed: () => showResultSheet(context, value.recordId!),
                  child: Text(
                    workText(
                      context,
                      'Open exact record and review',
                      'فتح السجل ومراجعته',
                    ),
                  ),
                ),
              if (value.route != null)
                TextButton(
                  onPressed: () => context.push(value.route!),
                  child: Text(
                    workText(
                      context,
                      'Open source workspace',
                      'فتح مساحة عمل المصدر',
                    ),
                  ),
                ),
            ],
          ),
        ),
  );
}

class HandoverScreen extends ConsumerStatefulWidget {
  const HandoverScreen({super.key});
  @override
  ConsumerState<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends ConsumerState<HandoverScreen> {
  final selected = <String>{};
  bool busy = false;
  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    final result = await Result.guardAsync(action);
    ref.invalidate(pendingHandoverProvider);
    ref.invalidate(staffWorkProvider);
    if (mounted) {
      setState(() => busy = false);
      showMutationFeedback(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentUserProvider)!.id;
    final pending = ref.watch(pendingHandoverProvider);
    final work = ref.watch(staffWorkProvider);
    return AppScaffold(
      title: workText(context, 'Shift handover', 'تسليم المناوبة'),
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            workText(context, 'Incoming responsibility', 'المسؤولية الواردة'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          pending.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (offers) => Column(
              children: [
                if (offers.isEmpty)
                  Text(
                    workText(
                      context,
                      'No pending offers.',
                      'لا توجد طلبات معلقة.',
                    ),
                  ),
                for (final o in offers)
                  Card(
                    child: ListTile(
                      title: Text('${o.count} · ${o.sender}'),
                      subtitle: Text(fmtDateTime(o.expires)),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: workText(
                              context,
                              'Accept responsibility',
                              'قبول المسؤولية',
                            ),
                            onPressed: busy
                                ? null
                                : () => run(
                                    () => ref
                                        .read(taskWorkflowProvider)
                                        .decide(actor, o.bundle, accept: true),
                                  ),
                            icon: const Icon(Icons.check),
                          ),
                          IconButton(
                            tooltip: workText(context, 'Decline', 'رفض'),
                            onPressed: busy
                                ? null
                                : () => run(
                                    () => ref
                                        .read(taskWorkflowProvider)
                                        .decide(actor, o.bundle, accept: false),
                                  ),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(() async {
                    await ref.read(staffOpsProvider).refreshPanel();
                    await ref.read(taskWorkflowProvider).generate(actor);
                  }),
            icon: const Icon(Icons.refresh),
            label: Text(
              workText(
                context,
                'Refresh unfinished work, results and replies',
                'تحديث العمل والنتائج والردود غير المكتملة',
              ),
            ),
          ),
          work.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (tasks) {
              final open = tasks.where((t) => t.isOpen).toList();
              return Column(
                children: [
                  for (final t in open)
                    CheckboxListTile(
                      value: selected.contains(t.id),
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              if (v!) {
                                selected.add(t.id);
                              } else {
                                selected.remove(t.id);
                              }
                            }),
                      title: Text(t.title),
                      subtitle: Text(
                        '${t.priority.name} · ${t.patientId ?? ''}',
                      ),
                    ),
                  FilledButton(
                    onPressed: busy || !open.any((t) => selected.contains(t.id))
                        ? null
                        : () => offerWork(
                            context,
                            ref,
                            open.where((t) => selected.contains(t.id)).toList(),
                          ),
                    child: Text(
                      workText(
                        context,
                        'Offer selected work',
                        'تسليم العمل المحدد',
                      ),
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
