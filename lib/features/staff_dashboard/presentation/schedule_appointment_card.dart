/// The appointment card on the staff schedule's day timeline.
///
/// The workflow actions live directly on the card — there is no popup — and
/// only the ones that apply to the current state are shown:
///
///   Booked / Called   Call patient · Arrived · Not arrived · Open chart
///   Arrived           Complete visit · Open chart
///   Not arrived       Arrived (undo) · Open chart
///   Completed         Open chart
///
/// "Call patient" pages the patient in over the clinic system (not a phone
/// call) and is repeatable — the card notes the last page. "Patient arrived"
/// and "Patient not arrived" flash a green ✓ / red ✕ (the booking-confirmation
/// motion) and keep the doctor on the schedule. "Complete visit" opens the
/// consultation page, where the visit is actually closed; the card flashes ✓
/// again when it returns as completed. "Open chart" is the only action that
/// navigates.
///
/// The card hugs its content, growing to fill the time slot when the visit is
/// long enough that its slot is taller than the content.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../consultation/application/consultation_providers.dart';
import '../application/staff_providers.dart';

/// Where an appointment sits in the doctor's workflow, collapsed from
/// [AppointmentStatus] + `calledInAt` into the five cases the card draws.
enum ScheduleCardState { booked, called, arrived, notArrived, done }

ScheduleCardState scheduleCardStateOf(Appointment a) => switch (a.status) {
  AppointmentStatus.completed || AppointmentStatus.cancelled =>
    ScheduleCardState.done,
  AppointmentStatus.inProgress => ScheduleCardState.arrived,
  AppointmentStatus.noShow => ScheduleCardState.notArrived,
  AppointmentStatus.booked || AppointmentStatus.confirmed =>
    a.wasCalledIn ? ScheduleCardState.called : ScheduleCardState.booked,
};

/// The height the day layout should reserve for a card's push-down maths — an
/// estimate of the content height (the real card sizes itself). When the
/// timeline is zoomed right out the card collapses to one compact row.
double scheduleCardEstimatedHeight(Appointment a, {required bool compact}) {
  if (compact) return 44;
  final state = scheduleCardStateOf(a);
  var h = 20.0 + 22 /* padding + name row */ + 22 /* badge + details row */;
  if (a.reasonText != null) h += 16;
  final hasInfo = switch (state) {
    ScheduleCardState.called || ScheduleCardState.arrived => true,
    ScheduleCardState.done => a.outcomeNote != null,
    _ => false,
  };
  if (hasInfo) h += 16;
  h += 9; // divider
  final buttonRows = state == ScheduleCardState.booked ||
          state == ScheduleCardState.called
      ? 2
      : 1;
  h += buttonRows * 40 + (buttonRows - 1) * 8;
  return h;
}

/// Below this many pixels-per-hour the day view is an overview, and cards drop
/// to a single compact row.
const double scheduleCompactBelow = 96;

enum _Flash { check, cross }

class ScheduleAppointmentCard extends ConsumerStatefulWidget {
  const ScheduleAppointmentCard({
    required this.appointment,
    this.compact = false,
    super.key,
  });

  final Appointment appointment;

  /// One-row overview form — name, badge and time only, no actions.
  final bool compact;

  @override
  ConsumerState<ScheduleAppointmentCard> createState() =>
      _ScheduleAppointmentCardState();
}

