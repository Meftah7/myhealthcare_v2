/// Admin → audit log viewer (P5-17). Read-only feed of the audit trail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../application/admin_providers.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(auditLogProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(auditLogProvider),
          ),
          const SignOutAction(),
        ],
      ),
      body: entries.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load the audit log.',
          onRetry: () => ref.invalidate(auditLogProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No audit entries yet.',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = list[i];
              return ListTile(
                dense: true,
                title: Text(e.action),
                subtitle: Text(
                  [
                    e.entityType,
                    if (e.entityId != null) e.entityId,
                    if (e.actorUserId != null) 'by ${e.actorUserId}',
                    if (e.detail != null) e.detail,
                  ].whereType<String>().join(' · '),
                ),
                trailing: Text(
                  fmtDateTime(e.at),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
