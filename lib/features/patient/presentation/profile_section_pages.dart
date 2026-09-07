/// Each patient-profile section as its own page. The Profile screen lists them
/// as rows; tapping a row pushes the matching page (with a back button in the
/// top-left that returns to the same Profile screen).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../domain/entities/entities.dart';
import '../../billing/presentation/wallet_section.dart';
import '../../settings/presentation/preferences_section.dart';
import '../application/patient_data_providers.dart';
import 'family_network_section.dart';
import 'health_details_section.dart';
import 'personal_info_section.dart';

/// Shared shell: an app bar with an automatic back button, content capped at
/// the app's max width, scrollable.
class _SectionScaffold extends StatelessWidget {
  const _SectionScaffold({required this.title, required this.child});

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

/// A section that needs the loaded patient — handles its own loading / error.
class _PatientSectionPage extends ConsumerWidget {
  const _PatientSectionPage({required this.title, required this.builder});

  final String title;
  final Widget Function(Patient patient) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(patientProfileProvider);
    return _SectionScaffold(
      title: title,
      child: profile.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your profile.',
          onRetry: () => ref.invalidate(patientProfileProvider),
        ),
        data: builder,
      ),
    );
  }
}

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) => _PatientSectionPage(
    title: 'Personal info',
    builder: (p) => PersonalInfoSection(patient: p),
  );
}

class HealthDetailsPage extends StatelessWidget {
  const HealthDetailsPage({super.key});

  @override
  Widget build(BuildContext context) => _PatientSectionPage(
    title: 'Health details',
    builder: (p) => HealthDetailsSection(patient: p),
  );
}

class FamilyNetworkPage extends StatelessWidget {
  const FamilyNetworkPage({super.key});

  @override
  Widget build(BuildContext context) => _PatientSectionPage(
    title: 'Family network',
    builder: (p) => FamilyNetworkSection(patient: p, embedded: true),
  );
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SectionScaffold(title: 'Wallet', child: WalletSection());
}

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) => const _SectionScaffold(
    title: 'Preferences',
    child: PreferencesSection(bare: true),
  );
}
