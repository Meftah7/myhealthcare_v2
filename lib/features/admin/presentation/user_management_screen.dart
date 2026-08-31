/// Admin → user management (P5-14): directory, activate/deactivate, password
/// reset, and staff creation with department assignment.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../application/admin_providers.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _State();
}

class _State extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User management'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Patients'),
            Tab(text: 'Staff'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStaff(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add staff'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _UserList(role: UserRole.patient),
          _UserList(role: UserRole.staff),
          _UserList(role: UserRole.admin),
        ],
      ),
    );
  }
}

class _UserList extends ConsumerWidget {
  const _UserList({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersByRoleProvider(role));
    return users.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: 'Could not load users.',
        onRetry: () => ref.invalidate(usersByRoleProvider(role)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            message: 'No users in this group.',
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final u = list[i];
            return ListTile(
              leading: CircleAvatar(
                child: Icon(u.isActive ? Icons.person : Icons.person_off),
              ),
              title: Text(u.fullName),
              subtitle: Text(u.isActive ? u.email : '${u.email} · deactivated'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => _onAction(context, ref, u, v),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(u.isActive ? 'Deactivate' : 'Reactivate'),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Text('Reset password'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    User u,
    String action,
  ) async {
    final actions = ref.read(adminActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (action == 'toggle') {
      await actions.setActive(id: u.id, active: !u.isActive);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            u.isActive
                ? '${u.fullName} deactivated'
                : '${u.fullName} reactivated',
          ),
        ),
      );
    } else if (action == 'reset') {
      final pw = await _promptPassword(context);
      if (pw == null) return;
      final r = await actions.resetPassword(id: u.id, newPassword: pw);
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (r) {
            Ok() => 'Password reset for ${u.fullName}',
            Err(:final failure) => failure.message,
          }),
        ),
      );
    }
  }
}

Future<String?> _promptPassword(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New temporary password'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'At least 8 characters'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            Navigator.pop(context, v.length >= 8 ? v : null);
          },
          child: const Text('Reset'),
        ),
      ],
    ),
  );
}

Future<void> _showCreateStaff(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: const _CreateStaffSheet(),
    ),
  );
}

class _CreateStaffSheet extends ConsumerStatefulWidget {
  const _CreateStaffSheet();

  @override
  ConsumerState<_CreateStaffSheet> createState() => _CreateStaffSheetState();
}

class _CreateStaffSheetState extends ConsumerState<_CreateStaffSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _specialty = TextEditingController();
  String? _departmentId;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _specialty]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _email.text.contains('@') &&
      _password.text.trim().length >= 8;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final r = await ref
        .read(adminActionsProvider)
        .createStaff(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          temporaryPassword: _password.text.trim(),
          specialty: _specialty.text.trim().isEmpty
              ? null
              : _specialty.text.trim(),
          departmentId: _departmentId,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok(:final value) => '${value.fullName} created',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (r.isOk) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(departmentsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add staff member',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Temporary password (8+ chars)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _specialty,
              decoration: const InputDecoration(
                labelText: 'Specialty (optional)',
              ),
            ),
            const SizedBox(height: Space.sm),
            departments.maybeWhen(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                ),
                items: [
                  const DropdownMenuItem(child: Text('None')),
                  for (final d in list)
                    DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: (_busy || !_valid) ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
