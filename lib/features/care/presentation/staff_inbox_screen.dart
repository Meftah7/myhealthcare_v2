/// Staff inbox — patient messages waiting for a reply (P10-07).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../data/repositories/task_workflow.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../staff_dashboard/presentation/staff_top_actions.dart';
import '../../tasks/presentation/task_detail_screen.dart';
import '../application/care_providers.dart';
import 'thread_list.dart';

class StaffInboxScreen extends ConsumerWidget {
  const StaffInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final threads = ref.watch(staffThreadsProvider);
    final awaiting = ref.watch(staffAwaitingReplyProvider);

    return AppScaffold(
      title: t.messagesTitle,
      actions: const [StaffTopActions()],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(staffThreadsProvider),
        child: threads.when(
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorStateView(
            message: t.couldNotLoadInbox,
            onRetry: () => ref.invalidate(staffThreadsProvider),
          ),
          data: (list) {
            final waiting = awaiting.valueOrNull ?? [];
            DateTime? dueFor(String patient, String owner) {
              final dates =
                  waiting
                      .where(
                        (m) =>
                            m.patientId == patient &&
                            m.staffId == owner &&
                            m.responseDueAt != null,
                      )
                      .map((m) => m.responseDueAt!)
                      .toList()
                    ..sort();
              return dates.isEmpty ? null : dates.first;
            }

            list = [...list]
              ..sort((a, b) {
                final ad = dueFor(a.patientId, a.staffId),
                    bd = dueFor(b.patientId, b.staffId);
                if (ad == null) {
                  return bd == null
                      ? b.lastMessage.sentAt.compareTo(a.lastMessage.sentAt)
                      : 1;
                }
                if (bd == null) return -1;
                return ad.compareTo(bd);
              });
            if (list.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.inbox_outlined,
                    message: t.noPatientMessages,
                  ),
                ],
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.md,
                    Space.md,
                    Space.xxl,
                  ),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return awaiting.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('$e'),
                        data: (messages) => Column(
                          children: [
                            for (final m in messages.where(
                              (m) => m.isOverdueAt(DateTime.now()),
                            ))
                              ListTile(
                                leading: const Icon(Icons.schedule),
                                title: Text(
                                  workText(
                                    context,
                                    'Overdue reply',
                                    'رد متأخر',
                                  ),
                                ),
                                subtitle: Text(
                                  '${m.patientId} · ${fmtDateTime(m.responseDueAt!)}',
                                ),
                                onTap: () => context.push(
                                  AppRoutes.staffInboxThread(
                                    m.patientId,
                                    ownerId: m.staffId,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: workText(
                                    context,
                                    'Create linked task',
                                    'إنشاء مهمة مرتبطة',
                                  ),
                                  icon: const Icon(Icons.add_task),
                                  onPressed: () async {
                                    final result = await Result.guardAsync(
                                      () => ref
                                          .read(taskWorkflowProvider)
                                          .replyTask(
                                            ref.read(currentUserProvider)!.id,
                                            m.id,
                                          ),
                                    );
                                    if (!context.mounted) return;
                                    if (result.isOk) {
                                      await context.push<void>(
                                        '/staff/tasks/${Uri.encodeComponent(result.valueOrNull!)}',
                                      );
                                    } else {
                                      showMutationFeedback(context, result);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                    final t = list[i - 1];
                    return ThreadTile(
                      thread: t,
                      viewerIsStaff: true,
                      onTap: () => context.push(
                        AppRoutes.staffInboxThread(
                          t.patientId,
                          name: t.counterpartName,
                          ownerId: t.staffId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      centerBody: false,
    );
  }
}
