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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
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
                      child: SegmentedButton<_RecordsView>(
                        segments: const [
                          ButtonSegment(
                            value: _RecordsView.timeline,
                            icon: Icon(Icons.timeline_outlined),
                            label: Text('Timeline'),
                          ),
                          ButtonSegment(
                            value: _RecordsView.medications,
                            icon: Icon(Icons.medication_outlined),
                            label: Text('Medications'),
                          ),
                          ButtonSegment(
                            value: _RecordsView.bills,
                            icon: Icon(Icons.receipt_long_outlined),
                            label: Text('Bills'),
                          ),
                        ],
                        selected: {_view},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            setState(() => _view = s.first),
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
    final allergies =
        ref.watch(patientProfileProvider).valueOrNull?.allergies ??
        const <String>[];

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
                    'Allergies: ${allergies.join(', ')}',
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.patientImaging),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Imaging'),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: DocumentDownloadButton(
                label: 'Vitals report',
                filename: 'vital-signs-report.pdf',
                icon: Icons.monitor_heart_outlined,
                build: () => buildVitalsReport(ref),
              ),
            ),
          ],
        ),
        if (allergies.isEmpty) ...[
          const SizedBox(height: Space.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.patientAllergies),
              icon: const Icon(Icons.medical_information_outlined, size: 16),
              label: const Text('Allergies'),
            ),
          ),
        ],
      ],
    );
  }
}
