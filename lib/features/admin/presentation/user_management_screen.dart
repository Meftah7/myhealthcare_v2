/// Admin → user management (P5-14): directory with search, activate/deactivate,
/// password reset, and account creation (patient / staff / admin) with the
/// add button following the selected tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../application/admin_providers.dart';
import 'admin_top_actions.dart';

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
        actions: const [AdminTopActions()],
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
        children: [for (final r in _roles) _UserList(role: r, query: _query)],
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
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.sm,
            Space.md,
            Space.xxl,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => _UserCard(user: list[i]),
        );
      },
    );
  }
}

/// One directory row: collapsed it's name + email; tap to expand a detail
/// panel with the account actions. Replaces the old trailing "⋮" menu — the
/// actions now have room for labels and, for a patient, a couple more of them.
class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPatient = user.role == UserRole.patient;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          // Drop the ExpansionTile's stock top/bottom divider lines — the card
          // hairline is the boundary.
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(),
            collapsedShape: const RoundedRectangleBorder(),
            tilePadding: const EdgeInsets.symmetric(horizontal: Space.md),
            childrenPadding: const EdgeInsets.fromLTRB(
              Space.md,
              0,
              Space.md,
              Space.md,
            ),
            expandedAlignment: Alignment.topLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            leading: CircleAvatar(
              backgroundColor: user.isActive
                  ? scheme.secondaryContainer
                  : scheme.surfaceContainerHighest,
              child: Icon(
                user.isActive ? Icons.person : Icons.person_off,
                color: user.isActive
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            title: Text(user.fullName),
            subtitle: Text(
              user.isActive ? user.email : '${user.email} · deactivated',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              _DetailRows(user: user),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _toggleActive(context, ref),
                    icon: Icon(
                      user.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outline,
                      size: 18,
                    ),
                    label: Text(user.isActive ? 'Deactivate' : 'Reactivate'),
                    style: user.isActive
                        ? OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            side: BorderSide(
                              color: scheme.error.withValues(alpha: 0.4),
                            ),
                          )
                        : null,
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _resetPassword(context, ref),
                    icon: const Icon(Icons.password_outlined, size: 18),
                    label: const Text('Reset password'),
                  ),
                  if (isPatient) ...[
                    OutlinedButton.icon(
                      onPressed: () => _bookAppointment(context),
                      icon: const Icon(
                        Icons.event_available_outlined,
                        size: 18,
                      ),
                      label: const Text('Book appointment'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _refer(context),
                      icon: const Icon(
                        Icons.forward_to_inbox_outlined,
                        size: 18,
                      ),
                      label: const Text('Refer'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(adminActionsProvider)
        .setActive(id: user.id, active: !user.isActive);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          user.isActive
              ? '${user.fullName} deactivated'
              : '${user.fullName} reactivated',
        ),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final pw = await _promptPassword(context);
    if (pw == null) return;
    final r = await ref
        .read(adminActionsProvider)
        .resetPassword(id: user.id, newPassword: pw);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => 'Password reset for ${user.fullName}',
          Err(:final failure) => failure.message,
        }),
      ),
    );
  }

  Future<void> _bookAppointment(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _BookForPatientSheet(patient: user),
    ),
  );

  Future<void> _refer(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _ReferPatientSheet(patient: user),
    ),
  );
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Email', user.email),
        if (user.phone != null) row('Phone', user.phone!),
        if (user.nationalId != null) row('National ID', user.nationalId!),
        row('Role', user.role.name),
        row('Status', user.isActive ? 'Active' : 'Deactivated'),
        row('Joined', fmtDate(user.createdAt)),
      ],
    );
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

