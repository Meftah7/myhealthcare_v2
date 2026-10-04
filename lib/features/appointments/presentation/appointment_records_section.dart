library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/appointment_records_provider.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../billing/presentation/payments_screen.dart' show money;
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';

class AppointmentRecordsSection extends ConsumerWidget {
  const AppointmentRecordsSection({required this.appointmentId, super.key});
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final records = ref.watch(appointmentRecordsProvider(appointmentId));
    final labels = <RecordType, String>{
      RecordType.visitNote: t.appointmentClinicVisit,
      RecordType.labResult: t.appointmentLaboratoryPanel,
      RecordType.imaging: t.recordTypeImaging,
      RecordType.prescription: t.filterPrescriptions,
      RecordType.vaccination: t.filterVaccinations,
      RecordType.discharge: t.recordTypeDischarge,
      RecordType.referral: t.filterReferrals,
    };
    Widget heading(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.md,
        Space.md,
        Space.xs,
      ),
      child: ReadableLabel(
        label,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadableLabel(
          t.appointmentRecordsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Space.sm),
        records.when(
          loading: () => const SkeletonList(lines: 2),
          error: (_, _) => ErrorStateView(
            message: t.couldNotLoadRecords,
            onRetry: () =>
                ref.invalidate(appointmentRecordsProvider(appointmentId)),
          ),
          data: (bundle) {
            if (bundle.isEmpty)
              return EmptyState(
                icon: Icons.folder_open_outlined,
                message: t.appointmentRecordsEmpty,
              );
            return AppCard(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final type in RecordType.values)
                    if (bundle.records.any((r) => r.recordType == type) ||
                        (type == RecordType.prescription &&
                            bundle.medications.isNotEmpty)) ...[
                      heading(labels[type]!),
                      for (final record in bundle.records.where(
                        (r) => r.recordType == type,
                      ))
                        ListTile(
                          title: Text(record.title),
                          subtitle: Text(fmtDateTime(record.occurredAt)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push(AppRoutes.patientRecord(record.id)),
                        ),
                      if (type == RecordType.prescription)
                        for (final medication in bundle.medications)
                          ListTile(
                            title: Text(medication.name),
                            subtitle: Text(
                              [
                                ?medication.dose,
                                ?medication.frequency,
                                fmtDate(medication.startDate),
                                if (medication.endDate != null)
                                  fmtDate(medication.endDate!),
                              ].join(' · '),
                            ),
                          ),
                    ],
                  if (bundle.sickLeave.isNotEmpty) ...[
                    heading(t.visitSickLeaveHeading),
                    for (final cert in bundle.sickLeave)
                      ListTile(
                        title: Text(cert.diagnosis),
                        subtitle: Text(
                          '${fmtDate(cert.fromDate)} – ${fmtDate(cert.toDate)}',
                        ),
                        trailing: DocumentDownloadButton(
                          label: t.certificatePdfLabel,
                          filename: 'sick-leave-${fmtDate(cert.fromDate)}.pdf',
                          build: () => buildSickLeave(ref, cert),
                          dense: true,
                        ),
                      ),
                  ],
                  if (bundle.invoices.isNotEmpty) ...[
                    heading(t.visitInvoicesHeading),
                    for (final invoice in bundle.invoices)
                      ListTile(
                        title: Text(money(invoice.totalAmount)),
                        subtitle: Text(
                          invoiceStatusLabel(
                            context,
                            invoice.status,
                            overdue: invoice.isOverdue,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.patientBilling),
                      ),
                  ],
                  if (bundle.vitals.isNotEmpty) ...[
                    heading(t.vitalsRecordedTitle),
                    for (final v in bundle.vitals)
                      ListTile(
                        title: Text(fmtDateTime(v.recordedAt)),
                        subtitle: Text(
                          [
                            if (v.hasBloodPressure)
                              'BP ${v.systolic}/${v.diastolic} mmHg',
                            if (v.heartRate != null) 'HR ${v.heartRate} bpm',
                            if (v.tempC != null) '${v.tempC} °C',
                            if (v.weightKg != null) '${v.weightKg} kg',
                            if (v.heightCm != null) '${v.heightCm} cm',
                            if (v.spo2 != null) 'SpO₂ ${v.spo2}%',
                            if (v.glucose != null)
                              '${t.chartGlucose} ${v.glucose}',
                          ].join(' · '),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
