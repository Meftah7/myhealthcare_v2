import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/app_scaffold.dart';
import '../../core/presentation/readable_label.dart';
import '../../core/utils/ids.dart';
import '../auth/application/session.dart';
import '../workspace/workspace_repository.dart';
import '../workspace/workspace_widgets.dart';
import '../staff_dashboard/presentation/staff_top_actions.dart';
import 'workforce_repository.dart';

final teamThreadProvider = FutureProvider.autoDispose
    .family<WorkspaceData, String>((ref, id) {
      ref.watch(currentUserProvider);
      ref.watch(workspaceChangesProvider);
      return ref.watch(workforceRepositoryProvider).read('thread', {'id': id});
    });

class TeamDirectoryScreen extends ConsumerStatefulWidget {
  const TeamDirectoryScreen({super.key});
  @override
  ConsumerState<TeamDirectoryScreen> createState() => _DirectoryState();
}

class _DirectoryState extends ConsumerState<TeamDirectoryScreen> {
  String query = '';
  String? opening, error;
  @override
  Widget build(BuildContext c) => AppScaffold(
    title: wt(c, 'Team directory', 'دليل الفريق'),
    actions: const [StaffTopActions()],
    children: [
      TextField(
        onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
        decoration: InputDecoration(
          labelText: wt(
            c,
            'Search name, role or department',
            'البحث بالاسم أو الدور أو القسم',
          ),
          prefixIcon: const Icon(Icons.search),
        ),
      ),
      if (error != null) ReadableLabel(error!),
      WorkspaceAsync(
        value: ref.watch(workforceDataProvider('directory')),
        retry: () => ref.invalidate(workforceDataProvider('directory')),
        builder: (data) {
          final found = rows(data['rows'])
              .where(
                (r) => '${r['name']} ${r['role']} ${r['department']}'
                    .toLowerCase()
                    .contains(query),
              )
              .toList();
          return Column(
            children: [
              if (found.isEmpty)
                ReadableLabel(
                  wt(c, 'No matching staff.', 'لا يوجد موظفون مطابقون.'),
                ),
              for (final person in found)
                ListTile(
                  title: ReadableLabel(person['name'] as String),
                  subtitle: ReadableLabel(
                    '${wlabel(c, person['role'])} · ${person['department'] ?? ''}${person['start_minutes'] == null ? '' : '\n${_minutes(person['start_minutes'])}–${_minutes(person['end_minutes'])}'}',
                  ),
                  trailing: person['id'] == ref.watch(currentUserProvider)?.id
                      ? null
                      : IconButton(
                          tooltip: wt(c, 'Message colleague', 'مراسلة الزميل'),
                          onPressed: opening != null
                              ? null
                              : () async {
                                  setState(() {
                                    opening = person['id'] as String;
                                    error = null;
                                  });
                                  try {
                                    final id = await ref
                                        .read(workforceRepositoryProvider)
                                        .startConversation(opening!);
                                    ref.invalidate(
                                      workforceDataProvider('conversations'),
                                    );
                                    if (c.mounted)
                                      c.push('/staff/team-chat/$id');
                                  } catch (e) {
                                    if (mounted) setState(() => error = '$e');
                                  } finally {
                                    if (mounted) setState(() => opening = null);
                                  }
                                },
                          icon: const Icon(Icons.chat_bubble_outline),
                        ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

String _minutes(dynamic value) {
  final n = (value as num).toInt();
  return '${(n ~/ 60).toString().padLeft(2, '0')}:${(n % 60).toString().padLeft(2, '0')}';
}

class TeamConversationsScreen extends ConsumerWidget {
  const TeamConversationsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) => AppScaffold(
    title: wt(c, 'Team messages', 'رسائل الفريق'),
    actions: const [StaffTopActions()],
    onRefresh: () async =>
        ref.invalidate(workforceDataProvider('conversations')),
    children: [
      FilledButton.icon(
        onPressed: () => c.push('/staff/team'),
        icon: const Icon(Icons.person_add_alt),
        label: ReadableLabel(wt(c, 'Choose a colleague', 'اختيار زميل')),
      ),
      WorkspaceAsync(
        value: ref.watch(workforceDataProvider('conversations')),
        retry: () => ref.invalidate(workforceDataProvider('conversations')),
        builder: (data) => Column(
          children: [
            if (rows(data['rows']).isEmpty)
              ReadableLabel(
                wt(
                  c,
                  'No team conversations yet. Choose a colleague to begin.',
                  'لا توجد محادثات فريق بعد. اختر زميلاً للبدء.',
                ),
              ),
            for (final thread in rows(data['rows']))
              ListTile(
                title: ReadableLabel(
                  '${thread['peer_name']} · ${wlabel(c, thread['peer_role'])}',
                ),
                subtitle: ReadableLabel(
                  thread['latest_message'] as String? ??
                      wt(c, 'No messages yet', 'لا توجد رسائل بعد'),
                ),
                trailing: (thread['unread'] as num) > 0
                    ? Badge(label: Text('${thread['unread']}'))
                    : null,
                onTap: () => c.push('/staff/team-chat/${thread['id']}'),
              ),
          ],
        ),
      ),
    ],
  );
}

class TeamThreadScreen extends ConsumerStatefulWidget {
  const TeamThreadScreen({required this.id, super.key});
  final String id;
  @override
  ConsumerState<TeamThreadScreen> createState() => _ThreadState();
}

class _ThreadState extends ConsumerState<TeamThreadScreen> {
  final input = TextEditingController();
  bool busy = false;
  String? error, key, payload, lastRead;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || input.text.trim().isEmpty) return;
    final body = input.text.trim();
    if (payload != body) {
      key = newId('team_message');
      payload = body;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(workforceRepositoryProvider).send(widget.id, body, key!);
      input.clear();
      payload = null;
      key = null;
      ref.invalidate(teamThreadProvider(widget.id));
      ref.invalidate(workforceDataProvider('conversations'));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> markRead(String marker) async {
    try {
      await ref.read(workforceRepositoryProvider).markRead(widget.id);
      if (mounted) ref.invalidate(workforceDataProvider('conversations'));
    } catch (_) {
      if (mounted && lastRead == marker) lastRead = null;
    }
  }

  @override
  Widget build(BuildContext c) {
    ref.listen(teamThreadProvider(widget.id), (previous, next) {
      final messages = next.valueOrNull == null
          ? <WorkspaceData>[]
          : rows(next.valueOrNull!['rows']);
      final marker = messages.lastOrNull?['id'] as String?;
      if (marker != null && marker != lastRead) {
        lastRead = marker;
        unawaited(markRead(marker));
      }
    });
    return AppScaffold(
      title: wt(c, 'Team conversation', 'محادثة الفريق'),
      actions: const [StaffTopActions()],
      onRefresh: () async => ref.invalidate(teamThreadProvider(widget.id)),
      children: [
        WorkspaceAsync(
          value: ref.watch(teamThreadProvider(widget.id)),
          retry: () => ref.invalidate(teamThreadProvider(widget.id)),
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final message in rows(data['rows']))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReadableLabel(
                          '${message['sender_name']} · ${wallDate(message['sent_at'])} ${wallTime(message['sent_at'])}',
                        ),
                        SelectableText(message['body'] as String),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (error != null)
          ReadableLabel(
            '${wt(c, 'Message not sent. Your text is retained.', 'لم ترسل الرسالة. تم الاحتفاظ بالنص.')} $error',
          ),
        TextField(
          controller: input,
          enabled: !busy,
          minLines: 2,
          maxLines: 6,
          maxLength: 4000,
          decoration: InputDecoration(labelText: wt(c, 'Message', 'الرسالة')),
        ),
        FilledButton.icon(
          onPressed: busy ? null : send,
          icon: const Icon(Icons.send),
          label: ReadableLabel(
            busy
                ? wt(c, 'Sending…', 'جارٍ الإرسال…')
                : error == null
                ? wt(c, 'Send', 'إرسال')
                : wt(c, 'Retry send', 'إعادة الإرسال'),
          ),
        ),
      ],
    );
  }
}
