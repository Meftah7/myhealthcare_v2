/// Staff inbox — patient messages waiting for a reply (P10-07).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../staff_dashboard/presentation/staff_top_actions.dart';
import '../application/care_providers.dart';
import 'message_thread_screen.dart';
import 'thread_list.dart';

class StaffInboxScreen extends ConsumerWidget {
  const StaffInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(staffThreadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: const [StaffTopActions()],
      ),
      body: threads.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your inbox.',
          onRetry: () => ref.invalidate(staffThreadsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'No patient messages.',
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
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) {
                  final t = list[i];
                  return ThreadTile(
                    thread: t,
                    viewerIsStaff: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MessageThreadScreen(
                          patientId: t.patientId,
                          staffId: t.staffId,
                          title: t.counterpartName,
                          viewerIsStaff: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
