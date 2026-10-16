import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di.dart';
import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../l10n/app_localizations.dart';
import '../staff_dashboard/presentation/role_workspaces.dart';
import '../workspace/workspace_widgets.dart';
import 'role_navigation.dart';
import 'workforce_home.dart';
import 'workforce_repository.dart';

class StaffDocumentsHub extends ConsumerStatefulWidget {
  const StaffDocumentsHub({super.key});
  @override
  ConsumerState<StaffDocumentsHub> createState() => _DocumentsState();
}

class _DocumentsState extends ConsumerState<StaffDocumentsHub> {
  final query = TextEditingController();
  Future<Result<List<Patient>>>? result;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final role = ref.watch(currentStaffRoleProvider);
    return AppScaffold(
      title: wt(c, 'Documents and work records', 'الوثائق وسجلات العمل'),
      children: [
        if (role == StaffRole.receptionist) ...[
          ReadableLabel(
            wt(
              c,
              'Confirm an already-issued copy using its verification reference. Clinical approval and signing remain with the qualified issuer.',
              'تأكيد نسخة صادرة مسبقاً باستخدام مرجع التحقق. يظل الاعتماد والتوقيع السريري لدى المصدر المؤهل.',
            ),
          ),
          FilledButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: c,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const ConfirmCopySheet(),
            ),
            icon: const Icon(Icons.verified_outlined),
            label: ReadableLabel(
              wt(c, 'Check an issued copy', 'فحص نسخة صادرة'),
            ),
          ),
        ] else if (role == StaffRole.pharmacist)
          const PharmacyDispensingHistory()
        else ...[
          ReadableLabel(
            wt(
              c,
              'Find a patient in your authorized care scope to view issued documents or prepare an eligible request.',
              'ابحث عن مريض ضمن نطاق رعايتك المصرح به لعرض الوثائق الصادرة أو إعداد طلب مؤهل.',
            ),
          ),
          TextField(
            controller: query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => setState(
              () => result = ref
                  .read(patientRepositoryProvider)
                  .search(query.text.trim()),
            ),
            decoration: InputDecoration(
              labelText: wt(
                c,
                'Patient name or identifier',
                'اسم المريض أو المعرف',
              ),
              suffixIcon: IconButton(
                tooltip: wt(c, 'Search', 'بحث'),
                onPressed: () => setState(
                  () => result = ref
                      .read(patientRepositoryProvider)
                      .search(query.text.trim()),
                ),
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          if (result != null)
            FutureBuilder<Result<List<Patient>>>(
              future: result,
              builder: (c, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return switch (snapshot.data!) {
                  Err(:final failure) => ReadableLabel(failure.message),
                  Ok(:final value) => Column(
                    children: [
                      if (value.isEmpty)
                        ReadableLabel(
                          wt(
                            c,
                            'No matching authorized patient.',
                            'لا يوجد مريض مطابق ضمن النطاق المصرح.',
                          ),
                        ),
                      for (final patient in value)
                        ListTile(
                          title: ReadableLabel(patient.user.fullName),
                          subtitle: ReadableLabel(patient.id),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              c.push('/staff/patients/${patient.id}/documents'),
                        ),
                    ],
                  ),
                };
              },
            ),
        ],
      ],
    );
  }
}

class StaffCareToolsScreen extends StatelessWidget {
  const StaffCareToolsScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final t = AppLocalizations.of(c)!;
    return AppScaffold(
      title: wt(c, 'Care tools', 'أدوات الرعاية'),
      children: [
        ReadableLabel(t.htScope),
        for (final (title, path, icon) in [
          (
            wt(c, 'Body measurements', 'قياسات الجسم'),
            'bmi',
            Icons.monitor_weight_outlined,
          ),
          (t.htIdealWeight, 'ideal-weight', Icons.monitor_weight_outlined),
          (t.htBodyFat, 'body-fat', Icons.accessibility_new),
          (t.htDueDate, 'due-date', Icons.child_care_outlined),
          (t.htOvulation, 'ovulation', Icons.calendar_month_outlined),
          (
            wt(c, 'Glucose conversion', 'تحويل الجلوكوز'),
            'glucose',
            Icons.science_outlined,
          ),
          (
            wt(c, 'Cholesterol conversion', 'تحويل الكوليسترول'),
            'cholesterol',
            Icons.science_outlined,
          ),
          (
            wt(c, 'Triglyceride conversion', 'تحويل الدهون الثلاثية'),
            'triglycerides',
            Icons.science_outlined,
          ),
        ])
          ListTile(
            leading: Icon(icon),
            title: ReadableLabel(title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => c.push('/staff/care-tools/$path'),
          ),
      ],
    );
  }
}

