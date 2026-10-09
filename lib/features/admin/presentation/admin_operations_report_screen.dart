import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../data/repositories/admin_workspace.dart';
import '../../../domain/identity/permissions.dart';
import 'admin_workspace_screens.dart' show adminWorkProvider;
import 'admin_workspace_shared.dart';

class AdminOperationsReportScreen extends ConsumerWidget {
  const AdminOperationsReportScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final data = ref.watch(adminWorkProvider);
    return AppScaffold(
      title: adminText(c, 'Operational report', 'التقرير التشغيلي'),
      children: [
        data.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (items) => Column(
            children: [
              for (final q in AdminQueue.values)
                ListTile(
                  title: ReadableLabel(queueLabel(c, q)),
                  subtitle: ReadableLabel(
                    '${adminText(c, 'Open / unassigned / overdue', 'مفتوح / غير مسند / متأخر')}: ${items.where((w) => w.type == q && w.state != 'resolved').length} / ${items.where((w) => w.type == q && w.owner == null && w.state != 'resolved').length} / ${items.where((w) => w.type == q && w.overdue).length}',
                  ),
                  onTap: () => c.push('/admin/work?filter=${q.name}'),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(
                  adminText(c, 'Copy CSV report', 'نسخ التقرير بصيغة CSV'),
                ),
                onPressed: () async {
                  await ref
                      .read(adminWorkspaceProvider)
                      .authorize(Permission.viewOperationalReports);
                  final latest = await ref.read(adminWorkspaceProvider).queue();
                  final csv =
                      'queue,source,owner,state,due\n${latest.map((w) => [w.type.name, w.sourceId, w.owner ?? '', w.state, w.due?.toIso8601String() ?? ''].map((s) => '"${s.replaceAll('"', '""')}"').join(',')).join('\n')}';
                  await Clipboard.setData(ClipboardData(text: csv));
                  await ref
                      .read(accessPolicyProvider)
                      .audit(
                        'operational_report.exported',
                        entityType: 'admin_report',
                      );
                  if (c.mounted) {
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(
                        content: Text(
                          adminText(c, 'Report copied.', 'تم نسخ التقرير'),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
