/// Admin → user management (P5-14): directory with search, activate/deactivate,
/// password reset, and account creation (patient / staff / admin) with the
/// add button following the selected tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
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

  ({String label, IconData icon}) _addLabel(AppLocalizations t) =>
      switch (_role) {
        UserRole.patient => (
          label: t.addPatientAction,
          icon: Icons.person_add_alt,
        ),
        UserRole.staff => (label: t.addStaffAction, icon: Icons.badge_outlined),
        UserRole.admin => (
          label: t.addAdminAction,
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
    final t = AppLocalizations.of(context)!;
    final add = _addLabel(t);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.userManagementTitle),
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
                  hintText: t.searchByNameOrEmailHint,
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
                tabs: [
                  Tab(text: t.patientsAction),
                  Tab(text: t.staffCountLabel),
                  Tab(text: t.adminsLabel),
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
    final t = AppLocalizations.of(context)!;
    final users = ref.watch(usersByRoleProvider(role));
    return users.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadUsers,
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
            message: q.isEmpty ? t.noUsersInGroup : t.noUsersMatchQuery(query),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPatient = user.role == UserRole.patient;
    final isStaff = user.role == UserRole.staff;

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
            expandedAlignment: AlignmentDirectional.topStart,
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
              user.isActive ? user.email : t.emailDeactivatedLabel(user.email),
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
                    label: Text(
                      user.isActive ? t.deactivateAction : t.reactivateAction,
                    ),
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
                    label: Text(t.resetPasswordAction),
                  ),
                  if (isPatient) ...[
                    OutlinedButton.icon(
                      onPressed: () => _bookAppointment(context),
                      icon: const Icon(
                        Icons.event_available_outlined,
                        size: 18,
                      ),
                      label: Text(t.bookAppointmentAction),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _refer(context),
                      icon: const Icon(
                        Icons.forward_to_inbox_outlined,
                        size: 18,
                      ),
                      label: Text(t.referAction),
                    ),
                  ],
                  if (isStaff)
                    OutlinedButton.icon(
                      onPressed: () => _editSchedule(context),
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(t.editScheduleAction),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(adminActionsProvider)
        .setActive(id: user.id, active: !user.isActive);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          user.isActive
              ? t.userDeactivatedSnackbar(user.fullName)
              : t.userReactivatedSnackbar(user.fullName),
        ),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final pw = await _promptPassword(context);
    if (pw == null) return;
    final r = await ref
        .read(adminActionsProvider)
        .resetPassword(id: user.id, newPassword: pw);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => t.passwordResetForSnackbar(user.fullName),
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

  Future<void> _editSchedule(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _ScheduleEditorSheet(staff: user),
    ),
  );
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
        row(t.emailLabel, user.email),
        if (user.phone != null) row(t.phoneLabel, user.phone!),
        if (user.nationalId != null) row(t.nationalIdLabel, user.nationalId!),
        row(t.roleLabel, user.role.label(context, gender: user.gender)),
        row(
          t.statusLabel,
          user.isActive ? t.accountActiveLabel : t.accountDeactivatedLabel,
        ),
        row(t.joinedLabel, fmtDate(user.createdAt)),
      ],
    );
  }
}

