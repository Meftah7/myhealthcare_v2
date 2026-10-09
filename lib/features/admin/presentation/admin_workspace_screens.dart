import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../data/repositories/admin_workspace.dart';
import '../../../domain/identity/permissions.dart';
import '../../auth/application/session.dart';
import '../../tasks/presentation/task_detail_screen.dart' show showWorkDialog;
import 'admin_top_actions.dart';
import 'admin_workspace_shared.dart';

export 'admin_configuration_screen.dart';
export 'admin_hub_screen.dart';
export 'admin_operations_report_screen.dart';
export 'admin_search_screen.dart';
export 'admin_workspace_shared.dart';

String _historySubtitle(
  BuildContext c,
  String reason,
  String json,
  Map<String, String> names,
) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  final owner = data['owner'] as String?;
  final status = data['status'] as String?;
  final label = switch (status) {
    'waiting' => adminText(c, 'Waiting', 'بانتظار الرد'),
    'resolved' => adminText(c, 'Resolved', 'تم الحل'),
    _ => adminText(c, 'Open', 'مفتوح'),
  };
  return '$reason\n$label · ${names[owner] ?? owner ?? '—'}';
}

class AdminWorkspaceOverview extends ConsumerStatefulWidget {
  const AdminWorkspaceOverview({super.key});
  @override
  ConsumerState<AdminWorkspaceOverview> createState() => _OverviewState();
}

class _OverviewState extends ConsumerState<AdminWorkspaceOverview> {
  late final Timer _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => ref
      .watch(adminWorkProvider)
      .when(
        loading: () => Column(
          children: [
            const LinearProgressIndicator(),
            Text(
              adminText(
                c,
                'Checking operational queues…',
                'جار التحقق من قوائم العمل…',
              ),
            ),
          ],
        ),
        error: (e, _) => Column(
          children: [
            Text(
              adminText(
                c,
                'Queues could not be checked.',
                'تعذر التحقق من قوائم العمل',
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(adminWorkProvider),
              child: Text(adminText(c, 'Retry', 'إعادة المحاولة')),
            ),
          ],
        ),
        data: (rows) {
          final open = {
            for (final w in rows.where((w) => w.state != 'resolved')) w.id: w,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReadableLabel(
                '${adminText(c, 'Operational items needing attention', 'عناصر المتابعة الإدارية')}: ${open.length}',
                style: Theme.of(c).textTheme.headlineSmall,
              ),
              for (final (en, ar, filter, count) in [
                (
                  'Unassigned',
                  'غير مسند',
                  'unassigned',
                  open.values.where((w) => w.owner == null).length,
                ),
                (
                  'Overdue',
                  'متأخر',
                  'overdue',
                  open.values.where((w) => w.overdue).length,
                ),
                (
                  'Document approvals',
                  'اعتمادات المستندات',
                  'document',
                  open.values
                      .where((w) => w.type == AdminQueue.document)
                      .length,
                ),
                (
                  'Delivery failures',
                  'فشل التسليم',
                  'delivery',
                  open.values
                      .where((w) => w.type == AdminQueue.delivery)
                      .length,
                ),
              ])
                ListTile(
                  title: Text(adminText(c, en, ar)),
                  trailing: Text('$count'),
                  onTap: () => c.push('/admin/work?filter=$filter'),
                ),
            ],
          );
        },
      );
}

final adminWorkProvider = StreamProvider.autoDispose<List<AdminWork>>((ref) {
  ref.watch(currentUserProvider);
  final db = ref.watch(appDatabaseProvider);
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.adminWorkItems,
          db.referralRequests,
          db.homeVisitRequests,
          db.resultReviews,
          db.careMessages,
          db.documentRequests,
          db.outboxEvents,
          db.reminders,
          db.documentDeliveryEvents,
          db.feedbacks,
          db.users,
        },
      )
      .watch()
      .asyncMap((_) => ref.read(adminWorkspaceProvider).queue());
});
final adminOwnerNamesProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(adminWorkspaceProvider);
  await service.authorize(Permission.viewOperationalReports);
  return {
    for (final u in await service.db.select(service.db.users).get())
      u.id: u.fullName,
  };
});

class AdminUnifiedWorkScreen extends ConsumerStatefulWidget {
  const AdminUnifiedWorkScreen({this.filter, this.item, super.key});
  final String? filter, item;
  @override
  ConsumerState<AdminUnifiedWorkScreen> createState() => _AdminWorkState();
}

