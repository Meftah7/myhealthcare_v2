import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/documents/document_rules.dart';
import '../../../domain/identity/operational_roles.dart';
import '../../../domain/identity/permissions.dart';
import '../../../domain/repositories/document_policy_repository.dart';
import '../../../domain/repositories/document_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../auth/presentation/reauth_prompt.dart';
import 'admin_profile_pages.dart';

T _value<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

final documentPoliciesProvider = FutureProvider<List<DocumentPolicy>>((
  ref,
) async {
  ref.watch(currentUserProvider);
  return _value(await ref.watch(documentPolicyRepositoryProvider).forReview());
});
final policyManagementEnabledProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final grants = _value(
    await ref.watch(scopedGrantRepositoryProvider).forAccount(user.id),
  );
  final now = DateTime.now();
  return grants.any(
    (g) =>
        g.permission == Permission.manageDocumentTemplates &&
        g.scope == GrantScope.clinic &&
        g.scopeId.isEmpty &&
        g.revokedAt == null &&
        !g.startsAt.isAfter(now) &&
        (g.expiresAt == null || g.expiresAt!.isAfter(now)),
  );
});

class DocumentPoliciesScreen extends ConsumerStatefulWidget {
  const DocumentPoliciesScreen({super.key});
  @override
  ConsumerState<DocumentPoliciesScreen> createState() =>
      _DocumentPoliciesScreenState();
}

