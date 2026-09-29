/// Admin → Work needing attention (Phase 6): the exceptions an administrator
/// corrects rather than admires — results nobody owns or that are overdue
/// (assign them), patient messages past their reply time (who owns and who
/// covers), and notifications that did not go out (queue them again).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/data_state_view.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/operational_list.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/admin_providers.dart';
import '../application/attention_providers.dart';
import 'admin_top_actions.dart';

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

final _reviewsNeedingAttentionProvider =
    FutureProvider.autoDispose<List<ResultReview>>((ref) async {
      return _unwrap(
        await ref
            .watch(resultReviewRepositoryProvider)
            .openReviews(needsAttentionOnly: true),
      );
    });

final _deliveryHealthProvider = FutureProvider.autoDispose<DeliveryHealth>((
  ref,
) async {
  return _unwrap(
    await ref.watch(notificationRepositoryProvider).deliveryHealth(),
  );
});

class AdminWorkQueueScreen extends ConsumerWidget {
  const AdminWorkQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final names = <String, String>{
      ...?ref.watch(adminPatientNamesProvider).valueOrNull,
      for (final s
          in ref.watch(staffDirectoryProvider).valueOrNull ?? const <Staff>[])
        s.id: s.fullName,
    };
    final staff =
        ref.watch(staffDirectoryProvider).valueOrNull ?? const <Staff>[];
    void refresh() {
      ref
        ..invalidate(_reviewsNeedingAttentionProvider)
        ..invalidate(overdueMessagesProvider)
        ..invalidate(_deliveryHealthProvider);
      refreshAdminAttention(ref);
    }

    return AppScaffold(
      title: t.workQueueTitle,
      actions: const [AdminTopActions()],
      onRefresh: () async => refresh(),
      children: [
        SectionHeader(t.attentionResultReviews, overline: true, first: true),
        AsyncDataView(
          value: ref.watch(_reviewsNeedingAttentionProvider),
          onRetry: () => ref.invalidate(_reviewsNeedingAttentionProvider),
          isEmpty: (list) => list.isEmpty,
          empty: _Quiet(t.nothingNeedsAttention),
          builder: (context, list) => OperationalList<ResultReview>(
            items: list,
            itemId: (review) => review.id,
            searchText: (review) => [
              names[review.patientId],
              review.recordTitle,
              names[review.ownerStaffId],
            ].whereType<String>().join(' '),
            searchHint: t.searchRecordsHint,
            allLabel: t.allFilterChip,
            empty: _Quiet(t.nothingMatchesFilters),
            onRefresh: refresh,
            filters: [
              OperationalFilter(
                label: t.allStaffOption,
                options: {
                  'unassigned': t.unassignedLabel,
                  for (final person in staff) person.id: person.fullName,
                },
                matches: (review, value) => value == 'unassigned'
                    ? review.ownerStaffId == null
                    : review.ownerStaffId == value,
              ),
              OperationalFilter(
                label: t.ageLabel,
                options: {
                  'overdue': t.invoiceStatusOverdue,
                  'current': t.resultReviewDue(''),
                },
                matches: (review, value) =>
                    review.isOverdueAt(DateTime.now()) == (value == 'overdue'),
              ),
              OperationalFilter(
                label: t.statusLabel,
                options: {
                  for (final status in ResultReviewStatus.values)
                    status.name: status.label(context),
                },
                matches: (review, value) => review.status.name == value,
              ),
            ],
            columns: [
              OperationalColumn(
                label: t.attentionResultReviews,
                value: (review) =>
                    '${names[review.patientId] ?? review.patientId} · ${review.recordTitle}',
              ),
              OperationalColumn(
                label: t.allStaffOption,
                value: (review) => review.ownerStaffId == null
                    ? t.unassignedLabel
                    : names[review.ownerStaffId] ?? review.ownerStaffId!,
              ),
              OperationalColumn(
                label: t.statusLabel,
                value: (review) => review.status.label(context),
              ),
              OperationalColumn(
                label: t.ageLabel,
                value: (review) {
                  final due =
                      '${fmtDate(review.dueAt)} ${fmtTime(review.dueAt)}';
                  return review.isOverdueAt(DateTime.now())
                      ? t.resultReviewOverdue(due)
                      : t.resultReviewDue(due);
                },
              ),
            ],
            trailing: (context, review) => TextButton(
              onPressed: () => _assignReview(context, ref, review, refresh),
              child: Text(t.assignAction),
            ),
          ),
        ),
        SectionHeader(t.attentionMessages, overline: true),
        AsyncDataView(
          value: ref.watch(overdueMessagesProvider),
          onRetry: () => ref.invalidate(overdueMessagesProvider),
          isEmpty: (list) => list.isEmpty,
          empty: _Quiet(t.nothingNeedsAttention),
          builder: (context, list) => AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final m in list)
                  ListTile(
                    leading: const Icon(Icons.mark_email_unread_outlined),
                    title: Text(names[m.patientId] ?? m.patientId),
                    subtitle: Text(
                      [
                        t.clinicianLabel(names[m.staffId] ?? m.staffId),
                        if (m.coverageStaffId != null)
                          t.resultReviewCoveredBy(
                            names[m.coverageStaffId] ?? m.coverageStaffId!,
                          ),
                        t.messageReplyWasDue(
                          '${fmtDate(m.responseDueAt!)} '
                          '${fmtTime(m.responseDueAt!)}',
                        ),
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SectionHeader(t.attentionDeliveries, overline: true),
        AsyncDataView(
          value: ref.watch(_deliveryHealthProvider),
          onRetry: () => ref.invalidate(_deliveryHealthProvider),
          isEmpty: (h) => h.total == 0,
          empty: _Quiet(t.nothingNeedsAttention),
          builder: (context, h) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.deliveryHealthSummary(
                    h.failedSideEffects + h.failedReminders,
                    h.overdueReminders,
                  ),
                ),
                if (h.failedSideEffects > 0) ...[
                  const SizedBox(height: Space.sm),
                  FilledButton.tonal(
                    onPressed: () async {
                      final r = await ref
                          .read(notificationRepositoryProvider)
                          .retryFailedDeliveries();
                      if (r.isOk) {
                        await ref.read(outboxDispatcherProvider).drain();
                      }
                      if (!context.mounted) return;
                      showMutationFeedback(
                        context,
                        r,
                        success: t.deliveriesRequeued(r.valueOrNull ?? 0),
                        onRetry: refresh,
                      );
                      refresh();
                    },
                    child: Text(t.retryFailedDeliveriesAction),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

Future<void> _assignReview(
  BuildContext context,
  WidgetRef ref,
  ResultReview review,
  VoidCallback onChanged,
) async {
  final t = AppLocalizations.of(context)!;
  final doctors = [
    for (final s in await ref.read(staffDirectoryProvider.future))
      if (s.isDoctor && s.user.isActive) s,
  ];
  if (!context.mounted) return;
  final picked = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.assignToLabel),
      children: [
        for (final d in doctors)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, d.id),
            child: Text(d.fullName),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  final r = await ref
      .read(resultReviewRepositoryProvider)
      .assign(
        id: review.id,
        ownerStaffId: picked,
        note: t.assignedByAdminNote,
        expectedVersion: review.version,
      );
  if (!context.mounted) return;
  showMutationFeedback(
    context,
    r,
    success: t.resultReviewUpdated,
    onReload: onChanged,
    onRetry: () => _assignReview(context, ref, review, onChanged),
  );
  onChanged();
}
