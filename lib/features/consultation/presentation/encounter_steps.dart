import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../auth/application/session.dart';
import '../../tasks/presentation/task_detail_screen.dart';
import '../application/consultation_providers.dart';

final encounterStepsProvider = FutureProvider.autoDispose
    .family<
      ({
        bool signed,
        bool draft,
        bool orders,
        bool reviewed,
        bool followUp,
        int documents,
        String original,
        List<String> amendments,
      }),
      String
    >((ref, id) async {
      ref.watch(consultationDraftSaveStateProvider(id));
      ref.watch(consultationAppointmentProvider(id));
      final db = ref.watch(appDatabaseProvider);
      final visit = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(id))).getSingle();
      await ref.watch(accessPolicyProvider).readPatient(visit.patientId);
      final signed =
          (await ref.watch(encounterRepositoryProvider).signedNoteFor(id))
              .valueOrNull;
      final draft = await (db.select(
        db.encounterDrafts,
      )..where((d) => d.appointmentId.equals(id))).getSingleOrNull();
      final reviews =
          await (db.select(db.auditLog)..where(
                (a) =>
                    a.entityId.equals(id) &
                    a.action.equals('encounter.review.confirmed'),
              ))
              .get();
      final follow =
          await (db.select(db.taskSources)..where(
                (s) => s.sourceId.equals(id) & s.episodeKey.like('follow-up:%'),
              ))
              .get();
      final docs = await (db.select(
        db.documentRequests,
      )..where((d) => d.appointmentId.equals(id))).get();
      return (
        signed: signed != null,
        draft: draft != null && draft.note.trim().isNotEmpty,
        orders:
            signed != null || draft != null && draft.medicationsJson != '[]',
        reviewed: reviews.isNotEmpty,
        followUp: follow.isNotEmpty,
        documents: docs.length,
        original: signed?.body ?? '',
        amendments: signed?.amendments.map((a) => a.body).toList() ?? [],
      );
    });

class EncounterSteps extends ConsumerWidget {
  const EncounterSteps({required this.visit, required this.patient, super.key});
  final String visit, patient;

  Future<void> _review(BuildContext context, WidgetRef ref) async {
    final result = await Result.guardAsync(() async {
      final actor = ref.read(currentUserProvider)!.id;
      final access = ref.read(accessPolicyProvider);
      await access.clinicalWrite(
        staffId: actor,
        patientId: patient,
        permission: Permission.runConsultation,
      );
      await access.audit(
        'encounter.review.confirmed',
        entityType: 'appointment',
        entityId: visit,
        subjectPatientId: patient,
        detail: 'Clinician confirmed chart/results and orders review.',
      );
    });
    ref.invalidate(encounterStepsProvider(visit));
    if (context.mounted) showMutationFeedback(context, result);
  }

