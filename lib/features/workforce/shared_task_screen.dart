import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/shared_mode.dart';
import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/readable_label.dart';
import '../auth/application/session.dart';
import '../workspace/workspace_repository.dart';
import '../workspace/workspace_widgets.dart';
import 'duty_screens.dart';

final sharedTaskDataProvider = FutureProvider.autoDispose
    .family<WorkspaceData, String>((ref, id) async {
      ref.watch(currentUserProvider);
      ref.watch(workspaceChangesProvider);
      final client = ref.watch(sharedClientProvider);
      final task = Map<String, dynamic>.from(
        await client.request('/api/tasks/$id') as Map,
      );
      final history = await client.request('/api/tasks/$id/history');
      return {...task, 'history': history};
    });

class SharedTaskScreen extends ConsumerStatefulWidget {
  const SharedTaskScreen({required this.id, super.key});
  final String id;
  @override
  ConsumerState<SharedTaskScreen> createState() => _TaskState();
}

class _TaskState extends ConsumerState<SharedTaskScreen> {
  final outcome = TextEditingController();
  String? status, error;
  DateTime? review;
  bool busy = false;
  @override
  void dispose() {
    outcome.dispose();
    super.dispose();
  }

  Future<void> save(WorkspaceData task) async {
    if (busy) return;
    final target = status ?? task['status'] as String;
    if (outcome.text.trim().isEmpty ||
        (['waiting', 'blocked'].contains(target) &&
            (review == null || !review!.isAfter(DateTime.now())))) {
      setState(
        () => error = wt(
          context,
          'Record an outcome and, for waiting or blocked work, a future review time.',
          'سجل النتيجة ووقت مراجعة مستقبلي للعمل المنتظر أو المتعثر.',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(sharedClientProvider)
          .request(
            '/api/tasks/${widget.id}',
            method: 'PATCH',
            body: {
              'status': target,
              'expectedVersion': task['version'],
              'outcome': outcome.text.trim(),
              'reviewAt': review?.toUtc().toIso8601String(),
            },
          );
      ref.invalidate(sharedTaskDataProvider(widget.id));
      ref.invalidate(dutyDataProvider('handover'));
      if (mounted) setState(() => outcome.clear());
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => AppScaffold(
    title: wt(c, 'Work item', 'مهمة عمل'),
    children: [
      WorkspaceAsync(
        value: ref.watch(sharedTaskDataProvider(widget.id)),
        retry: () => ref.invalidate(sharedTaskDataProvider(widget.id)),
        builder: (task) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReadableLabel(task['title'] as String),
            ReadableLabel(
              '${wt(c, 'Responsible owner', 'المالك المسؤول')}: ${task['owner']}',
            ),
            if (task['coverage_staff'] != null)
              ReadableLabel(
                '${wt(c, 'Covering staff', 'موظف التغطية')}: ${task['coverage_staff']}',
              ),
            if (task['patient'] != null)
              TextButton(
                onPressed: () => c.push('/staff/patients/${task['patient']}'),
                child: ReadableLabel(
                  wt(
                    c,
                    'Open authorized patient record',
                    'فتح سجل المريض المصرح به',
                  ),
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: status ?? task['status'] as String,
              isExpanded: true,
              decoration: InputDecoration(labelText: wt(c, 'Status', 'الحالة')),
              items: [
                for (final value in [
                  'open',
                  'inProgress',
                  'waiting',
                  'blocked',
                  'done',
                  'dismissed',
                ])
                  DropdownMenuItem(
                    value: value,
                    child: ReadableLabel(wlabel(c, value)),
                  ),
              ],
              onChanged: busy ? null : (v) => setState(() => status = v),
            ),
            TextField(
              controller: outcome,
              enabled: !busy,
              minLines: 2,
              maxLines: 6,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: wt(c, 'Outcome or reason', 'النتيجة أو السبب'),
              ),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      final day = await showDatePicker(
                        context: c,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (day == null || !c.mounted) return;
                      final time = await showTimePicker(
                        context: c,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null && mounted)
                        setState(
                          () => review = DateTime(
                            day.year,
                            day.month,
                            day.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                    },
              child: ReadableLabel(
                review == null
                    ? wt(c, 'Choose next review', 'اختيار المراجعة التالية')
                    : review!.toLocal().toString(),
              ),
            ),
            if (error != null) ReadableLabel(error!),
            FilledButton(
              onPressed: busy ? null : () => save(task),
              child: ReadableLabel(
                busy
                    ? wt(c, 'Saving…', 'جارٍ الحفظ…')
                    : wt(c, 'Save status and outcome', 'حفظ الحالة والنتيجة'),
              ),
            ),
            const SizedBox(height: 16),
            ReadableLabel(wt(c, 'Recorded history', 'السجل المسجل')),
            for (final event in rows(task['history']))
              ListTile(
                title: ReadableLabel(
                  event['reason'] as String? ??
                      event['outcome'] as String? ??
                      '',
                ),
                subtitle: ReadableLabel(
                  '${event['actor']} · ${DateTime.fromMillisecondsSinceEpoch((event['at'] as num).toInt(), isUtc: true).add(const Duration(hours: 3))}',
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
