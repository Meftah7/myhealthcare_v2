/// Admin triage queue for home-visit requests (P10-08).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/presentation/admin_top_actions.dart';
import '../application/care_providers.dart';
import 'home_visit_status.dart';

class AdminHomeVisitsScreen extends ConsumerStatefulWidget {
  const AdminHomeVisitsScreen({super.key});

  @override
  ConsumerState<AdminHomeVisitsScreen> createState() =>
      _AdminHomeVisitsScreenState();
}

class _AdminHomeVisitsScreenState
    extends ConsumerState<AdminHomeVisitsScreen> {
  HomeVisitStatus? _filter = HomeVisitStatus.requested;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final queue = ref.watch(homeVisitQueueProvider(_filter));
    final patients =
        ref.watch(patientDirectoryProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(t.homeVisitsTitle),
        actions: const [AdminTopActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              0,
              Space.md,
              Space.xs,
            ),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip(t.homeVisitStatusRequested, HomeVisitStatus.requested),
                  _chip(t.homeVisitStatusScheduled, HomeVisitStatus.scheduled),
                  _chip(t.homeVisitStatusCompleted, HomeVisitStatus.completed),
                  _chip(t.homeVisitStatusDeclined, HomeVisitStatus.declined),
                  _chip(t.allCategoriesChip, null),
                ],
              ),
            ),
          ),
        ),
      ),
      body: queue.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadQueue,
          onRetry: () => ref.invalidate(homeVisitQueueProvider(_filter)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.home_outlined,
              message: t.nothingHere,
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
                itemBuilder: (context, i) => _QueueCard(
                  request: list[i],
                  patientName: patients[list[i].patientId] ?? t.rolePatient,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, HomeVisitStatus? value) => Padding(
    padding: const EdgeInsetsDirectional.only(end: Space.xs),
    child: FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    ),
  );
}

class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.request, required this.patientName});

  final HomeVisitRequest request;
  final String patientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(patientName, style: theme.textTheme.titleMedium),
              ),
              HomeVisitStatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            t.preferredAndRequestedOn(
              fmtDate(request.preferredDate),
              fmtDate(request.createdAt),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(request.reasonText, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.xxs),
          Text(
            request.addressText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (request.decisionNote != null &&
              request.decisionNote!.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(
              t.noteLabel(request.decisionNote!),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (request.status == HomeVisitStatus.requested) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _decide(
                      context,
                      ref,
                      HomeVisitStatus.scheduled,
                    ),
                    child: Text(t.scheduleButton),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide(
                      context,
                      ref,
                      HomeVisitStatus.declined,
                    ),
                    child: Text(t.declineButton),
                  ),
                ),
              ],
            ),
          ] else if (request.status == HomeVisitStatus.scheduled) ...[
            const SizedBox(height: Space.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: () => _decide(
                  context,
                  ref,
                  HomeVisitStatus.completed,
                ),
                child: Text(t.markCompletedButton),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    HomeVisitStatus status,
  ) async {
    String? note;
    if (status == HomeVisitStatus.scheduled ||
        status == HomeVisitStatus.declined) {
      note = await _askNote(context, status);
      if (note == null) return; // cancelled the dialog
    }
    final result = await ref
        .read(homeVisitActionsProvider)
        .decide(id: request.id, status: status, decisionNote: note);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<String?> _askNote(BuildContext context, HomeVisitStatus status) {
    final controller = TextEditingController();
    final t = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == HomeVisitStatus.scheduled
              ? t.scheduleThisVisitTitle
              : t.declineThisRequestTitle,
        ),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: status == HomeVisitStatus.scheduled
                ? t.scheduleHint
                : t.declineHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
  }
}
