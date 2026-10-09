import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../data/repositories/admin_workspace.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/identity/permissions.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import 'admin_top_actions.dart';
import 'admin_workspace_screens.dart';
import 'verify_document_screen.dart';

final adminDocumentRegistryProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(adminWorkspaceProvider);
  await service.authorize(Permission.manageSettings);
  final db = service.db;
  final names = {
    for (final u in await db.select(db.users).get()) u.id: u.fullName,
  };
  final requests = await db.select(db.documentRequests).get();
  final copies = await db.select(db.issuedDocumentVersions).get();
  final artifacts = {
    for (final a in await db.select(db.documentArtifacts).get())
      a.issuedVersionId: a,
  };
  final deliveries = await db.select(db.documentDeliveryEvents).get();
  final verification = await db.select(db.documentVerifications).get();
  return [
    for (final r in requests)
      {
        'id': r.id,
        'patient': r.patientId,
        'name': names[r.patientId] ?? r.patientId,
        'status': r.status,
        'copies': [
          for (final d in copies.where((d) => d.requestId == r.id))
            {
              'id': d.id,
              'version': d.version,
              'type': d.documentType,
              'issued': fmtDateTime(d.issuedAt),
              'artifact': artifacts[d.id]?.status ?? 'pending',
              'supersedes': d.supersedesId,
              'verification':
                  verification
                      .where((v) => v.issuedVersionId == d.id)
                      .firstOrNull
                      ?.validity ??
                  'unknown',
              'delivery': deliveries
                  .where((e) => e.issuedVersionId == d.id)
                  .map((e) => '${e.channel}: ${e.status}')
                  .join(', '),
            },
        ],
      },
  ];
});

class AdminDocumentRegistryScreen extends ConsumerStatefulWidget {
  const AdminDocumentRegistryScreen({super.key});
  @override
  ConsumerState<AdminDocumentRegistryScreen> createState() => _RegistryState();
}

