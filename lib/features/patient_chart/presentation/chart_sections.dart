import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/di.dart';
import '../../../core/utils/format.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../tasks/presentation/task_detail_screen.dart';
import '../application/chart_providers.dart';
import 'result_review_sheet.dart';

enum ChartSection { overview, visits, results, medicines, documents, careTeam }

final chartSectionProvider = StateProvider.autoDispose
    .family<ChartSection, String>((ref, id) => ChartSection.overview);
final chartSectionsProvider = FutureProvider.autoDispose
    .family<
      ({
        List<AppointmentRow> visits,
        List<MedicalRecordRow> results,
        List<CareTeamAssignmentRow> team,
      }),
      String
    >((ref, id) async {
      await ref.watch(staffPatientAccessProvider(id).future);
      await ref.watch(accessPolicyProvider).readPatient(id);
      final db = ref.watch(appDatabaseProvider);
      final visits =
          await (db.select(db.appointments)
                ..where((a) => a.patientId.equals(id))
                ..orderBy([(a) => OrderingTerm.desc(a.slotStart)]))
              .get();
      final results =
          await (db.select(db.medicalRecords)
                ..where(
                  (r) =>
                      r.patientId.equals(id) &
                      (r.recordType.equalsValue(RecordType.labResult) |
                          r.recordType.equalsValue(RecordType.imaging)),
                )
                ..orderBy([(r) => OrderingTerm.desc(r.occurredAt)]))
              .get();
      final team = await (db.select(
        db.careTeamAssignments,
      )..where((c) => c.patientId.equals(id))).get();
      return (visits: visits, results: results, team: team);
    });

class ChartSectionPicker extends ConsumerWidget {
  const ChartSectionPicker(this.patient, {super.key});
  final String patient;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    children: [
      for (final section in ChartSection.values)
        ChoiceChip(
          selected: ref.watch(chartSectionProvider(patient)) == section,
          onSelected: (_) =>
              ref.read(chartSectionProvider(patient).notifier).state = section,
          label: Text(switch (section) {
            ChartSection.overview => workText(context, 'Overview', 'نظرة عامة'),
            ChartSection.visits => workText(context, 'Visits', 'الزيارات'),
            ChartSection.results => workText(context, 'Results', 'النتائج'),
            ChartSection.medicines => workText(context, 'Medicines', 'الأدوية'),
            ChartSection.documents => workText(context, 'Documents', 'الوثائق'),
            ChartSection.careTeam => workText(
              context,
              'Care team',
              'فريق الرعاية',
            ),
          }),
        ),
    ],
  );
}

class ChartSectionContent extends ConsumerWidget {
  const ChartSectionContent(this.patient, {super.key});
  final String patient;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(chartSectionProvider(patient));
    if (section == ChartSection.documents) {
      return OutlinedButton.icon(
        onPressed: () =>
            context.push('${AppRoutes.staffPatients}/$patient/documents'),
        icon: const Icon(Icons.description_outlined),
        label: Text(
          workText(context, 'Open document workspace', 'فتح مساحة الوثائق'),
        ),
      );
    }
    return ref
        .watch(chartSectionsProvider(patient))
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Column(
            children: [
              Text('$e'),
              TextButton(
                onPressed: () => ref.invalidate(chartSectionsProvider(patient)),
                child: Text(workText(context, 'Retry', 'إعادة المحاولة')),
              ),
            ],
          ),
          data: (data) {
            final items = <Widget>[];
            if (section == ChartSection.visits) {
              for (final v in data.visits) {
                items.add(
                  ListTile(
                    title: Text(fmtDateTime(v.slotStart)),
                    subtitle: Text('${v.status.name} · ${v.staffId}'),
                    onTap: () =>
                        context.push(AppRoutes.staffConsultation(v.id)),
                  ),
                );
              }
            }
            if (section == ChartSection.results) {
              for (final r in data.results) {
                items.add(
                  ListTile(
                    title: Text(r.title),
                    subtitle: Text(
                      '${fmtDateTime(r.occurredAt)} · ${r.uploadedByPatient ? workText(context, 'Patient import', 'استيراد المريض') : workText(context, 'Clinic record', 'سجل العيادة')}',
                    ),
                    onTap: () => showResultSheet(context, r.id),
                  ),
                );
              }
            }
            if (section == ChartSection.careTeam) {
              for (final c in data.team) {
                items.add(
                  ListTile(
                    title: Text(c.staffId),
                    subtitle: Text(
                      '${c.role.name}\n${fmtDateTime(c.assignedAt)} · ${c.endedAt == null ? workText(context, 'Ongoing', 'مستمر') : fmtDateTime(c.endedAt!)}',
                    ),
                  ),
                );
              }
            }
            return Column(
              children: items.isEmpty
                  ? [
                      Text(
                        workText(
                          context,
                          'No items recorded.',
                          'لا توجد عناصر مسجلة.',
                        ),
                      ),
                    ]
                  : items,
            );
          },
        );
  }
}