class _DocumentPoliciesScreenState
    extends ConsumerState<DocumentPoliciesScreen> {
  bool _busy = false;
  void _reload() {
    ref.invalidate(documentPoliciesProvider);
    ref.invalidate(policyManagementEnabledProvider);
  }

  Future<void> _enable() async {
    final t = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    final result = await runWithReauth(
      context,
      ref,
      () => ref
          .read(scopedGrantRepositoryProvider)
          .grant(
            accountId: user.id,
            permission: Permission.manageDocumentTemplates,
            scope: GrantScope.clinic,
            scopeId: '',
            reason: t.policyGrantReason,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeFailure(t, failure).message)),
      );
    } else {
      ref.invalidate(policyManagementEnabledProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final policies = ref.watch(documentPoliciesProvider);
    final enabled = ref.watch(policyManagementEnabledProvider);
    return AdminSectionScaffold(
      title: t.documentPoliciesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => context.push('/admin/profile/document-access'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: Text(
              t.localeName == 'ar'
                  ? 'صلاحيات الوثائق ونسخ المرضى'
                  : 'Document access and patient copies',
            ),
          ),
          const SizedBox(height: Space.md),
          Text(t.policyReviewIntro),
          const SizedBox(height: Space.md),
          enabled.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => ErrorStateView(
              message: describeFailure(t, error).message,
              onRetry: () => ref.invalidate(policyManagementEnabledProvider),
            ),
            data: (canManage) => canManage
                ? Text(t.policyManagementEnabled)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(t.policyEnableExplanation),
                      const SizedBox(height: Space.sm),
                      OutlinedButton(
                        onPressed: _busy ? null : _enable,
                        child: Text(t.policyEnableManagement),
                      ),
                    ],
                  ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: Text(t.reloadAction),
            ),
          ),
          policies.when(
            loading: () => const SkeletonList(),
            error: (error, _) => ErrorStateView(
              message: describeFailure(t, error).message,
              onRetry: _reload,
            ),
            data: (items) => items.isEmpty
                ? EmptyState(
                    icon: Icons.description_outlined,
                    message: t.policyNoPolicies,
                  )
                : Column(
                    children: [
                      for (final policy in items)
                        _PolicyEditor(
                          key: ValueKey(
                            '${policy.draft.id}/${policy.draft.wording}/${policy.approvedAt}/${policy.retiredAt}',
                          ),
                          policy: policy,
                          canManage: enabled.valueOrNull ?? false,
                          nextVersion:
                              1 +
                              items
                                  .where(
                                    (p) =>
                                        p.draft.document ==
                                            policy.draft.document &&
                                        p.draft.language ==
                                            policy.draft.language &&
                                        p.draft.disclosure ==
                                            policy.draft.disclosure,
                                  )
                                  .fold<int>(
                                    0,
                                    (max, p) => p.draft.version > max
                                        ? p.draft.version
                                        : max,
                                  ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PolicyEditor extends ConsumerStatefulWidget {
  const _PolicyEditor({
    required this.policy,
    required this.canManage,
    required this.nextVersion,
    super.key,
  });
  final DocumentPolicy policy;
  final bool canManage;
  final int nextVersion;
  @override
  ConsumerState<_PolicyEditor> createState() => _PolicyEditorState();
}

class _PolicyEditorState extends ConsumerState<_PolicyEditor> {
  late final _wording = TextEditingController(
    text: widget.policy.draft.wording,
  );
  bool _accepted = false, _busy = false;
  @override
  void dispose() {
    _wording.dispose();
    super.dispose();
  }

  DocumentPolicyDraft _draft({bool newVersion = false}) {
    final d = widget.policy.draft;
    return DocumentPolicyDraft(
      id: newVersion
          ? '${d.document.name}-v${widget.nextVersion}-${d.language}-${d.disclosure.name}'
          : d.id,
      document: d.document,
      version: newVersion ? widget.nextVersion : d.version,
      language: d.language,
      disclosure: d.disclosure,
      wording: _wording.text.trim(),
      clinicalSignatureRequired: d.clinicalSignatureRequired,
    );
  }

  Future<void> _save({bool newVersion = false, bool approve = false}) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final repo = ref.read(documentPolicyRepositoryProvider);
    final result = await runWithReauth(
      context,
      ref,
      () => approve
          ? repo.approve(
              widget.policy.draft.id,
              expectedDraft: widget.policy.draft,
            )
          : repo.saveDraft(
              _draft(newVersion: newVersion),
              expectedWording: newVersion ? null : widget.policy.draft.wording,
              createOnly: newVersion,
            ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => approve ? t.policyApproved : t.policyDraftSaved,
          Err(:final failure) => describeFailure(t, failure).message,
        }),
      ),
    );
    if (result.isOk) ref.invalidate(documentPoliciesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final policy = widget.policy;
    final draft = policy.draft;
    final approved = policy.approvedAt != null;
    final dirty = _wording.text.trim() != draft.wording;
    final canAct = widget.canManage && !_busy;
    final disclosure = switch (draft.disclosure) {
      DisclosureProfile.clinic => t.policyClinicCopy,
      DisclosureProfile.employer => t.policyEmployerCopy,
      DisclosureProfile.school => t.policySchoolCopy,
    };
    return ExpansionTile(
      key: PageStorageKey('policy-${draft.id}'),
      tilePadding: EdgeInsets.zero,
      title: Text(
        '${DocumentRules.title(draft.document, arabic: Localizations.localeOf(context).languageCode == 'ar')} · $disclosure · ${draft.language == 'ar' ? t.languageArabic : t.languageEnglish} · v${draft.version}',
      ),
      subtitle: Text(
        policy.retiredAt != null
            ? t.policyRetired
            : approved
            ? t.policyApproved
            : t.policyDraft,
      ),
      childrenPadding: const EdgeInsets.only(bottom: Space.lg),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              draft.clinicalSignatureRequired
                  ? t.policySigningRule
                  : Localizations.localeOf(context).languageCode == 'ar'
                  ? 'الإصدار الإداري يتطلب صلاحية إصدار مستقلة. تتطلب الكشوف المالية صلاحية إدارة الفوترة أيضاً.'
                  : 'Administrative issuance requires a separate issue grant. Finance statements also require billing-management authority.',
            ),
            const SizedBox(height: Space.sm),
            Text(
              draft.disclosure == DisclosureProfile.clinic
                  ? t.policyClinicDisclosure
                  : t.policyExternalDisclosure,
            ),
            const SizedBox(height: Space.md),
            Text(t.policyWordingHint),
            const SizedBox(height: Space.sm),
            TextField(
              key: PageStorageKey('policy-wording-${draft.id}'),
              controller: _wording,
              readOnly: approved || !widget.canManage || _busy,
              textDirection: draft.language == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              minLines: 5,
              maxLines: null,
              decoration: InputDecoration(labelText: t.policyWording),
              onChanged: (_) => setState(() => _accepted = false),
            ),
            if (approved)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                child: Text(
                  '${policy.approvedByName ?? ''} · ${fmtDateTime(policy.approvedAt!)}',
                ),
              ),
            if (!approved && policy.retiredAt == null) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.policyAcceptance),
                value: _accepted,
                onChanged: canAct && !dirty
                    ? (value) => setState(() => _accepted = value ?? false)
                    : null,
              ),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  OutlinedButton(
                    onPressed:
                        canAct && dirty && _wording.text.trim().isNotEmpty
                        ? _save
                        : null,
                    child: Text(t.policySaveDraft),
                  ),
                  FilledButton(
                    onPressed: canAct && !dirty && _accepted
                        ? () => _save(approve: true)
                        : null,
                    child: Text(t.policyApproveVersion),
                  ),
                ],
              ),
            ] else
              OutlinedButton(
                onPressed: canAct ? () => _save(newVersion: true) : null,
                child: Text(t.policyCreateVersion),
              ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ],
    );
  }
}