class _RegistryState extends ConsumerState<AdminDocumentRegistryScreen> {
  String search = '', status = 'all';
  @override
  Widget build(BuildContext c) => AppScaffold(
    title: adminText(c, 'Document center', 'مركز المستندات'),
    actions: const [AdminTopActions()],
    centerBody: false,
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: adminText(
              c,
              'Patient or document reference',
              'المريض أو مرجع المستند',
            ),
          ),
          onChanged: (v) => setState(() => search = v.toLowerCase()),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final s in ['all', 'draft', 'submitted', 'approved', 'issued'])
              ChoiceChip(
                label: Text(switch (s) {
                  'all' => adminText(c, 'All', 'الكل'),
                  'draft' => adminText(c, 'Draft', 'مسودة'),
                  'submitted' => adminText(c, 'Submitted', 'مقدم'),
                  'approved' => adminText(c, 'Approved', 'معتمد'),
                  _ => adminText(c, 'Issued', 'صادر'),
                }),
                selected: status == s,
                onSelected: (_) => setState(() => status = s),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => openVerifyDocument(c),
              icon: const Icon(Icons.verified_outlined),
              label: Text(adminText(c, 'Verify a document', 'التحقق من مستند')),
            ),
            TextButton(
              onPressed: () => ref.invalidate(adminDocumentRegistryProvider),
              child: Text(adminText(c, 'Refresh', 'تحديث')),
            ),
            TextButton(
              onPressed: () => c.push('/admin/users'),
              child: Text(
                adminText(c, 'Prepare for a patient', 'إعداد مستند لمريض'),
              ),
            ),
          ],
        ),
        ref
            .watch(adminDocumentRegistryProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (all) {
                final rows = all
                    .where(
                      (r) =>
                          (status == 'all' || r['status'] == status) &&
                          '${r['id']} ${r['name']} ${r['copies']}'
                              .toLowerCase()
                              .contains(search),
                    )
                    .toList();
                if (rows.isEmpty) {
                  return Text(
                    adminText(
                      c,
                      'No matching documents.',
                      'لا توجد مستندات مطابقة',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final r in rows)
                      Card(
                        child: ExpansionTile(
                          title: Text('${r['name']} · ${r['status']}'),
                          subtitle: Text('${r['id']}'),
                          childrenPadding: const EdgeInsets.all(16),
                          children: [
                            for (final d
                                in r['copies'] as List<Map<String, Object?>>)
                              ListTile(
                                title: Text('${d['type']} · ${d['id']}'),
                                subtitle: Text(
                                  '${d['issued']}\n${adminText(c, 'Render / verification / delivery', 'التوليد / التحقق / التسليم')}: ${d['artifact']} / ${d['verification']} / ${d['delivery']}\n${d['supersedes'] == null ? '' : '${adminText(c, 'Replaces', 'يستبدل')}: ${d['supersedes']}'}',
                                ),
                              ),
                            TextButton(
                              onPressed: () => c.push(
                                '/admin/profile/document-workspace?patientId=${Uri.encodeComponent(r['patient'] as String)}',
                              ),
                              child: Text(
                                adminText(
                                  c,
                                  'Open authorized requests, copies and replacements',
                                  'فتح الطلبات والنسخ والبدائل المصرح بها',
                                ),
                              ),
                            ),
                          ],
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

final adminScheduleProvider = FutureProvider.autoDispose.family((
  ref,
  String id,
) async {
  final service = ref.watch(adminWorkspaceProvider);
  await service.authorize(Permission.manageClinicSchedules);
  final repo = ref.watch(appointmentRepositoryProvider);
  final templates = await repo.templatesFor(id);
  if (templates.isErr) throw templates.failureOrNull!;
  final exceptions = await repo.availabilityExceptions(
    id,
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().add(const Duration(days: 90)),
  );
  if (exceptions.isErr) throw exceptions.failureOrNull!;
  final db = service.db;
  final cover = await (db.select(
    db.staffTasks,
  )..where((t) => t.coverageStaffId.equals(id))).get();
  return (
    templates: templates.valueOrNull!,
    bookings: await service.affectedBookings(id),
    exceptions: exceptions.valueOrNull!,
    cover: cover,
  );
});

class AdminStaffScheduleScreen extends ConsumerStatefulWidget {
  const AdminStaffScheduleScreen({super.key});
  @override
  ConsumerState<AdminStaffScheduleScreen> createState() => _ScheduleState();
}

class _ScheduleState extends ConsumerState<AdminStaffScheduleScreen> {
  String? staff, replacement;
  bool busy = false;
  @override
  Widget build(BuildContext c) {
    final people = ref.watch(staffDirectoryProvider);
    return AppScaffold(
      title: adminText(
        c,
        'Schedules, cover and capacity',
        'الجداول والتغطية والسعة',
      ),
      actions: const [AdminTopActions()],
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          people.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (rows) => DropdownButtonFormField<String>(
              initialValue: staff,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: adminText(c, 'Staff member', 'الموظف'),
              ),
              items: [
                for (final s in rows.where((s) => s.user.isActive))
                  DropdownMenuItem(value: s.id, child: Text(s.fullName)),
              ],
              onChanged: (v) => setState(() {
                staff = v;
                replacement = null;
              }),
            ),
          ),
          if (staff != null)
            ref
                .watch(adminScheduleProvider(staff!))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        '${adminText(c, 'Weekly slot capacity', 'سعة المواعيد الأسبوعية')}: ${data.templates.fold<int>(0, (sum, t) => sum + (t.endMinutes - t.startMinutes) ~/ t.slotMinutes)}',
                      ),
                      for (final t in data.templates)
                        ListTile(
                          title: Text(
                            '${adminText(c, 'Weekday', 'يوم الأسبوع')} ${t.weekday} · ${t.startMinutes ~/ 60}:${(t.startMinutes % 60).toString().padLeft(2, '0')} – ${t.endMinutes ~/ 60}:${(t.endMinutes % 60).toString().padLeft(2, '0')}',
                          ),
                          subtitle: Text(
                            '${adminText(c, 'Slot minutes', 'دقائق الموعد')}: ${t.slotMinutes}',
                          ),
                        ),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => _editSchedule(data.templates),
                        child: Text(
                          adminText(
                            c,
                            'Edit recurring schedule',
                            'تعديل الجدول الأسبوعي',
                          ),
                        ),
                      ),
                      Text(
                        '${adminText(c, 'Affected active bookings', 'الحجوزات النشطة المتأثرة')}: ${data.bookings.length}',
                      ),
                      for (final a in data.bookings)
                        ListTile(
                          title: Text('${a.id} · ${fmtDateTime(a.slotStart)}'),
                          subtitle: Text(a.status.name),
                        ),
                      DropdownButtonFormField<String>(
                        key: ValueKey(staff),
                        initialValue: replacement,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: adminText(
                            c,
                            'Replacement doctor',
                            'الطبيب البديل',
                          ),
                        ),
                        items: [
                          for (final s in people.valueOrNull ?? <Staff>[])
                            if (s.id != staff && s.user.isActive && s.isDoctor)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(s.fullName),
                              ),
                        ],
                        onChanged: (v) => setState(() => replacement = v),
                      ),
                      OutlinedButton(
                        onPressed:
                            busy || replacement == null || data.bookings.isEmpty
                            ? null
                            : () async {
                                final reason = await _reason(
                                  c,
                                  adminText(
                                    c,
                                    'Move these bookings to the replacement?',
                                    'نقل هذه الحجوزات إلى البديل؟',
                                  ),
                                );
                                if (reason == null) return;
                                await _run(
                                  () => ref
                                      .read(adminWorkspaceProvider)
                                      .moveBookings(
                                        staff!,
                                        replacement!,
                                        data.bookings,
                                        reason,
                                      ),
                                );
                              },
                        child: Text(
                          adminText(
                            c,
                            'Confirm replacement for previewed bookings',
                            'تأكيد البديل للحجوزات المعروضة',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        adminText(c, 'Recorded cover', 'التغطية المسجلة'),
                        style: Theme.of(c).textTheme.titleMedium,
                      ),
                      for (final t in data.cover)
                        ListTile(
                          title: Text(t.id),
                          subtitle: Text(
                            '${adminText(c, 'Original owner', 'المسؤول الأصلي')}: ${t.staffId} · ${t.status.name}',
                          ),
                        ),
                      Text(
                        adminText(
                          c,
                          'Clinical responsibility uses explicit staff handover acceptance. Booking changes do not transfer notes or signing authority.',
                          'تتطلب المسؤولية السريرية قبول تسليم العمل. لا تنقل تغييرات الحجز الملاحظات أو صلاحية التوقيع.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        adminText(c, 'Time off', 'الإجازات'),
                        style: Theme.of(c).textTheme.titleMedium,
                      ),
                      for (final e in data.exceptions)
                        ListTile(
                          title: Text(
                            '${fmtDateTime(e.start)} – ${fmtDateTime(e.end)}',
                          ),
                          subtitle: Text(e.reason ?? ''),
                        ),
                      OutlinedButton(
                        onPressed: busy ? null : _timeOff,
                        child: Text(
                          adminText(
                            c,
                            'Add time off after booking replacement',
                            'إضافة إجازة بعد تعيين بديل للحجوزات',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => busy = true);
    final result = await Result.guardAsync(action);
    if (!mounted) return;
    setState(() => busy = false);
    showMutationFeedback(context, result);
    ref.invalidate(adminScheduleProvider(staff!));
  }

  Future<void> _editSchedule(List<ScheduleTemplate> current) async {
    final days = current.map((t) => t.weekday).toSet();
    var start = 8, end = 17, slot = 20;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(adminText(c, 'Recurring hours', 'الساعات الأسبوعية')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adminText(
                    c,
                    'Previewed bookings must remain covered. Conflicts prevent saving.',
                    'يجب أن تبقى الحجوزات المعروضة مغطاة. تمنع التعارضات الحفظ.',
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      FilterChip(
                        label: Text('$d'),
                        selected: days.contains(d),
                        onSelected: (v) => set(() {
                          v ? days.add(d) : days.remove(d);
                        }),
                      ),
                  ],
                ),
                for (final kind in ['start', 'end', 'slot'])
                  DropdownButtonFormField<int>(
                    initialValue: switch (kind) {
                      'start' => start,
                      'end' => end,
                      _ => slot,
                    },
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: switch (kind) {
                        'start' => adminText(c, 'Start hour', 'ساعة البدء'),
                        'end' => adminText(c, 'End hour', 'ساعة الانتهاء'),
                        _ => adminText(c, 'Slot minutes', 'دقائق الموعد'),
                      },
                    ),
                    items: [
                      for (final v
                          in kind == 'slot'
                              ? [10, 15, 20, 30, 60]
                              : List.generate(24, (i) => i))
                        DropdownMenuItem(value: v, child: Text('$v')),
                    ],
                    onChanged: (v) => set(() {
                      switch (kind) {
                        case 'start':
                          start = v!;
                        case 'end':
                          end = v!;
                        default:
                          slot = v!;
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(adminText(c, 'Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(adminText(c, 'Save', 'حفظ')),
            ),
          ],
        ),
      ),
    );
    if (yes != true || !mounted) return;
    await _run(() async {
      final r = await ref
          .read(appointmentRepositoryProvider)
          .setTemplates(
            staffId: staff!,
            templates: [
              for (final d in days)
                NewScheduleTemplate(
                  weekday: d,
                  startMinutes: start * 60,
                  endMinutes: end * 60,
                  slotMinutes: slot,
                ),
            ],
          );
      if (r.isErr) throw r.failureOrNull!;
    });
  }

  Future<void> _timeOff() async {
    final dates = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (dates == null || !mounted) return;
    final reason = await _reason(
      context,
      adminText(context, 'Confirm time off', 'تأكيد الإجازة'),
    );
    if (reason == null) return;
    await _run(() async {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .addAvailabilityException(
            staffId: staff!,
            start: dates.start,
            end: dates.end.add(const Duration(days: 1)),
            reason: reason,
          );
      if (result.isErr) throw result.failureOrNull!;
    });
  }
}

Future<String?> _reason(BuildContext context, String title) async {
  String value = '';
  return showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(title),
        content: TextField(
          maxLength: 500,
          decoration: InputDecoration(
            labelText: adminText(c, 'Required reason', 'السبب المطلوب'),
          ),
          onChanged: (v) => set(() => value = v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(adminText(c, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: value.isEmpty ? null : () => Navigator.pop(c, value),
            child: Text(adminText(c, 'Confirm', 'تأكيد')),
          ),
        ],
      ),
    ),
  );
}
