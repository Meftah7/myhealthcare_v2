/// The pharmacist's working tabs, all built on the existing pharmacy queue
/// (signed, active prescriptions — `PharmacyRepository.queue`) and its
/// supported outcomes:
///
/// * Home ([PharmacyWorkspace]) — the next prescription to review as the
///   primary card, figures, the queue with a direct action on every item,
///   dispensing history, stock and the role tools.
/// * Schedule ([PharmacyWorkSchedule]) — "Pharmacy work": the same queue
///   grouped by prescription date, plus the pharmacist's own shifts.
/// * Patients ([PharmacyPatients]) — only the patients in that queue, with
///   only the prescription details pharmacy work needs. No chart access.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/pharmacy_repository.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import '../../workforce/workforce_home.dart' show PharmacyDispensingHistory;
import '../../workforce/workforce_repository.dart';
import '../../workspace/workspace_widgets.dart' show rows, workspaceStat;
import 'role_workspaces.dart'
    show
        DispenseSheet,
        ReceiveStockSheet,
        pharmacyOutcomeAccent,
        pharmacyOutcomeLabel,
        pharmacyQueueProvider,
        pharmacyStockProvider,
        staffFailureText;
import 'staff_chat_screen.dart';
import 'staff_home.dart';
import 'staff_top_actions.dart';

String _t(BuildContext c, String en, String ar) => workText(c, en, ar);

/// The order's status in words and colour, clarification first.
StaffStatus pharmacyStatus(BuildContext context, PharmacyOrder o) =>
    o.clarificationPending
    ? StaffStatus(
        _t(context, 'Clarification unresolved', 'استيضاح غير محسوم'),
        accent: PatientAccent.amber,
        icon: Icons.help_outline,
      )
    : StaffStatus(
        pharmacyOutcomeLabel(context, o.lastOutcome),
        accent: pharmacyOutcomeAccent(o.lastOutcome),
        icon: o.isDispensed ? Icons.check : Icons.medication_outlined,
      );

String _medicine(PharmacyOrder o) =>
    [o.name, ?o.dose].where((s) => s.isNotEmpty).join(' · ');

/// Opens the existing outcome sheet for one prescription.
Future<void> reviewPrescription(BuildContext context, PharmacyOrder o) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DispenseSheet(order: o),
    );

Future<void> _receiveStock(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const ReceiveStockSheet(),
);

/// One queue item: medicine, patient, prescriber and date, its status, and
/// Review prescription (disabled once dispensed).
class PharmacyOrderRow extends StatelessWidget {
  const PharmacyOrderRow({
    required this.order,
    this.showPatient = true,
    super.key,
  });

