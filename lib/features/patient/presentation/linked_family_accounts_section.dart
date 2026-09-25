/// Linked family accounts: request/accept/decline, the accepted list with a
/// permission badge, and who currently has access to me.
///
/// Sits above the record-only "Family members" list in Family Network —
/// those are text records for people without their own login; these are
/// real accounts, gated by the other side's consent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/family_link_providers.dart';

class LinkedFamilyAccountsSection extends ConsumerWidget {
  const LinkedFamilyAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final incoming = ref.watch(incomingFamilyRequestsProvider).valueOrNull ?? const [];
    final outgoing = ref.watch(outgoingFamilyRequestsProvider).valueOrNull ?? const [];
    final linked = ref.watch(linkedAccountsProvider);
    final viewers = ref.watch(viewersOfMeProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _Label(t.linkedAccountsTitle)),
            TextButton.icon(
              onPressed: () => _openLinkSheet(context, ref),
              icon: const Icon(Icons.link, size: 18),
              label: Text(t.linkAccountAction),
            ),
          ],
        ),

        if (incoming.isNotEmpty) ...[
          _Label(t.pendingRequestsTitle),
          for (final v in incoming) _IncomingRequestCard(view: v),
          const SizedBox(height: Space.sm),
        ],

        linked.when(
          loading: () => const LoadingSkeleton(height: 56),
          error: (e, _) => InlineBanner.error(t.couldNotLoadFamilyMembers),
          data: (items) {
            if (items.isEmpty && incoming.isEmpty && outgoing.isEmpty) {
              return Text(
                t.noLinkedAccountsYet,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: [for (final v in items) _LinkedAccountTile(view: v)],
            );
          },
        ),

        if (outgoing.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          _Label(t.sentRequestsTitle),
          for (final v in outgoing) _OutgoingRequestTile(view: v),
        ],

        if (viewers.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          _Label(t.viewersOfMeTitle),
          for (final v in viewers) _ViewerTile(view: v),
        ],

        const SizedBox(height: Space.md),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _openLinkSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: const _LinkAccountSheet(),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs, top: Space.xs),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  const _PermissionBadge(this.permission);
  final FamilyLinkPermission permission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final manage = permission == FamilyLinkPermission.manage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: manage ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: Radii.pill,
      ),
      child: Text(
        permission.label(context),
        style: theme.textTheme.labelSmall?.copyWith(
          color: manage ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: scheme.secondaryContainer,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _IncomingRequestCard extends ConsumerWidget {
  const _IncomingRequestCard({required this.view});
  final FamilyLinkView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: AppCard(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(view.counterpart.fullName),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    view.counterpart.fullName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _PermissionBadge(view.link.permission),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(
              t.requestsAccessNote(view.counterpart.fullName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await ref
                          .read(familyLinkControllerProvider)
                          .decline(view.link.id);
                      if (context.mounted && result.isErr) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.failureOrNull!.message)),
                        );
                      }
                    },
                    child: Text(t.declineButton),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final result = await ref
                          .read(familyLinkControllerProvider)
                          .accept(view.link.id);
                      if (context.mounted && result.isErr) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.failureOrNull!.message)),
                        );
                      }
                    },
                    child: Text(t.acceptButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedAccountTile extends ConsumerWidget {
  const _LinkedAccountTile({required this.view});
  final FamilyLinkView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Avatar(view.counterpart.fullName),
        title: Row(
          children: [
            Flexible(
              child: Text(
                view.counterpart.fullName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Space.xs),
            _PermissionBadge(view.link.permission),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => context.push(
                AppRoutes.linkedAccount(view.link.ownerPatientId),
              ),
              child: Text(t.viewAccountAction),
            ),
            IconButton(
              icon: const Icon(Icons.link_off),
              tooltip: t.unlinkAction,
              onPressed: () => _unlink(context, ref, view),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    FamilyLinkView view,
  ) async {
    final t = AppLocalizations.of(context)!;
    final ok = await confirm(
      context,
      title: t.unlinkAccountTitle(view.counterpart.fullName),
      message: t.unlinkAccountNote,
      confirmLabel: t.unlinkAction,
      destructive: true,
    );
    if (!ok) return;
    final result = await ref
        .read(familyLinkControllerProvider)
        .unlink(view.link.id);
    if (context.mounted && result.isErr) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.message)));
    }
  }
}

