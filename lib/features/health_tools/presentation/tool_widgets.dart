import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';

/// A content-sized row: the scope badge never competes with a fixed title box.
class ToolEntryRow extends StatelessWidget {
  const ToolEntryRow({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.futureWork = true,
    super.key,
  });
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool futureWork;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: SurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            IconTile(icon: icon, accent: PatientAccent.blue),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (futureWork) ...[
                    const SizedBox(height: Space.xs),
                    FutureWorkBadge(label: t.paFutureWork),
                  ],
                  const SizedBox(height: Space.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: PatientPalette.of(context).textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> explainFutureTool(
  BuildContext context,
  String title,
  String body,
) {
  final t = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxWidth: 760,
      maxHeight: MediaQuery.sizeOf(context).height * .85,
    ),
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(sheet).textTheme.headlineSmall),
            const SizedBox(height: Space.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FutureWorkBadge(label: t.paFutureWork),
            ),
            const SizedBox(height: Space.md),
            Text(body),
            const SizedBox(height: Space.lg),
            SoftActionButton(
              label: t.paClose,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
