import 'package:flutter/material.dart';
import '../../../data/repositories/admin_workspace.dart';

String adminText(BuildContext c, String en, String ar) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;
String queueLabel(BuildContext c, AdminQueue q) => switch (q) {
  AdminQueue.referral => adminText(c, 'Referrals', 'الإحالات'),
  AdminQueue.homeVisit => adminText(c, 'Home visits', 'الزيارات المنزلية'),
  AdminQueue.review => adminText(c, 'Result reviews', 'مراجعة النتائج'),
  AdminQueue.reply => adminText(c, 'Replies', 'الردود'),
  AdminQueue.document => adminText(c, 'Documents', 'المستندات'),
  AdminQueue.delivery => adminText(c, 'Delivery failures', 'فشل التسليم'),
  AdminQueue.feedback => adminText(c, 'Feedback', 'الملاحظات'),
};
String queueFilterLabel(BuildContext c, String f) {
  final q = AdminQueue.values.where((q) => q.name == f).firstOrNull;
  if (q != null) return queueLabel(c, q);
  return switch (f) {
    'all' => adminText(c, 'All', 'الكل'),
    'unassigned' => adminText(c, 'Unassigned', 'غير مسند'),
    _ => adminText(c, 'Overdue', 'متأخر'),
  };
}

String readableAuditAction(BuildContext c, String action) {
  const labels = {
    'account.deactivated': ('Account deactivated', 'تعطيل الحساب'),
    'account.activated': ('Account activated', 'تنشيط الحساب'),
    'account.password_reset_by_admin': (
      'Password reset by administrator',
      'إعادة تعيين كلمة المرور بواسطة الإدارة',
    ),
    'appointment.replacement_assigned': (
      'Replacement clinician assigned',
      'تعيين طبيب بديل',
    ),
    'clinic.configuration.updated': (
      'Clinic configuration updated',
      'تحديث إعدادات العيادة',
    ),
    'admin.work.open': ('Operational work assigned', 'إسناد متابعة إدارية'),
    'admin.work.waiting': ('Information requested', 'طلب معلومات'),
    'admin.work.resolved': (
      'Operational outcome recorded',
      'تسجيل نتيجة المتابعة',
    ),
    'document.issued': ('Document issued', 'إصدار مستند'),
    'document.revoked': ('Document revoked', 'إلغاء صلاحية مستند'),
    'task.transition': (
      'Task outcome or state recorded',
      'تسجيل حالة المهمة أو نتيجتها',
    ),
  };
  final label = labels[action];
  if (label != null) return adminText(c, label.$1, label.$2);
  return action
      .replaceAll(RegExp(r'[._]'), ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
