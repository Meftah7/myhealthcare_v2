/// Staff Home dispatch for roles without clinical chart access, and the
/// sheets those roles act through: the front-desk booking sheet and issued-
/// copy check, the pharmacy outcome and stock sheets, and the unassigned-role
/// notice. The reception and pharmacy tabs live in `front_desk.dart` and
/// `pharmacy_work.dart` (re-exported here).
///
/// Every action here is re-authorized by its repository; these screens only
/// decide what to offer.
library;

export 'front_desk.dart'
    show
        DeskSchedule,
        FrontDeskWorkspace,
        ReceptionPatientLookup,
        deskArrivalsProvider,
        showDeskBookingFlow;
export 'pharmacy_work.dart'
    show PharmacyPatients, PharmacyWorkSchedule, PharmacyWorkspace;

import 'dart:async';
import '../../workforce/workforce_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/failures.dart';
import '../../workforce/role_navigation.dart' show deskDayAppointmentsProvider;
import '../../workspace/workspace_repository.dart';
import 'front_desk.dart' show FrontDeskWorkspace, deskArrivalsProvider;
import 'pharmacy_work.dart' show PharmacyWorkspace;

import '../../../app/theme/dimens.dart';
import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/result.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/documents/document_rules.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../../domain/repositories/document_service.dart';
import '../../../domain/repositories/pharmacy_repository.dart';
import '../../../domain/repositories/repositories.dart';
import '../../auth/application/session.dart';
import '../../booking/application/booking_providers.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import 'staff_top_actions.dart';

/// The Today workspace for a non-clinical staff role, or `null` to keep the
/// clinical dashboard.
Widget? roleWorkspaceFor(Set<Permission> permissions) {
  if (permissions.contains(Permission.readPatientChart)) return null;
  if (permissions.contains(Permission.dispenseMedication)) {
    return const PharmacyWorkspace();
  }
  if (permissions.contains(Permission.bookForPatients)) {
    return const FrontDeskWorkspace();
  }
  return const UnassignedRoleWorkspace();
}

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

String staffFailureText(Object e) => e is Exception || e is Error
    ? e.toString()
    : (e as dynamic).message as String? ?? '$e';

// ---------------------------------------------------------------------------
// Front desk
// ---------------------------------------------------------------------------

/// Books one visit for [patient] at the front desk: department → clinician
/// → day → an actually open slot → visit type → review → submit.
class DeskBookingSheet extends ConsumerStatefulWidget {
  const DeskBookingSheet({
    required this.patient,
    this.identityConfirmed = false,
    super.key,
  });

  final Patient patient;

  /// Set when the book-for-a-patient flow already had staff confirm the
  /// patient against their CPR / ID.
  final bool identityConfirmed;

  @override
  ConsumerState<DeskBookingSheet> createState() => _DeskBookingState();
}

class _DeskBookingState extends ConsumerState<DeskBookingSheet> {
  // One key per sheet: a retry after a lost response books once.
  final _key = IdempotencyKey.generate();
  late bool _identityChecked = widget.identityConfirmed;
  String? _departmentId;
  Staff? _clinician;
  DateTime _day = DateTime.now();
  OpenSlot? _slot;
  VisitType _visitType = VisitType.followUp;
  Future<Result<List<OpenSlot>>>? _slots;
  bool _busy = false;
  String? _error;
  Appointment? _booked;

  void _loadSlots() {
    final c = _clinician;
    _slot = null;
    _slots = c == null
        ? null
        : ref.read(appointmentRepositoryProvider).openSlots(c.id, _day);
  }

