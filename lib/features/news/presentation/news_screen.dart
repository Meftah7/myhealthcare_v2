/// News tab. There is no news repository or CMS in this build, so the tab
/// shows a meaningful empty state rather than placeholder articles. Clinical
/// features never depend on it.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PatientPageScaffold(
      header: PatientPageTitle(t.paNews),
      children: [
        const SizedBox(height: Space.md),
        PatientStateView(
          kind: PatientStateKind.empty,
          icon: Icons.newspaper_outlined,
          title: t.paNewsEmptyTitle,
          message: t.paNewsEmptyBody,
        ),
      ],
    );
  }
}