  Future<void> _followUp(BuildContext context, WidgetRef ref) async {
    final reason = TextEditingController();
    final value = await showWorkDialog<String>(
      context,
      builder: (c) => AlertDialog(
        title: Text(
          workText(c, 'Follow-up next action', 'إجراء المتابعة التالي'),
        ),
        content: TextField(controller: reason, maxLength: 180),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(workText(c, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isNotEmpty) {
                Navigator.pop(c, reason.text.trim());
              }
            },
            child: Text(workText(c, 'Choose deadline', 'اختر الموعد النهائي')),
          ),
        ],
      ),
    );
    reason.dispose();
    if (value == null || !context.mounted) return;
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (day == null || !context.mounted) return;
    final actor = ref.read(currentUserProvider)!.id;
    final result = await Result.guardAsync(() async {
      final access = ref.read(accessPolicyProvider);
      await access.clinicalWrite(
        staffId: actor,
        patientId: patient,
        permission: Permission.manageTasks,
      );
      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        final current = await (db.select(
          db.appointments,
        )..where((a) => a.id.equals(visit))).getSingle();
        if (current.patientId != patient || current.staffId != actor) {
          throw const AccessDeniedFailure();
        }
        final id = 'follow-up:$visit:${day.toIso8601String()}';
        if (await (db.select(
              db.staffTasks,
            )..where((t) => t.id.equals(id))).getSingleOrNull() !=
            null) {
          throw const ValidationFailure(
            'A follow-up for this visit and date already exists.',
          );
        }
        await db
            .into(db.staffTasks)
            .insert(
              StaffTasksCompanion.insert(
                id: id,
                staffId: actor,
                patientId: Value(patient),
                title: value,
                kind: TaskKind.followUpDue,
                dueAt: Value(DateTime(day.year, day.month, day.day, 17)),
              ),
            );
        await db
            .into(db.taskSources)
            .insert(
              TaskSourcesCompanion.insert(
                taskId: id,
                sourceType: 'visit',
                sourceId: visit,
                episodeKey: id,
                recordedAt: DateTime.now(),
              ),
            );
        await access.audit(
          'encounter.followup.created',
          entityType: 'appointment',
          entityId: visit,
          subjectPatientId: patient,
          detail:
              'Follow-up work and deadline recorded; clinical instructions remain in the authorized task.',
        );
      });
    });
    ref.invalidate(encounterStepsProvider(visit));
    if (context.mounted) showMutationFeedback(context, result);
  }

  Future<void> _amend(
    BuildContext context,
    WidgetRef ref, {
    String? draft,
  }) async {
    final signed = await ref
        .read(encounterRepositoryProvider)
        .signedNoteFor(visit);
    if (!context.mounted) return;
    if (signed.isErr) {
      showMutationFeedback(context, signed);
      return;
    }
    if (signed.valueOrNull == null) return;
    final body = TextEditingController(text: draft);
    final value = await showWorkDialog<String>(
      context,
      builder: (c) => AlertDialog(
        title: Text(
          workText(
            c,
            'Append correction; original retained',
            'إضافة تصحيح مع الاحتفاظ بالأصل',
          ),
        ),
        content: TextField(
          controller: body,
          minLines: 3,
          maxLines: 8,
          maxLength: 10000,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(workText(c, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () {
              if (body.text.trim().isNotEmpty) {
                Navigator.pop(c, body.text.trim());
              }
            },
            child: Text(workText(c, 'Append amendment', 'إضافة التعديل')),
          ),
        ],
      ),
    );
    body.dispose();
    if (value == null) return;
    final result = await ref
        .read(encounterRepositoryProvider)
        .amend(
          signedNoteId: signed.valueOrNull!.id,
          staffId: ref.read(currentUserProvider)!.id,
          body: value,
        );
    ref.invalidate(encounterStepsProvider(visit));
    if (context.mounted) {
      showMutationFeedback(
        context,
        result,
        onRetry: () => _amend(context, ref, draft: value),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(encounterStepsProvider(visit))
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
        data: (s) => Card(
          child: ExpansionTile(
            key: PageStorageKey('encounter-steps-$visit'),
            title: Text(
              workText(
                context,
                'Visit completion steps',
                'خطوات إكمال الزيارة',
              ),
            ),
            children: [
              if (s.signed)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    [s.original, ...s.amendments].join('\n\n---\n'),
                  ),
                ),
              ListTile(
                leading: Icon(s.signed ? Icons.check_circle : Icons.edit_note),
                title: Text(workText(context, 'Note', 'الملاحظة')),
                subtitle: Text(
                  s.signed
                      ? workText(
                          context,
                          'Signed; corrections append to the original',
                          'موقعة؛ تضاف التصحيحات إلى الأصل',
                        )
                      : s.draft
                      ? workText(
                          context,
                          'Draft saved; signature pending',
                          'المسودة محفوظة؛ التوقيع معلق',
                        )
                      : workText(
                          context,
                          'Draft not yet saved',
                          'المسودة غير محفوظة بعد',
                        ),
                ),
                trailing:
                    s.signed && ref.watch(canProvider(Permission.signEncounter))
                    ? IconButton(
                        tooltip: workText(context, 'Amend', 'تعديل'),
                        onPressed: () => _amend(context, ref),
                        icon: const Icon(Icons.edit_outlined),
                      )
                    : null,
              ),
              ListTile(
                title: Text(workText(context, 'Orders', 'الأوامر')),
                subtitle: Text(
                  s.orders
                      ? workText(
                          context,
                          'Orders recorded / finalized; verify below',
                          'الأوامر مسجلة / مكتملة؛ راجع أدناه',
                        )
                      : workText(
                          context,
                          'No medication orders recorded; review whether needed',
                          'لا توجد أوامر دوائية؛ راجع الحاجة إليها',
                        ),
                ),
              ),
              ListTile(
                title: Text(
                  workText(
                    context,
                    'Review chart, results and orders',
                    'مراجعة الملف والنتائج والأوامر',
                  ),
                ),
                leading: Icon(s.reviewed ? Icons.check_circle : Icons.rule),
                onTap: () => context.push(AppRoutes.staffPatientChart(patient)),
                trailing: IconButton(
                  tooltip: workText(
                    context,
                    'Confirm reviewed',
                    'تأكيد المراجعة',
                  ),
                  onPressed: s.reviewed ? null : () => _review(context, ref),
                  icon: const Icon(Icons.check),
                ),
              ),
              ListTile(
                title: Text(workText(context, 'Follow-up', 'المتابعة')),
                subtitle: Text(
                  s.followUp
                      ? workText(
                          context,
                          'Follow-up task recorded',
                          'تم تسجيل مهمة المتابعة',
                        )
                      : workText(
                          context,
                          'Record a next action and deadline if needed',
                          'سجل الإجراء التالي والموعد عند الحاجة',
                        ),
                ),
                trailing: IconButton(
                  tooltip: workText(context, 'Add follow-up', 'إضافة متابعة'),
                  onPressed: () => _followUp(context, ref),
                  icon: const Icon(Icons.add_task),
                ),
              ),
              ListTile(
                title: Text(workText(context, 'Documents', 'الوثائق')),
                subtitle: Text(
                  '${s.documents} ${workText(context, 'requests; issuance is separate', 'طلبات؛ الإصدار مستقل')}',
                ),
                onTap: () => context.push(
                  '${AppRoutes.staffPatients}/$patient/documents?appointmentId=$visit',
                ),
              ),
            ],
          ),
        ),
      );
}
