/// Doctor conversations, health shortcuts, and the existing record history.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/quick_actions.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../billing/presentation/payments_screen.dart';
import '../../care/application/care_providers.dart';
import '../../care/presentation/patient_doctor_chat_section.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/application/visited_doctors_provider.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../../records/presentation/medications_screen.dart';
import 'import_record_sheet.dart';
import 'timeline_screen.dart';

enum _RecordsView { overview, timeline, medications, bills }

class HealthRecordsScreen extends ConsumerStatefulWidget {
  const HealthRecordsScreen({this.startOnMedications = false, super.key});
  final bool startOnMedications;
  @override
  ConsumerState<HealthRecordsScreen> createState() =>
      _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends ConsumerState<HealthRecordsScreen> {
  late _RecordsView _view = widget.startOnMedications
      ? _RecordsView.medications
      : _RecordsView.overview;
  @override
  void didUpdateWidget(covariant HealthRecordsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startOnMedications != oldWidget.startOnMedications) {
      _view = widget.startOnMedications
          ? _RecordsView.medications
          : _RecordsView.overview;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_view == _RecordsView.overview)
      return AppScaffold(
        title: t.recordsTitle,
        actions: const [PatientTopActions()],
        onRefresh: () async {
          ref.invalidate(patientAppointmentsProvider);
          ref.invalidate(visitedDoctorsProvider);
          ref.invalidate(patientThreadsProvider);
          ref.invalidate(patientProfileProvider);
        },
        children: [
          const PatientDoctorChatSection(),
          const SizedBox(height: Space.lg),
          ReadableLabel(
            t.recordsYourHealthTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Space.sm),
          const _AllergiesAlert(),
          _HealthActions(
            onMedications: () =>
                setState(() => _view = _RecordsView.medications),
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _view = _RecordsView.timeline),
                icon: const Icon(Icons.timeline_outlined),
                label: Text(t.timelineSegment),
              ),
              OutlinedButton.icon(
                onPressed: () => showImportRecordSheet(context),
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(t.importPdfAction),
              ),
            ],
          ),
        ],
      );
    return AppScaffold(
      title: t.recordsTitle,
      actions: const [PatientTopActions()],
      body: ScrollableHeaderBody(
        header: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: WindowSize.of(context).gutter,
                vertical: Space.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _view = _RecordsView.overview),
                    icon: const Icon(Icons.arrow_back),
                    label: ReadableLabel(t.recordsBackToOverview),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: PillSegmented<_RecordsView>(
                      compact: true,
                      segments: [
                        (_RecordsView.timeline, t.timelineSegment),
                        (_RecordsView.medications, t.medicationsSegment),
                        (_RecordsView.bills, t.billsSegment),
                      ],
                      selected: _view,
                      onChanged: (value) => setState(() => _view = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: switch (_view) {
          _RecordsView.timeline => const TimelineScreen(embedded: true),
          _RecordsView.medications => const MedicationsScreen(embedded: true),
          _RecordsView.bills => const PaymentsScreen(embedded: true),
          _RecordsView.overview => const SizedBox.shrink(),
        },
      ),
      floatingActionButton: _view == _RecordsView.timeline
          ? FloatingActionButton.extended(
              onPressed: () => showImportRecordSheet(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(t.importPdfAction),
            )
          : null,
      centerBody: false,
    );
  }
}

class _HealthActions extends ConsumerWidget {
  const _HealthActions({required this.onMedications});
  final VoidCallback onMedications;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    Widget tile(IconData icon, String label, String route) => QuickActionTile(
      icon: icon,
      label: label,
      onTap: () => context.push(route),
    );
    final children = <Widget>[
      tile(
        Icons.home_outlined,
        t.quickActionHomeCare,
        AppRoutes.patientHomeVisit,
      ),
      QuickActionTile(
        icon: Icons.medication_outlined,
        label: t.medicationsSegment,
        onTap: onMedications,
      ),
      tile(
        Icons.receipt_long_outlined,
        t.billsSegment,
        AppRoutes.patientBilling,
      ),
      tile(
        Icons.groups_outlined,
        t.quickActionVisitedDoctors,
        AppRoutes.patientVisitedDoctors,
      ),
      tile(Icons.image_outlined, t.imagingTitle, AppRoutes.patientImaging),
      tile(
        Icons.event_busy_outlined,
        t.quickActionSickLeave,
        AppRoutes.patientSickLeave,
      ),
      DocumentDownloadButton(
        asQuickAction: true,
        label: t.vitalSignsReportLabel,
        filename: 'vital-signs-report.pdf',
        icon: Icons.monitor_heart_outlined,
        build: () => buildVitalsReport(ref),
      ),
      tile(
        Icons.medical_information_outlined,
        t.allergiesLabel,
        AppRoutes.patientAllergies,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
        final columns = constraints.maxWidth >= 700
            ? 4
            : (constraints.maxWidth < 300 && scale > 1.5 ? 1 : 2);
        final width =
            (constraints.maxWidth - Space.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                height: math.max(width, 116 * scale),
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _AllergiesAlert extends ConsumerWidget {
  const _AllergiesAlert();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final allergies =
        ref.watch(patientProfileProvider).valueOrNull?.allergies ??
        const <String>[];
    if (allergies.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        color: scheme.errorContainer,
        onTap: () => context.push(AppRoutes.patientAllergies),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                t.allergiesInline(allergies.join(', ')),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
