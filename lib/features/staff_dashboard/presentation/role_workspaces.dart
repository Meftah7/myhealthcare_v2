/// Today workspaces for staff roles without clinical chart access:
/// receptionist (front desk), pharmacist, and an unassigned/unknown role.
///
/// Doctors, dentists and nurses keep the clinical [StaffDashboardScreen].
/// Every action here is re-authorized by its repository; these screens only
/// decide what to offer.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimens.dart';
import '../../../app/theme/patient_palette.dart';
import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/result.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
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

String _failureText(Object e) => e is Exception || e is Error
    ? e.toString()
    : (e as dynamic).message as String? ?? '$e';

// ---------------------------------------------------------------------------
// Front desk
// ---------------------------------------------------------------------------

/// Today's clinic visits that can still be checked in, with patient names.
final deskArrivalsProvider =
    FutureProvider.autoDispose<List<(Appointment, String)>>((ref) async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final visits =
          _unwrap(
            await ref
                .watch(appointmentRepositoryProvider)
                .inRange(start, start.add(const Duration(days: 1))),
          ).where(
            (a) =>
                a.status == AppointmentStatus.booked ||
                a.status == AppointmentStatus.confirmed,
          );
      final patients = ref.watch(patientRepositoryProvider);
      final names = <String, String>{};
      final out = <(Appointment, String)>[];
      for (final a in visits) {
        names[a.patientId] ??=
            (await patients.byId(a.patientId)).valueOrNull?.user.fullName ?? '';
        out.add((a, names[a.patientId]!));
      }
      return out;
    });

class FrontDeskWorkspace extends ConsumerStatefulWidget {
  const FrontDeskWorkspace({super.key});

  @override
  ConsumerState<FrontDeskWorkspace> createState() => _FrontDeskState();
}

