import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shared_mode.dart';
import '../../core/di.dart';
import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';
import '../../domain/identity/permissions.dart';
import '../workspace/workspace_repository.dart';
import '../auth/application/session.dart';
import '../workspace/workspace_widgets.dart';

final dutyDataProvider = FutureProvider.autoDispose
    .family<WorkspaceData, String>((ref, resource) async {
      ref.watch(workspaceChangesProvider);
      ref.watch(currentUserProvider);
      if (ref.watch(sharedModeProvider))
        return Map<String, dynamic>.from(
          await ref.watch(sharedClientProvider).request('/api/duty/$resource')
              as Map,
        );
      final access = ref.watch(accessPolicyProvider),
          actor = await access.require(Permission.manageTasks);
      final db = ref.watch(appDatabaseProvider);
      final leave = await (db.select(
        db.availabilityExceptions,
      )..where((e) => e.staffId.equals(actor!.accountId))).get();
      return {
        'rows': [
          for (final e in leave)
            {
              'id': e.id,
              'start': e.startsAt.millisecondsSinceEpoch,
              'end': e.endsAt.millisecondsSinceEpoch,
              'reason': e.reason,
              'active': 1,
            },
        ],
        'conflicts': <WorkspaceData>[],
      };
    });

class WorkforceTimeOffScreen extends ConsumerStatefulWidget {
  const WorkforceTimeOffScreen({super.key});
  @override
  ConsumerState<WorkforceTimeOffScreen> createState() => _TimeOffState();
}