class _OutgoingRequestTile extends ConsumerWidget {
  const _OutgoingRequestTile({required this.view});
  final FamilyLinkView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Avatar(view.counterpart.fullName),
        title: Text(view.counterpart.fullName),
        subtitle: Text(
          t.waitingForAcceptanceNote(view.counterpart.fullName),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: TextButton(
          onPressed: () async {
            final result = await ref
                .read(familyLinkControllerProvider)
                .decline(view.link.id);
            if (context.mounted && result.isErr) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.message)));
            }
          },
          child: Text(t.declineButton),
        ),
      ),
    );
  }
}

class _ViewerTile extends ConsumerWidget {
  const _ViewerTile({required this.view});
  final FamilyLinkView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Avatar(view.counterpart.fullName),
        title: Row(
          children: [
            Flexible(
              child: Text(
                view.counterpart.fullName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Space.xs),
            _PermissionBadge(view.link.permission),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.link_off),
          tooltip: t.unlinkAction,
          onPressed: () async {
            final ok = await confirm(
              context,
              title: t.unlinkAccountTitle(view.counterpart.fullName),
              message: t.revokeAccessNote(view.counterpart.fullName),
              confirmLabel: t.unlinkAction,
              destructive: true,
            );
            if (!ok) return;
            final result = await ref
                .read(familyLinkControllerProvider)
                .unlink(view.link.id);
            if (context.mounted && result.isErr) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.message)));
            }
          },
        ),
      ),
    );
  }
}

class _LinkAccountSheet extends ConsumerStatefulWidget {
  const _LinkAccountSheet();

  @override
  ConsumerState<_LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends ConsumerState<_LinkAccountSheet> {
  final _query = TextEditingController();
  Patient? _selected;
  FamilyLinkPermission _permission = FamilyLinkPermission.viewOnly;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final target = _selected;
    if (target == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final t = AppLocalizations.of(context)!;
    final result = await ref
        .read(familyLinkControllerProvider)
        .request(ownerPatientId: target.id, permission: _permission);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.requestSentMessage)));
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
    final results = ref.watch(familyLinkSearchResultsProvider);

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.linkAccountSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            Text(
              t.linkAccountSearchHelper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _query,
              decoration: InputDecoration(
                labelText: t.linkAccountSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) {
                setState(() => _selected = null);
                ref.read(familyLinkSearchQueryProvider.notifier).state = v;
              },
            ),
            const SizedBox(height: Space.sm),
            if (_selected == null)
              results.when(
                loading: () => const LoadingSkeleton(height: 48),
                error: (e, _) => const SizedBox.shrink(),
                data: (list) {
                  if (_query.text.trim().length < 2) {
                    return const SizedBox.shrink();
                  }
                  if (list.isEmpty) {
                    return Text(
                      t.noAccountsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _Avatar(p.fullName),
                          title: Text(p.fullName),
                          subtitle: p.user.phone == null
                              ? null
                              : Text(p.user.phone!),
                          onTap: () => setState(() => _selected = p),
                        ),
                    ],
                  );
                },
              )
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _Avatar(_selected!.fullName),
                title: Text(_selected!.fullName),
                trailing: TextButton(
                  onPressed: () => setState(() => _selected = null),
                  child: Text(t.editAction),
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                t.permissionQuestionLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.xs),
              for (final p in FamilyLinkPermission.values)
                _PermissionOption(
                  permission: p,
                  selected: _permission == p,
                  onTap: () => setState(() => _permission = p),
                ),
            ],
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
                onPressed: (_selected != null && !_busy) ? _send : null,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.sendRequestButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionOption extends StatelessWidget {
  const _PermissionOption({
    required this.permission,
    required this.selected,
    required this.onTap,
  });

  final FamilyLinkPermission permission;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: selected ? scheme.secondaryContainer : scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardSmall,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: Space.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.label(context),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        permission.description(context),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
