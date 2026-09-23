/// Health Records — the patient's clinical history, in views chosen with a top
/// toggle (timeline, medications, bills), plus a documents & alerts strip:
/// allergies, imaging results and an exportable vital-signs report (P10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../billing/presentation/billing_screen.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../../records/presentation/medications_screen.dart';
import 'timeline_screen.dart';

enum _RecordsView { timeline, medications, bills }

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({this.startOnMedications = false, super.key});

  final bool startOnMedications;

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  late _RecordsView _view = widget.startOnMedications
      ? _RecordsView.medications
      : _RecordsView.timeline;

  @override
  Widget build(BuildContext context) {
    final gutter = WindowSize.of(context).gutter;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.recordsTitle),
        actions: const [PatientTopActions()],
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.sm,
                  gutter,
                  Space.sm,
                ),
                child: Column(
                  children: [
                    const _DocumentsStrip(),
                    const SizedBox(height: Space.sm),
                    SizedBox(
                      width: double.infinity,
                      // Clamped the same way as the bottom nav bar
                      // (app_shell.dart) — at the Default text-size tier and
                      // up, "Medication" wraps to a second line in this
                      // segment's fixed width. Capping at the Small tier's
                      // 0.92 keeps every segment label on one line.
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: MediaQuery.textScalerOf(
                            context,
                          ).clamp(maxScaleFactor: 0.92),
                        ),
                        child: SegmentedButton<_RecordsView>(
                          segments: [
                            ButtonSegment(
                              value: _RecordsView.timeline,
                              icon: const Icon(Icons.timeline_outlined),
                              label: Text(t.timelineSegment),
                            ),
                            ButtonSegment(
                              value: _RecordsView.medications,
                              icon: const Icon(Icons.medication_outlined),
                              label: Text(t.medicationsSegment),
                            ),
                            ButtonSegment(
                              value: _RecordsView.bills,
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: Text(t.billsSegment),
                            ),
                          ],
                          selected: {_view},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) =>
                              setState(() => _view = s.first),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: switch (_view) {
              _RecordsView.timeline => const TimelineScreen(embedded: true),
              _RecordsView.medications => const MedicationsScreen(
                embedded: true,
              ),
              _RecordsView.bills => const BillingScreen(embedded: true),
            },
          ),
        ],
      ),
    );
  }
}

/// Allergies alert + shortcuts to imaging results and the vital-signs report.
class _DocumentsStrip extends ConsumerWidget {
  const _DocumentsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final allergies =
        ref.watch(patientProfileProvider).valueOrNull?.allergies ??
        const <String>[];

    // Four shortcuts to the record documents, all the same shape and size:
    // imaging and sick leave were already a matched pair — the vital-signs
    // report and allergies now join them on the same 2×2 grid instead of
    // trailing off in a smaller, differently-styled row.
    Widget shortcut(IconData icon, String label, VoidCallback onTap) =>
        OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        );

    // IntrinsicHeight so both cells in a row match the taller button — the
    // "Vital signs report" label wraps to two lines where the others don't.
    Widget shortcutRow(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: Space.sm),
          Expanded(child: b),
        ],
      ),
    );

    return Column(
      children: [
        if (allergies.isNotEmpty) ...[
          AppCard(
            onTap: () => context.push(AppRoutes.patientAllergies),
            color: scheme.errorContainer,
            borderColor: scheme.error.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    t.allergiesInline(allergies.join(', ')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onErrorContainer),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
        ],
        shortcutRow(
          shortcut(
            Icons.image_outlined,
            t.imagingTitle,
            () => context.push(AppRoutes.patientImaging),
          ),
          shortcut(
            Icons.event_busy_outlined,
            t.quickActionSickLeave,
            () => context.push(AppRoutes.patientSickLeave),
          ),
        ),
        const SizedBox(height: Space.sm),
        shortcutRow(
          DocumentDownloadButton(
            label: t.vitalSignsReportLabel,
            filename: 'vital-signs-report.pdf',
            icon: Icons.monitor_heart_outlined,
            build: () => buildVitalsReport(ref),
          ),
          shortcut(
            Icons.medical_information_outlined,
            t.allergiesLabel,
            () => context.push(AppRoutes.patientAllergies),
          ),
        ),
      ],
    );
  }
}
