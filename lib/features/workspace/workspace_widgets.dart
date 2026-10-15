import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/patient_palette.dart';
import '../../core/di.dart';
import '../../core/presentation/app_card.dart';
import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/feedback.dart';
import '../../core/result.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../admin/application/admin_providers.dart';
import '../admin/presentation/admin_top_actions.dart';
import '../auth/application/session.dart';
import '../care/application/care_providers.dart';
import '../staff_dashboard/application/staff_providers.dart';
import 'workspace_repository.dart';

Object? workspaceStat(WorkspaceData? data, String key) =>
    (data?['stats'] as Map<String, dynamic>?)?[key];
String wt(BuildContext c, String en, String ar) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;
String bhd(num n) => '${(n / 1000).toStringAsFixed(3)} BHD';
String wallTime(dynamic seconds) {
  if (seconds == null) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(
    (seconds as num).toInt() * 1000,
    isUtc: true,
  ).add(const Duration(hours: 3));
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String wallDate(dynamic seconds) => seconds == null
    ? '—'
    : clinicDateLabel(
        clinicDay(
          DateTime.fromMillisecondsSinceEpoch(
            (seconds as num).toInt() * 1000,
            isUtc: true,
          ),
        ),
      );
List<WorkspaceData> rows(dynamic value) => [
  for (final r in value as List<dynamic>? ?? [])
    Map<String, dynamic>.from(r as Map<String, dynamic>),
];
final workspaceRowsProvider = FutureProvider.family<WorkspaceData, String>((
  ref,
  key,
) {
  ref.watch(workspaceChangesProvider);
  ref.watch(currentUserProvider);
  return ref.watch(workspaceRepositoryProvider).read(key);
});

class WorkspaceSection extends StatelessWidget {
  const WorkspaceSection(
    this.title, {
    required this.child,
    this.subtitle,
    this.action,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(title, style: Theme.of(c).textTheme.titleLarge),
                ?action,
              ],
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(subtitle!, style: Theme.of(c).textTheme.bodySmall),
              ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}

class WorkspaceMetrics extends StatelessWidget {
  const WorkspaceMetrics(this.items, {super.key});
  final List<(String, String, String)> items;
  @override
  Widget build(BuildContext c) => LayoutBuilder(
    builder: (c, b) {
      final scale = MediaQuery.textScalerOf(c).scale(14) / 14;
      final columns = (b.maxWidth / (135 * scale)).floor().clamp(
        1,
        items.length,
      );
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final (label, value, period) in items)
            SizedBox(
              width: (b.maxWidth - 12 * (columns - 1)) / columns,
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label),
                      const SizedBox(height: 8),
                      Text(value, style: Theme.of(c).textTheme.headlineSmall),
                      Text(period, style: Theme.of(c).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class WorkspaceAsync extends ConsumerWidget {
  const WorkspaceAsync({
    required this.value,
    required this.retry,
    required this.builder,
    super.key,
  });
  final AsyncValue<WorkspaceData> value;
  final VoidCallback retry;
  final Widget Function(WorkspaceData) builder;
  @override
  Widget build(BuildContext c, WidgetRef ref) => value.when(
    loading: () => const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (e, _) => Column(
      children: [
        Text('$e'),
        TextButton(
          onPressed: retry,
          child: Text(wt(c, 'Retry', 'إعادة المحاولة')),
        ),
      ],
    ),
    data: builder,
  );
}

class StaffQuickStatistics extends ConsumerWidget {
  const StaffQuickStatistics({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final clinical = ref.watch(canProvider(Permission.readPatientChart));
    final history = clinical ? ref.watch(historySummaryProvider) : null;
    final unread = ref.watch(staffUnreadCountProvider);
    return WorkspaceSection(
      wt(c, 'Quick Statistics', 'إحصاءات سريعة'),
      child: WorkspaceMetrics([
        if (clinical) ...[
          (
            wt(c, 'Appointments', 'المواعيد'),
            '${workspaceStat(history?.valueOrNull, 'appointmentsToday') ?? '—'}',
            wt(c, 'Today · all states', 'اليوم · جميع الحالات'),
          ),
          (
            wt(c, 'Consultations', 'الاستشارات'),
            '${workspaceStat(history?.valueOrNull, 'completedToday') ?? '—'}',
            wt(c, 'Completed today', 'المكتملة اليوم'),
          ),
          (
            wt(c, 'Patients seen', 'المرضى المعالجون'),
            '${workspaceStat(history?.valueOrNull, 'month') ?? '—'}',
            wt(c, 'Unique · this month', 'مرضى فريدون · هذا الشهر'),
          ),
        ],
        (
          wt(c, 'Unread messages', 'الرسائل غير المقروءة'),
          '${unread ?? '—'}',
          wt(c, 'Authorized conversations', 'المحادثات المصرح بها'),
        ),
      ]),
    );
  }
}

class PatientHistoryStatistics extends ConsumerWidget {
  const PatientHistoryStatistics({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => WorkspaceAsync(
    value: ref.watch(historySummaryProvider),
    retry: () => ref.invalidate(historySummaryProvider),
    builder: (d) {
      final s = Map<String, dynamic>.from(d['stats'] as Map<String, dynamic>);
      return Column(
        children: [
          WorkspaceMetrics([
            (
              wt(c, 'Total Patients', 'إجمالي المرضى'),
              '${s['total']}',
              wt(c, 'Unique · completed care', 'مرضى فريدون · رعاية مكتملة'),
            ),
            (
              wt(c, 'Critical', 'حرجة'),
              '${s['critical']}',
              wt(
                c,
                'Unresolved urgent clinical review',
                'مراجعة سريرية عاجلة غير محسومة',
              ),
            ),
            (
              wt(c, 'This Month', 'هذا الشهر'),
              '${s['month']}',
              wt(c, 'Unique · Bahrain calendar', 'مرضى فريدون · توقيت البحرين'),
            ),
            (
              wt(c, 'Follow-up', 'المتابعة'),
              '${s['followUp']}',
              wt(c, 'Unresolved follow-up', 'متابعة غير محسومة'),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              wt(
                c,
                'Completed-visit history only. Current care remains accessible from appointments. Nursing history requires personally recorded encounter participation.',
                'سجل الزيارات المكتملة فقط. تبقى الرعاية الحالية متاحة من المواعيد. يتطلب سجل التمريض توثيق المشاركة الشخصية في الزيارة.',
              ),
            ),
          ),
        ],
      );
    },
  );
}

class ParticipationButton extends ConsumerWidget {
  const ParticipationButton(this.patientId, {super.key});
  final String patientId;
  @override
  Widget build(BuildContext c, WidgetRef ref) => IconButton(
    tooltip: wt(
      c,
      'Record personal care participation',
      'تسجيل المشاركة الشخصية في الرعاية',
    ),
    icon: const Icon(Icons.how_to_reg_outlined),
    onPressed: () async {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .forPatient(patientId);
      if (!c.mounted) return;
      if (result.isErr) {
        showMutationFeedback(c, result);
        return;
      }
      final visits = result.valueOrNull!
          .where(
            (a) => [
              AppointmentStatus.inProgress,
              AppointmentStatus.completed,
            ].contains(a.status),
          )
          .toList();
      final visit = await showDialog<String>(
        context: c,
        builder: (dc) => AlertDialog(
          title: Text(wt(c, 'Confirm personal care', 'تأكيد الرعاية الشخصية')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    wt(
                      c,
                      'Select a visit only if you personally participated in caring for this patient. Your identity and time are recorded in the audit trail.',
                      'اختر الزيارة فقط إذا شاركت شخصياً في رعاية المريض. يتم تسجيل هويتك والوقت في سجل التدقيق.',
                    ),
                  ),
                  if (visits.isEmpty)
                    Text(
                      wt(
                        c,
                        'No active or completed visits.',
                        'لا توجد زيارات نشطة أو مكتملة.',
                      ),
                    ),
                  for (final a in visits)
                    ListTile(
                      title: Text(
                        '${clinicDateLabel(clinicDay(a.slotStart))} · ${wlabel(c, a.status.name)}',
                      ),
                      subtitle: Text(a.reasonText ?? a.visitType.name),
                      onTap: () => Navigator.pop(dc, a.id),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dc),
              child: Text(wt(c, 'Cancel', 'إلغاء')),
            ),
          ],
        ),
      );
      if (visit == null) return;
      final saved = await Result.guardAsync(
        () => ref.read(workspaceRepositoryProvider).recordParticipation(visit),
      );
      ref.invalidate(historySummaryProvider);
      ref.invalidate(patientSearchPageProvider);
      if (c.mounted) showMutationFeedback(c, saved);
    },
  );
}

class AdminClinicOverview extends ConsumerWidget {
  const AdminClinicOverview({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final day = ref.watch(workspaceDayProvider),
        days = ref.watch(workspacePeriodProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(wt(c, 'Reporting period', 'فترة التقرير')),
            SizedBox(
              width: 220,
              child: DropdownButton<int>(
                isExpanded: true,
                itemHeight: null,
                value: days,
                items: [
                  for (final n in [7, 14, 30])
                    DropdownMenuItem(
                      value: n,
                      child: Text(wt(c, '$n days', '$n يوماً')),
                    ),
                ],
                onChanged: (n) =>
                    ref.read(workspacePeriodProvider.notifier).state = n!,
              ),
            ),
            Text('${clinicDateLabel(day)} · Asia/Bahrain'),
          ],
        ),
        WorkspaceAsync(
          value: ref.watch(workspaceOverviewProvider),
          retry: () => ref.invalidate(workspaceOverviewProvider),
          builder: (d) {
            final s = Map<String, dynamic>.from(
              d['stats'] as Map<String, dynamic>,
            );
            final gender = rows(d['gender']);
            int n(String g) => gender
                .where((r) => r['gender'] == g)
                .fold(0, (a, r) => a + (r['n'] as num).toInt());
            final male = n('male'),
                female = n('female'),
                excluded =
                    gender.fold<int>(0, (a, r) => a + (r['n'] as num).toInt()) -
                    male -
                    female;
            final revenue = rows(d['revenue']);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkspaceMetrics([
                  (
                    wt(c, 'Total Patients', 'إجمالي المرضى'),
                    '${s['patients']}',
                    wt(
                      c,
                      "All time · active ${s['activePatients']}",
                      "الكل · نشط ${s['activePatients']}",
                    ),
                  ),
                  (
                    wt(c, 'Consultations', 'الاستشارات'),
                    '${s['consultations']}',
                    wt(c, 'Completed · $days days', 'مكتملة · $days يوماً'),
                  ),
                  (
                    wt(c, 'Total Staff', 'إجمالي الموظفين'),
                    '${s['staff']}',
                    wt(
                      c,
                      "All time · active ${s['activeStaff']}",
                      "الكل · نشط ${s['activeStaff']}",
                    ),
                  ),
                  (
                    wt(c, 'Total Rooms', 'إجمالي الغرف'),
                    s['roomsConfigured'] == true ? '${s['rooms']}' : '—',
                    wt(c, 'Enabled physical rooms', 'الغرف الفعلية المفعلة'),
                  ),
                  (
                    wt(c, 'Referrals', 'الإحالات'),
                    '${s['referrals']}',
                    wt(c, 'Created · $days days', 'المنشأة · $days يوماً'),
                  ),
                  (
                    wt(c, 'Prescriptions', 'الوصفات'),
                    '${s['prescriptions']}',
                    wt(c, 'Issued · $days days', 'الصادرة · $days يوماً'),
                  ),
                ]),
                const SizedBox(height: 20),
                _WorkspaceReportColumns(
                  children: [
                    WorkspaceSection(
                      wt(c, 'Upcoming Appointments', 'المواعيد القادمة'),
                      subtitle: wt(
                        c,
                        'All staff · selected clinic day',
                        'جميع الموظفين · اليوم المحدد',
                      ),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: wt(c, 'Previous day', 'اليوم السابق'),
                                onPressed: () =>
                                    ref
                                        .read(workspaceDayProvider.notifier)
                                        .state = day.subtract(
                                      const Duration(days: 1),
                                    ),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final selected = await showDatePicker(
                                    context: c,
                                    initialDate: day,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (selected != null) {
                                    ref
                                        .read(workspaceDayProvider.notifier)
                                        .state = DateTime.utc(
                                      selected.year,
                                      selected.month,
                                      selected.day,
                                    );
                                  }
                                },
                                child: Text(clinicDateLabel(day)),
                              ),
                              IconButton(
                                tooltip: wt(c, 'Next day', 'اليوم التالي'),
                                onPressed: () =>
                                    ref
                                        .read(workspaceDayProvider.notifier)
                                        .state = day.add(
                                      const Duration(days: 1),
                                    ),
                                icon: const Icon(Icons.chevron_right),
                              ),
                              TextButton(
                                onPressed: () =>
                                    ref
                                            .read(workspaceDayProvider.notifier)
                                            .state =
                                        clinicDay(),
                                child: Text(wt(c, 'Today', 'اليوم')),
                              ),
                            ],
                          ),
                          ...appointmentRows(c, d, upcoming: true),
                        ],
                      ),
                      action: TextButton(
                        onPressed: () => c.push(AppRoutes.adminAppointments),
                        child: Text(wt(c, 'Full schedule', 'الجدول الكامل')),
                      ),
                    ),
                    WorkspaceSection(
                      wt(c, 'Payment history', 'سجل المدفوعات'),
                      child: Column(
                        children: [
                          for (final p in rows(d['payments']))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${p['patient_name']} · ${bhd(fils(p['amount'] as num))}',
                              ),
                              subtitle: Text(
                                '${p['request_reference'] ?? p['id']} · ${p['invoice_id'] ?? '—'}\n${wallDate(p['created_at'])} · ${wlabel(c, p['method'])} · ${wlabel(c, p['status'])}\n${p['description'] ?? ''}${p['kind'] == 'refund' ? ' · ${wt(c, 'Refund', 'استرداد')}' : ''}${(p['refunded'] as num? ?? 0) > 0 ? '\n${wt(c, 'Refunded', 'مسترد')}: ${bhd(fils(p['refunded'] as num))}' : ''}',
                              ),
                            ),
                          if (rows(d['payments']).isEmpty)
                            Text(wt(c, 'No transactions.', 'لا توجد معاملات.')),
                        ],
                      ),
                      action: TextButton(
                        onPressed: () => c.push(AppRoutes.adminBilling),
                        child: Text(wt(c, 'Open billing', 'فتح الفوترة')),
                      ),
                    ),
                    WorkspaceSection(
                      wt(c, 'Appointments overview', 'نظرة عامة على المواعيد'),
                      subtitle: wt(
                        c,
                        'Appointment counts · $days days · cancelled/no-show excluded',
                        'عدد المواعيد · $days يوماً · باستثناء الملغاة وعدم الحضور',
                      ),
                      child: Column(
                        children: [
                          if (male + female == 0)
                            Text(
                              wt(
                                c,
                                'No male/female appointment data for this period.',
                                'لا توجد بيانات مواعيد للذكور والإناث في هذه الفترة.',
                              ),
                            )
                          else
                            Semantics(
                              label:
                                  '${wt(c, 'Male', 'ذكور')}: $male; ${wt(c, 'Female', 'إناث')}: $female',
                              child: SizedBox(
                                width: 180,
                                height: 180,
                                child: CustomPaint(
                                  painter: _GenderDonut(
                                    male,
                                    female,
                                    PatientPalette.of(c).action,
                                    PatientPalette.of(c).textMuted,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              Text(
                                '${wt(c, 'Male', 'ذكور')}: $male${male + female == 0 ? '' : ' · ${(male * 100 / (male + female)).toStringAsFixed(1)}%'}',
                              ),
                              Text(
                                '${wt(c, 'Female', 'إناث')}: $female${male + female == 0 ? '' : ' · ${(female * 100 / (male + female)).toStringAsFixed(1)}%'}',
                              ),
                            ],
                          ),
                          Text(
                            wt(
                              c,
                              'Other/undisclosed excluded: $excluded',
                              'المستبعدة (أخرى/غير مفصح): $excluded',
                            ),
                          ),
                        ],
                      ),
                    ),
                    WorkspaceSection(
                      wt(c, 'Available doctors', 'الأطباء المتاحون'),
                      subtitle: wt(
                        c,
                        'Active doctors with a future free slot on the selected day',
                        'أطباء نشطون لديهم وقت شاغر لاحق في اليوم المحدد',
                      ),
                      child: Column(
                        children: [
                          for (final doctor in rows(d['doctors']))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${doctor['name']}'),
                              subtitle: Text(
                                '${doctor['specialty']} · ${wallTime(doctor['next'])}',
                              ),
                              trailing: IconButton(
                                tooltip: wt(c, 'Open booking', 'فتح الحجز'),
                                icon: const Icon(Icons.calendar_month_outlined),
                                onPressed: () =>
                                    c.push(AppRoutes.adminAppointments),
                              ),
                            ),
                          if (rows(d['doctors']).isEmpty)
                            Text(
                              wt(
                                c,
                                'No available doctors for this day.',
                                'لا يوجد أطباء متاحون لهذا اليوم.',
                              ),
                            ),
                        ],
                      ),
                    ),
                    WorkspaceSection(
                      wt(c, 'Overall Appointments', 'إجمالي المواعيد'),
                      subtitle: wt(
                        c,
                        'Demand by scheduled start hour · $days days',
                        'الطلب حسب ساعة بدء الموعد · $days يوماً',
                      ),
                      child: _HourlyChart(rows(d['hours'])),
                    ),
                    WorkspaceSection(
                      wt(c, 'Daily Revenue Report', 'تقرير الإيرادات اليومي'),
                      subtitle: wt(
                        c,
                        'Settled receipts less settled refunds · BHD',
                        'المقبوضات المسواة ناقص الاستردادات المسواة · د.ب',
                      ),
                      action: SizedBox(
                        width: 220,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          itemHeight: null,
                          value: ref.watch(workspaceRevenuePeriodProvider),
                          items: [
                            for (final n in [7, 14, 30])
                              DropdownMenuItem(
                                value: n,
                                child: Text(wt(c, '$n days', '$n يوماً')),
                              ),
                          ],
                          onChanged: (n) =>
                              ref
                                      .read(
                                        workspaceRevenuePeriodProvider.notifier,
                                      )
                                      .state =
                                  n!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            wt(
                              c,
                              'Net receipts: ${bhd(revenue.fold<int>(0, (n, r) => n + (r['payments'] as int) - (r['refunds'] as int)))}',
                              'صافي المقبوضات: ${bhd(revenue.fold<int>(0, (n, r) => n + (r['payments'] as int) - (r['refunds'] as int)))}',
                            ),
                            style: Theme.of(c).textTheme.titleMedium,
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                for (final label in [
                                  wt(c, 'Day', 'اليوم'),
                                  wt(c, 'Payments', 'المدفوعات'),
                                  wt(c, 'Refunds', 'الاستردادات'),
                                  wt(c, 'Net receipts', 'صافي المقبوضات'),
                                ])
                                  DataColumn(label: Text(label)),
                              ],
                              rows: [
                                for (final r in revenue)
                                  DataRow(
                                    cells: [
                                      DataCell(Text('${r['day']}')),
                                      DataCell(Text(bhd(r['payments'] as num))),
                                      DataCell(Text(bhd(r['refunds'] as num))),
                                      DataCell(
                                        Text(
                                          bhd(
                                            (r['payments'] as num) -
                                                (r['refunds'] as num),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            wt(
                              c,
                              'Pending/failed transactions and wallet top-ups are excluded. No expense ledger; receipts are not profit.',
                              'تستبعد المعاملات المعلقة والفاشلة وشحن المحفظة. لا يوجد دفتر مصروفات؛ المقبوضات ليست أرباحاً.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    WorkspaceSection(
                      wt(c, 'Recent feedback', 'أحدث الملاحظات'),
                      child: Column(
                        children: [
                          for (final f in rows(d['feedback']))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${f['reporter_name'] ?? wt(c, 'Anonymous', 'مجهول')} · ${f['reporter_role'] ?? '—'}',
                              ),
                              subtitle: Text(
                                '${f['message']}\n${wlabel(c, f['status'])} · ${wallDate(f['created_at'])}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (rows(d['feedback']).isEmpty)
                            Text(
                              wt(c, 'No feedback yet.', 'لا توجد ملاحظات بعد.'),
                            ),
                        ],
                      ),
                      action: TextButton(
                        onPressed: () => c.push(AppRoutes.adminFeedback),
                        child: Text(wt(c, 'All feedback', 'جميع الملاحظات')),
                      ),
                    ),
                  ],
                ),
                for (final message in d['limitations'] as List<dynamic>? ?? [])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      workspaceNote(c, message as String),
                      style: Theme.of(c).textTheme.bodySmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

List<Widget> appointmentRows(
  BuildContext c,
  WorkspaceData d, {
  bool upcoming = false,
}) {
  final list = rows(d['appointments'])
      .where(
        (a) =>
            !upcoming ||
            [
              'booked',
              'confirmed',
              'checkedIn',
              'inProgress',
            ].contains(a['status']),
      )
      .toList();
  return [
    if (list.isEmpty)
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          wt(c, 'No appointments for this day.', 'لا توجد مواعيد لهذا اليوم.'),
        ),
      ),
    for (final a in list)
      ListTile(
        contentPadding: EdgeInsets.zero,
        isThreeLine: true,
        title: Text(
          '${wallTime(a['slot_start'])}–${wallTime(a['slot_end'])} · ${a['patient_name']}',
        ),
        subtitle: Text(
          '${a['staff_name']} · ${a['department'] ?? '—'}\n${a['reason_text'] ?? a['visit_type'] ?? ''} · ${a['room_number'] ?? wt(c, 'Room pending', 'الغرفة غير محددة')} · ${wlabel(c, a['status'])}',
        ),
      ),
  ];
}

class _GenderDonut extends CustomPainter {
  _GenderDonut(this.male, this.female, this.blue, this.secondary);
  final int male, female;
  final Color blue, secondary;
  @override
  void paint(Canvas canvas, Size size) {
    if (male + female == 0) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;
    final bounds = rect.deflate(14),
        angle = 2 * math.pi * male / (male + female);
    canvas.drawArc(bounds, -math.pi / 2, angle, false, paint..color = blue);
    canvas.drawArc(
      bounds,
      -math.pi / 2 + angle,
      2 * math.pi - angle,
      false,
      paint..color = secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _GenderDonut old) =>
      old.male != male ||
      old.female != female ||
      old.blue != blue ||
      old.secondary != secondary;
}

class _HourlyChart extends StatelessWidget {
  const _HourlyChart(this.data);
  final List<WorkspaceData> data;
  @override
  Widget build(BuildContext c) {
    if (data.isEmpty) {
      return Text(
        wt(
          c,
          'No scheduled appointments in this period.',
          'لا توجد مواعيد مجدولة في هذه الفترة.',
        ),
      );
    }
    final max = data.fold<int>(
      1,
      (n, r) => math.max(n, (r['n'] as num).toInt()),
    );
    final peak = data
        .where((r) => r['n'] == max)
        .map((r) => '${r['hour']}:00')
        .join(', ');
    return Column(
      children: [
        Text(
          wt(
            c,
            'Appointment count (vertical) · Scheduled hour (horizontal)',
            'عدد المواعيد (رأسي) · ساعة البدء (أفقي)',
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final r in data)
                Semantics(
                  label: '${r['hour']}:00 · ${r['n']}',
                  child: Tooltip(
                    message: '${r['hour']}:00 · ${r['n']}',
                    child: SizedBox(
                      width: 48,
                      child: Column(
                        children: [
                          Text('${r['n']}'),
                          Container(
                            height: 140 * (r['n'] as num) / max,
                            width: 24,
                            color: r['n'] == max
                                ? PatientPalette.of(c).action
                                : PatientPalette.of(c).textMuted,
                          ),
                          Text('${r['hour']}:00'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          wt(
            c,
            'Busiest hour: $peak. Cancelled/no-show excluded.',
            'الساعة الأكثر ازدحاماً: $peak. تستبعد الملغاة وعدم الحضور.',
          ),
        ),
      ],
    );
  }
}

class ClinicRoomsScreen extends ConsumerWidget {
  const ClinicRoomsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => AppScaffold(
    title: wt(c, 'Rooms', 'الغرف'),
    actions: const [AdminTopActions()],
    children: [
      WorkspaceAsync(
        value: ref.watch(workspaceRowsProvider('rooms')),
        retry: () => ref.invalidate(workspaceRowsProvider('rooms')),
        builder: (d) => WorkspaceSection(
          wt(c, 'Physical room directory', 'دليل الغرف الفعلية'),
          subtitle: wt(
            c,
            'Enabled rooms determine the dashboard total. Ticket labels are retained separately.',
            'تحدد الغرف المفعلة إجمالي لوحة التحكم. تحفظ تسميات التذاكر بشكل مستقل.',
          ),
          action: FilledButton.icon(
            onPressed: () => _editRoom(c, ref),
            icon: const Icon(Icons.add),
            label: Text(wt(c, 'Add room', 'إضافة غرفة')),
          ),
          child: Column(
            children: [
              if (rows(d['rows']).isEmpty)
                Text(
                  wt(
                    c,
                    'Unconfigured — add physical rooms to report an accurate total.',
                    'غير مهيأ — أضف الغرف الفعلية لإظهار إجمالي دقيق.',
                  ),
                ),
              for (final r in rows(d['rows']))
                ListTile(
                  title: Text('${r['display_label']}'),
                  subtitle: Text(
                    '${r['department'] ?? '—'} · ${r['enabled'] == true || r['enabled'] == 1 ? wt(c, 'Enabled', 'مفعلة') : wt(c, 'Disabled', 'معطلة')}',
                  ),
                  trailing: IconButton(
                    tooltip: wt(c, 'Edit room', 'تعديل الغرفة'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editRoom(c, ref, r),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

Future<void> _editRoom(
  BuildContext c,
  WidgetRef ref, [
  WorkspaceData? room,
]) async {
  final label = TextEditingController(text: room?['display_label'] as String?);
  String? department = room?['department_id'] as String?;
  bool enabled =
      room == null || room['enabled'] == true || room['enabled'] == 1;
  final departments = await ref.read(departmentsProvider.future);
  if (!c.mounted) {
    label.dispose();
    return;
  }
  final save = await showDialog<bool>(
    context: c,
    builder: (dc) => StatefulBuilder(
      builder: (dc, set) => AlertDialog(
        title: Text(wt(c, 'Room configuration', 'تهيئة الغرفة')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: wt(c, 'Display label', 'اسم الغرفة'),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: department,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: wt(c, 'Department', 'القسم'),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(wt(c, 'Unassigned', 'غير معين')),
                  ),
                  for (final d in departments)
                    DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => department = v,
              ),
              SwitchListTile(
                title: Text(wt(c, 'Enabled', 'مفعلة')),
                value: enabled,
                onChanged: (v) => set(() => enabled = v),
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
            child: Text(wt(c, 'Save', 'حفظ')),
          ),
        ],
      ),
    ),
  );
  if (save == true) {
    final result = await Result.guardAsync(
      () => ref
          .read(workspaceRepositoryProvider)
          .saveRoom(
            id: room?['id'] as String?,
            label: label.text,
            departmentId: department,
            enabled: enabled,
            version: (room?['version'] as int?) ?? 0,
          ),
    );
    ref.invalidate(workspaceRowsProvider('rooms'));
    ref.invalidate(workspaceOverviewProvider);
    if (c.mounted) showMutationFeedback(c, result);
  }
  label.dispose();
}

class _WorkspaceReportColumns extends StatelessWidget {
  const _WorkspaceReportColumns({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (bounds.maxWidth < 1000) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [children[0], children[1], children[5]],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [children[2], children[3], children[4], children[6]],
            ),
          ),
        ],
      );
    },
  );
}

String wlabel(BuildContext c, Object? value) {
  final labels = <String, (String, String)>{
    'patient': ('Patient', 'مريض'),
    'staff': ('Staff', 'موظف'),
    'admin': ('Admin', 'مدير'),
    'doctor': ('Doctor', 'طبيب'),
    'Doctor': ('Doctor', 'طبيب'),
    'nurse': ('Nurse', 'تمريض'),
    'Nurse': ('Nurse', 'تمريض'),
    'dentist': ('Dentist', 'طبيب أسنان'),
    'Dentist': ('Dentist', 'طبيب أسنان'),
    'receptionist': ('Receptionist', 'موظف استقبال'),
    'Receptionist': ('Receptionist', 'موظف استقبال'),
    'pharmacist': ('Pharmacist', 'صيدلي'),
    'Pharmacist': ('Pharmacist', 'صيدلي'),
    'booked': ('Booked', 'محجوز'),
    'confirmed': ('Confirmed', 'مؤكد'),
    'checkedIn': ('Checked in', 'تم تسجيل الوصول'),
    'inProgress': ('In progress', 'قيد التنفيذ'),
    'completed': ('Completed', 'مكتمل'),
    'cancelled': ('Cancelled', 'ملغى'),
    'noShow': ('No-show', 'عدم الحضور'),
    'open': ('Open', 'مفتوحة'),
    'resolved': ('Resolved', 'محسومة'),
    'settled': ('Settled', 'مسواة'),
    'cash': ('Cash', 'نقداً'),
    'card': ('Card', 'بطاقة'),
    'wallet': ('Wallet', 'المحفظة'),
    'savedCard': ('Saved card', 'بطاقة محفوظة'),
    'offline': ('Desk receipt', 'إيصال الاستقبال'),
    'desk': ('Desk receipt', 'إيصال الاستقبال'),
    'failed': ('Failed', 'فاشلة'),
    'initiated': ('Pending', 'معلقة'),
    'authorized': ('Authorized', 'مصرح بها'),
    'voided': ('Voided', 'ملغاة'),
    'male': ('Male', 'ذكر'),
    'female': ('Female', 'أنثى'),
    'other': ('Other', 'أخرى'),
    'undisclosed': ('Undisclosed', 'غير مفصح'),
    'bug': ('Bug report', 'بلاغ عن خلل'),
    'featureRequest': ('Feature request', 'طلب ميزة'),
    'generalFeedback': ('General feedback', 'ملاحظات عامة'),
    'complaint': ('Complaint', 'شكوى'),
  };
  final pair = labels[value];
  return pair == null ? (value?.toString() ?? '—') : wt(c, pair.$1, pair.$2);
}

String workspaceNote(BuildContext c, String value) => switch (value) {
  'unknownCompletionDates' => wt(
    c,
    'Legacy visits without an actual completion time are excluded from period counts.',
    'تستبعد الزيارات القديمة التي لا تملك وقت إكمال فعلياً من إحصاءات الفترة.',
  ),
  'unknownIssueDates' => wt(
    c,
    'Legacy prescriptions without an issuance time are excluded from period counts.',
    'تستبعد الوصفات القديمة التي لا تملك وقت إصدار من إحصاءات الفترة.',
  ),
  'deskReceipts' => wt(
    c,
    'Shared payments are settled desk receipts. No payment gateway is connected.',
    'المدفوعات المشتركة هي مقبوضات استقبال مسواة. لا توجد بوابة دفع متصلة.',
  ),
  'receiptsNotProfit' => wt(
    c,
    'No expense ledger: net receipts are not profit.',
    'لا يوجد دفتر مصروفات: صافي المقبوضات ليس ربحاً.',
  ),
  _ => value,
};
