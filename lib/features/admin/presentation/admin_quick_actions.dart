/// The admin dashboard "Quick actions" grid (ported from the FirstSemMyHealth
/// admin dashboard's scattered operations).
///
/// Every admin operation is reachable here — add a user, broadcast a message,
/// raise an invoice, jump to the billing / appointments / analytics / audit
/// screens, add a department, re-seed the demo data. New admin features are
/// added as tiles here.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../care/application/care_providers.dart';
import '../application/admin_providers.dart';
import 'departments_screen.dart';
import 'user_management_screen.dart';

class AdminQuickActions extends ConsumerWidget {
  const AdminQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = WindowSize.of(context);
    final crossAxisCount = size.isCompact
        ? 3
        : size.isMedium
        ? 4
        : 6;

    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.person_add_alt,
        label: 'Add user',
        onTap: () => unawaited(_addUser(context, ref)),
      ),
      _QuickAction(
        icon: Icons.campaign_outlined,
        label: 'Broadcast',
        onTap: () => unawaited(showBroadcastSheet(context, ref)),
      ),
      _QuickAction(
        icon: Icons.request_quote_outlined,
        label: 'Create invoice',
        onTap: () => unawaited(showCreateInvoiceSheet(context, ref)),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'Billing',
        onTap: () => unawaited(context.push(AppRoutes.adminBilling)),
      ),
      _QuickAction(
        icon: Icons.calendar_month_outlined,
        label: 'Appointments',
        onTap: () => unawaited(context.push(AppRoutes.adminAppointments)),
      ),
      _QuickAction(
        icon: Icons.add_home_outlined,
        label: switch (ref.watch(openHomeVisitCountProvider)) {
          0 => 'Home visits',
          final n => 'Home visits ($n)',
        },
        onTap: () => unawaited(context.push(AppRoutes.adminHomeVisits)),
      ),
      _QuickAction(
        icon: Icons.apartment_outlined,
        label: 'New department',
        onTap: () => unawaited(showNewDepartmentDialog(context, ref)),
      ),
      _QuickAction(
        icon: Icons.forum_outlined,
        label: 'Feedback',
        onTap: () => unawaited(context.push(AppRoutes.adminFeedback)),
      ),
      _QuickAction(
        icon: Icons.auto_awesome_outlined,
        label: 'AI activity',
        onTap: () => unawaited(context.push(AppRoutes.adminAiLog)),
      ),
      _QuickAction(
        icon: Icons.query_stats_outlined,
        label: 'Forecast',
        onTap: () => unawaited(context.push(AppRoutes.adminForecast)),
      ),
      _QuickAction(
        icon: Icons.insights_outlined,
        label: 'Analytics',
        onTap: () => unawaited(context.push(AppRoutes.adminAnalytics)),
      ),
      _QuickAction(
        icon: Icons.fact_check_outlined,
        label: 'Audit log',
        onTap: () => context.go(AppRoutes.adminAudit),
      ),
      _QuickAction(
        icon: Icons.dataset_outlined,
        label: 'Re-seed data',
        onTap: () => unawaited(_reseed(context, ref)),
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.xs,
      crossAxisSpacing: Space.xs,
      childAspectRatio: 0.92,
      children: [for (final a in actions) _QuickActionTile(action: a)],
    );
  }

  Future<void> _addUser(BuildContext context, WidgetRef ref) async {
    final role = await showModalBottomSheet<UserRole>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                0,
                Space.lg,
                Space.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a…',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            for (final (role, label, icon) in const [
              (UserRole.patient, 'Patient', Icons.person_outline),
              (UserRole.staff, 'Staff member', Icons.badge_outlined),
              (UserRole.admin, 'Administrator', Icons.shield_outlined),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(context).pop(role),
              ),
            const SizedBox(height: Space.sm),
          ],
        ),
      ),
    );
    if (role != null && context.mounted) {
      await showAddUserSheet(context, ref, role);
    }
  }

  Future<void> _reseed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirm(
      context,
      title: 'Re-seed demo data?',
      message: 'This wipes every account, appointment and record and rebuilds '
          'the demo dataset. You will be signed out.',
      confirmLabel: 'Re-seed',
      destructive: true,
    );
    if (!ok) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Re-seeding…')),
    );
    final r = await ref.read(seederProvider).reset();
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Re-seeded: ${r.patients} patients, ${r.staff} staff, '
            '${r.appointments} appointments.',
          ),
        ),
      );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(Space.xs),
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: Space.xs),
          Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

