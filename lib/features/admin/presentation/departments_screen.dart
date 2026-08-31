/// Admin → departments (P5-15). Create / rename / describe clinical
/// departments. (The per-staff schedule-template editor is tracked separately;
/// templates are currently provisioned by the seeder.)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../application/admin_providers.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
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
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final d = list[i];
              return ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: Text(d.name),
                subtitle: d.description == null ? null : Text(d.description!),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _edit(context, ref, d),
              );
            },
          );
        },
      ),
    );
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