/// Opens the right "add user" sheet for [role] — used by the admin dashboard's
/// Quick actions as well as this screen's FAB.
Future<void> showAddUserSheet(
  BuildContext context,
  WidgetRef ref,
  UserRole role,
) => role == UserRole.staff
    ? _showCreateStaff(context, ref)
    : _showCreate(context, ref, role);

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
  String _jobTitle = kDoctorJobTitle;
  bool _busy = false;

  bool get _isNurse => _jobTitle == kNurseJobTitle;

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
          jobTitle: _jobTitle,
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
            // Role first — a nurse works the nursing queue and never takes
            // appointments, so it changes what the rest of the form means.
            DropdownButtonFormField<String>(
              initialValue: _jobTitle,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: kDoctorJobTitle, child: Text('Doctor')),
                DropdownMenuItem(value: kNurseJobTitle, child: Text('Nurse')),
              ],
              onChanged: (v) =>
                  setState(() => _jobTitle = v ?? kDoctorJobTitle),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _specialty,
              decoration: InputDecoration(
                labelText: _isNurse
                    ? 'Specialty / unit (optional)'
                    : 'Specialty (optional)',
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

// --- admin: book a visit on a patient's behalf ------------------------------

class _BookForPatientSheet extends ConsumerStatefulWidget {
  const _BookForPatientSheet({required this.patient});

  final User patient;

  @override
  ConsumerState<_BookForPatientSheet> createState() =>
      _BookForPatientSheetState();
}

class _BookForPatientSheetState extends ConsumerState<_BookForPatientSheet> {
  String? _departmentId;
  String? _staffId;
  DateTime? _date;
  TimeOfDay? _time;
  VisitType _visitType = VisitType.followUp;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  DateTime? get _start {
    final d = _date, t = _time;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool get _valid {
    final s = _start;
    return _staffId != null && s != null && isWithinClinicHours(s);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: isClinicDay(today) ? today : nextClinicDay(today),
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: isClinicDay,
      helpText: 'Clinic days: Sunday–Thursday',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: clinicOpenHour, minute: 0),
      helpText: 'Clinic hours: 08:00–20:00',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final r = await ref
        .read(adminActionsProvider)
        .bookForPatient(
          patientId: widget.patient.id,
          staffId: _staffId!,
          start: _start!,
          duration: const Duration(minutes: 20),
          visitType: _visitType,
          departmentId: _departmentId,
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => 'Appointment booked for ${widget.patient.fullName}',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (r.isOk) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = MaterialLocalizations.of(context);
    final departments = ref.watch(departmentsProvider);
    final doctors = _departmentId == null
        ? const AsyncValue<List<Staff>>.data([])
        : ref.watch(adminDepartmentDoctorsProvider(_departmentId!));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Book an appointment', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              'For ${widget.patient.fullName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            departments.maybeWhen(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: const InputDecoration(labelText: 'Department'),
                items: [
                  for (final d in list)
                    DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() {
                  _departmentId = v;
                  _staffId = null;
                }),
              ),
              orElse: () => const LoadingSkeleton(height: 56),
            ),
            const SizedBox(height: Space.sm),
            doctors.when(
              loading: () => const LoadingSkeleton(height: 56),
              error: (e, _) =>
                  const InlineBanner.error('Could not load doctors.'),
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _staffId,
                decoration: InputDecoration(
                  labelText: 'Doctor',
                  helperText: _departmentId == null
                      ? 'Choose a department first'
                      : list.isEmpty
                      ? 'No doctors in this department'
                      : null,
                ),
                items: [
                  for (final s in list)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(clinicianName(s.fullName)),
                    ),
                ],
                onChanged: list.isEmpty
                    ? null
                    : (v) => setState(() => _staffId = v),
              ),
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _date == null ? 'Date' : df.formatMediumDate(_date!),
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text(
                      _time == null ? 'Time' : _time!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            if (_start != null && !isWithinClinicHours(_start!)) ...[
              const SizedBox(height: Space.xs),
              Text(
                'Pick a time between 08:00 and 20:00.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<VisitType>(
              initialValue: _visitType,
              decoration: const InputDecoration(labelText: 'Visit type'),
              items: [
                for (final v in VisitType.values)
                  DropdownMenuItem(value: v, child: Text(visitTypeLabel(v))),
              ],
              onChanged: (v) => setState(() => _visitType = v ?? _visitType),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
                  : const Text('Book appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- admin: refer a patient (another department, or another hospital) -------

class _ReferPatientSheet extends ConsumerStatefulWidget {
  const _ReferPatientSheet({required this.patient});

  final User patient;

  @override
  ConsumerState<_ReferPatientSheet> createState() => _ReferPatientSheetState();
}

class _ReferPatientSheetState extends ConsumerState<_ReferPatientSheet> {
  bool _external = false;
  String? _departmentId;
  String _hospital = kReferralHospitals.first;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid =>
      _reason.text.trim().isNotEmpty && (_external || _departmentId != null);

  Future<void> _submit(List<Department> departments) async {
    setState(() => _busy = true);
    final destination = _external
        ? _hospital
        : departments.firstWhere((d) => d.id == _departmentId).name;
    final r = await ref
        .read(adminActionsProvider)
        .referPatient(
          patientId: widget.patient.id,
          destination: destination,
          external: _external,
          reason: _reason.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => '${widget.patient.fullName} referred to $destination',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (r.isOk) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departments = ref.watch(departmentsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Refer patient', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              widget.patient.fullName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Another department')),
                ButtonSegment(value: true, label: Text('Another hospital')),
              ],
              selected: {_external},
              onSelectionChanged: (s) => setState(() => _external = s.first),
            ),
            const SizedBox(height: Space.md),
            if (_external)
              DropdownButtonFormField<String>(
                initialValue: _hospital,
                decoration: const InputDecoration(labelText: 'Hospital'),
                items: [
                  for (final h in kReferralHospitals)
                    DropdownMenuItem(value: h, child: Text(h)),
                ],
                onChanged: (v) => setState(() => _hospital = v ?? _hospital),
              )
            else
              departments.maybeWhen(
                data: (list) => DropdownButtonFormField<String>(
                  initialValue: _departmentId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: [
                    for (final d in list)
                      DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setState(() => _departmentId = v),
                ),
                orElse: () => const LoadingSkeleton(height: 56),
              ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason for referral',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: (_busy || !_valid)
                  ? null
                  : () => _submit(departments.valueOrNull ?? const []),
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Refer patient'),
            ),
          ],
        ),
      ),
    );
  }
}
