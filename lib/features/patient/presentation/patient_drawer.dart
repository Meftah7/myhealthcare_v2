/// The patient shell's native navigation drawer: account header → Account &
/// preferences → Supplementary account tools (Future work scope) → About &
/// support → Sign out. Holds the infrequent account actions that left the
/// bottom navigation and Home; every row opens the existing screen or sheet.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../service_catalog/application/catalog_dispatcher.dart';
import '../../service_catalog/domain/patient_catalog.dart';
import 'patient_account_action.dart';

class PatientDrawer extends ConsumerWidget {
  const PatientDrawer({this.primaryEntries, super.key});

  /// Present the same account actions inline on expanded patient windows.
  final List<Widget>? primaryEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    // Captured up front: the drawer subtree unmounts once it finishes
    // closing, so later steps must not reach back through its context/ref.
    final router = GoRouter.of(context);
    final session = ref.read(sessionProvider.notifier);

    /// Close the drawer first, then act — so back behaviour and focus land
    /// on the destination, not on a closing drawer.
    void close(VoidCallback then) {
      if (primaryEntries == null) Navigator.of(context).pop();
      then();
    }

    Widget section(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(28, Space.md, 28, Space.xs),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: palette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    Widget row({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool futureWork = false,
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      child: ListTile(
        key: key,
        minTileHeight: 52,
        leading: Icon(icon, color: palette.link),
        title: ReadableLabel(label, style: theme.textTheme.bodyLarge),
        // The scope label is visible text, not just a tooltip.
        subtitle: futureWork
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: FutureWorkBadge(label: t.paFutureWork),
              )
            : null,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        onTap: onTap,
      ),
    );

    void go(String route) => close(() => router.go(route));

    final content = SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.lg),
        children: [
          if (primaryEntries == null) const _DrawerHeader(),
          if (primaryEntries != null) ...[
            const Padding(
              padding: EdgeInsets.all(Space.lg),
              child: AppBrandLockup(),
            ),
            ...primaryEntries!,
          ],
          Divider(color: palette.divider),
          section(t.paDrawerAccount),
          for (final action in PatientAccountAction.values)
            row(
              key: ValueKey('drawer-${action.name}'),
              icon: action.icon,
              label: action.title(t),
              onTap: () => go(action.route),
            ),
          section(t.paDrawerSupplementary),
          for (final item in PatientCatalog.drawerTools)
            row(
              key: ValueKey('drawer-${item.id}'),
              icon: item.icon,
              label: item.title(t),
              futureWork: item.isFutureWork,
              onTap: () => close(() => openCatalogItem(context, ref, item)),
            ),
          section(t.paDrawerAbout),
          row(
            key: const ValueKey('drawer-about'),
            icon: Icons.info_outline,
            label: t.paAboutMyHealth,
            onTap: () => close(
              () => showAboutDialog(
                context: context,
                applicationName: 'myhealth',
                applicationLegalese: t.paAboutBody,
              ),
            ),
          ),
          row(
            key: const ValueKey('drawer-terms'),
            icon: Icons.gavel_outlined,
            label: t.paTerms,
            onTap: () => close(() => router.push(AppRoutes.policyTerms)),
          ),
          row(
            key: const ValueKey('drawer-privacy'),
            icon: Icons.privacy_tip_outlined,
            label: t.paPrivacy,
            onTap: () => close(() => router.push(AppRoutes.policyPrivacy)),
          ),
          const SizedBox(height: Space.sm),
          Divider(color: palette.divider),
          row(
            key: const ValueKey('drawer-sign-out'),
            icon: Icons.logout,
            label: t.signOut,
            onTap: () => close(() async {
              final ok = await confirm(
                context,
                title: t.signOutConfirmTitle,
                message: t.signOutConfirmBody,
                confirmLabel: t.signOut,
                destructive: true,
              );
              if (ok) unawaited(session.logout());
            }),
          ),
        ],
      ),
    );
    return primaryEntries == null
        ? Drawer(backgroundColor: palette.card, child: content)
        : Material(color: palette.card, child: content);
  }
}

/// The signed-in identity, with fallbacks for an empty name.
class _DrawerHeader extends ConsumerWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final user = ref.watch(currentUserProvider);
    final name = (user?.fullName ?? '').trim().isEmpty
        ? t.greetingFallbackName
        : user!.fullName.trim();
    final initials = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p.characters.first.toUpperCase())
        .join();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, Space.lg, 28, Space.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: palette.softAccent,
            foregroundColor: palette.onSoftAccent,
            child: initials.isEmpty
                ? const Icon(Icons.person_outline)
                : Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                if ((user?.email ?? '').isNotEmpty)
                  Text(
                    user!.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
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
