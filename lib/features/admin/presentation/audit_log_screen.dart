/// Admin → audit log viewer (P5-17). Read-only feed of the audit trail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/paging_widgets.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../application/admin_providers.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final entries = ref.watch(auditLogProvider);
    final hasMore =
        ref.watch(auditLogPageProvider).valueOrNull?.hasMore ?? false;
    // Read once here, on this widget's own context — not inside `itemBuilder`
    // below, whose `context` parameter shadows this one and won't reliably
    // rebuild already-realized rows on an in-session theme toggle otherwise.
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppScaffold(
      title: t.auditLogTitle,
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.refreshTooltip,
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(auditLogPageProvider),
        ),
      ],
      body: entries.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadAuditLog,
          onRetry: () => ref.invalidate(auditLogPageProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              message: t.noAuditEntriesYet,
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
                  Space.sm,
                  Space.md,
                  Space.xxl,
                ),
                itemCount: list.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
                itemBuilder: (context, i) {
                  if (i == list.length) {
                    return LoadMoreFooter(
                      onLoadMore: () =>
                          ref.read(auditLogPagesProvider.notifier).state++,
                    );
                  }
                  final e = list[i];
                  return AppCard(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdaptiveFormRow(
                          children: [
                            ReadableLabel(
                              e.action,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              fmtDateTime(e.at),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            e.entityType,
                            if (e.entityId != null) e.entityId,
                            if (e.actorUserId != null)
                              t.byActorLabel(e.actorUserId!),
                            if (e.detail != null) e.detail,
                          ].whereType<String>().join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      centerBody: false,
    );
  }
}