class _FrontDeskState extends ConsumerState<FrontDeskWorkspace> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  Future<Result<List<Patient>>>? _search;
  final _checkingIn = <String>{};

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _query.text.trim();
    if (q.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            workText(
              context,
              'Enter at least 3 characters of the CPR / ID, name or phone.',
              'أدخل ٣ أحرف على الأقل من الرقم الشخصي أو الاسم أو الهاتف.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _search = ref.read(patientRepositoryProvider).search(q));
  }

  Future<void> _checkIn(Appointment a) async {
    if (_checkingIn.contains(a.id)) return;
    setState(() => _checkingIn.add(a.id));
    final r = await ref
        .read(appointmentRepositoryProvider)
        .deskCheckIn(a.id, at: DateTime.now(), expectedVersion: a.version);
    if (!mounted) return;
    setState(() => _checkingIn.remove(a.id));
    final messenger = ScaffoldMessenger.of(context);
    switch (r) {
      case Ok():
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              workText(context, 'Arrival confirmed.', 'تم تأكيد الوصول.'),
            ),
          ),
        );
        ref.invalidate(deskArrivalsProvider);
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        ref.invalidate(deskArrivalsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final arrivals = ref.watch(deskArrivalsProvider);
    return AppScaffold(
      heroOverline: workText(context, 'Front desk', 'الاستقبال'),
      title: user?.fullName ?? '',
      actions: const [StaffTopActions()],
      onRefresh: () async => ref.invalidate(deskArrivalsProvider),
      children: [
        GradientHeroCard(
          icon: Icons.badge_outlined,
          title: workText(context, 'Find a patient', 'ابحث عن مريض'),
          subtitle: workText(
            context,
            'Search by CPR / ID, name or phone, confirm identity, then book or check in.',
            'ابحث بالرقم الشخصي أو الاسم أو الهاتف، وتحقق من الهوية، ثم احجز أو سجّل الوصول.',
          ),
          onTap: _focus.requestFocus,
        ),
        const SizedBox(height: Space.md),
        TextField(
          key: const ValueKey('desk-search'),
          controller: _query,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _runSearch(),
          decoration: InputDecoration(
            labelText: workText(
              context,
              'CPR / ID, name or phone',
              'الرقم الشخصي أو الاسم أو الهاتف',
            ),
            suffixIcon: IconButton(
              tooltip: workText(context, 'Search', 'بحث'),
              icon: const Icon(Icons.search),
              onPressed: _runSearch,
            ),
          ),
        ),
        if (_search != null)
          FutureBuilder<Result<List<Patient>>>(
            future: _search,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(Space.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return switch (snap.data!) {
                Err(:final failure) => PatientStateView(
                  kind: PatientStateKind.error,
                  message: failure.message,
                  actionLabel: workText(context, 'Retry', 'إعادة المحاولة'),
                  onAction: _runSearch,
                ),
                Ok(:final value) when value.isEmpty => PatientStateView(
                  kind: PatientStateKind.empty,
                  message: workText(
                    context,
                    'No patient matches. Check the number or try the full name.',
                    'لا يوجد مريض مطابق. تحقق من الرقم أو جرّب الاسم الكامل.',
                  ),
                ),
                Ok(:final value) => Column(
                  children: [
                    for (final p in value)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: SurfaceCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const IconTile(icon: Icons.person_outline),
                            title: Text(p.user.fullName),
                            subtitle: Text(
                              [
                                if (p.user.nationalId != null)
                                  p.user.nationalId!,
                                if (p.user.dob != null) fmtDate(p.user.dob!),
                              ].join(' · '),
                            ),
                            trailing: FilledButton(
                              onPressed: () => unawaited(
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) => DeskBookingSheet(patient: p),
                                ),
                              ),
                              child: Text(workText(context, 'Book', 'احجز')),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              };
            },
          ),
        const SizedBox(height: Space.lg),
        SectionHeading(
          workText(context, "Today's arrivals", 'وصول اليوم'),
          subtitle: workText(
            context,
            'Confirm arrival only after checking identity at the desk.',
            'أكّد الوصول فقط بعد التحقق من الهوية في الاستقبال.',
          ),
        ),
        arrivals.when(
          loading: () => const PatientStateView(kind: PatientStateKind.loading),
          error: (e, _) => PatientStateView(
            kind: PatientStateKind.error,
            message: _failureText(e),
            actionLabel: workText(context, 'Retry', 'إعادة المحاولة'),
            onAction: () => ref.invalidate(deskArrivalsProvider),
          ),
          data: (list) => list.isEmpty
              ? PatientStateView(
                  kind: PatientStateKind.empty,
                  message: workText(
                    context,
                    'No more visits to check in today.',
                    'لا توجد زيارات أخرى لتسجيل وصولها اليوم.',
                  ),
                )
              : Column(
                  children: [
                    for (final (a, name) in list)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: SurfaceCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${fmtTime(a.slotStart)} · $name',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    if (a.ticketTag != null) Text(a.ticketTag!),
                                  ],
                                ),
                              ),
                              if (a.checkedInAt != null)
                                StatusBadge(
                                  workText(context, 'Arrived', 'وصل'),
                                  accent: PatientAccent.green,
                                  icon: Icons.check,
                                )
                              else
                                OutlinedButton(
                                  onPressed: _checkingIn.contains(a.id)
                                      ? null
                                      : () => unawaited(_checkIn(a)),
                                  child: Text(
                                    workText(
                                      context,
                                      'Mark arrived',
                                      'تسجيل الوصول',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Space.lg),
        SectionHeading(workText(context, 'Documents', 'المستندات')),
        SurfaceCard(
          onTap: () => unawaited(
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const ConfirmCopySheet(),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconTile(icon: Icons.verified_outlined),
            title: Text(
              workText(context, 'Confirm issued copy', 'تأكيد نسخة صادرة'),
            ),
            subtitle: Text(
              workText(
                context,
                'Administrative check of an already issued document. Not a clinical signature.',
                'تحقق إداري من مستند صادر مسبقًا. ليس توقيعًا سريريًا.',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}

/// Books one visit for [patient] at the front desk: department → clinician
/// → day → an actually open slot → visit type → review → submit.
class DeskBookingSheet extends ConsumerStatefulWidget {
  const DeskBookingSheet({required this.patient, super.key});

  final Patient patient;

  @override
  ConsumerState<DeskBookingSheet> createState() => _DeskBookingState();
}

class _DeskBookingState extends ConsumerState<DeskBookingSheet> {
  // One key per sheet: a retry after a lost response books once.
  final _key = IdempotencyKey.generate();
  bool _identityChecked = false;
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
          ref.invalidate(deskArrivalsProvider);
        case Err(:final failure):
          // Inputs stay; a taken slot is refreshed so another can be chosen.
          _error = failure.message;
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
                    '${workText(context, 'Reference', 'المرجع')}: ${booked.id}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.md),
                  FilledButton(
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
                    error: (e, _) => Text(_failureText(e)),
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
                      error: (e, _) => Text(_failureText(e)),
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
          _reference.text.trim(),
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
                decoration: InputDecoration(
                  labelText: workText(
                    context,
                    'Document reference',
                    'مرجع المستند',
                  ),
                ),
              ),
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
                onPressed: _busy ? null : () => unawaited(_submit()),
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

final pharmacyQueueProvider = FutureProvider.autoDispose<List<PharmacyOrder>>(
  (ref) async => _unwrap(await ref.watch(pharmacyRepositoryProvider).queue()),
);

String _outcomeLabel(BuildContext c, DispenseOutcome? o) => switch (o) {
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

PatientAccent _outcomeAccent(DispenseOutcome? o) => switch (o) {
  null => PatientAccent.blue,
  DispenseOutcome.dispensed => PatientAccent.green,
  DispenseOutcome.partial ||
  DispenseOutcome.held ||
  DispenseOutcome.clarificationRequested => PatientAccent.amber,
};

class PharmacyWorkspace extends ConsumerWidget {
  const PharmacyWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final queue = ref.watch(pharmacyQueueProvider);
    final waiting = queue.valueOrNull?.where((o) => !o.isDispensed).length;
    return AppScaffold(
      heroOverline: workText(context, 'Pharmacy', 'الصيدلية'),
      title: user?.fullName ?? '',
      actions: const [StaffTopActions()],
      onRefresh: () async => ref.invalidate(pharmacyQueueProvider),
      children: [
        GradientHeroCard(
          icon: Icons.medication_outlined,
          title: workText(context, 'Prescription queue', 'قائمة الوصفات'),
          subtitle: waiting == null
              ? workText(context, 'Loading orders…', 'جارٍ تحميل الطلبات…')
              : workText(
                  context,
                  '$waiting order(s) not yet fully dispensed. Verify the patient and order before supplying.',
                  '$waiting طلب لم يُصرف بالكامل بعد. تحقق من المريض والطلب قبل الصرف.',
                ),
        ),
        const SizedBox(height: Space.lg),
        SectionHeading(workText(context, 'Orders', 'الطلبات')),
        queue.when(
          loading: () => const PatientStateView(kind: PatientStateKind.loading),
          error: (e, _) => PatientStateView(
            kind: PatientStateKind.error,
            message: _failureText(e),
            actionLabel: workText(context, 'Retry', 'إعادة المحاولة'),
            onAction: () => ref.invalidate(pharmacyQueueProvider),
          ),
          data: (orders) => orders.isEmpty
              ? PatientStateView(
                  kind: PatientStateKind.empty,
                  message: workText(
                    context,
                    'No active prescriptions.',
                    'لا توجد وصفات نشطة.',
                  ),
                )
              : Column(
                  children: [
                    for (final o in orders)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: Space.xs,
                                runSpacing: Space.xxs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    o.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  StatusBadge(
                                    _outcomeLabel(context, o.lastOutcome),
                                    accent: _outcomeAccent(o.lastOutcome),
                                  ),
                                ],
                              ),
                              Text(
                                [
                                  o.dose,
                                  o.frequency,
                                ].whereType<String>().join(' · '),
                              ),
                              Text(
                                '${workText(context, 'Patient', 'المريض')}: ${o.patientName}',
                              ),
                              Text(
                                '${workText(context, 'Prescribed by', 'وصفها')} ${clinicianName(o.prescriberName)} · ${fmtDate(o.startDate)}',
                                style: TextStyle(
                                  color: PatientPalette.of(context).textMuted,
                                ),
                              ),
                              const SizedBox(height: Space.xs),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: OutlinedButton(
                                  onPressed: o.isDispensed
                                      ? null
                                      : () => unawaited(
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            builder: (_) =>
                                                DispenseSheet(order: o),
                                          ),
                                        ),
                                  child: Text(
                                    workText(
                                      context,
                                      'Record outcome',
                                      'تسجيل النتيجة',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Space.lg),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureWorkBadge(
                label: workText(context, 'Future work', 'عمل مستقبلي'),
              ),
              const SizedBox(height: Space.xs),
              Text(
                workText(
                  context,
                  'Stock levels, barcode scanning and automatic expiry alerts are not part of this release. '
                      'Batch and expiry entered here are recorded with the dispensing record only.',
                  'مستويات المخزون ومسح الباركود وتنبيهات انتهاء الصلاحية التلقائية ليست ضمن هذا الإصدار. '
                      'تُسجّل الدفعة وتاريخ الانتهاء المدخلة هنا مع سجل الصرف فقط.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DispenseSheet extends ConsumerStatefulWidget {
  const DispenseSheet({required this.order, super.key});

  final PharmacyOrder order;

  @override
  ConsumerState<DispenseSheet> createState() => _DispenseState();
}

class _DispenseState extends ConsumerState<DispenseSheet> {
  final _key = IdempotencyKey.generate();
  final _quantity = TextEditingController();
  final _batch = TextEditingController();
  final _note = TextEditingController();
  DispenseOutcome _outcome = DispenseOutcome.dispensed;
  DateTime? _expiry;
  bool _verified = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _batch.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref
        .read(pharmacyRepositoryProvider)
        .record(
          DispenseInput(
            medicationId: widget.order.medicationId,
            outcome: _outcome,
            patientVerified: _verified,
            idempotencyKey: _key.value,
            quantity: _quantity.text,
            batch: _batch.text,
            expiry: _expiry,
            note: _note.text,
          ),
        );
    if (!mounted) return;
    switch (r) {
      case Ok():
        ref.invalidate(pharmacyQueueProvider);
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
                    child: Text(_outcomeLabel(context, v)),
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
              TextField(
                controller: _batch,
                decoration: InputDecoration(
                  labelText: workText(
                    context,
                    'Batch (optional)',
                    'رقم الدفعة (اختياري)',
                  ),
                ),
              ),
              const SizedBox(height: Space.xs),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _expiry == null
                      ? workText(
                          context,
                          'Expiry date (optional)',
                          'تاريخ الانتهاء (اختياري)',
                        )
                      : fmtDate(_expiry!),
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiry ?? now.add(const Duration(days: 30)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365 * 10)),
                  );
                  if (picked != null && mounted) {
                    setState(() => _expiry = picked);
                  }
                },
              ),
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