class _TimeOffState extends ConsumerState<WorkforceTimeOffScreen> {
  DateTime? start, end;
  final reason = TextEditingController();
  bool busy = false;
  String? error, key, payload;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<DateTime?> choose(DateTime? initial) async {
    final day = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (day == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    return time == null
        ? null
        : DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> save() async {
    if (busy) return;
    if (start == null ||
        end == null ||
        start!.isBefore(DateTime.now()) ||
        !end!.isAfter(start!) ||
        reason.text.trim().isEmpty) {
      setState(
        () => error = wt(
          context,
          'Choose a future start/end and record a reason.',
          'اختر بداية ونهاية مستقبلية وسجل السبب.',
        ),
      );
      return;
    }
    final signature = '$start|$end|${reason.text.trim()}';
    if (payload != signature) {
      payload = signature;
      key = newId('time_off');
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (ref.read(sharedModeProvider)) {
        await ref
            .read(sharedClientProvider)
            .request(
              '/api/duty/time-off',
              method: 'POST',
              body: {
                'start': start!.toUtc().toIso8601String(),
                'end': end!.toUtc().toIso8601String(),
                'reason': reason.text.trim(),
                'idempotencyKey': key,
              },
            );
      } else {
        final actor = await ref
            .read(accessPolicyProvider)
            .require(Permission.manageTasks);
        final db = ref.read(appDatabaseProvider);
        await db.transaction(() async {
          final existing = await (db.select(
            db.availabilityExceptions,
          )..where((e) => e.id.equals(key!))).getSingleOrNull();
          if (existing == null) {
            await db
                .into(db.availabilityExceptions)
                .insert(
                  AvailabilityExceptionsCompanion.insert(
                    id: key!,
                    staffId: actor!.accountId,
                    startsAt: start!,
                    endsAt: end!,
                    reason: Value(reason.text.trim()),
                  ),
                );
            await ref
                .read(accessPolicyProvider)
                .audit(
                  'schedule.timeOffRecorded',
                  entityType: 'availability',
                  entityId: key,
                );
          }
        });
      }
      ref.invalidate(dutyDataProvider('time-off'));
      if (mounted)
        setState(() {
          start = null;
          end = null;
          reason.clear();
          key = null;
          payload = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => AppScaffold(
    title: wt(c, 'Cover and Time Off', 'التغطية والإجازة'),
    children: [
      TextButton.icon(
        onPressed: () => c.push('/staff/tasks/handover'),
        icon: const Icon(Icons.swap_horiz),
        label: ReadableLabel(
          wt(c, 'Arrange accepted cover', 'ترتيب تغطية مقبولة'),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final v = await choose(start);
                    if (mounted && v != null) setState(() => start = v);
                  },
            child: ReadableLabel(
              start == null
                  ? wt(c, 'Choose start', 'اختيار البداية')
                  : _stamp(start!.millisecondsSinceEpoch),
            ),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final v = await choose(end);
                    if (mounted && v != null) setState(() => end = v);
                  },
            child: ReadableLabel(
              end == null
                  ? wt(c, 'Choose end', 'اختيار النهاية')
                  : _stamp(end!.millisecondsSinceEpoch),
            ),
          ),
        ],
      ),
      TextField(
        controller: reason,
        enabled: !busy,
        minLines: 2,
        maxLines: 5,
        maxLength: 2000,
        decoration: InputDecoration(labelText: wt(c, 'Reason', 'السبب')),
      ),
      if (error != null) ReadableLabel(error!),
      FilledButton(
        onPressed: busy ? null : save,
        child: ReadableLabel(
          busy
              ? wt(c, 'Saving…', 'جارٍ الحفظ…')
              : wt(c, 'Record time off', 'تسجيل الإجازة'),
        ),
      ),
      WorkspaceAsync(
        value: ref.watch(dutyDataProvider('time-off')),
        retry: () => ref.invalidate(dutyDataProvider('time-off')),
        builder: (data) => Column(
          children: [
            for (final conflict in rows(data['conflicts']))
              ListTile(
                leading: const Icon(Icons.warning_amber),
                title: ReadableLabel(
                  wt(
                    c,
                    'Existing appointment needs attention',
                    'موعد حالي يحتاج إلى متابعة',
                  ),
                ),
                subtitle: ReadableLabel(
                  '${conflict['id']} · ${_stamp(conflict['start'])}',
                ),
              ),
            for (final leave in rows(data['rows']))
              ListTile(
                title: ReadableLabel(
                  '${_stamp(leave['start'])}–${_stamp(leave['end'])}',
                ),
                subtitle: ReadableLabel(
                  '${leave['reason']} · ${leave['active'] == 1 ? wt(c, 'Active', 'سارية') : wt(c, 'Cancelled', 'ملغاة')}',
                ),
                trailing: leave['active'] != 1
                    ? null
                    : IconButton(
                        tooltip: wt(c, 'Cancel time off', 'إلغاء الإجازة'),
                        icon: const Icon(Icons.close),
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                try {
                                  if (ref.read(sharedModeProvider)) {
                                    await ref
                                        .read(sharedClientProvider)
                                        .request(
                                          '/api/duty/cancel-time-off',
                                          method: 'POST',
                                          body: {
                                            'id': leave['id'],
                                            'reason':
                                                'Cancelled by staff member',
                                          },
                                        );
                                  } else {
                                    final actor = await ref
                                        .read(accessPolicyProvider)
                                        .require(Permission.manageTasks);
                                    final db = ref.read(appDatabaseProvider);
                                    await (db.delete(db.availabilityExceptions)
                                          ..where(
                                            (e) =>
                                                e.id.equals(
                                                  leave['id'] as String,
                                                ) &
                                                e.staffId.equals(
                                                  actor!.accountId,
                                                ),
                                          ))
                                        .go();
                                  }
                                  ref.invalidate(dutyDataProvider('time-off'));
                                } catch (e) {
                                  if (mounted) setState(() => error = '$e');
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                      ),
              ),
          ],
        ),
      ),
    ],
  );
}

String _stamp(dynamic value) {
  final date = DateTime.fromMillisecondsSinceEpoch(
    (value as num).toInt(),
    isUtc: true,
  ).add(const Duration(hours: 3));
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class SharedHandoverScreen extends ConsumerStatefulWidget {
  const SharedHandoverScreen({super.key});
  @override
  ConsumerState<SharedHandoverScreen> createState() => _HandoverState();
}

class _HandoverState extends ConsumerState<SharedHandoverScreen> {
  final selected = <String, int>{};
  final expires = DateTime.now().add(const Duration(hours: 24));
  final reason = TextEditingController();
  String? recipient, error;
  bool busy = false;
  String? key, payload;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> action(String endpoint, WorkspaceData body) async {
    if (busy) return;
    final signature = '$endpoint|$body';
    if (payload != signature) {
      payload = signature;
      key = newId('handover');
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(sharedClientProvider)
          .request(
            '/api/duty/$endpoint',
            method: 'POST',
            body: {...body, 'idempotencyKey': key},
          );
      ref.invalidate(dutyDataProvider('handover'));
      if (mounted)
        setState(() {
          selected.clear();
          reason.clear();
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => AppScaffold(
    title: wt(c, 'Shift handover', 'تسليم المناوبة'),
    children: [
      if (error != null) ReadableLabel(error!),
      WorkspaceAsync(
        value: ref.watch(dutyDataProvider('handover')),
        retry: () => ref.invalidate(dutyDataProvider('handover')),
        builder: (data) {
          final me = ref.watch(sharedClientProvider).user!['id'];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReadableLabel(
                wt(
                  c,
                  'The current owner remains accountable. Cover starts only after the named recipient accepts and expires automatically.',
                  'يظل المالك الحالي مسؤولاً. تبدأ التغطية بعد قبول المستلم المحدد وتنتهي تلقائياً.',
                ),
              ),
              for (final task in rows(data['tasks']).where(
                (t) =>
                    t['owner'] == me &&
                    !['done', 'dismissed'].contains(t['status']),
              ))
                CheckboxListTile(
                  value: selected.containsKey(task['id']),
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          if (v == true) {
                            selected[task['id'] as String] =
                                (task['version'] as num).toInt();
                          } else {
                            selected.remove(task['id']);
                          }
                        }),
                  title: ReadableLabel(task['title'] as String),
                  subtitle: ReadableLabel(
                    '${task['status']} · ${task['patient'] ?? ''}',
                  ),
                ),
              if (rows(data['tasks']).isEmpty)
                ReadableLabel(
                  wt(
                    c,
                    'No owned work to hand over.',
                    'لا يوجد عمل مملوك لتسليمه.',
                  ),
                ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: recipient,
                decoration: InputDecoration(
                  labelText: wt(c, 'Named recipient', 'المستلم المحدد'),
                ),
                items: [
                  for (final user in rows(data['recipients']))
                    DropdownMenuItem(
                      value: user['id'] as String,
                      child: ReadableLabel(
                        '${user['name']} · ${wlabel(c, user['job'])}',
                      ),
                    ),
                ],
                onChanged: busy ? null : (v) => setState(() => recipient = v),
              ),
              TextField(
                controller: reason,
                enabled: !busy,
                minLines: 2,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: wt(
                    c,
                    'Reason and handover instructions',
                    'السبب وتعليمات التسليم',
                  ),
                ),
              ),
              FilledButton(
                onPressed: busy || selected.isEmpty || recipient == null
                    ? null
                    : () => action('offers', {
                        'recipient': recipient,
                        'tasks': [
                          for (final e in selected.entries)
                            {'id': e.key, 'version': e.value},
                        ],
                        'reason': reason.text.trim(),
                        'expires': expires.toUtc().toIso8601String(),
                      }),
                child: ReadableLabel(
                  wt(c, 'Offer 24-hour cover', 'عرض تغطية لمدة ٢٤ ساعة'),
                ),
              ),
              const SizedBox(height: 16),
              for (final offer in rows(data['offers']))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ReadableLabel(
                        '${offer['sender_name']} · ${offer['task_count']} ${wt(c, 'task(s)', 'مهمة')}',
                      ),
                      ReadableLabel(
                        '${offer['status']} · ${_stamp(offer['expires'])}',
                      ),
                      if (offer['recipient'] == me &&
                          offer['status'] == 'pending')
                        Wrap(
                          spacing: 4,
                          children: [
                            for (final accept in [true, false])
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => action('decide', {
                                        'id': offer['id'],
                                        'accept': accept,
                                      }),
                                child: Text(
                                  accept
                                      ? wt(c, 'Accept', 'قبول')
                                      : wt(c, 'Decline', 'رفض'),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