  Future<void> _submit() async {
    final slot = _slot;
    final c = _clinician;
    if (_busy || slot == null || c == null || !_identityChecked) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref
        .read(appointmentRepositoryProvider)
        .book(
          BookingRequest(
            patientId: widget.patient.id,
            staffId: c.id,
            start: slot.start,
            end: slot.end,
            visitType: _visitType,
            idempotencyKey: _key,
          ),
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (r) {
        case Ok(:final value):
          _booked = value;
          ref
            ..invalidate(deskArrivalsProvider)
            ..invalidate(deskDayAppointmentsProvider)
            ..invalidate(workforceDataProvider('home'));
        case Err(:final failure):
          // The patient and choices stay; a taken slot is refreshed so one
          // of the remaining times can be chosen.
          _error = failure is ConflictFailure
              ? workText(
                  context,
                  'That time was just taken. Choose one of the remaining times.',
                  'تم حجز هذا الوقت للتو. اختر أحد الأوقات المتبقية.',
                )
              : failure.message;
          _loadSlots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final booked = _booked;
    final departments = ref.watch(departmentsProvider);
    final staff = _departmentId == null
        ? null
        : ref.watch(departmentStaffProvider(_departmentId!));
    return Padding(
      padding: EdgeInsets.only(
        left: Space.md,
        right: Space.md,
        top: Space.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.md,
      ),
      child: SingleChildScrollView(
        child: booked != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 48),
                  const SizedBox(height: Space.sm),
                  Text(
                    workText(context, 'Booking confirmed', 'تم تأكيد الحجز'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    '${widget.patient.user.fullName}\n'
                    '${fmtDate(booked.slotStart)} ${fmtTime(booked.slotStart)}'
                    '${booked.ticketTag == null ? '' : ' · ${booked.ticketTag}'}\n'
                    '${clinicianName(_clinician?.fullName ?? '')} · ${visitTypeLabel(booked.visitType)}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.md),
                  PrimaryActionButton(
                    key: const ValueKey('desk-booking-view'),
                    label: workText(
                      context,
                      'View in schedule',
                      'عرض في الجدول',
                    ),
                    onPressed: () {
                      ref.read(workspaceDayProvider.notifier).state = clinicDay(
                        booked.slotStart,
                      );
                      Navigator.of(context).pop();
                      GoRouter.of(context).go(AppRoutes.staffSchedule);
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(workText(context, 'Done', 'تم')),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    workText(
                      context,
                      'Book for ${widget.patient.user.fullName}',
                      'حجز لـ ${widget.patient.user.fullName}',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _identityChecked,
                    onChanged: (v) =>
                        setState(() => _identityChecked = v ?? false),
                    title: Text(
                      workText(
                        context,
                        'Identity confirmed with CPR / ID',
                        'تم التحقق من الهوية بالرقم الشخصي',
                      ),
                    ),
                  ),
                  departments.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(staffFailureText(e)),
                    data: (list) => DropdownButtonFormField<String>(
                      initialValue: _departmentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: workText(
                          context,
                          'Clinic / department',
                          'العيادة / القسم',
                        ),
                      ),
                      items: [
                        for (final d in list)
                          DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ],
                      onChanged: (v) => setState(() {
                        _departmentId = v;
                        _clinician = null;
                        _loadSlots();
                      }),
                    ),
                  ),
                  if (staff != null) ...[
                    const SizedBox(height: Space.sm),
                    staff.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(staffFailureText(e)),
                      data: (list) {
                        final bookable = [
                          for (final s in list)
                            if (s.takesAppointments && s.user.isActive) s,
                        ];
                        return DropdownButtonFormField<String>(
                          initialValue: _clinician?.id,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: workText(context, 'Clinician', 'الطبيب'),
                          ),
                          items: [
                            for (final s in bookable)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(clinicianName(s.fullName)),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            _clinician = bookable.firstWhere((s) => s.id == v);
                            _loadSlots();
                          }),
                        );
                      },
                    ),
                  ],
                  if (_clinician != null) ...[
                    const SizedBox(height: Space.sm),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined),
                      label: Text(fmtDate(_day)),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _day,
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: now.add(const Duration(days: 120)),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _day = picked;
                            _loadSlots();
                          });
                        }
                      },
                    ),
                    FutureBuilder<Result<List<OpenSlot>>>(
                      future: _slots,
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const LinearProgressIndicator();
                        }
                        return switch (snap.data!) {
                          Err(:final failure) => Text(failure.message),
                          Ok(:final value) when value.isEmpty => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Space.sm,
                            ),
                            child: Text(
                              workText(
                                context,
                                'No open times on this day. Choose another day.',
                                'لا توجد أوقات متاحة في هذا اليوم. اختر يومًا آخر.',
                              ),
                            ),
                          ),
                          Ok(:final value) => Wrap(
                            spacing: Space.xs,
                            runSpacing: Space.xs,
                            children: [
                              for (final s in value.take(24))
                                ChoiceChip(
                                  label: Text(fmtTime(s.start)),
                                  selected: _slot?.start == s.start,
                                  onSelected: (_) => setState(() => _slot = s),
                                ),
                            ],
                          ),
                        };
                      },
                    ),
                  ],
                  const SizedBox(height: Space.sm),
                  DropdownButtonFormField<VisitType>(
                    initialValue: _visitType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: workText(context, 'Visit type', 'نوع الزيارة'),
                    ),
                    items: [
                      for (final v in VisitType.values)
                        DropdownMenuItem(
                          value: v,
                          child: Text(visitTypeLabel(v)),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _visitType = v ?? _visitType),
                  ),
                  if (_slot != null && _clinician != null) ...[
                    const SizedBox(height: Space.md),
                    InlineBanner.info(
                      '${widget.patient.user.fullName} · ${clinicianName(_clinician!.fullName)}\n'
                      '${fmtDate(_slot!.start)} ${fmtTime(_slot!.start)} · ${visitTypeLabel(_visitType)}',
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: Space.sm),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.md),
                  PrimaryActionButton(
                    label: workText(context, 'Confirm booking', 'تأكيد الحجز'),
                    busy: _busy,
                    onPressed: _slot != null && _identityChecked && !_busy
                        ? () => unawaited(_submit())
                        : null,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Front-desk administrative confirmation of an issued copy.
class ConfirmCopySheet extends ConsumerStatefulWidget {
  const ConfirmCopySheet({super.key});

  @override
  ConsumerState<ConfirmCopySheet> createState() => _ConfirmCopyState();
}

class _ConfirmCopyState extends ConsumerState<ConfirmCopySheet> {
  final _reference = TextEditingController();
  final _reason = TextEditingController();
  final _key = IdempotencyKey.generate();
  bool _identityChecked = false;
  bool _busy = false;
  String? _error;
  DateTime? _done;
  IssuedDocument? _found;
  String? _foundPatient;

  Future<void> _lookUp() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _found = null;
    });
    final r = await ref
        .read(documentServiceProvider)
        .findForDesk(_reference.text);
    String? name;
    if (r case Ok(:final value)) {
      name = (await ref.read(patientRepositoryProvider).byId(value.patientId))
          .valueOrNull
          ?.user
          .fullName;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (r) {
        case Ok(:final value):
          _found = value;
          _foundPatient = name;
        case Err(:final failure):
          _error = failure.message;
      }
    });
  }

  /// Plain status for the found copy; only a valid, ready copy can be
  /// confirmed.
  (String, PatientAccent, bool) _status(IssuedDocument d) {
    if (d.validity != DocumentValidity.valid) {
      return (
        workText(context, 'Revoked or no longer valid', 'ملغى أو غير صالح'),
        PatientAccent.red,
        false,
      );
    }
    return switch (d.renderStatus) {
      DocumentRenderStatus.ready => (
        workText(context, 'Issued', 'صادر'),
        PatientAccent.green,
        true,
      ),
      DocumentRenderStatus.failed => (
        workText(context, 'Rendering failed', 'فشل إنشاء الملف'),
        PatientAccent.red,
        false,
      ),
      _ => (
        workText(context, 'Rendering pending', 'إنشاء الملف قيد الانتظار'),
        PatientAccent.amber,
        false,
      ),
    };
  }

  @override
  void dispose() {
    _reference.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref
        .read(documentServiceProvider)
        .confirmIssuedCopy(
          _found!.id,
          recipientIdentityChecked: _identityChecked,
          reason: _reason.text,
          idempotencyKey: _key.value,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (r) {
        case Ok(:final value):
          _done = value;
        case Err(:final failure):
          _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Space.md,
        right: Space.md,
        top: Space.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              workText(context, 'Confirm issued copy', 'تأكيد نسخة صادرة'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.xs),
            Text(
              workText(
                context,
                'Checks that the document is issued, not revoked, and that the stored copy is intact. '
                    'It does not sign, approve or change the document. Drafts awaiting clinical signature cannot be confirmed.',
                'يتحقق من أن المستند صادر وغير ملغى وأن النسخة المحفوظة سليمة. '
                    'لا يوقّع المستند أو يعتمده أو يغيّره. لا يمكن تأكيد المسودات التي تنتظر التوقيع السريري.',
              ),
            ),
            if (_done != null) ...[
              const SizedBox(height: Space.md),
              InlineBanner.info(
                workText(
                  context,
                  'Copy confirmed ${fmtDate(_done!)} ${fmtTime(_done!)}. Recorded with your name.',
                  'تم تأكيد النسخة ${fmtDate(_done!)} ${fmtTime(_done!)}. سُجّل باسمك.',
                ),
              ),
              const SizedBox(height: Space.md),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(workText(context, 'Done', 'تم')),
              ),
            ] else ...[
              const SizedBox(height: Space.md),
              TextField(
                controller: _reference,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => unawaited(_lookUp()),
                onChanged: (_) {
                  if (_found != null) setState(() => _found = null);
                },
                decoration: InputDecoration(
                  labelText: workText(
                    context,
                    'Document reference (printed / QR code)',
                    'مرجع المستند (المطبوع / رمز QR)',
                  ),
                  suffixIcon: IconButton(
                    tooltip: workText(context, 'Look up', 'بحث'),
                    icon: const Icon(Icons.search),
                    onPressed: () => unawaited(_lookUp()),
                  ),
                ),
              ),
              if (_found case final d?) ...[
                const SizedBox(height: Space.sm),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DocumentRules.title(
                          d.documentType,
                          arabic:
                              Localizations.localeOf(context).languageCode ==
                              'ar',
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_foundPatient != null) Text(_foundPatient!),
                      Text(
                        '${workText(context, 'Issued', 'صدر')} ${d.issuedAt == null ? '' : fmtDate(d.issuedAt!)} · ${d.verificationCode}',
                      ),
                      const SizedBox(height: Space.xs),
                      StatusBadge(_status(d).$1, accent: _status(d).$2),
                    ],
                  ),
                ),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _identityChecked,
                onChanged: (v) => setState(() => _identityChecked = v ?? false),
                title: Text(
                  workText(
                    context,
                    "Recipient's identity checked",
                    'تم التحقق من هوية المستلم',
                  ),
                ),
              ),
              TextField(
                controller: _reason,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: workText(
                    context,
                    'Reason (e.g. collected at desk)',
                    'السبب (مثل: استلام من الاستقبال)',
                  ),
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: Space.sm),
              PrimaryActionButton(
                label: workText(
                  context,
                  'Verify and confirm copy',
                  'تحقق وأكّد النسخة',
                ),
                busy: _busy,
                onPressed: _busy || _found == null || !_status(_found!).$3
                    ? null
                    : () => unawaited(_submit()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pharmacy
// ---------------------------------------------------------------------------

final pharmacyStockProvider = FutureProvider.autoDispose<List<StockBatch>>(
  (ref) async => _unwrap(await ref.watch(pharmacyRepositoryProvider).stock()),
);

final pharmacyQueueProvider = FutureProvider.autoDispose<List<PharmacyOrder>>(
  (ref) async => _unwrap(await ref.watch(pharmacyRepositoryProvider).queue()),
);

String pharmacyOutcomeLabel(BuildContext c, DispenseOutcome? o) => switch (o) {
  null => workText(c, 'Awaiting review', 'بانتظار المراجعة'),
  DispenseOutcome.dispensed => workText(c, 'Dispensed', 'تم الصرف'),
  DispenseOutcome.partial => workText(c, 'Partly supplied', 'صُرف جزئيًا'),
  DispenseOutcome.held => workText(c, 'On hold', 'معلّق'),
  DispenseOutcome.clarificationRequested => workText(
    c,
    'Clarification requested',
    'طُلب توضيح',
  ),
};

PatientAccent pharmacyOutcomeAccent(DispenseOutcome? o) => switch (o) {
  null => PatientAccent.blue,
  DispenseOutcome.dispensed => PatientAccent.green,
  DispenseOutcome.partial ||
  DispenseOutcome.held ||
  DispenseOutcome.clarificationRequested => PatientAccent.amber,
};

class DispenseSheet extends ConsumerStatefulWidget {
  const DispenseSheet({required this.order, super.key});

  final PharmacyOrder order;

  @override
  ConsumerState<DispenseSheet> createState() => _DispenseState();
}

class _DispenseState extends ConsumerState<DispenseSheet> {
  final _key = IdempotencyKey.generate();
  final _quantity = TextEditingController();
  final _note = TextEditingController();
  final _units = TextEditingController();
  DispenseOutcome _outcome = DispenseOutcome.dispensed;
  StockBatch? _stock;
  bool _verified = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _units.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final supplying =
        _outcome == DispenseOutcome.dispensed ||
        _outcome == DispenseOutcome.partial;
    final r = await ref
        .read(pharmacyRepositoryProvider)
        .record(
          DispenseInput(
            medicationId: widget.order.medicationId,
            outcome: _outcome,
            patientVerified: _verified,
            idempotencyKey: _key.value,
            quantity: _quantity.text,
            note: _note.text,
            stockBatchId: supplying ? _stock?.id : null,
            units: !supplying || _stock == null
                ? null
                : int.tryParse(_units.text.trim()),
          ),
        );
    if (!mounted) return;
    switch (r) {
      case Ok():
        ref
          ..invalidate(pharmacyQueueProvider)
          ..invalidate(pharmacyStockProvider)
          ..invalidate(workforceDataProvider('home'))
          ..invalidate(workforceDataProvider('dispensing-history'))
          ..invalidate(workforceDataProvider('clarifications'));
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              workText(
                context,
                'Pharmacy outcome recorded.',
                'تم تسجيل نتيجة الصيدلية.',
              ),
            ),
          ),
        );
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final supplying =
        _outcome == DispenseOutcome.dispensed ||
        _outcome == DispenseOutcome.partial;
    return Padding(
      padding: EdgeInsets.only(
        left: Space.md,
        right: Space.md,
        top: Space.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(o.name, style: Theme.of(context).textTheme.titleLarge),
            Text(
              o.orderedUnits == null
                  ? workText(
                      context,
                      'Ordered quantity not recorded — verify with the prescriber.',
                      'الكمية المطلوبة غير مسجلة — تحقق مع الواصف.',
                    )
                  : workText(
                      context,
                      'Ordered quantity: ${o.orderedUnits} whole units',
                      'الكمية المطلوبة: ${o.orderedUnits} وحدات كاملة',
                    ),
            ),
            if (o.clarificationPending)
              Text(
                workText(
                  context,
                  'Unresolved clarification. Supply remains blocked until the responsible prescriber responds.',
                  'استيضاح غير محسوم. يظل الصرف محظوراً حتى يرد الواصف المسؤول.',
                ),
              ),
            Text('${o.patientName} · ${clinicianName(o.prescriberName)}'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _verified,
              onChanged: (v) => setState(() => _verified = v ?? false),
              title: Text(
                workText(
                  context,
                  'Patient identity and order verified',
                  'تم التحقق من هوية المريض والطلب',
                ),
              ),
            ),
            DropdownButtonFormField<DispenseOutcome>(
              initialValue: _outcome,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: workText(context, 'Outcome', 'النتيجة'),
              ),
              items: [
                for (final v in DispenseOutcome.values)
                  DropdownMenuItem(
                    value: v,
                    child: Text(pharmacyOutcomeLabel(context, v)),
                  ),
              ],
              onChanged: (v) => setState(() => _outcome = v ?? _outcome),
            ),
            if (supplying) ...[
              TextField(
                controller: _quantity,
                decoration: InputDecoration(
                  labelText: workText(
                    context,
                    'Quantity supplied',
                    'الكمية المصروفة',
                  ),
                ),
              ),
              ...() {
                final now = DateTime.now();
                final usable = [
                  for (final b
                      in ref.watch(pharmacyStockProvider).valueOrNull ??
                          const <StockBatch>[])
                    if (b.matches(o.name) &&
                        !b.isExpired(now) &&
                        b.quantity > 0)
                      b,
                ];
                if (usable.isEmpty)
                  return <Widget>[
                    Text(
                      workText(
                        context,
                        'No matching unexpired stock is available. Receive stock or record a hold.',
                        '\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u062e\u0632\u0648\u0646 \u0645\u0637\u0627\u0628\u0642 \u0648\u0633\u0627\u0631\u064d.',
                      ),
                    ),
                  ];
                return <Widget>[
                  DropdownButtonFormField<String?>(
                    initialValue: _stock?.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: workText(
                        context,
                        'Supply from stock batch',
                        'الصرف من دفعة المخزون',
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        child: Text(
                          workText(
                            context,
                            'Choose a recorded stock batch',
                            'اختر دفعة مخزون مسجلة',
                          ),
                        ),
                      ),
                      for (final b in usable)
                        DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            '${b.batch} · ${b.quantity} ${b.unit} · ${fmtDate(b.expiry)}',
                          ),
                        ),
                    ],
                    onChanged: (id) => setState(
                      () => _stock = id == null
                          ? null
                          : usable.firstWhere((b) => b.id == id),
                    ),
                  ),
                  if (_stock != null)
                    TextField(
                      controller: _units,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: workText(
                          context,
                          'Units taken from this batch',
                          'الوحدات المأخوذة من هذه الدفعة',
                        ),
                      ),
                    ),
                ];
              }(),
            ],
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: _outcome == DispenseOutcome.dispensed
                    ? workText(context, 'Note (optional)', 'ملاحظة (اختياري)')
                    : workText(context, 'Reason (required)', 'السبب (مطلوب)'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: Space.md),
            PrimaryActionButton(
              label: workText(context, 'Record', 'تسجيل'),
              busy: _busy,
              onPressed: _verified && !_busy
                  ? () => unawaited(_submit())
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unknown role
// ---------------------------------------------------------------------------

class UnassignedRoleWorkspace extends ConsumerWidget {
  const UnassignedRoleWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return AppScaffold(
      title: user?.fullName ?? '',
      actions: const [StaffTopActions()],
      children: [
        PatientStateView(
          kind: PatientStateKind.unavailable,
          title: workText(
            context,
            'Your staff role is not set up',
            'لم يتم إعداد دورك الوظيفي',
          ),
          message: workText(
            context,
            'Ask an administrator to assign your role (doctor, nurse, receptionist, pharmacist or dentist). '
                'Patient and clinical tools stay unavailable until then.',
            'اطلب من المسؤول تعيين دورك (طبيب، ممرض، موظف استقبال، صيدلي أو طبيب أسنان). '
                'تبقى أدوات المرضى والأدوات السريرية غير متاحة حتى ذلك الحين.',
          ),
        ),
      ],
    );
  }
}

