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
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../service_catalog/application/catalog_dispatcher.dart';
import '../../service_catalog/domain/patient_catalog.dart';

class PatientDrawer extends ConsumerWidget {
  const PatientDrawer({super.key});

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
      Navigator.of(context).pop();
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
        title: Text(label, style: theme.textTheme.bodyLarge),
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

    return Drawer(
      backgroundColor: palette.card,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.lg),
          children: [
            const _DrawerHeader(),
            Divider(color: palette.divider),
            section(t.paDrawerAccount),
            row(
              key: const ValueKey('drawer-profile'),
              icon: Icons.account_circle_outlined,
              label: t.paMyProfile,
              onTap: () => go(AppRoutes.patientSettings),
            ),
            row(
              key: const ValueKey('drawer-personal'),
              icon: Icons.badge_outlined,
              label: t.paPersonalInformation,
              onTap: () => go(AppRoutes.patientProfilePersonal),
            ),
            row(
              key: const ValueKey('drawer-health'),
              icon: Icons.favorite_outline,
              label: t.healthDetailsTitle,
              onTap: () => go(AppRoutes.patientProfileHealth),
            ),
            row(
              key: const ValueKey('drawer-preferences'),
              icon: Icons.tune,
              label: t.paSettingsPreferences,
              onTap: () => go(AppRoutes.patientProfilePreferences),
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
                  applicationName: 'MyHealth Care',
                  applicationLegalese: t.paAboutBody,
                ),
              ),
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
      ),
    );
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
