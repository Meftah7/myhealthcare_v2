import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shared_mode.dart';
import '../../core/di.dart';
import '../../core/presentation/readable_label.dart';
import '../../data/seed/demo_workforce.dart';
import '../workspace/workspace_repository.dart';
import '../workspace/workspace_widgets.dart';

final demoAccountsProvider = FutureProvider.autoDispose<List<WorkspaceData>>((
  ref,
) async {
  if (!ref.watch(appModeProvider).isDemo) return [];
  if (ref.watch(sharedModeProvider)) {
    final data = await ref
        .watch(sharedClientProvider)
        .request('/api/demo/accounts');
    return rows(data);
  }
  final manifest = await DemoWorkforce(
    ref.watch(appDatabaseProvider),
    demoEnabled: true,
  ).manifest();
  final allowed = demoWorkforceAccounts.map((a) => a['email']).toSet();
  return manifest.where((a) => allowed.contains(a['email'])).toList();
});

class DemoAccountPicker extends ConsumerStatefulWidget {
  const DemoAccountPicker({required this.onSelect, super.key});
  final ValueChanged<String> onSelect;
  @override
  ConsumerState<DemoAccountPicker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<DemoAccountPicker> {
  String query = '';
  @override
  Widget build(BuildContext c) {
    if (!ref.watch(appModeProvider).isDemo) return const SizedBox.shrink();
    return ExpansionTile(
      title: ReadableLabel(
        wt(
          c,
          'Choose another demo staff account',
          'اختيار حساب موظف تجريبي آخر',
        ),
      ),
      children: [
        ReadableLabel(
          wt(
            c,
            'Choose an account, then enter its current password. Existing passwords and inactive or locked accounts are preserved.',
            'اختر حساباً ثم أدخل كلمة مروره الحالية. يتم الاحتفاظ بكلمات المرور والحسابات المعطلة أو المقفلة.',
          ),
        ),
        TextField(
          onChanged: (v) => setState(() => query = v.toLowerCase().trim()),
          decoration: InputDecoration(
            labelText: wt(
              c,
              'Search name, role, department or email',
              'البحث بالاسم أو الدور أو القسم أو البريد',
            ),
          ),
        ),
        ref
            .watch(demoAccountsProvider)
            .when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Column(
                children: [
                  ReadableLabel('$e'),
                  TextButton(
                    onPressed: () => ref.invalidate(demoAccountsProvider),
                    child: Text(wt(c, 'Retry', 'إعادة المحاولة')),
                  ),
                ],
              ),
              data: (accounts) => SizedBox(
                height: 300,
                child: ListView(
                  children: [
                    for (final a in accounts.where(
                      (a) =>
                          '${a['name']} ${a['professional_role'] ?? a['professionalRole'] ?? a['role']} ${a['department']} ${a['email']}'
                              .toLowerCase()
                              .contains(query),
                    ))
                      ListTile(
                        title: ReadableLabel(a['name'] as String),
                        subtitle: ReadableLabel(
                          '${a['professional_role'] ?? a['professionalRole'] ?? a['role'] ?? a['account_type']} · ${a['department'] ?? ''}\n${a['email']}',
                        ),
                        enabled: a['active'] != 0 && a['active'] != false,
                        onTap: () => widget.onSelect(a['email'] as String),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