/// Records a received batch (item, batch number, expiry, quantity).
class ReceiveStockSheet extends ConsumerStatefulWidget {
  const ReceiveStockSheet({super.key});

  @override
  ConsumerState<ReceiveStockSheet> createState() => _ReceiveStockState();
}

class _ReceiveStockState extends ConsumerState<ReceiveStockSheet> {
  final _key = IdempotencyKey.generate();
  final _item = TextEditingController();
  final _batch = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'tablets');
  DateTime? _expiry;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_item, _batch, _quantity, _unit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantity.text.trim());
    if (_busy) return;
    if (_expiry == null || quantity == null) {
      setState(
        () => _error = workText(
          context,
          'Enter a whole-number quantity and choose the expiry date.',
          'أدخل كمية بعدد صحيح واختر تاريخ الانتهاء.',
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref
        .read(pharmacyRepositoryProvider)
        .receive(
          ReceiveStockInput(
            itemName: _item.text,
            batch: _batch.text,
            expiry: _expiry!,
            quantity: quantity,
            unit: _unit.text,
            idempotencyKey: _key.value,
          ),
        );
    if (!mounted) return;
    switch (r) {
      case Ok():
        ref.invalidate(pharmacyStockProvider);
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Space.md,
        right: Space.md,
        top: Space.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              workText(context, 'Receive stock', 'استلام مخزون'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _item,
              decoration: InputDecoration(
                labelText: workText(context, 'Item name', 'اسم الصنف'),
              ),
            ),
            TextField(
              controller: _batch,
              decoration: InputDecoration(
                labelText: workText(context, 'Batch number', 'رقم الدفعة'),
              ),
            ),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: workText(context, 'Quantity', 'الكمية'),
              ),
            ),
            TextField(
              controller: _unit,
              decoration: InputDecoration(
                labelText: workText(context, 'Unit', 'الوحدة'),
              ),
            ),
            const SizedBox(height: Space.xs),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _expiry == null
                    ? workText(context, 'Expiry date', 'تاريخ الانتهاء')
                    : fmtDate(_expiry!),
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 180)),
                  firstDate: now.add(const Duration(days: 1)),
                  lastDate: now.add(const Duration(days: 365 * 10)),
                );
                if (picked != null && mounted) {
                  setState(() => _expiry = picked);
                }
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: Space.md),
            PrimaryActionButton(
              label: workText(context, 'Record batch', 'تسجيل الدفعة'),
              busy: _busy,
              onPressed: _busy ? null : () => unawaited(_submit()),
            ),
          ],
        ),
      ),
    );
  }
}