  final PharmacyOrder order;
  final bool showPatient;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return StaffRow(
      key: ValueKey('pharmacy-order-${o.medicationId}'),
      leadingIcon: Icons.medication_outlined,
      muted: o.isDispensed,
      title: _medicine(o),
      subtitle: [
        if (showPatient) o.patientName,
        ?o.frequency,
        '${_t(context, 'Prescribed by', 'وصفها')} ${clinicianName(o.prescriberName)} · ${fmtDate(o.startDate)}',
      ].join(' · '),
      status: pharmacyStatus(context, o),
      trailing: OutlinedButton(
        onPressed: o.isDispensed
            ? null
            : () => unawaited(reviewPrescription(context, o)),
        child: Text(_t(context, 'Review', 'مراجعة')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class PharmacyWorkspace extends ConsumerWidget {
  const PharmacyWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => _t(context, en, ar);
    final queue = ref.watch(pharmacyQueueProvider);
    final home = ref.watch(workforceDataProvider('home')).valueOrNull;
    return StaffHomeScaffold(
      onRefresh: () async {
        ref
          ..invalidate(pharmacyQueueProvider)
          ..invalidate(pharmacyStockProvider)
          ..invalidate(workforceDataProvider('home'))
          ..invalidate(workforceDataProvider('dispensing-history'))
          ..invalidate(workforceDataProvider('conversations'));
      },
      children: [
        // 1. The one primary card: the next prescription to review.
        const _NextPrescriptionCard(),
        // 2. Today in four figures.
        const SizedBox(height: Space.md),
        StaffFigureGrid([
          StaffFigure(
            label: t('Pending orders', 'الطلبات المعلقة'),
            value: '${workspaceStat(home, 'pendingOrders') ?? '—'}',
            icon: Icons.pending_actions_outlined,
            onTap: () => context.go(AppRoutes.staffSchedule),
          ),
          StaffFigure(
            label: t('Dispensed today', 'المصروف اليوم'),
            value: '${workspaceStat(home, 'dispensedToday') ?? '—'}',
            icon: Icons.task_alt,
            accent: PatientAccent.green,
          ),
          StaffFigure(
            label: t('Clarifications', 'الاستيضاحات'),
            value: '${workspaceStat(home, 'clarifications') ?? '—'}',
            icon: Icons.help_outline,
            accent: PatientAccent.amber,
          ),
          StaffFigure(
            label: t('Stock alerts', 'تنبيهات المخزون'),
            value: '${workspaceStat(home, 'stockAlerts') ?? '—'}',
            icon: Icons.inventory_2_outlined,
            accent: PatientAccent.red,
          ),
        ]),
        // 3. The queue, each item with its own action.
        SectionHeading(
          t('Prescription queue', 'قائمة الوصفات'),
          actionLabel: t('Pharmacy work', 'عمل الصيدلية'),
          onAction: () => context.go(AppRoutes.staffSchedule),
        ),
        queue.when(
          loading: () => const PatientStateView(kind: PatientStateKind.loading),
          error: (e, _) => PatientStateView(
            kind: PatientStateKind.error,
            message: staffFailureText(e),
            actionLabel: t('Retry', 'إعادة المحاولة'),
            onAction: () => ref.invalidate(pharmacyQueueProvider),
          ),
          data: (orders) => StaffListCard(
            emptyIcon: Icons.medication_outlined,
            emptyMessage: t('No active prescriptions.', 'لا توجد وصفات نشطة.'),
            children: [
              for (final o in orders.where((o) => !o.isDispensed).take(8))
                PharmacyOrderRow(order: o),
            ],
          ),
        ),
        // 4. Conversations, then history and stock (formerly My work).
        const StaffUnreadConversations(),
        const SizedBox(height: Space.md),
        const PharmacyDispensingHistory(),
        const _PharmacyStock(),
        StaffToolsCard(
          staffTools(
            context,
            StaffRole.pharmacist,
            leading: [
              StaffTool(
                Icons.add_box_outlined,
                t('Receive stock', 'استلام مخزون'),
                t('Record a received batch', 'تسجيل دفعة مستلمة'),
                () => unawaited(_receiveStock(context)),
                key: const ValueKey('tool-receive-stock'),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureWorkBadge(label: t('Future work', 'عمل مستقبلي')),
              const SizedBox(height: Space.xs),
              Text(
                t(
                  'Barcode scanning and supplier ordering are not part of this release.',
                  'مسح الباركود والطلب من الموردين ليسا ضمن هذا الإصدار.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextPrescriptionCard extends ConsumerWidget {
  const _NextPrescriptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => _t(context, en, ar);
    final queue = ref.watch(pharmacyQueueProvider);
    if (queue.hasError && !queue.hasValue) {
      return PatientStateView(
        kind: PatientStateKind.error,
        message: staffFailureText(queue.error!),
        actionLabel: t('Retry', 'إعادة المحاولة'),
        onAction: () => ref.invalidate(pharmacyQueueProvider),
      );
    }
    if (!queue.hasValue) {
      return const PatientStateView(kind: PatientStateKind.loading);
    }
    final next = queue.requireValue.where((o) => !o.isDispensed).firstOrNull;
    return StaffWorkCard(
      key: const ValueKey('staff-work-card'),
      overline: t('Next prescription', 'الوصفة التالية'),
      icon: Icons.medication_outlined,
      title: next == null ? null : _medicine(next),
      lines: next == null
          ? const []
          : [
              '${t('For', 'للمريض')} ${next.patientName}',
              [
                ?next.frequency,
                if (next.orderedUnits != null)
                  t('${next.orderedUnits} units', '${next.orderedUnits} وحدة'),
              ].join(' · '),
              '${t('Prescribed by', 'وصفها')} ${clinicianName(next.prescriberName)} · ${fmtDate(next.startDate)}',
            ].where((s) => s.isNotEmpty).toList(),
      status: next == null ? null : pharmacyStatus(context, next),
      primaryLabel: t('Review prescription', 'مراجعة الوصفة'),
      onPrimary: next == null
          ? null
          : () => unawaited(reviewPrescription(context, next)),
      secondaryLabel: t('View pharmacy work', 'عرض عمل الصيدلية'),
      onSecondary: () => context.go(AppRoutes.staffSchedule),
      emptyMessage: t(
        'No prescriptions waiting. Signed prescriptions appear here.',
        'لا توجد وصفات بالانتظار. تظهر الوصفات الموقعة هنا.',
      ),
    );
  }
}

class _PharmacyStock extends ConsumerWidget {
  const _PharmacyStock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => _t(context, en, ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          t('Stock', 'المخزون'),
          actionLabel: t('Receive stock', 'استلام مخزون'),
          onAction: () => unawaited(_receiveStock(context)),
        ),
        ref
            .watch(pharmacyStockProvider)
            .when(
              loading: () =>
                  const PatientStateView(kind: PatientStateKind.loading),
              error: (e, _) => PatientStateView(
                kind: PatientStateKind.error,
                message: staffFailureText(e),
                actionLabel: t('Retry', 'إعادة المحاولة'),
                onAction: () => ref.invalidate(pharmacyStockProvider),
              ),
              data: (batches) => StaffListCard(
                emptyIcon: Icons.inventory_2_outlined,
                emptyMessage: t(
                  'No stock recorded yet. Receive a batch to track quantities and expiry.',
                  'لا يوجد مخزون مسجل بعد. استلم دفعة لتتبع الكميات وتاريخ الانتهاء.',
                ),
                children: [
                  for (final b in batches)
                    StaffRow(
                      leadingIcon: Icons.inventory_2_outlined,
                      title: '${b.itemName} · ${b.batch}',
                      subtitle:
                          '${b.quantity} ${b.unit} · ${t('expires', 'ينتهي')} ${fmtDate(b.expiry)}',
                      status: b.isExpired(DateTime.now())
                          ? StaffStatus(
                              t('Expired', 'منتهي'),
                              accent: PatientAccent.red,
                              icon: Icons.block,
                            )
                          : b.quantity == 0
                          ? StaffStatus(
                              t('Out of stock', 'نفد'),
                              accent: PatientAccent.red,
                            )
                          : b.expiresSoon(DateTime.now())
                          ? StaffStatus(
                              t(
                                'Expires within 30 days',
                                'ينتهي خلال ٣٠ يومًا',
                              ),
                              accent: PatientAccent.amber,
                              icon: Icons.schedule,
                            )
                          : null,
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule — Pharmacy work
// ---------------------------------------------------------------------------

/// The pharmacy role has no appointment schedule: its dated work is the
/// prescription queue, grouped here by prescription date, and its own shifts.
class PharmacyWorkSchedule extends ConsumerWidget {
  const PharmacyWorkSchedule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => _t(context, en, ar);
    final lang = Localizations.localeOf(context).languageCode;
    return AppScaffold(
      title: t('Pharmacy work', 'عمل الصيدلية'),
      actions: const [StaffTopActions()],
      onRefresh: () async {
        ref
          ..invalidate(pharmacyQueueProvider)
          ..invalidate(workforceDataProvider('shifts'));
      },
      children: [
        ref
            .watch(pharmacyQueueProvider)
            .when(
              loading: () =>
                  const PatientStateView(kind: PatientStateKind.loading),
              error: (e, _) => PatientStateView(
                kind: PatientStateKind.error,
                message: staffFailureText(e),
                actionLabel: t('Retry', 'إعادة المحاولة'),
                onAction: () => ref.invalidate(pharmacyQueueProvider),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return StaffListCard(
                    emptyIcon: Icons.medication_outlined,
                    emptyMessage: t(
                      'No active prescriptions.',
                      'لا توجد وصفات نشطة.',
                    ),
                    children: const [],
                  );
                }
                final byDay = <DateTime, List<PharmacyOrder>>{};
                for (final o in orders) {
                  final d = DateTime(
                    o.startDate.year,
                    o.startDate.month,
                    o.startDate.day,
                  );
                  (byDay[d] ??= []).add(o);
                }
                final days = byDay.keys.toList()
                  ..sort((a, b) => b.compareTo(a));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in days) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: Space.md,
                          bottom: Space.xs,
                        ),
                        child: Text(
                          '${fmtRelativeDay(d)} · ${byDay[d]!.length}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      StaffListCard(
                        children: [
                          for (final o in byDay[d]!) PharmacyOrderRow(order: o),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
        SectionHeading(t('My shifts', 'مناوباتي')),
        ref
            .watch(workforceDataProvider('shifts'))
            .when(
              loading: () =>
                  const PatientStateView(kind: PatientStateKind.loading),
              error: (e, _) => PatientStateView(
                kind: PatientStateKind.error,
                message: staffFailureText(e),
                actionLabel: t('Retry', 'إعادة المحاولة'),
                onAction: () => ref.invalidate(workforceDataProvider('shifts')),
              ),
              data: (data) => StaffListCard(
                emptyIcon: Icons.work_outline,
                emptyMessage: t(
                  'No shifts assigned. Contact the clinic administrator.',
                  'لم يتم تعيين مناوبات. تواصل مع مدير العيادة.',
                ),
                children: [
                  for (final shift in rows(data['rows']))
                    StaffRow(
                      leadingIcon: Icons.work_outline,
                      title: DateFormat.EEEE(lang).format(
                        DateTime(
                          2026,
                          1,
                          4 + (shift['weekday'] as num).toInt(),
                        ),
                      ),
                      subtitle:
                          '${fmtMinutes((shift['start_minutes'] as num).toInt())}–${fmtMinutes((shift['end_minutes'] as num).toInt())}',
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Patients
// ---------------------------------------------------------------------------

/// Patients with prescriptions in the pharmacy queue — name and their
/// prescriptions only, which is what pharmacy work is authorized to see.
class PharmacyPatients extends ConsumerStatefulWidget {
  const PharmacyPatients({super.key});

  @override
  ConsumerState<PharmacyPatients> createState() => _PharmacyPatientsState();
}

class _PharmacyPatientsState extends ConsumerState<PharmacyPatients> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => _t(context, en, ar);
    final q = _query.text.trim().toLowerCase();
    return AppScaffold(
      title: t('Patients', 'المرضى'),
      actions: const [StaffTopActions()],
      onRefresh: () async => ref.invalidate(pharmacyQueueProvider),
      children: [
        Text(
          t(
            'Patients with signed prescriptions in the pharmacy queue. Clinical records are not available to pharmacy.',
            'المرضى الذين لديهم وصفات موقعة في قائمة الصيدلية. السجلات السريرية غير متاحة للصيدلية.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: PatientPalette.of(context).textMuted,
          ),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          key: const ValueKey('pharmacy-patient-search'),
          controller: _query,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: t(
              'Search by patient or medicine',
              'ابحث بالمريض أو الدواء',
            ),
          ),
        ),
        const SizedBox(height: Space.sm),
        ref
            .watch(pharmacyQueueProvider)
            .when(
              loading: () =>
                  const PatientStateView(kind: PatientStateKind.loading),
              error: (e, _) => PatientStateView(
                kind: PatientStateKind.error,
                message: staffFailureText(e),
                actionLabel: t('Retry', 'إعادة المحاولة'),
                onAction: () => ref.invalidate(pharmacyQueueProvider),
              ),
              data: (orders) {
                final byPatient = <String, List<PharmacyOrder>>{};
                for (final o in orders) {
                  if (q.isEmpty ||
                      o.patientName.toLowerCase().contains(q) ||
                      o.name.toLowerCase().contains(q)) {
                    (byPatient[o.patientId] ??= []).add(o);
                  }
                }
                final ids = byPatient.keys.toList()
                  ..sort(
                    (a, b) => byPatient[a]!.first.patientName.compareTo(
                      byPatient[b]!.first.patientName,
                    ),
                  );
                if (ids.isEmpty) {
                  return StaffListCard(
                    emptyIcon: Icons.people_outline,
                    emptyMessage: orders.isEmpty
                        ? t(
                            'No patients have active prescriptions.',
                            'لا يوجد مرضى لديهم وصفات نشطة.',
                          )
                        : t('No patient matches.', 'لا يوجد مريض مطابق.'),
                    children: const [],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final id in ids) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: Space.md,
                          bottom: Space.xs,
                        ),
                        child: ReadableLabel(
                          byPatient[id]!.first.patientName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      StaffListCard(
                        children: [
                          for (final o in byPatient[id]!)
                            PharmacyOrderRow(order: o, showPatient: false),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
      ],
    );
  }
}
