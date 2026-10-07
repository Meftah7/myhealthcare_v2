import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../application/records_providers.dart';

class RecordsSubjectHeader extends ConsumerWidget {
  const RecordsSubjectHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final id = ref.watch(recordsPatientIdProvider);
    final links = ref.watch(linkedAccountsProvider);
    final profile = ref.watch(recordsProfileProvider);
    final family = links.valueOrNull ?? [];
    final available = id == me.id || family.any((v) => v.counterpart.id == id);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey('records-subject-$id-$available'),
            initialValue: available ? id : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.importForLabel),
            items: [
              DropdownMenuItem(value: me.id, child: Text(me.fullName)),
              for (final member in family)
                DropdownMenuItem(
                  value: member.counterpart.id,
                  child: Text(member.counterpart.fullName),
                ),
            ],
            onChanged: links.isLoading
                ? null
                : (value) {
                    ref.read(selectedRecordsPatientProvider.notifier).state =
                        value == me.id ? null : value;
                  },
          ),
          if (links.isLoading) const LinearProgressIndicator(),
          if (links.hasError || !available)
            TextButton.icon(
              onPressed: () => ref.invalidate(linkedAccountsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(t.recordsFamilyUnavailable),
            ),
          profile.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => TextButton.icon(
              onPressed: () {
                ref.invalidate(recordsProfileProvider);
                ref.invalidate(patientProfileProvider);
                ref.invalidate(linkedPatientProvider(id));
              },
              icon: const Icon(Icons.refresh),
              label: Text(t.couldNotLoadAllergies),
            ),
            data: (patient) => patient.allergies.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Tooltip(
                      message: t.allergiesInline(patient.allergies.join(', ')),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              t.allergiesInline(patient.allergies.join(', ')),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
