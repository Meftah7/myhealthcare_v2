/// Admin → departments (P5-15). Create / rename / describe / delete clinical
/// departments. (The per-staff schedule-template editor is tracked separately;
/// templates are currently provisioned by the seeder.)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../application/admin_providers.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: const [SignOutAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New department'),
      ),
      body: departments.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load departments.',
          onRetry: () => ref.invalidate(departmentsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.apartment_outlined,
              message: 'No departments yet.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.sm,
                  Space.md,
                  Space.xxl + Space.xl,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final d = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: AppCard(
                      padding: const EdgeInsets.fromLTRB(
                        Space.md,
                        Space.xs,
                        Space.xs,
                        Space.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                                if (d.description != null)
                                  Text(
                                    d.description!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                unawaited(_edit(context, ref, d));
                              }
                              if (v == 'delete') {
                                unawaited(_delete(context, ref, d));
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
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

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Department d,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirm(
      context,
      title: 'Delete ${d.name}?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final r = await ref.read(adminActionsProvider).deleteDepartment(d.id);
    if (r case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text('${d.name} deleted')));
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Department? existing,
  ) {
    final name = TextEditingController(text: existing?.name ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New department' : 'Edit department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: desc,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              if (name.text.trim().isEmpty) return;
              final r = await ref
                  .read(adminActionsProvider)
                  .saveDepartment(
                    id: existing?.id,
                    name: name.text.trim(),
                    description: desc.text.trim().isEmpty
                        ? null
                        : desc.text.trim(),
                  );
              navigator.pop();
              if (r case Err(:final failure)) {
                messenger.showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