class _AdminWorkState extends ConsumerState<AdminUnifiedWorkScreen> {
  late final Timer _clock;
  final _drafts =
      <String, ({String owner, String status, DateTime due, String reason})>{};
  String search = '', state = 'open';
  String? filter;
  @override
  void initState() {
    super.initState();
    filter = widget.filter;
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminWorkProvider);
    final names =
        ref.watch(adminOwnerNamesProvider).valueOrNull ??
        const <String, String>{};
    return AppScaffold(
      title: adminText(context, 'Work', 'العمل'),
      actions: const [AdminTopActions()],
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: adminText(
                context,
                'Search work or owner',
                'البحث عن عمل أو مسؤول',
              ),
            ),
            onChanged: (v) => setState(() => search = v.toLowerCase()),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final f in [
                'all',
                'unassigned',
                'overdue',
                ...AdminQueue.values.map((q) => q.name),
              ])
                ChoiceChip(
                  label: Text(queueFilterLabel(context, f)),
                  selected: filter == f || filter == null && f == 'all',
                  onSelected: (_) => setState(() => filter = f),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final s in ['open', 'waiting', 'resolved'])
                ChoiceChip(
                  label: Text(switch (s) {
                    'open' => adminText(context, 'Open', 'مفتوح'),
                    'waiting' => adminText(context, 'Waiting', 'بانتظار الرد'),
                    _ => adminText(context, 'Resolved', 'تم الحل'),
                  }),
                  selected: state == s,
                  onSelected: (_) => setState(() => state = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          data.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Column(
              children: [
                Text(
                  adminText(
                    context,
                    'Could not load work.',
                    'تعذر تحميل العمل',
                  ),
                ),
                Text('$e'),
                TextButton(
                  onPressed: () => ref.invalidate(adminWorkProvider),
                  child: Text(adminText(context, 'Retry', 'إعادة المحاولة')),
                ),
              ],
            ),
            data: (items) {
              final rows = items
                  .where(
                    (w) =>
                        w.state == state &&
                        (filter == null ||
                            filter == 'all' ||
                            filter == w.type.name ||
                            filter == 'unassigned' && w.owner == null ||
                            filter == 'overdue' && w.overdue) &&
                        '${w.sourceId} ${names[w.owner] ?? ''} ${queueLabel(context, w.type)}'
                            .toLowerCase()
                            .contains(search) &&
                        (widget.item == null || widget.item == w.id),
                  )
                  .toList();
              if (rows.isEmpty) {
                return Text(
                  adminText(context, 'No matching work.', 'لا يوجد عمل مطابق'),
                );
              }
              return Column(
                children: [
                  for (final w in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${queueLabel(context, w.type)} · ${w.sourceId}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${adminText(context, 'Operational owner', 'مسؤول المتابعة')}: ${names[w.owner] ?? w.owner ?? adminText(context, 'Unassigned', 'غير مسند')}',
                              ),
                              Text(
                                '${adminText(context, 'Waiting since', 'بانتظار منذ')}: ${fmtDateTime(w.created)}',
                              ),
                              Text(
                                '${adminText(context, 'Due', 'الموعد')}: ${w.due == null ? '—' : fmtDateTime(w.due!)}${w.overdue ? ' · ${adminText(context, 'Overdue', 'متأخر')}' : ''}',
                              ),
                              Text(
                                adminText(
                                  context,
                                  w.nextAction,
                                  switch (w.type) {
                                    AdminQueue.review =>
                                      'تعيين طبيب مؤهل لمراجعة النتيجة',
                                    AdminQueue.reply =>
                                      'متابعة رد الفريق السريري',
                                    AdminQueue.referral =>
                                      'تنسيق الإحالة أو طلب توضيح',
                                    AdminQueue.homeVisit =>
                                      'فرز أو ترتيب زيارة منزلية',
                                    AdminQueue.document =>
                                      'إعداد المستند وإحالته للاعتماد المصرح',
                                    AdminQueue.delivery =>
                                      'مراجعة فشل التسليم وإعادة المحاولة',
                                    AdminQueue.feedback =>
                                      'التحقيق وتسجيل نتيجة المتابعة',
                                  },
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _edit(w),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(
                                      adminText(
                                        context,
                                        'Assign / update',
                                        'إسناد / تحديث',
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push(w.route),
                                    child: Text(
                                      adminText(
                                        context,
                                        'Open source controls',
                                        'فتح إجراءات المصدر',
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _history(w, names),
                                    child: Text(
                                      adminText(context, 'History', 'السجل'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Future<void> _edit(AdminWork item) async {
    final service = ref.read(adminWorkspaceProvider);
    final owners = await service.owners();
    if (!mounted) return;
    String owner = owners.any((o) => o.id == item.owner)
        ? item.owner!
        : ref.read(currentUserProvider)!.id;
    var status = item.state;
    var due = item.due ?? DateTime.now().add(const Duration(days: 1));
    final draft = _drafts[item.id];
    if (draft != null) {
      owner = draft.owner;
      status = draft.status;
      due = draft.due;
    }
    final reason = TextEditingController(text: draft?.reason);
    final form = GlobalKey<FormState>();
    try {
      final save = await showWorkDialog<bool>(
        context,
        builder: (c) => StatefulBuilder(
          builder: (c, set) => AlertDialog(
            title: Text(
              adminText(
                c,
                'Update operational work',
                'تحديث المتابعة الإدارية',
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      adminText(
                        c,
                        'Source clinical decisions remain separate.',
                        'تبقى القرارات السريرية ضمن إجراءات المصدر.',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: owner,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: adminText(c, 'Owner', 'المسؤول'),
                      ),
                      items: [
                        for (final o in owners)
                          DropdownMenuItem(
                            value: o.id,
                            child: Text(o.fullName),
                          ),
                      ],
                      onChanged: (v) => set(() => owner = v!),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: adminText(c, 'Next state', 'الحالة التالية'),
                      ),
                      items: [
                        for (final s in ['open', 'waiting', 'resolved'])
                          DropdownMenuItem(
                            value: s,
                            child: Text(switch (s) {
                              'open' => adminText(c, 'Open', 'مفتوح'),
                              'waiting' => adminText(
                                c,
                                'Request information',
                                'طلب معلومات',
                              ),
                              _ => adminText(
                                c,
                                'Resolve coordination',
                                'إنهاء المتابعة',
                              ),
                            }),
                          ),
                      ],
                      onChanged: (v) => set(() => status = v!),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: c,
                          initialDate: due.isBefore(DateTime.now())
                              ? DateTime.now()
                              : due,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          set(
                            () => due = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              17,
                            ),
                          );
                        }
                      },
                      child: Text(
                        '${adminText(c, 'Due / review', 'موعد المراجعة')}: ${fmtDateTime(due)}',
                      ),
                    ),
                    TextFormField(
                      controller: reason,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: adminText(
                          c,
                          'Reason, information needed or outcome',
                          'السبب أو المعلومات المطلوبة أو النتيجة',
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? adminText(c, 'Required', 'مطلوب')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(adminText(c, 'Cancel', 'إلغاء')),
              ),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) Navigator.pop(c, true);
                },
                child: Text(adminText(c, 'Save', 'حفظ')),
              ),
            ],
          ),
        ),
      );
      if (save != true) return;
      final result = await Result.guardAsync(
        () => service.updateWork(
          item,
          owner: owner,
          due: due,
          status: status,
          reason: reason.text,
        ),
      );
      if (!mounted) return;
      if (result.isErr) {
        _drafts[item.id] = (
          owner: owner,
          status: status,
          due: due,
          reason: reason.text,
        );
      } else {
        _drafts.remove(item.id);
      }
      showMutationFeedback(
        context,
        result,
        onRetry: () => _edit(item),
        onReload: () => ref.invalidate(adminWorkProvider),
      );
    } finally {
      reason.dispose();
    }
  }

  Future<void> _history(AdminWork item, Map<String, String> names) async {
    final result = await Result.guardAsync(
      () => ref.read(adminWorkspaceProvider).history(item),
    );
    if (!mounted) return;
    if (result.isErr) {
      showMutationFeedback(context, result);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          adminText(
            c,
            'Assignment and resolution history',
            'سجل الإسناد والمتابعة',
          ),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final h in result.valueOrNull!)
                  ListTile(
                    title: Text(
                      '${names[h.actorId] ?? h.actorId} · ${fmtDateTime(h.at)}',
                    ),
                    subtitle: Text(
                      _historySubtitle(c, h.reason, h.afterJson, names),
                    ),
                  ),
                if (result.valueOrNull!.isEmpty)
                  Text(
                    adminText(
                      c,
                      'No changes recorded.',
                      'لا توجد تغييرات مسجلة',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(adminText(c, 'Close', 'إغلاق')),
          ),
        ],
      ),
    );
  }
}