class _ScheduleAppointmentCardState
    extends ConsumerState<ScheduleAppointmentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashCtl;
  _Flash? _flash;
  bool _busy = false;

  Appointment get _a => widget.appointment;
  ConsultationController get _controller =>
      ref.read(consultationControllerProvider(_a.id));

  @override
  void initState() {
    super.initState();
    _flashCtl = AnimationController(
      vsync: this,
      duration: Motion.slow,
      reverseDuration: Motion.medium,
    );
  }

  @override
  void didUpdateWidget(ScheduleAppointmentCard old) {
    super.didUpdateWidget(old);
    // Completion happens on the consultation page, off this screen — flash the
    // green ✓ here when the card returns as `done`.
    final was = scheduleCardStateOf(old.appointment);
    final now = scheduleCardStateOf(_a);
    if (was != ScheduleCardState.done && now == ScheduleCardState.done) {
      unawaited(_playFlash(_Flash.check));
    }
  }

  @override
  void dispose() {
    _flashCtl.dispose();
    super.dispose();
  }

  Future<void> _playFlash(_Flash kind) async {
    if (!mounted || Motion.reduced(context)) return;
    setState(() => _flash = kind);
    await _flashCtl.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 640));
    if (!mounted) return;
    await _flashCtl.reverse();
    if (!mounted) return;
    setState(() => _flash = null);
  }

  Future<void> _run(
    Future<Result<void>> Function() action, {
    _Flash? flash,
    String? ok,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    if (flash != null) unawaited(_playFlash(flash));
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } else if (ok != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(ok)));
    }
  }

  void _call() => unawaited(
    _run(() async {
      final r = await _controller.callPatient();
      if (r.isOk) ref.read(scheduleCallLogProvider.notifier).bump(_a.id);
      return r;
    }, ok: 'Patient paged.'),
  );

  void _markArrived() => unawaited(
    _run(_controller.markArrived, flash: _Flash.check, ok: 'Patient arrived.'),
  );

  void _undoNotArrived() => unawaited(
    _run(
      () => _controller.markArrived(fromNoShow: true),
      flash: _Flash.check,
      ok: 'Moved to arrived.',
    ),
  );

  void _markNotArrived() => unawaited(
    _run(
      _controller.markNoShow,
      flash: _Flash.cross,
      ok: 'Marked as not arrived.',
    ),
  );

  void _openChart() => context.go(AppRoutes.staffPatientChart(_a.patientId));

  void _completeVisit() =>
      unawaited(context.push(AppRoutes.staffConsultation(_a.id)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = scheduleCardStateOf(_a);
    final pal = _CardPalette.of(context, state);
    final highlighted = ref.watch(scheduleHighlightIdProvider) == _a.id;
    final names =
        ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    final who = names[_a.patientId] ?? visitTypeLabel(_a.visitType);

    final border = Border.all(
      color: highlighted
          ? theme.colorScheme.primary
          : pal.fg.withValues(alpha: 0.22),
      width: highlighted ? 2 : 1,
    );

    if (widget.compact) {
      return _CompactCard(
        appointment: _a,
        who: who,
        state: state,
        palette: pal,
        border: border,
        highlighted: highlighted,
        onTap: _openChart,
      );
    }

    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.standard,
      decoration: BoxDecoration(
        color: pal.bg,
        borderRadius: Radii.cardSmall,
        border: border,
        boxShadow: highlighted
            ? Shadows.glow(theme.colorScheme.primary)
            : const <BoxShadow>[],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openChart,
              ),
            ),
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: 0,
              child: Container(width: 4, color: pal.bar),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Space.sm,
                Space.xs,
                Space.xs,
                Space.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          who,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: pal.fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Text(
                        '${fmtTime(_a.slotStart)} – ${fmtTime(_a.slotEnd)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: pal.subtle,
                          fontFeatures: kTabularFigures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StateBadge(state: state, appointment: _a),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            _detailLine(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: pal.subtle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_a.reasonText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _a.reasonText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: pal.subtle,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (_infoLine() case final info?) ...[
                    const SizedBox(height: 2),
                    Text(
                      info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: pal.bar,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.xs),
                  Container(height: 1, color: pal.fg.withValues(alpha: 0.16)),
                  const SizedBox(height: Space.xs),
                  // Swallow taps so a button press never opens the chart.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: [
                        for (final action in _actionsFor(state))
                          _CardButton(action: action, palette: pal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_flash != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _flashCtl,
                    builder: (context, _) =>
                        _FlashMark(kind: _flash!, t: _flashCtl.value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _detailLine() => [
    visitTypeLabel(_a.visitType),
    if (_a.roomNumber != null) 'Room ${_a.roomNumber}',
    if (_a.ticketTag != null) 'Ticket ${_a.ticketTag}',
  ].join(' · ');

  String? _infoLine() {
    switch (scheduleCardStateOf(_a)) {
      case ScheduleCardState.called:
        final entry = ref.watch(scheduleCallLogProvider)[_a.id];
        final count = entry?.count ?? 1;
        final at = entry?.at ?? _a.calledInAt;
        if (at == null) return null;
        return count == 1
            ? 'Called ${fmtTime(at)}'
            : 'Called ×$count · ${fmtTime(at)}';
      case ScheduleCardState.arrived:
        final at = _a.checkedInAt;
        return at == null ? null : 'Arrived ${fmtTime(at)}';
      case ScheduleCardState.done:
        return _a.outcomeNote;
      case ScheduleCardState.booked:
      case ScheduleCardState.notArrived:
        return null;
    }
  }

  List<_CardActionSpec> _actionsFor(ScheduleCardState state) {
    final act = !_busy;
    switch (state) {
      case ScheduleCardState.booked:
      case ScheduleCardState.called:
        return [
          _CardActionSpec(
            Icons.campaign_rounded,
            'Call patient',
            act ? _call : null,
          ),
          _CardActionSpec(
            Icons.check_rounded,
            'Arrived',
            act ? _markArrived : null,
            primary: true,
          ),
          _CardActionSpec(
            Icons.close_rounded,
            'Not arrived',
            act ? _markNotArrived : null,
          ),
          _CardActionSpec(Icons.assignment_outlined, 'Open chart', _openChart),
        ];
      case ScheduleCardState.arrived:
        return [
          _CardActionSpec(
            Icons.done_all_rounded,
            'Complete visit',
            _completeVisit,
            primary: true,
          ),
          _CardActionSpec(Icons.assignment_outlined, 'Open chart', _openChart),
        ];
      case ScheduleCardState.notArrived:
        return [
          _CardActionSpec(
            Icons.check_rounded,
            'Arrived',
            act ? _undoNotArrived : null,
            primary: true,
          ),
          _CardActionSpec(Icons.assignment_outlined, 'Open chart', _openChart),
        ];
      case ScheduleCardState.done:
        return [
          _CardActionSpec(Icons.assignment_outlined, 'Open chart', _openChart),
        ];
    }
  }
}

// ---------------------------------------------------------------------------
// Compact overview card
// ---------------------------------------------------------------------------

class _CompactCard extends StatelessWidget {
  const _CompactCard({
    required this.appointment,
    required this.who,
    required this.state,
    required this.palette,
    required this.border,
    required this.highlighted,
    required this.onTap,
  });

  final Appointment appointment;
  final String who;
  final ScheduleCardState state;
  final _CardPalette palette;
  final Border border;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.standard,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: Radii.chip,
        border: border,
        boxShadow: highlighted
            ? Shadows.glow(theme.colorScheme.primary)
            : const <BoxShadow>[],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(width: 4, color: palette.bar),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xxs),
                  child: Row(
                    children: [
                      Text(
                        fmtTime(appointment.slotStart),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.subtle,
                          fontFeatures: kTabularFigures,
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          who,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: palette.fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      _StateBadge(state: state, appointment: appointment),
                      const SizedBox(width: Space.xs),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State badge — colour + icon + word, readable without relying on the card fill
// ---------------------------------------------------------------------------

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, required this.appointment});

  final ScheduleCardState state;
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ramp = theme.clinicalStatus;

    final (String label, IconData icon, Color bg, Color fg) = switch (state) {
      ScheduleCardState.booked => (
        'Booked',
        Icons.event_outlined,
        scheme.surface,
        scheme.onSurface,
      ),
      ScheduleCardState.called => (
        'Called',
        Icons.campaign_rounded,
        scheme.primary,
        scheme.onPrimary,
      ),
      ScheduleCardState.arrived => (
        'Arrived',
        Icons.check_rounded,
        ramp.riskLow.onContainer,
        ramp.riskLow.container,
      ),
      ScheduleCardState.notArrived => (
        'Not arrived',
        Icons.close_rounded,
        ramp.riskHigh.onContainer,
        ramp.riskHigh.container,
      ),
      ScheduleCardState.done =>
        appointment.status == AppointmentStatus.cancelled
            ? (
                'Cancelled',
                Icons.block_rounded,
                scheme.onSurfaceVariant,
                scheme.surface,
              )
            : (
                'Completed',
                Icons.check_circle_rounded,
                scheme.onSurfaceVariant,
                scheme.surface,
              ),
    };

    return StatusPill(
      label: label,
      icon: icon,
      container: bg,
      onContainer: fg,
      dense: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Labelled action button
// ---------------------------------------------------------------------------

class _CardActionSpec {
  const _CardActionSpec(this.icon, this.label, this.onTap, {this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.action, required this.palette});

  final _CardActionSpec action;
  final _CardPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = Text(action.label);
    final icon = Icon(action.icon, size: 18);

    if (action.primary) {
      return FilledButton.icon(
        onPressed: action.onTap,
        icon: icon,
        label: label,
        style: FilledButton.styleFrom(
          backgroundColor: palette.fg,
          foregroundColor: palette.bg,
          visualDensity: VisualDensity.compact,
          textStyle: theme.textTheme.labelMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.xs,
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: action.onTap,
      icon: icon,
      label: label,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.fg,
        side: BorderSide(color: palette.fg.withValues(alpha: 0.4)),
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The ✓ / ✕ flash — the booking-confirmation motion (easeOutBack scale-in,
// brief hold, ease-out fade), rendered on the card. Red ✕ is the same motion.
// ---------------------------------------------------------------------------

class _FlashMark extends StatelessWidget {
  const _FlashMark({required this.kind, required this.t});

  final _Flash kind;
  final double t;

  @override
  Widget build(BuildContext context) {
    if (t == 0) return const SizedBox.shrink();
    final ramp = Theme.of(context).clinicalStatus;
    final style = kind == _Flash.cross ? ramp.riskHigh : ramp.riskLow;
    final icon =
        kind == _Flash.cross ? Icons.close_rounded : Icons.check_rounded;
    final scale = 0.6 + 0.4 * Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

    return Container(
      alignment: Alignment.center,
      color: style.container.withValues(alpha: 0.30 * t),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: style.container,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: style.onContainer),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Palette — violet identity kept for booked / called; the status ramp for the
// rest (green arrived, red not-arrived, muted done).
// ---------------------------------------------------------------------------

class _CardPalette {
  const _CardPalette({
    required this.bg,
    required this.fg,
    required this.bar,
    required this.subtle,
  });

  final Color bg;
  final Color fg;
  final Color bar;
  final Color subtle;

  static _CardPalette of(BuildContext context, ScheduleCardState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ramp = theme.clinicalStatus;
    switch (state) {
      case ScheduleCardState.booked:
      case ScheduleCardState.called:
        return _CardPalette(
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
          bar: scheme.primary,
          subtle: scheme.onPrimaryContainer.withValues(alpha: 0.74),
        );
      case ScheduleCardState.arrived:
        return _CardPalette(
          bg: ramp.riskLow.container,
          fg: ramp.riskLow.onContainer,
          bar: ramp.riskLow.onContainer,
          subtle: ramp.riskLow.onContainer.withValues(alpha: 0.78),
        );
      case ScheduleCardState.notArrived:
        return _CardPalette(
          bg: ramp.riskHigh.container,
          fg: ramp.riskHigh.onContainer,
          bar: ramp.riskHigh.onContainer,
          subtle: ramp.riskHigh.onContainer.withValues(alpha: 0.78),
        );
      case ScheduleCardState.done:
        return _CardPalette(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurfaceVariant,
          bar: scheme.outline,
          subtle: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        );
    }
  }
}
