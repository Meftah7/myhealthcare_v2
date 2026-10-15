import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/shared_mode.dart';
import '../../core/failures.dart';
import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/feedback.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../data/remote/shared_client.dart';
import '../../domain/enums.dart';
import '../admin/presentation/admin_top_actions.dart';
import '../auth/presentation/reauth_prompt.dart';
import '../shared/presentation/shared_clinic_views.dart';
import 'workspace_repository.dart';
import 'workspace_widgets.dart';

class WorkspaceFeedbackScreen extends ConsumerStatefulWidget {
  const WorkspaceFeedbackScreen({super.key});
  @override
  ConsumerState<WorkspaceFeedbackScreen> createState() => _FeedbackState();
}

class _FeedbackState extends ConsumerState<WorkspaceFeedbackScreen> {
  String status = 'all', role = 'all', query = '';
  @override
  Widget build(BuildContext c) => AppScaffold(
    title: wt(c, 'Feedback', 'الملاحظات'),
    actions: const [AdminTopActions()],
    onRefresh: () async => ref.invalidate(workspaceRowsProvider('feedback')),
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (s, en, ar) in [
            ('all', 'All', 'الكل'),
            ('open', 'Open', 'مفتوحة'),
            ('resolved', 'Resolved', 'محسومة'),
          ])
            ChoiceChip(
              label: Text(wt(c, en, ar)),
              selected: status == s,
              onSelected: (_) => setState(() => status = s),
            ),
          SizedBox(
            width: 240,
            child: DropdownButton<String>(
              isExpanded: true,
              itemHeight: null,
              value: role,
              items: [
                for (final (r, en, ar) in [
                  ('all', 'All submitters', 'جميع المرسلين'),
                  ('patient', 'Patients', 'مرضى'),
                  ('staff', 'Staff', 'موظفون'),
                  ('admin', 'Admins', 'مديرون'),
                ])
                  DropdownMenuItem(
                    value: r,
                    child: ReadableLabel(wt(c, en, ar)),
                  ),
              ],
              onChanged: (r) => setState(() => role = r!),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: TextField(
          decoration: InputDecoration(
            labelText: wt(c, 'Search feedback', 'البحث في الملاحظات'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (q) => setState(() => query = q.trim().toLowerCase()),
        ),
      ),
      WorkspaceAsync(
        value: ref.watch(workspaceRowsProvider('feedback')),
        retry: () => ref.invalidate(workspaceRowsProvider('feedback')),
        builder: (d) {
          final list = rows(d['rows'])
              .where(
                (f) =>
                    (status == 'all' || f['status'] == status) &&
                    (role == 'all' || f['reporter_role'] == role) &&
                    '${f['reporter_name']} ${f['message']} ${f['category']}'
                        .toLowerCase()
                        .contains(query),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                wt(
                  c,
                  '${list.length} matching reports · Open means unresolved',
                  '${list.length} ملاحظات مطابقة · مفتوحة تعني غير محسومة',
                ),
              ),
              for (final f in list)
                WorkspaceSection(
                  wlabel(c, f['category']),
                  subtitle:
                      '${f['reporter_name'] ?? wt(c, 'Anonymous', 'مجهول')} · ${wlabel(c, f['reporter_role'])} · ${wallDate(f['created_at'])} ${wallTime(f['created_at'])}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText('${f['message']}'),
                      const SizedBox(height: 12),
                      Text(wlabel(c, f['status'])),
                      if (f['handler_name'] != null)
                        Text(
                          '${wt(c, 'Handled by', 'عولجت بواسطة')} ${f['handler_name']} · ${wallDate(f['handled_at'])}',
                        ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: OutlinedButton(
                          onPressed: () async {
                            final result = await Result.guardAsync(
                              () => ref
                                  .read(workspaceRepositoryProvider)
                                  .setFeedback(f),
                            );
                            if (!mounted || !c.mounted) return;
                            showMutationFeedback(c, result);
                            if (result.isOk) {
                              ref.invalidate(workspaceRowsProvider('feedback'));
                              ref.invalidate(workspaceOverviewProvider);
                            }
                          },
                          child: Text(
                            f['status'] == 'open'
                                ? wt(c, 'Mark resolved', 'وضع علامة محسومة')
                                : wt(c, 'Reopen', 'إعادة الفتح'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    wt(c, 'No matching feedback.', 'لا توجد ملاحظات مطابقة.'),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

/// Shared-mode tools use server repositories, never local DB screens.
class SharedAdminOperationsScreen extends ConsumerStatefulWidget {
  const SharedAdminOperationsScreen({required this.billing, super.key});
  final bool billing;
  @override
  ConsumerState<SharedAdminOperationsScreen> createState() =>
      _SharedOperationsState();
}

class _SharedOperationsState
    extends ConsumerState<SharedAdminOperationsScreen> {
  String? patient;
  @override
  Widget build(BuildContext c) {
    final client = ref.watch(sharedClientProvider),
        repo = SharedWorkspaceRepository(client);
    final user = client.user ?? {};
    return AppScaffold(
      title: widget.billing
          ? wt(c, 'Billing', 'الفوترة')
          : wt(c, 'Clinic appointments', 'مواعيد العيادة'),
      actions: const [AdminTopActions()],
      children: [
        WorkspaceAsync(
          value: ref.watch(workspaceRowsProvider('users')),
          retry: () => ref.invalidate(workspaceRowsProvider('users')),
          builder: (d) => widget.billing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: patient,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: wt(c, 'Patient', 'المريض'),
                      ),
                      items: [
                        for (final u in rows(
                          d['rows'],
                        ).where((u) => u['role'] == 'patient'))
                          DropdownMenuItem(
                            value: u['id'] as String,
                            child: Text('${u['fullName']}'),
                          ),
                      ],
                      onChanged: (id) => setState(() => patient = id),
                    ),
                    if (patient != null)
                      SharedBillingView(
                        key: ValueKey(patient),
                        repository: repo,
                        user: user,
                        patient: patient,
                        tr: (en, ar) => wt(c, en, ar),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          wt(
                            c,
                            'Choose a patient to manage invoices and record desk payments.',
                            'اختر المريض لإدارة الفواتير وتسجيل مدفوعات الاستقبال.',
                          ),
                        ),
                      ),
                    WorkspaceAsync(
                      value: ref.watch(workspaceOverviewProvider),
                      retry: () => ref.invalidate(workspaceOverviewProvider),
                      builder: (overview) => WorkspaceSection(
                        wt(
                          c,
                          'Recent settled desk receipts',
                          'آخر مقبوضات الاستقبال المسواة',
                        ),
                        subtitle: wt(
                          c,
                          'Refund records document money already returned at the desk. No gateway is connected.',
                          'توثق الاستردادات الأموال المعادة فعلياً في الاستقبال. لا توجد بوابة دفع متصلة.',
                        ),
                        child: Column(
                          children: [
                            for (final p in rows(overview['payments']))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${p['patient_name']} · ${bhd(fils(p['amount'] as num))}',
                                ),
                                subtitle: Text('${p['id']}'),
                                trailing: TextButton(
                                  onPressed: () => _refund(c, p),
                                  child: Text(
                                    wt(c, 'Record refund', 'تسجيل استرداد'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SharedAppointmentsView(
                  repository: repo,
                  user: user,
                  people: rows(d['rows']),
                  tr: (en, ar) => wt(c, en, ar),
                ),
        ),
      ],
    );
  }

  Future<void> _refund(BuildContext c, WorkspaceData payment) async {
    final amount = TextEditingController(), reason = TextEditingController();
    final yes = await showDialog<bool>(
      context: c,
      builder: (dc) => AlertDialog(
        title: Text(
          wt(
            c,
            'Record settled desk refund',
            'تسجيل استرداد مسوى في الاستقبال',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                wt(
                  c,
                  'Record only after money was returned to the patient. This records an offline refund; it does not transfer money.',
                  'سجل فقط بعد إعادة الأموال إلى المريض. هذا توثيق لاسترداد خارج النظام ولا ينقل الأموال.',
                ),
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'BHD'),
              ),
              TextField(
                controller: reason,
                decoration: InputDecoration(
                  labelText: wt(c, 'Reason', 'السبب'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(wt(c, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dc, true),
            child: Text(wt(c, 'Record refund', 'تسجيل استرداد')),
          ),
        ],
      ),
    );
    final parsed = num.tryParse(amount.text.trim());
    final reasonText = reason.text.trim();
    amount.dispose();
    reason.dispose();
    if (yes != true || !c.mounted) return;
    if (parsed == null ||
        !parsed.isFinite ||
        parsed <= 0 ||
        reasonText.isEmpty) {
      showMutationFeedback(
        c,
        const Err<void>(
          ValidationFailure('Enter a positive BHD amount and a reason.'),
        ),
      );
      return;
    }
    final key = newId('refund');
    final result = await runWithReauth(
      c,
      ref,
      () => Result.guardAsync(() async {
        try {
          await ref
              .read(sharedClientProvider)
              .request(
                '/api/workspace/refunds',
                method: 'POST',
                body: {
                  'paymentId': payment['id'],
                  'amountFils': fils(parsed),
                  'reason': reasonText,
                  'idempotencyKey': key,
                },
              );
        } on AuthFailure catch (e) {
          if (e.message.contains('Confirm your password')) {
            throw const ReauthRequiredFailure();
          }
          rethrow;
        }
      }),
    );
    ref.invalidate(workspaceOverviewProvider);
    if (c.mounted) showMutationFeedback(c, result);
  }
}

class SharedUsersScreen extends ConsumerStatefulWidget {
  const SharedUsersScreen({super.key});
  @override
  ConsumerState<SharedUsersScreen> createState() => _SharedUsersState();
}

class _SharedUsersState extends ConsumerState<SharedUsersScreen> {
  String category = 'patient',
      status = 'all',
      staffRole = 'all',
      department = 'all',
      clinician = 'all',
      query = '';
  bool selecting = false, busy = false;
  final selected = <String>{};
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void change(VoidCallback fn) => setState(() {
    selected.clear();
    fn();
  });
  @override
  Widget build(BuildContext c) => AppScaffold(
    title: wt(c, 'Users', 'المستخدمون'),
    actions: const [AdminTopActions()],
    children: [
      Wrap(
        spacing: 10,
        children: [
          for (final (r, en, ar) in [
            ('patient', 'Patients', 'المرضى'),
            ('staff', 'Staff', 'الموظفون'),
            ('admin', 'Admins', 'المديرون'),
          ])
            ChoiceChip(
              label: Text(wt(c, en, ar)),
              selected: category == r,
              onSelected: (_) => change(() {
                category = r;
                status = staffRole = department = clinician = 'all';
                selecting = false;
              }),
            ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: wt(
            c,
            'Search name, email or ID',
            'ابحث بالاسم أو البريد أو الرقم',
          ),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (v) => change(() => query = v.toLowerCase().trim()),
      ),
      WorkspaceAsync(
        value: ref.watch(workspaceRowsProvider('users')),
        retry: () => ref.invalidate(workspaceRowsProvider('users')),
        builder: (d) {
          final all = rows(d['rows']), assignments = rows(d['assignments']);
          final departments = all
              .map((u) => u['departmentName'])
              .whereType<String>()
              .toSet();
          Widget filter(
            String label,
            String value,
            List<(String, String)> items,
            void Function(String) set,
          ) => SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              key: ValueKey('$label-$value'),
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(labelText: label),
              items: [
                for (final (v, l) in items)
                  DropdownMenuItem(value: v, child: Text(l)),
              ],
              onChanged: (v) => change(() => set(v!)),
            ),
          );
          final list = all
              .where(
                (u) =>
                    u['role'] == category &&
                    (status == 'all' ||
                        (u['isActive'] == true) == (status == 'active')) &&
                    (category != 'staff' ||
                        (staffRole == 'all' || u['job'] == staffRole) &&
                            (department == 'all' ||
                                u['departmentName'] == department)) &&
                    (category != 'patient' ||
                        clinician == 'all' ||
                        assignments.any(
                          (a) =>
                              a['patient'] == u['id'] &&
                              a['staff'] == clinician,
                        )) &&
                    '${u['fullName']} ${u['email']} ${u['id']} ${u['nationalId'] ?? ''}'
                        .toLowerCase()
                        .contains(query),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  filter(wt(c, 'Account status', 'حالة الحساب'), status, [
                    ('all', wt(c, 'All', 'الكل')),
                    ('active', wt(c, 'Active', 'نشط')),
                    ('inactive', wt(c, 'Inactive', 'غير نشط')),
                  ], (v) => status = v),
                  if (category == 'staff') ...[
                    filter(wt(c, 'Staff role', 'دور الموظف'), staffRole, [
                      ('all', wt(c, 'All roles', 'جميع الأدوار')),
                      for (final r in StaffRole.values)
                        (r.name, wlabel(c, r.name)),
                    ], (v) => staffRole = v),
                    filter(wt(c, 'Department', 'القسم'), department, [
                      ('all', wt(c, 'All departments', 'كل الأقسام')),
                      for (final dep in departments) (dep, dep),
                    ], (v) => department = v),
                  ],
                  if (category == 'patient')
                    filter(
                      wt(c, 'Treating clinician', 'الممارس المعالج'),
                      clinician,
                      [
                        ('all', wt(c, 'All clinicians', 'كل الممارسين')),
                        for (final u in all.where(
                          (u) =>
                              u['role'] == 'staff' &&
                              ['doctor', 'dentist', 'nurse'].contains(u['job']),
                        ))
                          (u['id'] as String, u['fullName'] as String),
                      ],
                      (v) => clinician = v,
                    ),
                  TextButton(
                    onPressed: () => change(() {
                      status = staffRole = department = clinician = 'all';
                      query = '';
                      searchController.clear();
                    }),
                    child: Text(wt(c, 'Reset filters', 'إعادة ضبط التصفية')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    wt(
                      c,
                      '${list.length} matching accounts',
                      '${list.length} حسابات مطابقة',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => change(() => selecting = !selecting),
                    child: Text(
                      selecting
                          ? wt(c, 'Cancel selection', 'إلغاء التحديد')
                          : wt(c, 'Select accounts', 'تحديد الحسابات'),
                    ),
                  ),
                  if (selecting) ...[
                    Text('${selected.length}'),
                    TextButton(
                      onPressed: () => setState(
                        () =>
                            selected.addAll(list.map((u) => u['id'] as String)),
                      ),
                      child: Text(wt(c, 'Select visible', 'تحديد الظاهر')),
                    ),
                    FilledButton(
                      onPressed: selected.isEmpty || busy
                          ? null
                          : () => _review(c, list),
                      child: Text(
                        wt(c, 'Review deactivation', 'مراجعة التعطيل'),
                      ),
                    ),
                  ],
                ],
              ),
              for (final u in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: selecting
                      ? Checkbox(
                          value: selected.contains(u['id']),
                          onChanged: (v) => setState(
                            () => v == true
                                ? selected.add(u['id'] as String)
                                : selected.remove(u['id']),
                          ),
                        )
                      : null,
                  title: Text('${u['fullName']}'),
                  subtitle: Text(
                    '${u['email']} · ${u['id']}\n${wlabel(c, u['job'] ?? u['role'])} · ${u['departmentName'] ?? '—'} · ${u['isActive'] == true ? wt(c, 'Active', 'نشط') : wt(c, 'Inactive', 'غير نشط')}',
                  ),
                  trailing: selecting
                      ? null
                      : IconButton(
                          tooltip: wt(c, 'Account details', 'تفاصيل الحساب'),
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => showDialog<void>(
                            context: c,
                            builder: (dc) => AlertDialog(
                              title: Text('${u['fullName']}'),
                              content: SelectableText(
                                '${u['email']}\n${u['id']}\n${wlabel(c, u['job'] ?? u['role'])}\n${u['departmentName'] ?? '—'}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dc),
                                  child: Text(wt(c, 'Close', 'إغلاق')),
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
  );
  Future<void> _review(BuildContext c, List<WorkspaceData> visible) async {
    final accounts = visible.where((u) => selected.contains(u['id'])).toList();
    final yes = await showDialog<bool>(
      context: c,
      builder: (dc) => AlertDialog(
        title: Text(
          wt(c, 'Review affected accounts', 'مراجعة الحسابات المتأثرة'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final u in accounts) Text('${u['fullName']} · ${u['id']}'),
              Text(
                wt(
                  c,
                  'All changes commit together. Last-admin, active bookings and clinical responsibilities are protected.',
                  'تحفظ جميع التغييرات معاً. تتم حماية آخر مدير والحجوزات النشطة والمسؤوليات السريرية.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(wt(c, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dc, true),
            child: Text(wt(c, 'Confirm', 'تأكيد')),
          ),
        ],
      ),
    );
    if (yes != true || !c.mounted) return;
    setState(() => busy = true);
    final result = await runWithReauth(
      c,
      ref,
      () => Result.guardAsync(() async {
        try {
          await ref
              .read(sharedClientProvider)
              .request(
                '/api/workspace/users',
                method: 'POST',
                body: {
                  'accounts': [
                    for (final u in accounts)
                      {'id': u['id'], 'version': u['version']},
                  ],
                  'active': false,
                },
              );
        } on AuthFailure catch (e) {
          if (e.message.contains('Confirm your password')) {
            throw const ReauthRequiredFailure();
          }
          rethrow;
        }
      }),
    );
    if (!mounted || !c.mounted) return;
    setState(() => busy = false);
    if (result.isOk) {
      selected.clear();
      ref.invalidate(workspaceRowsProvider('users'));
    }
    showMutationFeedback(c, result);
  }
}
