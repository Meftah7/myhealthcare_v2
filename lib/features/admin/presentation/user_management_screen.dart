/// Admin → user management (P5-14): directory with search, activate/deactivate,
/// password reset, and account creation (patient / staff / admin) with the
/// add button following the selected tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../application/admin_providers.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _State();
}

const _roles = [UserRole.patient, UserRole.staff, UserRole.admin];

class _State extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  UserRole get _role => _roles[_tabs.index];

  ({String label, IconData icon}) get _addLabel => switch (_role) {
    UserRole.patient => (label: 'Add patient', icon: Icons.person_add_alt),
    UserRole.staff => (label: 'Add staff', icon: Icons.badge_outlined),
    UserRole.admin => (
      label: 'Add admin',
      icon: Icons.admin_panel_settings_outlined,
    ),
  };

  Future<void> _onAddPressed() {
    return switch (_role) {
      UserRole.patient => _showCreate(context, ref, UserRole.patient),
      UserRole.staff => _showCreateStaff(context, ref),
      UserRole.admin => _showCreate(context, ref, UserRole.admin),
    };
  }

  @override
  Widget build(BuildContext context) {
    final add = _addLabel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('User management'),
        actions: const [SignOutAction()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  0,
                  Space.md,
                  Space.sm,
                ),
                child: SearchBar(
                  controller: _search,
                  hintText: 'Search by name or email',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Patients'),
                  Tab(text: 'Staff'),
                  Tab(text: 'Admins'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPressed,
        icon: Icon(add.icon),
        label: Text(add.label),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final r in _roles) _UserList(role: r, query: _query),
        ],
      ),
    );
  }
}

class _UserList extends ConsumerWidget {
  const _UserList({required this.role, required this.query});
  final UserRole role;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersByRoleProvider(role));
    return users.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: 'Could not load users.',
        onRetry: () => ref.invalidate(usersByRoleProvider(role)),
      ),
      data: (all) {
        final q = query.trim().toLowerCase();
        final list = q.isEmpty
            ? all
            : all
                  .where(
                    (u) =>
                        u.fullName.toLowerCase().contains(q) ||
                        u.email.toLowerCase().contains(q),
                  )
                  .toList();
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            message: q.isEmpty
                ? 'No users in this group.'
                : 'No users match “$query”.',
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

// --- create: patient / admin (simple account) --------------------------------

Future<void> _showCreate(BuildContext context, WidgetRef ref, UserRole role) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _CreatePersonSheet(role: role),
    ),
  );
}

class _CreatePersonSheet extends ConsumerStatefulWidget {
  const _CreatePersonSheet({required this.role});
  final UserRole role;

  @override
  ConsumerState<_CreatePersonSheet> createState() => _CreatePersonSheetState();
}

class _CreatePersonSheetState extends ConsumerState<_CreatePersonSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _email.text.contains('@') &&
      _password.text.trim().length >= 8;

  String get _noun => widget.role == UserRole.admin ? 'admin' : 'patient';

  Future<void> _submit() async {
    setState(() => _busy = true);
    final actions = ref.read(adminActionsProvider);
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pw = _password.text.trim();
    final (ok, message) = switch (widget.role) {
      UserRole.admin => switch (await actions.createAdmin(
        fullName: name,
        email: email,
        temporaryPassword: pw,
      )) {
        Ok(:final value) => (true, '${value.fullName} created'),
        Err(:final failure) => (false, failure.message),
      },
      _ => switch (await actions.createPatient(
        fullName: name,
        email: email,
        temporaryPassword: pw,
      )) {
        Ok(:final value) => (true, '${value.user.fullName} created'),
        Err(:final failure) => (false, failure.message),
      },
    };
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add ${_noun == 'admin' ? 'an administrator' : 'a patient'}',
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

// --- create: staff (with department + specialty) ----------------------------

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