// --- broadcast composer -------------------------------------------------

Future<void> showBroadcastSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _BroadcastSheet(),
  );
}

class _BroadcastSheet extends ConsumerStatefulWidget {
  const _BroadcastSheet();

  @override
  ConsumerState<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends ConsumerState<_BroadcastSheet> {
  NotificationAudience _audience = NotificationAudience.allPatients;
  NotificationCategory _category = NotificationCategory.system;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  Future<void> _send() async {
    setState(() => _busy = true);
    final result = await ref
        .read(adminActionsProvider)
        .broadcast(
          audience: _audience,
          category: _category,
          title: _title.text.trim(),
          body: _body.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok(:final value) => 'Sent to $value '
              '${value == 1 ? 'person' : 'people'}.',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + insets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Broadcast a notification', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<NotificationAudience>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Send to'),
              items: const [
                DropdownMenuItem(
                  value: NotificationAudience.allPatients,
                  child: Text('All patients'),
                ),
                DropdownMenuItem(
                  value: NotificationAudience.allStaff,
                  child: Text('All staff'),
                ),
                DropdownMenuItem(
                  value: NotificationAudience.everyone,
                  child: Text('Everyone'),
                ),
              ],
              onChanged: (v) => setState(() => _audience = v!),
            ),
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<NotificationCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in NotificationCategory.values)
                  DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _body,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: (_busy || !_valid) ? null : _send,
              icon: _busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(NotificationCategory c) => switch (c) {
  NotificationCategory.appointment => 'Appointment',
  NotificationCategory.billing => 'Billing',
  NotificationCategory.labResult => 'Lab result',
  NotificationCategory.prescription => 'Prescription',
  NotificationCategory.message => 'Message',
  NotificationCategory.system => 'System',
};

// --- create invoice ---------------------------------------------------

Future<void> showCreateInvoiceSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CreateInvoiceSheet(),
  );
}

class _CreateInvoiceSheet extends ConsumerStatefulWidget {
  const _CreateInvoiceSheet();

  @override
  ConsumerState<_CreateInvoiceSheet> createState() =>
      _CreateInvoiceSheetState();
}

class _CreateInvoiceSheetState extends ConsumerState<_CreateInvoiceSheet> {
  String? _patientId;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? get _subtotal => double.tryParse(_amount.text.trim());
  bool get _valid => _patientId != null && (_subtotal ?? -1) >= 0;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref
        .read(adminActionsProvider)
        .issueInvoice(
          patientId: _patientId!,
          subtotal: _subtotal!,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok(:final value) =>
            'Invoice raised — BD ${value.totalAmount.toStringAsFixed(2)}.',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = ref.watch(adminPatientNamesProvider);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final subtotal = _subtotal;

    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + insets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create an invoice', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.md),
            names.when(
              loading: () => const LoadingSkeleton(height: 56),
              error: (e, _) =>
                  const InlineBanner.error('Could not load patients.'),
              data: (map) {
                final entries = map.entries.toList()
                  ..sort((a, b) => a.value.compareTo(b.value));
                return DropdownMenu<String>(
                  expandedInsets: EdgeInsets.zero,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  label: const Text('Patient'),
                  onSelected: (v) => setState(() => _patientId = v),
                  dropdownMenuEntries: [
                    for (final e in entries)
                      DropdownMenuEntry(value: e.key, label: e.value),
                  ],
                );
              },
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (BD, before tax)',
                prefixText: 'BD ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'What is this for? (optional)',
              ),
            ),
            if (subtotal != null && subtotal >= 0) ...[
              const SizedBox(height: Space.sm),
              Text(
                '+ 10% tax = BD ${(subtotal * 1.10).toStringAsFixed(2)} total · '
                'due ${fmtDate(DateTime.now().add(const Duration(days: 30)))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: (_busy || !_valid) ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Raise invoice'),
            ),
          ],
        ),
      ),
    );
  }
}
