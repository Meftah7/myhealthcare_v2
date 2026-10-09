import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import 'admin_top_actions.dart';
import 'admin_workspace_shared.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen(this.section, {super.key});
  final String section;
  @override
  Widget build(BuildContext c) {
    final entries = switch (section) {
      'clinic' => <(String, String, IconData, String)>[
        (
          'Appointments',
          'المواعيد',
          Icons.calendar_month,
          '/admin/appointments',
        ),
        (
          'Staff schedules, cover and capacity',
          'جداول الموظفين والتغطية والسعة',
          Icons.event_available,
          '/admin/clinic/schedules',
        ),
        (
          'Service hours',
          'ساعات الخدمة',
          Icons.schedule,
          '/admin/profile/clinic-hours',
        ),
        ('Departments', 'الأقسام', Icons.apartment, '/admin/departments'),
      ],
      'documents' => <(String, String, IconData, String)>[
        (
          'Requests and issued documents',
          'الطلبات والمستندات الصادرة',
          Icons.description,
          '/admin/documents/registry',
        ),
        (
          'Templates and approvals',
          'القوالب والاعتمادات',
          Icons.rule,
          '/admin/profile/document-policies',
        ),
        (
          'Document grants',
          'صلاحيات المستندات',
          Icons.admin_panel_settings,
          '/admin/profile/document-access',
        ),
        (
          'Pending document work',
          'عمل المستندات المعلق',
          Icons.pending_actions,
          '/admin/work?filter=document',
        ),
      ],
      'reports' => <(String, String, IconData, String)>[
        (
          'Operational report and export',
          'التقرير التشغيلي والتصدير',
          Icons.file_download,
          '/admin/reports/operations',
        ),
        ('Analytics', 'التحليلات', Icons.insights, '/admin/profile/analytics'),
        (
          'Capacity forecast',
          'توقعات السعة',
          Icons.query_stats,
          '/admin/profile/forecast',
        ),
        ('Feedback', 'الملاحظات', Icons.forum, '/admin/feedback'),
      ],
      _ => <(String, String, IconData, String)>[
        (
          'Clinic identity',
          'هوية العيادة',
          Icons.local_hospital,
          '/admin/settings/clinic',
        ),
        (
          'Language and appearance',
          'اللغة والمظهر',
          Icons.language,
          '/admin/profile/preferences',
        ),
        (
          'Integrations and verification',
          'التكاملات والتحقق',
          Icons.link,
          '/admin/settings/integrations',
        ),
        (
          'AI capabilities',
          'إعدادات الذكاء الاصطناعي',
          Icons.auto_awesome,
          '/admin/profile/ai',
        ),
        (
          'Grants',
          'الصلاحيات',
          Icons.security,
          '/admin/profile/document-access',
        ),
        ('Audit activity', 'سجل النشاط', Icons.history, '/admin/profile/audit'),
        (
          'Backups and recovery configuration',
          'إعدادات النسخ الاحتياطي والاستعادة',
          Icons.backup,
          '/admin/settings/backup',
        ),
        (
          'Account and recovery controls',
          'الحساب وإجراءات الاستعادة',
          Icons.account_circle,
          '/admin/profile',
        ),
      ],
    };
    return AppScaffold(
      title: adminText(
        c,
        switch (section) {
          'clinic' => 'Clinic',
          'documents' => 'Documents',
          'reports' => 'Reports',
          _ => 'Settings',
        },
        switch (section) {
          'clinic' => 'العيادة',
          'documents' => 'المستندات',
          'reports' => 'التقارير',
          _ => 'الإعدادات',
        },
      ),
      actions: const [AdminTopActions()],
      children: [
        for (final (en, ar, icon, route) in entries)
          ListTile(
            leading: Icon(icon),
            title: ReadableLabel(adminText(c, en, ar)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => c.push(route),
          ),
      ],
    );
  }
}
