/// The staff Chat tab — one list of the conversations this person may see:
/// patient threads for clinicians (the care-message relationship rules) and
/// staff-to-staff team conversations for every role (membership rules). Both
/// come from the existing repositories; nothing here widens who can talk to
/// whom.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import '../../care/application/care_providers.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import '../../workforce/role_navigation.dart' show currentStaffRoleProvider;
import '../../workforce/workforce_repository.dart';
import '../../workspace/workspace_widgets.dart' show rows, wlabel;
import 'staff_home.dart';
import 'staff_navigation.dart';
import 'staff_top_actions.dart';

enum StaffConversationKind { patient, team }

/// One row of the Chat list, whichever repository it came from.
class StaffConversation {
  const StaffConversation({
    required this.kind,
    required this.name,
    required this.route,
    required this.unread,
    this.subtitle,
    this.latest,
    this.at,
  });

  final StaffConversationKind kind;
  final String name;

  /// Who they are — the colleague's role, or "Patient".
  final String? subtitle;
  final String? latest;
  final DateTime? at;
  final int unread;

  /// The thread under the Chat tab — the same route from Home and from Chat.
  final String route;
}

/// Whether this role holds patient care conversations (clinicians).
bool _hasPatientThreads(StaffRole? role) =>
    role != StaffRole.receptionist && role != StaffRole.pharmacist;

/// Every conversation this person can open, newest first. Loading until both
/// sources answer; an error if either fails (never a silent partial list).
final staffConversationsProvider =
    Provider<AsyncValue<List<StaffConversation>>>((ref) {
      final role = ref.watch(currentStaffRoleProvider);
      final me = ref.watch(currentUserProvider)?.id;
      final team = ref.watch(workforceDataProvider('conversations'));
      final patients = _hasPatientThreads(role)
          ? ref.watch(staffThreadsProvider)
          : const AsyncValue<List<CareThread>>.data([]);
      if (team.hasError) {
        return AsyncValue.error(team.error!, team.stackTrace!);
      }
      if (patients.hasError) {
        return AsyncValue.error(patients.error!, patients.stackTrace!);
      }
      if (!team.hasValue || !patients.hasValue) {
        return const AsyncValue.loading();
      }
      final list = <StaffConversation>[
        for (final t in patients.requireValue)
          StaffConversation(
            kind: StaffConversationKind.patient,
            name: t.counterpartName,
            latest: t.lastMessage.body,
            at: t.lastMessage.sentAt,
            unread: t.unreadForStaff,
            route: AppRoutes.staffInboxThread(
              t.patientId,
              name: t.counterpartName,
              ownerId: t.staffId == me ? null : t.staffId,
            ),
          ),
        for (final row in rows(team.requireValue['rows']))
          StaffConversation(
            kind: StaffConversationKind.team,
            name: row['peer_name'] as String? ?? '',
            subtitle: row['peer_role'] as String?,
            latest: row['latest_message'] as String?,
            at: row['latest_at'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    (row['latest_at'] as num).toInt() * 1000,
                  ),
            unread: (row['unread'] as num? ?? 0).toInt(),
            route: AppRoutes.staffTeamThread(row['id'] as String),
          ),
      ]..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
      return AsyncValue.data(list);
    });

/// Total unread across both sources, or null while unknown.
final staffChatUnreadProvider = Provider<int?>(
  (ref) => ref
      .watch(staffConversationsProvider)
      .valueOrNull
      ?.fold<int>(0, (sum, c) => sum + c.unread),
);

enum StaffChatFilter { all, unread, patients, team }

/// Kept across tab switches, like the patient app's list filters.
final staffChatFilterProvider = StateProvider<StaffChatFilter>(
  (ref) => StaffChatFilter.all,
);
final staffChatQueryProvider = StateProvider<String>((ref) => '');

void _refresh(WidgetRef ref) {
  ref
    ..invalidate(workforceDataProvider('conversations'))
    ..invalidate(staffThreadsProvider);
}

class StaffChatScreen extends ConsumerStatefulWidget {
  const StaffChatScreen({super.key});

