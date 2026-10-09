import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../data/repositories/admin_workspace.dart';
import '../../../domain/identity/permissions.dart';
import 'admin_workspace_screens.dart';

final adminFinanceReportProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(adminWorkspaceProvider);
  await service.authorize(Permission.manageBilling);
  final db = service.db;
  return (
    invoices: await db.select(db.invoices).get(),
    payments: await db.select(db.paymentTransactions).get(),
  );
});

class AdminFinanceReportScreen extends ConsumerWidget {
  const AdminFinanceReportScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => AppScaffold(
    title: adminText(
      c,
      'Finance exceptions and export',
      'استثناءات المالية والتصدير',
    ),
    children: [
      ReadableLabel(
        adminText(
          c,
          'Payments use the configured local simulation. Refunds and desk corrections require recorded reasons and preserve transaction history.',
          'تستخدم المدفوعات المحاكاة المحلية. تتطلب الاستردادات والتصحيحات أسبابا مسجلة وتحافظ على سجل المعاملات.',
        ),
      ),
      ref
          .watch(adminFinanceReportProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in data.payments.where(
                  (p) =>
                      p.failureReason != null ||
                      {
                        'initiated',
                        'pending',
                        'unknown',
                        'failed',
                      }.contains(p.status.name),
                ))
                  ListTile(
                    title: Text('${p.id} · BHD ${p.amount.toStringAsFixed(3)}'),
                    subtitle: Text(
                      '${p.status.name} · ${p.failureReason ?? p.reason ?? adminText(c, 'Reconcile payment state', 'تسوية حالة الدفع')}',
                    ),
                    onTap: () => c.push('/admin/billing'),
                  ),
                TextButton(
                  onPressed: () => c.push('/admin/billing'),
                  child: Text(
                    adminText(
                      c,
                      'Open refunds, receipts and reconciliation',
                      'فتح الاستردادات والإيصالات والتسويات',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(
                    adminText(
                      c,
                      'Copy finance CSV',
                      'نسخ التقرير المالي بصيغة CSV',
                    ),
                  ),
                  onPressed: () async {
                    final service = ref.read(adminWorkspaceProvider);
                    await service.authorize(Permission.manageBilling);
                    final db = service.db;
                    final payments = await db
                        .select(db.paymentTransactions)
                        .get();
                    final invoices = await db.select(db.invoices).get();
                    String cell(String s) =>
                        '"${(RegExp(r'^[=+@\-\t\r]').hasMatch(s) ? "'$s" : s).replaceAll('"', '""')}"';
                    final rows = [
                      [
                        'kind',
                        'reference',
                        'invoice',
                        'amount_bhd',
                        'state',
                        'reason',
                      ],
                      for (final i in invoices)
                        [
                          'invoice',
                          i.id,
                          i.id,
                          i.totalAmount.toStringAsFixed(3),
                          i.status.name,
                          '',
                        ],
                      for (final p in payments)
                        [
                          'payment',
                          p.id,
                          p.invoiceId ?? '',
                          p.amount.toStringAsFixed(3),
                          p.status.name,
                          p.reason ?? p.failureReason ?? '',
                        ],
                    ];
                    await Clipboard.setData(
                      ClipboardData(
                        text: rows.map((r) => r.map(cell).join(',')).join('\n'),
                      ),
                    );
                    await service.access.audit(
                      'finance_report.exported',
                      entityType: 'finance_report',
                    );
                    if (c.mounted) {
                      ScaffoldMessenger.of(c).showSnackBar(
                        SnackBar(
                          content: Text(
                            adminText(
                              c,
                              'Finance report copied.',
                              'تم نسخ التقرير المالي',
                            ),
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
