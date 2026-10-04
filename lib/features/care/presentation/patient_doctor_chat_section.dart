library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/application/visited_doctors_provider.dart';
import '../../../domain/entities/entities.dart';
import '../application/care_providers.dart';
import 'thread_list.dart';

class PatientDoctorChatSection extends ConsumerWidget {
  const PatientDoctorChatSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final doctors = ref.watch(visitedDoctorsProvider);
    final threads = ref.watch(patientThreadsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadableLabel(
          t.recordsDoctorChatTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Space.xs),
        Text(t.recordsDoctorChatNote),
        const SizedBox(height: Space.sm),
        doctors.when(
          loading: () => const SkeletonList(lines: 2),
          error: (_, _) => ErrorStateView(
            message: t.couldNotLoadMessages,
            onRetry: () => ref.invalidate(visitedDoctorsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return AppCard(child: Text(t.recordsNoVisitedDoctors));
            }
            void open(String staffId, String name) => context.push(
              '${AppRoutes.patientMessages}/$staffId'
              '?name=${Uri.encodeComponent(name)}',
            );
            // Only conversations that already have messages are listed;
            // any other doctor is reached through "Chat with doctor".
            final active = [
              for (final thread in threads.valueOrNull ?? const <CareThread>[])
                if (list.any((d) => d.staffId == thread.staffId)) thread,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (threads.hasError)
                  ErrorStateView(
                    message: t.couldNotLoadMessages,
                    onRetry: () => ref.invalidate(patientThreadsProvider),
                  )
                else if (active.isEmpty)
                  AppCard(child: Text(t.chatNoMessagesYet)),
                for (final thread in active) ...[
                  ThreadTile(
                    thread: thread,
                    viewerIsStaff: false,
                    onTap: () => open(
                      thread.staffId,
                      list.firstWhere((d) => d.staffId == thread.staffId).name,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                ],
                const SizedBox(height: Space.xs),
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(t.chatWithDoctorAction),
                  onPressed: () async {
                    final picked = await showModalBottomSheet<int>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (sheet) => SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                Space.md,
                                0,
                                Space.md,
                                Space.sm,
                              ),
                              child: Text(
                                t.chooseDoctorTitle,
                                style: Theme.of(sheet).textTheme.titleMedium,
                              ),
                            ),
                            for (final (i, doctor) in list.indexed)
                              ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: ReadableLabel(doctor.name),
                                subtitle: ReadableLabel(
                                  doctor.departmentName ?? t.yourDoctorFallback,
                                ),
                                onTap: () => Navigator.of(sheet).pop(i),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (picked != null && context.mounted) {
                      open(list[picked].staffId, list[picked].name);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
