/// Booking discovery (approved blue rebuild): a full-screen "Book Appointment"
/// landing with a General / Virtual Care segment, Clinic · Doctor · Region
/// discovery rows, a help panel with the assistance sheet, and the search
/// pages behind each row. Every path ends in the existing booking wizard
/// (`continueToBooking`), which owns slots, review and confirmation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../service_catalog/application/catalog_dispatcher.dart';
import '../application/booking_providers.dart';
import '../application/discovery_providers.dart';

enum BookingLandingMode { general, virtual }

AppBar _patientAppBar(BuildContext context, String title) => AppBar(
  title: Text(title),
  leading: BackButton(
    onPressed: () =>
        context.canPop() ? context.pop() : context.go(AppRoutes.patientHome),
  ),
);

class BookAppointmentLandingScreen extends StatefulWidget {
  const BookAppointmentLandingScreen({
    this.initialMode = BookingLandingMode.general,
    super.key,
  });

  final BookingLandingMode initialMode;

  @override
  State<BookAppointmentLandingScreen> createState() =>
      _BookAppointmentLandingScreenState();
}

class _BookAppointmentLandingScreenState
    extends State<BookAppointmentLandingScreen> {
  late BookingLandingMode _mode = widget.initialMode;
  final _helpKey = GlobalKey();

  @override
  void didUpdateWidget(BookAppointmentLandingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Navigating to the same page with another `?mode=` switches the tab.
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PatientPageScaffold(
      appBar: _patientAppBar(context, t.paBookAppointment),
      children: [
        BookingModeSegment<BookingLandingMode>(
          options: [
            (
              BookingLandingMode.general,
              t.paGeneralBooking,
              Icons.local_hospital_outlined,
            ),
            (
              BookingLandingMode.virtual,
              '${t.paVirtualCare} · ${t.paFutureWork}',
              Icons.video_camera_front_outlined,
            ),
          ],
          selected: _mode,
          onSelected: (m) => setState(() => _mode = m),
        ),
        const SizedBox(height: Space.lg),
        if (_mode == BookingLandingMode.general) ...[
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                DiscoveryOptionRow(
                  key: const ValueKey('discover-clinic'),
                  icon: Icons.local_hospital_outlined,
                  title: t.paClinic,
                  hint: t.paTapToSelect,
                  onTap: () => context.push(AppRoutes.patientFindClinic),
                ),
                const Divider(indent: Space.md, endIndent: Space.md),
                DiscoveryOptionRow(
                  key: const ValueKey('discover-doctor'),
                  icon: Icons.person_search_outlined,
                  title: t.doctorLabel,
                  hint: t.paTapToSelect,
                  accent: PatientAccent.green,
                  onTap: () => context.push(AppRoutes.patientFindDoctor),
                ),
                const Divider(indent: Space.md, endIndent: Space.md),
                DiscoveryOptionRow(
                  key: const ValueKey('discover-region'),
                  icon: Icons.place_outlined,
                  title: t.paRegion,
                  hint: t.paTapToSelect,
                  accent: PatientAccent.amber,
                  onTap: () => context.push(AppRoutes.patientFindRegion),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          HelpChoosingCard(
            key: _helpKey,
            onTap: () => showAssistanceSheet(context),
          ),
        ] else
          const _VirtualCarePanel(),
      ],
    );
  }
}

/// "Need help choosing?" panel with the blue arrow.
class HelpChoosingCard extends StatelessWidget {
  const HelpChoosingCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return SurfaceCard(
      onTap: onTap,
      color: palette.softAccent,
      semanticLabel: t.paNeedHelpTitle,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReadableLabel(
                  t.paNeedHelpTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                ReadableLabel(
                  t.paNeedHelpBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.action,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_back
                  : Icons.arrow_forward,
              color: palette.onAction,
            ),
          ),
        ],
      ),
    );
  }
}

