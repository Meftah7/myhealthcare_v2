/// The staff shell's five destinations — Home, Schedule, Patients, Chat,
/// Settings — for every staff role, and the sidebar that hosts them on wide
/// windows. Rendered by the same patient bar / rail / sidebar pattern as the
/// patient app (see `AppShell`), so both apps read as one product.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../app/shell/app_shell.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../auth/application/session.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import '../../workforce/workforce_repository.dart';
import '../../workspace/workspace_widgets.dart' show wlabel;
import '../application/staff_providers.dart';

/// Branch order of the staff shell — also the tab order.
abstract final class StaffTab {
  static const home = 0;
  static const schedule = 1;
  static const patients = 2;
  static const chat = 3;
  static const settings = 4;
}

/// The five staff destinations, in their fixed order. The labels are the same
/// for every role; each tab's content is what changes with the role.
List<AppDestination> staffDestinations(BuildContext context) => [
  AppDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: workText(context, 'Home', 'الرئيسية'),
  ),
  AppDestination(
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    label: workText(context, 'Schedule', 'الجدول'),
  ),
  AppDestination(
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    label: workText(context, 'Patients', 'المرضى'),
  ),
  AppDestination(
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
    label: workText(context, 'Chat', 'المحادثات'),
  ),
  AppDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: workText(context, 'Settings', 'الإعدادات'),
  ),
];

/// "Receptionist · Reception" — the signed-in staff member's role and
/// department, or null while the profile loads. The department name comes
/// from the workforce home read every staff Home already makes.
final staffRoleLineProvider = Provider<({String? role, String? department})?>((
  ref,
) {
  final profile = ref.watch(staffProfileProvider).valueOrNull;
  if (profile == null) return null;
  final home = ref.watch(workforceDataProvider('home')).valueOrNull;
  return (role: profile.jobTitle, department: home?['department'] as String?);
});

String staffRoleLabel(BuildContext context, String? jobTitle) =>
    StaffRole.parse(jobTitle) == null
    ? (jobTitle ?? '')
    : wlabel(context, StaffRole.parse(jobTitle)!.name);

/// The wide-window staff sidebar: the patient sidebar's surface and brand
/// lockup, the five destinations, and who is signed in.
class StaffSidebar extends ConsumerWidget {
  const StaffSidebar({required this.entries, super.key});

  final List<Widget> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final user = ref.watch(currentUserProvider);
    final line = ref.watch(staffRoleLineProvider);
    return Material(
      color: palette.card,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: Space.lg),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: AppBrandLockup(),
                  ),
                  ...entries,
                ],
              ),
            ),
            if (user != null) ...[
              Divider(height: 1, color: palette.divider),
              ListTile(
                minTileHeight: 64,
                leading: CircleAvatar(
                  backgroundColor: palette.softAccent,
                  foregroundColor: palette.onSoftAccent,
                  child: Text(
                    initialsOf(user.fullName),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(
                  user.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: line == null
                    ? null
                    : Text(
                        [
                          staffRoleLabel(context, line.role),
                          ?line.department,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String initialsOf(String name) => name
    .split(' ')
    .where((p) => p.isNotEmpty)
    .take(2)
    .map((p) => p[0].toUpperCase())
    .join();

/// A patient chart opened by link (or by Back history) is still role-gated:
/// staff without chart access see why, and a way back to their own Patients
/// tab — the repository refuses the read either way.
class StaffChartGate extends ConsumerWidget {
  const StaffChartGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(canProvider(Permission.readPatientChart))) return child;
    return AppScaffold(
      title: workText(context, 'Patients', 'المرضى'),
      children: [
        const SizedBox(height: Space.xl),
        EmptyState(
          icon: Icons.lock_outline,
          message: workText(
            context,
            'Your role does not include clinical chart access. Use the Patients tab for the work your role allows.',
            'لا يتضمن دورك الوصول إلى الملف السريري. استخدم تبويب المرضى للعمل المسموح لدورك.',
          ),
          actionLabel: workText(
            context,
            'Back to Patients',
            'العودة إلى المرضى',
          ),
          onAction: () => context.go(AppRoutes.staffPatients),
        ),
      ],
    );
  }
}
