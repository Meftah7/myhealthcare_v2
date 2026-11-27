/// Patient record history and the medications view.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../../records/application/records_providers.dart';
import '../../records/presentation/medications_screen.dart';
import '../../records/presentation/records_subject_header.dart';
import 'timeline_screen.dart';

class HealthRecordsScreen extends ConsumerWidget {
  const HealthRecordsScreen({this.startOnMedications = false, super.key});
  final bool startOnMedications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    if (!startOnMedications) {
      return AppScaffold(
        title: t.recordsTitle,
        actions: const [PatientTopActions()],
        body: TimelineScreen(
          embedded: true,
          onRefresh: () async {
            ref.invalidate(patientTimelinePageProvider);
            ref.invalidate(linkedTimelinePageProvider);
            ref.invalidate(linkedPatientProvider);
            ref.invalidate(recordsHistoryProvider);
            ref.invalidate(recordsVitalsProvider);
            ref.invalidate(linkedVitalsProvider);
            ref.invalidate(patientProfileProvider);
            ref.invalidate(patientVitalsProvider);
            ref.invalidate(patientAppointmentsProvider);
          },
          header: const RecordsSubjectHeader(),
        ),
        centerBody: false,
      );
    }
    return AppScaffold(
      title: t.recordsTitle,
      actions: const [PatientTopActions()],
      body: Column(
        children: [
          const RecordsSubjectHeader(),
          Expanded(
            child: ScrollableHeaderBody(
              header: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Space.maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: WindowSize.of(context).gutter,
                      vertical: Space.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () =>
                                context.go(AppRoutes.patientTimeline),
                            icon: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_forward
                                  : Icons.arrow_back,
                            ),
                            label: ReadableLabel(t.recordsBackToOverview),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: PatientPageTitle(t.paMedications),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              body: const MedicationsScreen(embedded: true),
            ),
          ),
        ],
      ),
      centerBody: false,
    );
  }
}
