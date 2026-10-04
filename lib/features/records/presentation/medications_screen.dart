/// Medications list — active vs past (P2-16).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../care/application/care_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/visited_doctors_provider.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({this.embedded = false, super.key});

  /// When true, render the list without a Scaffold/AppBar — the caller (the
  /// Health Records screen) supplies those.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _body(context, ref);
    if (embedded) return body;
    return AppScaffold(
      title: AppLocalizations.of(context)!.quickActionMedications,
      body: body,
      centerBody: false,
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final meds = ref.watch(patientMedicationsProvider);
    return meds.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadMedications,
        onRetry: () => ref.invalidate(patientMedicationsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.medication_outlined,
            message: t.noMedicationsOnRecord,
          );
        }
        final active = list.where((m) => m.isCurrent).toList();
        final past = list.where((m) => !m.isCurrent).toList();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                Space.xxl,
              ),
              children: [
                if (active.isNotEmpty) ...[
                  SectionHeader(t.currentSectionLabel, overline: true),
                  _group(active),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  SectionHeader(t.pastSectionLabel, overline: true),
                  _group(past),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _group(List<Medication> meds) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < meds.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: Space.md),
          _MedTile(meds[i]),
        ],
      ],
    ),
  );
}

class _MedTile extends StatelessWidget {
  const _MedTile(this.m);
  final Medication m;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final how = [?m.dose, ?m.frequency].join(' · ');
    return ListTile(
      leading: Icon(
        m.isCurrent ? Icons.medication : Icons.medication_outlined,
        color: m.isCurrent ? theme.colorScheme.primary : null,
      ),
      title: ReadableLabel(m.name),
      subtitle: Text(
        how.isEmpty ? t.medNoInstructions : t.medHowToTake(how),
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _MedicationDetails(m),
      ),
    );
  }
}

/// One medicine: how and how often to take it, for how long, who prescribed
/// it — and a way to ask that doctor for more.
class _MedicationDetails extends ConsumerStatefulWidget {
  const _MedicationDetails(this.m);
  final Medication m;

  @override
  ConsumerState<_MedicationDetails> createState() => _MedicationDetailsState();
}

class _MedicationDetailsState extends ConsumerState<_MedicationDetails> {
  bool _sending = false;

  /// The prescriber when the patient can message them (a doctor they have
  /// visited), or else the doctor they saw most recently.
  Future<({String id, String name})?> _doctor() async {
    final visited = await ref.read(visitedDoctorsProvider.future);
    if (visited.isEmpty) return null;
    final prescriber = visited
        .where((d) => d.staffId == widget.m.prescriberId)
        .firstOrNull;
    final pick =
        prescriber ??
        ([...visited]..sort((a, b) => b.lastVisit.compareTo(a.lastVisit)))
            .first;
    return (id: pick.staffId, name: pick.name);
  }

  Future<void> _requestRefill() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _sending = true);
    final doctor = await _doctor();
    if (doctor == null) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(t.refillNoDoctor)));
      return;
    }
    final m = widget.m;
    final r = await ref
        .read(messageActionsProvider)
        .sendAsCurrentUser(
          counterpartId: doctor.id,
          body: t.refillRequestMessage(
            [m.name, ?m.dose, ?m.frequency].join(' · '),
          ),
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.isOk) navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          r.isOk ? t.refillRequestSent(doctor.name) : t.refillRequestFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final m = widget.m;
    final prescriber = ref
        .watch(doctorDirectoryProvider)
        .valueOrNull?[m.prescriberId]
        ?.name;
    Widget row(IconData icon, String label, String value) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: theme.textTheme.bodySmall),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReadableLabel(m.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              m.isCurrent ? t.medStatusCurrent : t.medStatusFinished,
              style: theme.textTheme.bodySmall?.copyWith(
                color: m.isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.sm),
            row(
              Icons.medication_liquid_outlined,
              t.medDoseLabel,
              m.dose ?? t.medAskDoctor,
            ),
            row(
              Icons.schedule,
              t.medHowOftenLabel,
              m.frequency ?? t.medAskDoctor,
            ),
            row(
              Icons.date_range_outlined,
              t.medPeriodLabel,
              m.endDate == null
                  ? t.medDoseFrom(fmtDate(m.startDate))
                  : '${fmtDate(m.startDate)} – ${fmtDate(m.endDate!)}',
            ),
            if (prescriber != null)
              row(Icons.person_outline, t.medPrescribedByLabel, prescriber),
            const SizedBox(height: Space.sm),
            Text(
              t.medSafetyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: _sending ? null : _requestRefill,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.autorenew),
              label: Text(t.requestRefillAction),
            ),
          ],
        ),
      ),
    );
  }
}
