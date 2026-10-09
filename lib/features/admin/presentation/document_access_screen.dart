import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/operational_roles.dart';
import '../../../domain/identity/permissions.dart';
import '../../../domain/repositories/scoped_grant_repository.dart';
import '../../auth/application/session.dart';
import '../../auth/presentation/reauth_prompt.dart';
import 'admin_profile_pages.dart';

T _value<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

final _accountsProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  ref.watch(currentUserProvider);
  final repo = ref.watch(userRepositoryProvider);
  return [
    ..._value(await repo.byRole(UserRole.staff)),
    ..._value(await repo.byRole(UserRole.admin)),
  ];
});
final _grantsProvider = FutureProvider.autoDispose
    .family<List<ScopedGrant>, String>((ref, id) async {
      ref.watch(currentUserProvider);
      return _value(
        await ref.watch(scopedGrantRepositoryProvider).forAccount(id),
      );
    });

class DocumentAccessScreen extends ConsumerStatefulWidget {
  const DocumentAccessScreen({super.key});
  @override
  ConsumerState<DocumentAccessScreen> createState() =>
      _DocumentAccessScreenState();
}

class _DocumentAccessScreenState extends ConsumerState<DocumentAccessScreen> {
  String? _account;
  Permission _permission = Permission.prepareDocument;
  GrantScope _scope = GrantScope.patient;
  final _scopeId = TextEditingController();
  final _reason = TextEditingController();
  final _patient = TextEditingController();
  bool _busy = false;
  String? _error;
  String s(String en, String ar) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  String permission(Permission p) => switch (p) {
    Permission.prepareDocument => s('Prepare requests', 'إعداد الطلبات'),
    Permission.issueAdministrativeDocument => s(
      'Issue administrative documents',
      'إصدار الوثائق الإدارية',
    ),
    Permission.signClinicalDocument => s(
      'Sign clinical documents',
      'توقيع الوثائق الطبية',
    ),
    Permission.reprintApprovedDocument => s(
      'Reprint approved external copies',
      'إعادة طباعة النسخ الخارجية المعتمدة',
    ),
    Permission.revokeDocument => s('Revoke documents', 'إلغاء الوثائق'),
    _ => p.name,
  };
  @override
  void dispose() {
    _scopeId.dispose();
    _reason.dispose();
    _patient.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Result<Object?>> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await runWithReauth(context, ref, action);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.failureOrNull?.message;
    });
    if (result.isOk && _account != null) {
      ref.invalidate(_grantsProvider(_account!));
    }
  }

  @override
  Widget build(BuildContext context) => AdminSectionScaffold(
    title: s('Document access', 'صلاحيات الوثائق'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s(
            'Assign only the required patient or department scope. A signing grant still requires a verified current medical licence, doctor profile and care relationship. No grant approves a policy.',
            'امنح نطاق المريض أو القسم المطلوب فقط. يتطلب التوقيع أيضاً ترخيصاً طبياً سارياً تم التحقق منه وملف طبيب وعلاقة رعاية. منح الصلاحية لا يعتمد السياسة.',
          ),
        ),
        const SizedBox(height: Space.md),
        ref
            .watch(_accountsProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => TextButton(
                onPressed: () => ref.invalidate(_accountsProvider),
                child: Text(s('Retry account list', 'إعادة تحميل الحسابات')),
              ),
              data: (accounts) => DropdownButtonFormField<String>(
                initialValue: _account,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s('Staff or administrator', 'الموظف أو المسؤول'),
                ),
                items: [
                  for (final a in accounts)
                    if (a.isActive)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.fullName} · ${a.id}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: _busy ? null : (id) => setState(() => _account = id),
              ),
            ),
        const SizedBox(height: Space.md),
        DropdownButtonFormField<Permission>(
          initialValue: _permission,
          isExpanded: true,
          decoration: InputDecoration(labelText: s('Permission', 'الصلاحية')),
          items: [
            for (final p in [
              Permission.prepareDocument,
              Permission.issueAdministrativeDocument,
              Permission.signClinicalDocument,
              Permission.reprintApprovedDocument,
              Permission.revokeDocument,
            ])
              DropdownMenuItem(
                value: p,
                child: Text(permission(p), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _busy ? null : (p) => setState(() => _permission = p!),
        ),
        const SizedBox(height: Space.md),
        DropdownButtonFormField<GrantScope>(
          initialValue: _scope,
          isExpanded: true,
          decoration: InputDecoration(labelText: s('Scope', 'النطاق')),
          items: [
            DropdownMenuItem(
              value: GrantScope.patient,
              child: Text(s('One patient', 'مريض واحد')),
            ),
            DropdownMenuItem(
              value: GrantScope.department,
              child: Text(s('One department', 'قسم واحد')),
            ),
            DropdownMenuItem(
              value: GrantScope.clinic,
              child: Text(s('Whole clinic', 'العيادة كاملة')),
            ),
          ],
          onChanged: _busy ? null : (p) => setState(() => _scope = p!),
        ),
        if (_scope != GrantScope.clinic) ...[
          const SizedBox(height: Space.md),
          TextField(
            controller: _scopeId,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: _scope == GrantScope.patient
                  ? s('Patient ID', 'معرف المريض')
                  : s('Department ID', 'معرف القسم'),
            ),
          ),
        ],
        const SizedBox(height: Space.md),
        TextField(
          controller: _reason,
          enabled: !_busy,
          maxLength: 300,
          decoration: InputDecoration(
            labelText: s(
              'Reason for grant or revocation',
              'سبب منح الصلاحية أو إلغائها',
            ),
          ),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: _busy || _account == null
              ? null
              : () => _run(
                  () => ref
                      .read(scopedGrantRepositoryProvider)
                      .grant(
                        accountId: _account!,
                        permission: _permission,
                        scope: _scope,
                        scopeId: _scope == GrantScope.clinic
                            ? ''
                            : _scopeId.text.trim(),
                        reason: _reason.text.trim(),
                      ),
                ),
          child: Text(s('Grant access', 'منح الصلاحية')),
        ),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: Space.lg),
        if (_account != null)
          ref
              .watch(_grantsProvider(_account!))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) =>
                    Text(s('Could not load grants.', 'تعذر تحميل الصلاحيات.')),
                data: (grants) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final g in grants.where(
                      (g) => [
                        Permission.prepareDocument,
                        Permission.issueAdministrativeDocument,
                        Permission.signClinicalDocument,
                        Permission.reprintApprovedDocument,
                        Permission.revokeDocument,
                      ].contains(g.permission),
                    )) ...[
                      const Divider(),
                      Text(
                        '${permission(g.permission)} · ${g.scope.name} ${g.scopeId}',
                      ),
                      if (g.revokedAt != null)
                        Text(s('Revoked', 'ملغاة'))
                      else
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => ref
                                      .read(scopedGrantRepositoryProvider)
                                      .revoke(
                                        g.id,
                                        reason: _reason.text.trim(),
                                      ),
                                ),
                          child: Text(
                            s('Revoke this grant', 'إلغاء هذه الصلاحية'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
        const Divider(height: 48),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(
                  () => Result.guardAsync<void>(() async {
                    final bytes = _value(
                      await ref
                          .read(documentServiceProvider)
                          .exportVerificationManifest(),
                    );
                    await FilePicker.saveFile(
                      fileName: 'document-verification-manifest.json',
                      bytes: bytes,
                      mimeType: 'application/json',
                    );
                  }),
                ),
          child: Text(
            s(
              'Export minimal verification registry',
              'تصدير سجل التحقق بالحد الأدنى من البيانات',
            ),
          ),
        ),
        Text(
          s('Open a patient’s document workspace', 'فتح مساحة وثائق المريض'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Space.md),
        TextField(
          controller: _patient,
          decoration: InputDecoration(
            labelText: s('Patient ID', 'معرف المريض'),
          ),
        ),
        const SizedBox(height: Space.sm),
        OutlinedButton(
          onPressed: () async {
            if (_patient.text.trim().isNotEmpty) {
              await context.push<void>(
                '/admin/profile/document-workspace?patientId=${Uri.encodeQueryComponent(_patient.text.trim())}',
              );
            }
          },
          child: Text(s('Open documents', 'فتح الوثائق')),
        ),
      ],
    ),
  );
}
