import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';

/// The selected environment has departments, not a physical facility directory.
/// Do not turn departments/branding into invented hospitals or distances.
/// Reuse the existing department → clinician → booking path as the fallback.
Future<void> showSelectHospitalSheet(BuildContext context) async {
  final t = AppLocalizations.of(context)!;
  final browseClinic = await showModalBottomSheet<bool>(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.htSelectHospital,
                    style: Theme.of(sheet).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  key: const ValueKey('hospital-close'),
                  autofocus: true,
                  tooltip: t.paClose,
                  onPressed: () => Navigator.of(sheet).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: t.htSearchHospital,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(t.htSearchUnavailable),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                Chip(label: Text(t.htAllFacilities)),
                Chip(label: Text(t.htConfiguredFacilities)),
              ],
            ),
            const SizedBox(height: Space.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FutureWorkBadge(label: t.paFutureWork),
            ),
            const SizedBox(height: Space.md),
            Text(t.htNoHospitals),
            const SizedBox(height: Space.lg),
            PrimaryActionButton(
              key: const ValueKey('hospital-browse-clinic'),
              label: t.htUseClinic,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
  if (browseClinic == true && context.mounted) {
    await context.push(AppRoutes.patientFindClinic);
  }
}
