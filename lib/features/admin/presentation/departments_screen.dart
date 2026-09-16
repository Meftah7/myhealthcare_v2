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
import '../../../l10n/app_localizations.dart';
import '../application/admin_providers.dart';
import 'admin_top_actions.dart';

/// Opens the "new department" dialog — used by the admin dashboard's Quick
/// actions as well as this screen's FAB.
Future<void> showNewDepartmentDialog(BuildContext context, WidgetRef ref) =>
    const DepartmentsScreen()._edit(context, ref, null);

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final departments = ref.watch(departmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.departmentsLabel),
        actions: const [AdminTopActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(t.newDepartmentAction),
      ),
      body: departments.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadDepartments,
          onRetry: () => ref.invalidate(departmentsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.apartment_outlined,
              message: t.noDepartmentsYet,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (d.description != null)
                                  Text(
                                    d.description!,
                                    style: Theme.of(context).textTheme.bodySmall
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
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(t.editAction),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(t.deleteAction),
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
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirm(
      context,
      title: t.deleteConfirmTitle(d.name),
      message: t.cannotBeUndoneNote,
      confirmLabel: t.deleteAction,
      destructive: true,
    );
    if (!ok) return;
    final r = await ref.read(adminActionsProvider).deleteDepartment(d.id);
    if (r case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(t.itemDeletedSnackbar(d.name))),
      );
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Department? existing,
  ) {
    final t = AppLocalizations.of(context)!;
    final name = TextEditingController(text: existing?.name ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existing == null ? t.newDepartmentAction : t.editDepartmentTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: t.nameLabel),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: desc,
              decoration: InputDecoration(
                labelText: t.descriptionOptionalLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
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
            child: Text(t.saveButton),
          ),
        ],
      ),
    );
  }
}
