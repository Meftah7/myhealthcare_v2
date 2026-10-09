import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/utils/format.dart';
import '../../../data/repositories/admin_workspace.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import 'admin_workspace_screens.dart';

final adminPeopleAssignmentsProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(adminWorkspaceProvider);
  await service.authorize(Permission.manageCareTeams);
  final now = DateTime.now();
  return (service.db.select(service.db.careTeamAssignments)..where(
        (a) =>
            a.assignedAt.isSmallerOrEqualValue(now) &
            (a.endedAt.isNull() | a.endedAt.isBiggerThanValue(now)),
      ))
      .get();
});

final adminPersonProvider = FutureProvider.autoDispose.family((
  ref,
  String id,
) async {
  final service = ref.watch(adminWorkspaceProvider);
  await service.authorize(Permission.manageUsers);
  final db = service.db;
  final user = await ref.watch(userRepositoryProvider).byId(id);
  if (user.isErr) throw user.failureOrNull!;
  final profile = await (db.select(
    db.staffProfiles,
  )..where((s) => s.userId.equals(id))).getSingleOrNull();
  final department = profile?.departmentId == null
      ? null
      : await (db.select(
          db.departments,
        )..where((d) => d.id.equals(profile!.departmentId!))).getSingleOrNull();
  return (user: user.valueOrNull!, profile: profile, department: department);
});

final adminPersonSectionProvider = FutureProvider.autoDispose
    .family<List<String>, ({String id, String section})>((ref, key) async {
      final service = ref.watch(adminWorkspaceProvider);
      final db = service.db;
      await service.authorize(switch (key.section) {
        'bookings' => Permission.manageClinicSchedules,
        'finance' => Permission.manageBilling,
        _ => Permission.manageSettings,
      });
      if (key.section == 'bookings') {
        return [
          for (final a
              in await (db.select(db.appointments)..where(
                    (a) =>
                        a.patientId.equals(key.id) | a.staffId.equals(key.id),
                  ))
                  .get())
            '${a.id} · ${fmtDateTime(a.slotStart)} · ${a.status.name}',
        ];
      }
      if (key.section == 'finance') {
        return [
          for (final i in await (db.select(
            db.invoices,
          )..where((i) => i.patientId.equals(key.id))).get())
            '${i.id} · ${i.status.name} · BHD ${i.totalAmount.toStringAsFixed(3)}',
        ];
      }
      return [
        for (final d
            in await (db.select(db.documentRequests)..where(
                  (d) =>
                      d.patientId.equals(key.id) | d.requestedBy.equals(key.id),
                ))
                .get())
          '${d.id} · ${d.status}',
      ];
    });

class AdminPeopleProfileScreen extends ConsumerStatefulWidget {
  const AdminPeopleProfileScreen(this.id, {super.key});
  final String id;
  @override
  ConsumerState<AdminPeopleProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<AdminPeopleProfileScreen> {
  String section = 'account';
  @override
  Widget build(BuildContext c) => AppScaffold(
    title: adminText(c, 'Person profile', 'ملف الشخص'),
    children: [
      ref
          .watch(adminPersonProvider(widget.id))
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  p.user.fullName,
                  style: Theme.of(c).textTheme.headlineSmall,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (key, en, ar) in [
                      ('account', 'Account', 'الحساب'),
                      ('bookings', 'Bookings', 'الحجوزات'),
                      ('documents', 'Documents', 'المستندات'),
                      if (p.user.role == UserRole.patient)
                        ('finance', 'Finance', 'المالية'),
                    ])
                      ChoiceChip(
                        label: Text(adminText(c, en, ar)),
                        selected: section == key,
                        onSelected: (_) => setState(() => section = key),
                      ),
                  ],
                ),
                if (section == 'account')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(p.user.email),
                      Text(
                        '${p.user.role.name} · ${p.user.isActive ? adminText(c, 'Active', 'نشط') : adminText(c, 'Inactive', 'غير نشط')}',
                      ),
                      if (p.department != null) Text(p.department!.name),
                      if (p.profile != null)
                        Text(
                          '${p.profile!.jobTitle ?? ''} · ${p.profile!.presence?.name ?? ''}',
                        ),
                    ],
                  )
                else
                  ref
                      .watch(
                        adminPersonSectionProvider((
                          id: widget.id,
                          section: section,
                        )),
                      )
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('$e'),
                        data: (items) => Column(
                          children: [
                            if (items.isEmpty)
                              Text(
                                adminText(
                                  c,
                                  'No records in this section.',
                                  'لا توجد سجلات في هذا القسم',
                                ),
                              ),
                            for (final row in items) ListTile(title: Text(row)),
                          ],
                        ),
                      ),
                if (p.user.role == UserRole.patient && section == 'documents')
                  TextButton(
                    onPressed: () => c.push(
                      '/admin/profile/document-workspace?patientId=${Uri.encodeComponent(widget.id)}',
                    ),
                    child: Text(
                      adminText(
                        c,
                        'Open authorized document workspace',
                        'فتح مساحة المستندات المصرح بها',
                      ),
                    ),
                  ),
                if (p.user.role == UserRole.staff)
                  TextButton(
                    onPressed: () => c.push('/admin/clinic/schedules'),
                    child: Text(
                      adminText(
                        c,
                        'Preview bookings and arrange replacement',
                        'معاينة الحجوزات وتعيين البديل',
                      ),
                    ),
                  ),
              ],
            ),
          ),
    ],
  );
}