  @override
  ConsumerState<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends ConsumerState<StaffChatScreen> {
  late final _query = TextEditingController(
    text: ref.read(staffChatQueryProvider),
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => workText(context, en, ar);
    final role = ref.watch(currentStaffRoleProvider);
    final filter = ref.watch(staffChatFilterProvider);
    final query = ref.watch(staffChatQueryProvider).trim().toLowerCase();
    final conversations = ref.watch(staffConversationsProvider);
    final filters = [
      (StaffChatFilter.all, t('All', 'الكل')),
      (StaffChatFilter.unread, t('Unread', 'غير المقروءة')),
      if (_hasPatientThreads(role)) ...[
        (StaffChatFilter.patients, t('Patients', 'المرضى')),
        (StaffChatFilter.team, t('Team', 'الفريق')),
      ],
    ];
    return AppScaffold(
      title: t('Chat', 'المحادثات'),
      actions: const [StaffTopActions()],
      onRefresh: () async => _refresh(ref),
      children: [
        TextField(
          key: const ValueKey('staff-chat-search'),
          controller: _query,
          textInputAction: TextInputAction.search,
          onChanged: (v) => ref.read(staffChatQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: t('Search conversations', 'ابحث في المحادثات'),
          ),
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final (value, label) in filters)
              ChoiceChip(
                key: ValueKey('staff-chat-filter-${value.name}'),
                label: Text(label),
                selected: filter == value,
                onSelected: (_) =>
                    ref.read(staffChatFilterProvider.notifier).state = value,
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('staff-chat-new'),
            onPressed: () =>
                unawaited(context.push(AppRoutes.staffTeamDirectory)),
            icon: const Icon(Icons.edit_square),
            label: ReadableLabel(t('Message a colleague', 'راسل زميلاً')),
          ),
        ),
        conversations.when(
          loading: () => const PatientStateView(kind: PatientStateKind.loading),
          error: (e, _) => PatientStateView(
            kind: PatientStateKind.error,
            message: t(
              'Conversations could not be loaded.',
              'تعذّر تحميل المحادثات.',
            ),
            actionLabel: t('Retry', 'إعادة المحاولة'),
            onAction: () => _refresh(ref),
          ),
          data: (all) {
            final shown = [
              for (final c in all)
                if ((filter != StaffChatFilter.unread || c.unread > 0) &&
                    (filter != StaffChatFilter.patients ||
                        c.kind == StaffConversationKind.patient) &&
                    (filter != StaffChatFilter.team ||
                        c.kind == StaffConversationKind.team) &&
                    (query.isEmpty ||
                        c.name.toLowerCase().contains(query) ||
                        (c.latest ?? '').toLowerCase().contains(query)))
                  c,
            ];
            return StaffListCard(
              emptyIcon: Icons.forum_outlined,
              emptyMessage: all.isEmpty
                  ? t(
                      'No conversations yet. Message a colleague to begin.',
                      'لا توجد محادثات بعد. راسل زميلاً للبدء.',
                    )
                  : filter == StaffChatFilter.unread && query.isEmpty
                  ? t('No unread conversations.', 'لا توجد محادثات غير مقروءة.')
                  : t('No conversations match.', 'لا توجد محادثات مطابقة.'),
              children: [
                for (final c in shown)
                  StaffConversationRow(
                    conversation: c,
                    onTap: () => unawaited(context.push(c.route)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Sender, latest message, time and unread count (as a number and words).
class StaffConversationRow extends StatelessWidget {
  const StaffConversationRow({
    required this.conversation,
    required this.onTap,
    super.key,
  });

  final StaffConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final c = conversation;
    final who = c.kind == StaffConversationKind.patient
        ? workText(context, 'Patient', 'مريض')
        : wlabel(context, c.subtitle);
    final unreadText = workText(
      context,
      '${c.unread} unread',
      '${c.unread} غير مقروءة',
    );
    return Semantics(
      button: true,
      label: [c.name, who, if (c.unread > 0) unreadText, ?c.latest].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: palette.softAccent,
                foregroundColor: palette.onSoftAccent,
                child: Text(
                  initialsOf(c.name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ReadableLabel(
                            c.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: c.unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: palette.text,
                            ),
                          ),
                        ),
                        if (c.at != null)
                          Text(
                            fmtTimeAgo(c.at!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: c.unread > 0
                                  ? palette.link
                                  : palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                    ReadableLabel(
                      who,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    if (c.latest != null)
                      Text(
                        c.latest!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: c.unread > 0
                              ? palette.text
                              : palette.textMuted,
                        ),
                      ),
                    if (c.unread > 0) ...[
                      const SizedBox(height: Space.xxs),
                      StatusBadge(
                        unreadText,
                        icon: Icons.mark_chat_unread_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home's unread panel: up to three unread conversations. Opens the same
/// thread, under the Chat tab, that the Chat list opens.
class StaffUnreadConversations extends ConsumerWidget {
  const StaffUnreadConversations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => workText(context, en, ar);
    final conversations = ref.watch(staffConversationsProvider);
    final unread = [
      for (final c in conversations.valueOrNull ?? const <StaffConversation>[])
        if (c.unread > 0) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          t('Unread conversations', 'محادثات غير مقروءة'),
          actionLabel: t('Open Chat', 'فتح المحادثات'),
          onAction: () => context.go(AppRoutes.staffChat),
        ),
        if (conversations.hasError)
          PatientStateView(
            kind: PatientStateKind.error,
            message: t(
              'Conversations could not be loaded.',
              'تعذّر تحميل المحادثات.',
            ),
            actionLabel: t('Retry', 'إعادة المحاولة'),
            onAction: () => _refresh(ref),
          )
        else if (conversations.isLoading && !conversations.hasValue)
          const PatientStateView(kind: PatientStateKind.loading)
        else
          StaffListCard(
            emptyIcon: Icons.mark_chat_read_outlined,
            emptyMessage: t(
              'No unread conversations.',
              'لا توجد محادثات غير مقروءة.',
            ),
            children: [
              for (final c in unread.take(3))
                StaffConversationRow(
                  key: ValueKey('home-unread-${c.route}'),
                  conversation: c,
                  // `go`, not `push`: the thread opens under Chat with the
                  // list beneath it, exactly as when opened from Chat.
                  onTap: () => context.go(c.route),
                ),
            ],
          ),
      ],
    );
  }
}