Future<String?> _promptPassword(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.newTemporaryPasswordTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: t.atLeast8Characters),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            Navigator.pop(context, v.length >= 8 ? v : null);
          },
          child: Text(t.resetAction),
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

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
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
        Ok(:final value) => (true, t.createdSnackbar(value.fullName)),
        Err(:final failure) => (false, failure.message),
      },
      _ => switch (await actions.createPatient(
        fullName: name,
        email: email,
        temporaryPassword: pw,
      )) {
        Ok(:final value) => (true, t.createdSnackbar(value.user.fullName)),
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
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.role == UserRole.admin
                  ? t.addAnAdministratorTitle
                  : t.addAPatientTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: t.fullNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.emailLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: t.temporaryPasswordLabel),
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
                  : Text(t.createAction),
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
    final t = AppLocalizations.of(context)!;
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
          Ok(:final value) => t.createdSnackbar(value.fullName),
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (r.isOk) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final departments = ref.watch(departmentsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.addStaffMemberTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: t.fullNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.emailLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: t.temporaryPasswordLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            // Role first — a nurse works the nursing queue and never takes
            // appointments, so it changes what the rest of the form means.
            DropdownButtonFormField<String>(
              initialValue: _jobTitle,
              decoration: InputDecoration(labelText: t.roleLabel),
              items: [
                DropdownMenuItem(
                  value: kDoctorJobTitle,
                  child: Text(t.doctorOption),
                ),
                DropdownMenuItem(
                  value: kNurseJobTitle,
                  child: Text(t.nurseOption),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _jobTitle = v ?? kDoctorJobTitle),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _specialty,
              decoration: InputDecoration(
                labelText: _isNurse
                    ? t.specialtyUnitOptionalLabel
                    : t.specialtyOptionalLabel,
              ),
            ),
            const SizedBox(height: Space.sm),
            departments.maybeWhen(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: InputDecoration(
                  labelText: t.departmentOptionalLabel,
                ),
                items: [
                  DropdownMenuItem(
                    child: Text(
                      t.noneOption,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  for (final d in list)
                    DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        d.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
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
                  : Text(t.createAction),
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
    return _staffId != null &&
        s != null &&
        isWithinClinicHours(s, ref.read(clinicScheduleProvider));
  }

  Future<void> _pickDate() async {
    final t = AppLocalizations.of(context)!;
    final schedule = ref.read(clinicScheduleProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: isClinicDay(today, schedule)
          ? today
          : nextClinicDay(today, schedule),
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: (d) => isClinicDay(d, schedule),
      helpText: t.clinicDaysHelpText,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final t = AppLocalizations.of(context)!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: ref.read(clinicScheduleProvider).openHour,
        minute: 0,
      ),
      helpText: t.clinicHoursHelpText,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
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
          Ok() => t.appointmentBookedForSnackbar(widget.patient.fullName),
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (r.isOk) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
            Text(t.bookAnAppointmentTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              t.forPatientLabel(widget.patient.fullName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            departments.maybeWhen(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: InputDecoration(labelText: t.departmentLabel),
                items: [
                  for (final d in list)
                    DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        d.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
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
              error: (e, _) => InlineBanner.error(t.couldNotLoadDoctors),
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _staffId,
                decoration: InputDecoration(
                  labelText: t.doctorLabel,
                  helperText: _departmentId == null
                      ? t.chooseDepartmentFirstHelper
                      : list.isEmpty
                      ? t.noDoctorsInDepartmentHelper
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
                      _date == null ? t.dateLabel : df.formatMediumDate(_date!),
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text(
                      _time == null ? t.timeLabel : _time!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            if (_start != null &&
                !isWithinClinicHours(
                  _start!,
                  ref.read(clinicScheduleProvider),
                )) ...[
              const SizedBox(height: Space.xs),
              Text(
                t.pickTimeBetweenNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<VisitType>(
              initialValue: _visitType,
              decoration: InputDecoration(labelText: t.visitTypeFieldLabel),
              items: [
                for (final v in VisitType.values)
                  DropdownMenuItem(value: v, child: Text(visitTypeLabel(v))),
              ],
              onChanged: (v) => setState(() => _visitType = v ?? _visitType),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _reason,
              decoration: InputDecoration(labelText: t.reasonOptionalLabel),
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
                  : Text(t.bookAppointmentAction),
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
    final t = AppLocalizations.of(context)!;
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
          Ok() => t.patientReferredToSnackbar(
            widget.patient.fullName,
            destination,
          ),
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (r.isOk) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final departments = ref.watch(departmentsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.referPatientAction, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              widget.patient.fullName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(t.anotherDepartmentSegment),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(t.anotherHospitalSegment),
                ),
              ],
              selected: {_external},
              onSelectionChanged: (s) => setState(() => _external = s.first),
            ),
            const SizedBox(height: Space.md),
            if (_external)
              DropdownButtonFormField<String>(
                initialValue: _hospital,
                decoration: InputDecoration(labelText: t.hospitalLabel),
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
                  decoration: InputDecoration(labelText: t.departmentLabel),
                  items: [
                    for (final d in list)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(
                          d.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
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
              decoration: InputDecoration(
                labelText: t.reasonForReferralLabel,
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
                  : Text(t.referPatientAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDraft {
  _DayDraft({
    required this.weekday,
    this.active = false,
    this.startMinutes = 9 * 60,
    this.endMinutes = 17 * 60,
    this.slotMinutes = 20,
  });

  final int weekday;
  bool active;
  int startMinutes;
  int endMinutes;
  int slotMinutes;
}

class _ScheduleEditorSheet extends ConsumerStatefulWidget {
  const _ScheduleEditorSheet({required this.staff});
  final User staff;

  @override
  ConsumerState<_ScheduleEditorSheet> createState() =>
      _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends ConsumerState<_ScheduleEditorSheet> {
  List<_DayDraft>? _days;
  bool _busy = false;
  String? _error;

  void _initFrom(List<ScheduleTemplate> templates) {
    if (_days != null) return;
    final byWeekday = {for (final t in templates) t.weekday: t};
    _days = [
      for (var w = 1; w <= 7; w++)
        if (byWeekday[w] case final existing?)
          _DayDraft(
            weekday: w,
            active: true,
            startMinutes: existing.startMinutes,
            endMinutes: existing.endMinutes,
            slotMinutes: existing.slotMinutes,
          )
        else
          _DayDraft(weekday: w),
    ];
  }

  Future<void> _pickTime(_DayDraft day, {required bool isStart}) async {
    final t = AppLocalizations.of(context)!;
    final current = isStart ? day.startMinutes : day.endMinutes;
    final initial = TimeOfDay(hour: current ~/ 60, minute: current % 60);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? t.startTimeLabel : t.endTimeLabel,
    );
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isStart) {
        day.startMinutes = minutes;
      } else {
        day.endMinutes = minutes;
      }
    });
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final active = _days!.where((d) => d.active).toList();
    if (active.isEmpty) {
      setState(() => _error = t.noWorkingDaysNote);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(scheduleTemplateActionsProvider)
        .save(
          staffId: widget.staff.id,
          templates: [
            for (final d in active)
              NewScheduleTemplate(
                weekday: d.weekday,
                startMinutes: d.startMinutes,
                endMinutes: d.endMinutes,
                slotMinutes: d.slotMinutes,
              ),
          ],
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.scheduleSavedMessage)));
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(staffScheduleTemplatesProvider(widget.staff.id));

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: async.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 120,
          child: Center(child: Text(t.couldNotLoadSchedule)),
        ),
        data: (templates) {
          _initFrom(templates);
          final days = _days!;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.scheduleEditorTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.xxs),
                Text(
                  '${widget.staff.fullName} · ${t.scheduleEditorSubtitle}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.md),
                for (final d in days)
                  _DayRow(
                    day: d,
                    onToggle: () => setState(() => d.active = !d.active),
                    onPickStart: () => _pickTime(d, isStart: true),
                    onPickEnd: () => _pickTime(d, isStart: false),
                    onSlotMinutesChanged: (v) =>
                        setState(() => d.slotMinutes = v),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: Space.sm),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: Space.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.saveChangesAction),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onSlotMinutesChanged,
  });

  final _DayDraft day;
  final VoidCallback onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<int> onSlotMinutesChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fmtWeekdayName(day.weekday),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Switch(value: day.active, onChanged: (_) => onToggle()),
              ],
            ),
            if (day.active) ...[
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPickStart,
                      child: Text(
                        '${t.startTimeLabel}: ${fmtMinutes(day.startMinutes)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPickEnd,
                      child: Text(
                        '${t.endTimeLabel}: ${fmtMinutes(day.endMinutes)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.slotLengthLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  DropdownButton<int>(
                    value: day.slotMinutes,
                    items: const [10, 15, 20, 30, 45, 60]
                        .map(
                          (m) => DropdownMenuItem(value: m, child: Text('$m')),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onSlotMinutesChanged(v);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