/// The assistance sheet. Dismissing it leaves any draft untouched; the modal
/// route returns focus to the trigger when it closes.
Future<void> showAssistanceSheet(BuildContext context) async {
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      final t = AppLocalizations.of(sheet)!;
      final theme = Theme.of(sheet);
      final palette = PatientPalette.of(sheet);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kPatientInset,
            0,
            kPatientInset,
            Space.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: IconTile(icon: Icons.support_agent_outlined, size: 56),
              ),
              const SizedBox(height: Space.md),
              ReadableLabel(
                t.paNeedHelpTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                t.paAssistanceBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: Space.lg),
              PrimaryActionButton(
                label: t.paYesPlease,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
              const SizedBox(height: Space.sm),
              SoftActionButton(
                label: t.paNoThanks,
                onPressed: () => Navigator.of(sheet).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (accepted == true && context.mounted) {
    await context.push(AppRoutes.patientSpecialtyGuide);
  }
}

class _VirtualCarePanel extends ConsumerWidget {
  const _VirtualCarePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final rows = [
      (Icons.forum_outlined, PatientAccent.blue, t.paVc1Title, t.paVc1Body),
      (Icons.add_home_outlined, PatientAccent.green, t.paVc2Title, t.paVc2Body),
      (
        Icons.description_outlined,
        PatientAccent.amber,
        t.paVc3Title,
        t.paVc3Body,
      ),
      (
        Icons.video_camera_front_outlined,
        PatientAccent.neutral,
        t.paVc4Title,
        t.paVc4Body,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PatientPageTitle(t.paVirtualCare, subtitle: t.paVirtualCareIntro),
        const SizedBox(height: Space.xs),
        // Outside the proposal: Virtual Care is future work until a supported
        // integration exists; the rows below describe what works today.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FutureWorkBadge(label: t.paFutureWork),
        ),
        const SizedBox(height: Space.md),
        for (final (icon, accent, title, body) in rows) ...[
          SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: icon, accent: accent),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReadableLabel(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ReadableLabel(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
        ],
        const SizedBox(height: Space.sm),
        PrimaryActionButton(
          label: t.paMessageCareTeam,
          onPressed: () => context.go(AppRoutes.patientMessages),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery pages
// ---------------------------------------------------------------------------

/// Clinic departments of the MyHealth clinic (specialty departments, not
/// separate physical sites).
class ClinicSearchScreen extends ConsumerStatefulWidget {
  const ClinicSearchScreen({super.key});

  @override
  ConsumerState<ClinicSearchScreen> createState() => _ClinicSearchScreenState();
}

class _ClinicSearchScreenState extends ConsumerState<ClinicSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final departments = ref.watch(departmentsProvider);
    return PatientPageScaffold(
      appBar: _patientAppBar(context, t.paClinic),
      children: [
        ReadableLabel(
          t.paClinicExplainer,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: PatientPalette.of(context).textMuted,
          ),
        ),
        const SizedBox(height: Space.md),
        TextField(
          decoration: InputDecoration(
            labelText: t.paSearchClinics,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: Space.md),
        ...departments.when(
          loading: () => [
            const PatientStateView(kind: PatientStateKind.loading),
          ],
          error: (_, _) => [
            PatientStateView(
              kind: PatientStateKind.error,
              title: t.paLoadFailed,
              actionLabel: t.tryAgain,
              onAction: () => ref.invalidate(departmentsProvider),
            ),
          ],
          data: (list) {
            final shown = list
                .where((d) => d.name.toLowerCase().contains(_query))
                .toList();
            if (shown.isEmpty) {
              return [
                PatientStateView(
                  kind: PatientStateKind.empty,
                  title: t.paNoResults,
                ),
              ];
            }
            return [
              for (final d in shown) ...[
                _DepartmentCard(
                  department: d,
                  onTap: () => context.push(
                    Uri(
                      path: AppRoutes.patientFindDoctor,
                      queryParameters: {'dept': d.id},
                    ).toString(),
                  ),
                ),
                const SizedBox(height: Space.sm),
              ],
            ];
          },
        ),
      ],
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department, required this.onTap});

  final Department department;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return SurfaceCard(
      onTap: onTap,
      semanticLabel: department.name,
      child: Row(
        children: [
          const IconTile(icon: Icons.local_hospital_outlined),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReadableLabel(
                  department.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                if ((department.description ?? '').isNotEmpty)
                  ReadableLabel(
                    department.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            color: palette.textMuted,
          ),
        ],
      ),
    );
  }
}

/// Published clinician directory with name/specialty search and a department
/// filter.
class DoctorSearchScreen extends ConsumerStatefulWidget {
  const DoctorSearchScreen({this.departmentId, super.key});

  final String? departmentId;

  @override
  ConsumerState<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends ConsumerState<DoctorSearchScreen> {
  String _query = '';
  late String? _dept = widget.departmentId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final doctors = ref.watch(publicDoctorsProvider);
    final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
    final deptNames = {for (final d in departments) d.id: d.name};
    return PatientPageScaffold(
      appBar: _patientAppBar(context, t.paFindDoctor),
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: t.paSearchDoctors,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: Space.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(t.paAllDepartments),
                selected: _dept == null,
                onSelected: (_) => setState(() => _dept = null),
              ),
              for (final d in departments) ...[
                const SizedBox(width: Space.xs),
                ChoiceChip(
                  label: Text(d.name),
                  selected: _dept == d.id,
                  onSelected: (_) => setState(() => _dept = d.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        ...doctors.when(
          loading: () => [
            const PatientStateView(kind: PatientStateKind.loading),
          ],
          error: (_, _) => [
            PatientStateView(
              kind: PatientStateKind.error,
              title: t.paLoadFailed,
              actionLabel: t.tryAgain,
              onAction: () => ref.invalidate(publicDoctorsProvider),
            ),
          ],
          data: (list) {
            final shown = list.where((s) {
              if (_dept != null && s.departmentId != _dept) return false;
              if (_query.isEmpty) return true;
              final hay = [
                s.fullName,
                s.specialty ?? '',
                deptNames[s.departmentId] ?? '',
              ].join(' ').toLowerCase();
              return hay.contains(_query);
            }).toList();
            if (shown.isEmpty) {
              return [
                PatientStateView(
                  kind: PatientStateKind.empty,
                  title: t.paNoResults,
                ),
              ];
            }
            return [
              for (final s in shown) ...[
                _DoctorCard(
                  doctor: s,
                  departmentName: deptNames[s.departmentId],
                ),
                const SizedBox(height: Space.sm),
              ],
            ];
          },
        ),
      ],
    );
  }
}

class _DoctorCard extends ConsumerWidget {
  const _DoctorCard({required this.doctor, this.departmentName});

  final Staff doctor;
  final String? departmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final details = [
      ?doctor.specialty,
      ?departmentName,
    ].where((s) => s.isNotEmpty).join(' · ');
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: palette.softAccent,
                foregroundColor: palette.onSoftAccent,
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReadableLabel(
                      doctor.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    if (details.isNotEmpty)
                      ReadableLabel(
                        details,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    if (doctor.jobTitle != null)
                      ReadableLabel(
                        doctor.jobTitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          // Published visit mode vs. a planned one (never implies video).
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xxs,
            children: [
              StatusBadge(
                t.paInClinicVisits,
                accent: PatientAccent.blue,
                icon: Icons.local_hospital_outlined,
              ),
              StatusBadge(
                '${t.paVideoVisitsMode} · ${t.paFutureWork}',
                icon: Icons.videocam_off_outlined,
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          _AvailabilityLine(staffId: doctor.id),
          const SizedBox(height: Space.sm),
          PrimaryActionButton(
            label: t.paSeeAvailability,
            onPressed: () => continueToBooking(
              context,
              ref,
              departmentId: doctor.departmentId,
              staffId: doctor.id,
            ),
          ),
        ],
      ),
    );
  }
}

/// No regions/facility locations are configured in this build, so the page
/// says so instead of inventing locations.
class RegionSearchScreen extends StatelessWidget {
  const RegionSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PatientPageScaffold(
      appBar: _patientAppBar(context, t.paRegion),
      children: [
        PatientStateView(
          kind: PatientStateKind.unavailable,
          icon: Icons.place_outlined,
          title: t.paRegionUnavailableTitle,
          message: t.paRegionUnavailableBody,
          actionLabel: t.paChooseClinicInstead,
          onAction: () => context.pushReplacement(AppRoutes.patientFindClinic),
        ),
      ],
    );
  }
}

/// Specialty guidance: plain descriptions of each department so a patient
/// can pick where to book. This is information, not symptom triage.
class SpecialtyGuideScreen extends ConsumerWidget {
  const SpecialtyGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final palette = PatientPalette.of(context);
    final departments = ref.watch(departmentsProvider);
    return PatientPageScaffold(
      appBar: _patientAppBar(context, t.paSpecialtyGuideTitle),
      children: [
        ReadableLabel(
          t.paSpecialtyGuideIntro,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: Space.sm),
        SurfaceCard(
          color: palette.dangerContainer,
          onTap: () => showEmergencySheet(context),
          child: Row(
            children: [
              Icon(Icons.emergency_outlined, color: palette.danger),
              const SizedBox(width: Space.sm),
              Expanded(child: ReadableLabel(t.paSpecialtyEmergencyNote)),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        ...departments.when(
          loading: () => [
            const PatientStateView(kind: PatientStateKind.loading),
          ],
          error: (_, _) => [
            PatientStateView(
              kind: PatientStateKind.error,
              title: t.paLoadFailed,
              actionLabel: t.tryAgain,
              onAction: () => ref.invalidate(departmentsProvider),
            ),
          ],
          data: (list) => [
            for (final d in list) ...[
              _DepartmentCard(
                department: d,
                onTap: () => context.push(
                  Uri(
                    path: AppRoutes.patientFindDoctor,
                    queryParameters: {'dept': d.id},
                  ).toString(),
                ),
              ),
              const SizedBox(height: Space.sm),
            ],
          ],
        ),
      ],
    );
  }
}

/// The doctor's bounded availability summary, from the one batched
/// look-ahead. A summary, not a reservation.
class _AvailabilityLine extends ConsumerWidget {
  const _AvailabilityLine({required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: palette.textMuted);
    return ref
        .watch(doctorAvailabilityProvider)
        .when(
          loading: () => Row(
            children: [
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: Space.xs),
              Expanded(child: Text(t.paAvailabilityLoading, style: muted)),
            ],
          ),
          error: (_, _) => Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: palette.danger),
              const SizedBox(width: Space.xs),
              Expanded(child: Text(t.paAvailabilityError, style: muted)),
              TextButton(
                onPressed: () => ref.invalidate(doctorAvailabilityProvider),
                child: Text(t.tryAgain),
              ),
            ],
          ),
          data: (map) {
            final summary = map[staffId];
            final (IconData icon, String line, Color color) = switch (summary) {
              null => (
                Icons.help_outline,
                t.paAvailabilityUnknown,
                palette.textMuted,
              ),
              StaffAvailabilitySummary(hasSchedule: false) => (
                Icons.event_busy_outlined,
                t.paNoPublishedSchedule,
                palette.textMuted,
              ),
              StaffAvailabilitySummary(nextSlot: null) => (
                Icons.event_busy_outlined,
                t.paNoOpenTimes(summary.windowDays),
                palette.textMuted,
              ),
              final s => (
                Icons.event_available_outlined,
                t.paNextAvailable(
                  '${fmtRelativeDay(s.nextSlot!.start)} · ${fmtTime(s.nextSlot!.start)}',
                  s.openSlotCount,
                  s.windowDays,
                ),
                palette.success,
              ),
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 26),
                  child: Text(t.paAvailabilityNotGuaranteed, style: muted),
                ),
              ],
            );
          },
        );
  }
}
