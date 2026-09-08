/// Staff-profile section pages. The Profile screen lists the sections as rows;
/// tapping a row pushes the matching page (with a back button in the top-left
/// that returns to the same Profile screen). Mirrors the patient app's
/// `profile_section_pages.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../settings/presentation/preferences_section.dart';
import '../application/staff_providers.dart';

/// Shared shell: an app bar with an automatic back button, content capped at
/// the app's max width, scrollable.
class StaffSectionScaffold extends StatelessWidget {
  const StaffSectionScaffold({
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

/// Read-only account details — maintained by an administrator.
class StaffAccountPage extends ConsumerWidget {
  const StaffAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(staffProfileProvider);

    return StaffSectionScaffold(
      title: t.account,
      child: profile.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your profile.',
          onRetry: () => ref.invalidate(staffProfileProvider),
        ),
        data: (s) {
          final u = s.user;
          final deptName = ref.watch(departmentNameProvider(s.departmentId));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _row(t.specialty, s.specialty ?? t.none),
                    const Divider(height: 1, indent: Space.md),
                    _row(t.jobTitle, s.jobTitle ?? t.none),
                    const Divider(height: 1, indent: Space.md),
                    _row(t.licenseNo, s.licenseNo ?? t.none),
                    const Divider(height: 1, indent: Space.md),
                    _row(
                      t.department,
                      deptName.maybeWhen(
                        data: (n) => n ?? t.none,
                        orElse: () => '…',
                      ),
                    ),
                    const Divider(height: 1, indent: Space.md),
                    _row(t.memberSince, fmtDate(u.createdAt)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xs,
                  Space.sm,
                  Space.xs,
                  0,
                ),
                child: Text(
                  t.managedByAdmin,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) =>
      ListTile(dense: true, title: Text(label), subtitle: Text(value));
}

/// Device preferences — theme, text size, language, alert channels.
class StaffPreferencesPage extends StatelessWidget {
  const StaffPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) => StaffSectionScaffold(
    title: AppStrings.of(context).preferences,
    child: const PreferencesSection(bare: true),
  );
}
