/// Admin-profile section pages. The Profile screen lists the sections as rows;
/// tapping a row pushes the matching page with a back button in the top-left.
/// Mirrors the patient and staff `*_profile_pages.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../auth/application/session.dart';
import '../../settings/presentation/preferences_section.dart';

/// Shared shell: an app bar with an automatic back button, content capped at
/// the app's max width, scrollable.
class AdminSectionScaffold extends StatelessWidget {
  const AdminSectionScaffold({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gutter = WindowSize.of(context).gutter;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, Space.md, gutter, Space.xxl),
            children: [child],
          ),
        ),
      ),
    );
  }
}

/// Read-only account details for the signed-in administrator.
class AdminAccountPage extends ConsumerWidget {
  const AdminAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final user = ref.watch(currentUserProvider);

    return AdminSectionScaffold(
      title: t.account,
      child: user == null
          ? const SkeletonList()
          : AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _row('Name', user.fullName),
                  const Divider(height: 1, indent: Space.md),
                  _row('Email', user.email),
                  const Divider(height: 1, indent: Space.md),
                  _row('Role', t.roleAdmin),
                  if (user.phone != null) ...[
                    const Divider(height: 1, indent: Space.md),
                    _row('Phone', user.phone!),
                  ],
                  const Divider(height: 1, indent: Space.md),
                  _row(t.memberSince, fmtDate(user.createdAt)),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value) =>
      ListTile(dense: true, title: Text(label), subtitle: Text(value));
}

/// Device preferences — theme, text size, language, alerts, sounds.
class AdminPreferencesPage extends StatelessWidget {
  const AdminPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) => AdminSectionScaffold(
    title: AppStrings.of(context).preferences,
    child: const PreferencesSection(bare: true),
  );
}
