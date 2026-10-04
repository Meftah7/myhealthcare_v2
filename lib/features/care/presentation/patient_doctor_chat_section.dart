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
            if (list.isEmpty)
              return AppCard(child: Text(t.recordsNoVisitedDoctors));
            return Column(
              children: [
                if (threads.hasError)
                  ErrorStateView(
                    message: t.couldNotLoadMessages,
                    onRetry: () => ref.invalidate(patientThreadsProvider),
                  ),
                for (final doctor in list) ...[
                  Builder(
                    builder: (context) {
                      final thread = threads.valueOrNull
                          ?.where((t) => t.staffId == doctor.staffId)
                          .firstOrNull;
                      void open() => context.push(
                        '${AppRoutes.patientMessages}/${doctor.staffId}?name=${Uri.encodeComponent(doctor.name)}',
                      );
                      if (thread != null)
                        return ThreadTile(
                          thread: thread,
                          viewerIsStaff: false,
                          onTap: open,
                        );
                      return AppCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: ReadableLabel(doctor.name),
                          subtitle: ReadableLabel(
                            doctor.departmentName ?? t.yourDoctorFallback,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: open,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: Space.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
