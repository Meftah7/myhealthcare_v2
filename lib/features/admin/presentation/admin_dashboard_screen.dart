import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/shared_mode.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../workspace/workspace_repository.dart';
import '../../workspace/workspace_widgets.dart';
import 'admin_top_actions.dart';
import 'admin_quick_actions.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: wt(context, 'Clinic overview', 'نظرة عامة على العيادة'),
    actions: const [AdminTopActions()],
    onRefresh: () async => ref.invalidate(workspaceOverviewProvider),
    children: [
      const AdminClinicOverview(),
      if (!ref.watch(sharedModeProvider))
        WorkspaceSection(
          wt(context, 'Quick actions', 'إجراءات سريعة'),
          child: const AdminQuickActions(),
        ),
      WorkspaceSection(
        wt(context, 'Clinic quick access', 'وصول سريع للعيادة'),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final (label, ar, route) in [
              ('Rooms', 'الغرف', '/admin/rooms'),
              ('Clinical work', 'العمل السريري', AppRoutes.adminWorkQueue),
              ('Documents', 'المستندات', AppRoutes.adminDocumentPolicies),
              ('Referrals', 'الإحالات', AppRoutes.adminReferralRequests),
              (
                'Clinic settings',
                'إعدادات العيادة',
                AppRoutes.adminDepartments,
              ),
            ])
              OutlinedButton(
                onPressed: () => context.push(route),
                child: Text(wt(context, label, ar)),
              ),
          ],
        ),
      ),
    ],
  );
}
