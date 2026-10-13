import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/admin_workspace.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../../domain/repositories/scoped_grant_repository.dart';
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
            '${fmtDateTime(a.slotStart)} · ${a.status.name}',
        ];
      }
      if (key.section == 'finance') {
        return [
          for (final i in await (db.select(
            db.invoices,
          )..where((i) => i.patientId.equals(key.id))).get())
            '${fmtDate(i.issuedAt)} · ${fmtBhd(i.totalAmount)} · ${i.status.name}',
        ];
      }
      return [
        for (final d
            in await (db.select(db.documentRequests)..where(
                  (d) =>
                      d.patientId.equals(key.id) | d.requestedBy.equals(key.id),
                ))
                .get())
          '${fmtDate(d.createdAt)} · ${d.status}',
      ];
    });

/// Credentials, scoped permissions and temporary cover for one account.
final adminPersonAccessProvider = FutureProvider.autoDispose.family((
  ref,
  String id,
) async {
  final service = ref.watch(adminWorkspaceProvider);
  await service.authorize(Permission.manageUsers);
  final db = service.db;
  final now = DateTime.now();
  final credentials = await (db.select(
    db.staffCredentials,
  )..where((c) => c.staffId.equals(id))).get();
  final grants =
      (await ref.watch(scopedGrantRepositoryProvider).forAccount(id))
          .valueOrNull ??
      const <ScopedGrant>[];
  final cover =
      await (db.select(db.careTeamAssignments)..where(
            (a) =>
                a.staffId.equals(id) &
                a.assignedAt.isSmallerOrEqualValue(now) &
                (a.endedAt.isNull() | a.endedAt.isBiggerThanValue(now)),
          ))
          .get();
  final covering =
      await (db.select(db.staffTasks)..where(
            (t) =>
                t.coverageStaffId.equals(id) &
                t.status.isNotInValues([TaskStatus.done, TaskStatus.dismissed]),
          ))
          .get();
  return (
    credentials: credentials,
    grants: grants,
    cover: cover,
    covering: covering,
  );
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
                  _AccessSections(person: p, id: widget.id)
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

/// Identity, role & assignment, clinical credentials, scoped permissions and
/// temporary cover, each in its own card.
class _AccessSections extends ConsumerWidget {
  const _AccessSections({required this.person, required this.id});

  final ({User user, StaffProfileRow? profile, DepartmentRow? department})
  person;
  final String id;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final u = person.user;
    final profile = person.profile;
    final role = StaffRole.parse(profile?.jobTitle);
    final access = u.role == UserRole.staff
        ? ref.watch(adminPersonAccessProvider(id))
        : null;
    Widget card(String en, String ar, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(adminText(c, en, ar), style: Theme.of(c).textTheme.titleSmall),
            const SizedBox(height: Space.xs),
            ...children,
          ],
        ),
      ),
    );
    String date(DateTime? d) => d == null ? '—' : fmtDate(d);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card('Identity', 'الهوية', [
          Text(u.email),
          Text(
            '${u.role.name} · ${u.isActive ? adminText(c, 'Active', 'نشط') : adminText(c, 'Inactive', 'غير نشط')}',
          ),
        ]),
        if (u.role == UserRole.staff) ...[
          card('Role & assignment', 'الدور والتعيين', [
            Text(
              role == null
                  ? adminText(
                      c,
                      'Role not set — no clinical or desk permissions.',
                      'الدور غير محدد — لا توجد صلاحيات سريرية أو استقبال.',
                    )
                  : role.jobTitle,
            ),
            Text(
              '${adminText(c, 'Department', 'القسم')}: ${person.department?.name ?? '—'}',
            ),
            if (profile?.specialty != null) Text(profile!.specialty!),
            Text(
              '${adminText(c, 'Availability (local preference)', 'التوفر (تفضيل محلي)')}: ${profile?.presence?.name ?? '—'}',
            ),
          ]),
          ...?access?.when(
            loading: () => const [LinearProgressIndicator()],
            error: (e, _) => [
              Text(
                adminText(
                  c,
                  'Could not load access details.',
                  'تعذّر تحميل تفاصيل الصلاحيات.',
                ),
              ),
            ],
            data: (a) => [
              card('Clinical credentials', 'الاعتمادات السريرية', [
                if (a.credentials.isEmpty)
                  Text(adminText(c, 'None recorded.', 'لا يوجد.')),
                for (final cr in a.credentials)
                  Text(
                    '${cr.kind.name} · ${cr.identifier} · '
                    '${cr.revokedAt != null
                        ? adminText(c, 'revoked', 'ملغى')
                        : cr.verifiedAt == null
                        ? adminText(c, 'not verified', 'غير موثق')
                        : adminText(c, 'verified', 'موثق')} · '
                    '${adminText(c, 'valid until', 'صالح حتى')} ${date(cr.validUntil)}',
                  ),
              ]),
              card('Scoped permissions', 'الصلاحيات المحددة', [
                if (a.grants.isEmpty)
                  Text(
                    adminText(
                      c,
                      'Role permissions only; no extra grants.',
                      'صلاحيات الدور فقط؛ لا توجد صلاحيات إضافية.',
                    ),
                  ),
                for (final g in a.grants)
                  Text(
                    '${g.permission.name} · ${g.scope.name} · '
                    '${g.revokedAt != null ? adminText(c, 'revoked', 'ملغاة') : '${adminText(c, 'until', 'حتى')} ${date(g.expiresAt)}'}',
                  ),
                TextButton(
                  onPressed: () => c.push('/admin/profile/document-access'),
                  child: Text(adminText(c, 'Manage access', 'إدارة الصلاحيات')),
                ),
              ]),
              card('Temporary cover', 'التغطية المؤقتة', [
                if (a.cover.isEmpty && a.covering.isEmpty)
                  Text(adminText(c, 'No active cover.', 'لا توجد تغطية نشطة.')),
                for (final x in a.cover)
                  Text(
                    '${x.role.name} · ${adminText(c, 'ends', 'تنتهي')} ${date(x.endedAt)}',
                  ),
                if (a.covering.isNotEmpty)
                  Text(
                    adminText(
                      c,
                      'Covering ${a.covering.length} open task(s) for colleagues.',
                      'يغطي ${a.covering.length} مهمة مفتوحة لزملاء.',
                    ),
                  ),
              ]),
            ],
          ),
        ],
      ],
    );
  }
}