class StaffHelpScreen extends StatelessWidget {
  const StaffHelpScreen({super.key});
  @override
  Widget build(BuildContext c) => AppScaffold(
    title: wt(c, 'Workspace help', 'مساعدة مساحة العمل'),
    children: [
      for (final (title, ar, body, bodyAr) in [
        (
          'Doctor and dentist',
          'الطبيب وطبيب الأسنان',
          'Use Today or Schedule to open your assigned consultation. Save drafts before signing. A signed encounter is permanent; corrections use the existing amendment workflow.',
          'استخدم اليوم أو الجدول لفتح الاستشارة المسندة إليك. احفظ المسودات قبل التوقيع. الاستشارة الموقعة دائمة وتصحح عبر مسار التعديلات.',
        ),
        (
          'Nursing intake',
          'التقييم التمريضي',
          'Open an assigned intake. Temperature is °C, pulse is beats/min, and oxygen saturation is %. Failed saves retain your inputs for retry. Completing intake records participation and keeps the booked clinician responsible.',
          'افتح تقييماً مسنداً إليك. الحرارة بالدرجة المئوية والنبض بالدقات في الدقيقة وتشبع الأكسجين بالنسبة المئوية. يحتفظ فشل الحفظ بالمدخلات لإعادة المحاولة. يسجل إكمال التقييم المشاركة مع بقاء الطبيب مسؤولاً.',
        ),
        (
          'Front desk',
          'الاستقبال',
          'Verify identity before booking, check-in or rescheduling. Document checks apply only to an existing valid issued copy and never sign clinical content.',
          'تحقق من الهوية قبل الحجز أو تسجيل الوصول أو تغيير الموعد. يقتصر فحص الوثائق على نسخة صادرة سارية ولا يوقع محتوى سريرياً.',
        ),
        (
          'Pharmacy',
          'الصيدلية',
          'Review a signed active prescription, verify patient and stock, and record the actual outcome. A hold does not resolve a clarification; only the responsible prescriber can respond.',
          'راجع وصفة موقعة وسارية وتحقق من المريض والمخزون وسجل النتيجة الفعلية. لا يحسم التعليق الاستيضاح؛ يرد عليه الواصف المسؤول فقط.',
        ),
        (
          'Messages and cover',
          'الرسائل والتغطية',
          'Team messages are visible only to conversation members. Cover starts after explicit acceptance. Use Profile to change preferences or sign out before switching accounts.',
          'تظهر رسائل الفريق لأعضاء المحادثة فقط. تبدأ التغطية بعد القبول الصريح. استخدم الملف لتغيير التفضيلات أو تسجيل الخروج قبل تبديل الحسابات.',
        ),
      ])
        WorkspaceSection(
          wt(c, title, ar),
          child: ReadableLabel(wt(c, body, bodyAr)),
        ),
    ],
  );
}

class WorkforceActivityScreen extends ConsumerWidget {
  const WorkforceActivityScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => AppScaffold(
    title: wt(c, 'My activity', 'نشاطي'),
    children: [
      WorkspaceAsync(
        value: ref.watch(workforceDataProvider('activity')),
        retry: () => ref.invalidate(workforceDataProvider('activity')),
        builder: (data) => Column(
          children: [
            if (rows(data['rows']).isEmpty)
              ReadableLabel(
                wt(c, 'No recorded actions yet.', 'لا توجد إجراءات مسجلة بعد.'),
              ),
            for (final event in rows(data['rows']))
              ListTile(
                title: ReadableLabel(event['action'] as String),
                subtitle: ReadableLabel(
                  '${wallDate(event['at'])} ${wallTime(event['at'])} · ${event['entity'] ?? ''}',
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
