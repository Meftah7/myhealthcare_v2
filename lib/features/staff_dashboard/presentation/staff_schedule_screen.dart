/// The clinician's calendar (P5-12, calendar rebuild) — three levels that
/// drill into each other the way the iOS Calendar does:
///
///   Year   12 mini-months. Tap one to open it.
///   Month  a six-week grid, a mark under every day that has visits.
///   Day    an hour-by-hour timeline with the appointments laid out on it and
///          a live "now" line that slides down as the clock moves.
///
/// The button in the app bar's top-left always steps *up* a level — from a day
/// to its month, from a month to its year.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../domain/entities/entities.dart';
import '../application/staff_providers.dart';
import 'schedule_appointment_card.dart';
import 'schedule_queue_strip.dart';
import 'staff_top_actions.dart';

class StaffScheduleScreen extends ConsumerWidget {
  const StaffScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(scheduleViewProvider);
    final focused = ref.watch(scheduleFocusedDayProvider);

    void goUp(ScheduleView to) =>
        ref.read(scheduleViewProvider.notifier).state = to;

    final title = switch (view) {
      ScheduleView.year => '${focused.year}',
      ScheduleView.month => DateFormat('MMMM').format(focused),
      ScheduleView.day => DateFormat('EEE d').format(focused),
    };

    return Scaffold(
      appBar: AppBar(
        // Steps up a level, and says where it goes — the year from a month,
        // the month from a day.
        leadingWidth: view == ScheduleView.year ? null : 108,
        leading: switch (view) {
          ScheduleView.year => null,
          ScheduleView.month => _UpButton(
            label: '${focused.year}',
            onTap: () => goUp(ScheduleView.year),
          ),
          ScheduleView.day => _UpButton(
            label: DateFormat('MMM').format(focused),
            onTap: () => goUp(ScheduleView.month),
          ),
        },
        title: Text(title),
        actions: const [StaffTopActions()],
      ),
      body: switch (view) {
        ScheduleView.year => const _YearView(),
        ScheduleView.month => const _MonthView(),
        ScheduleView.day => const _DayView(),
      },
    );
  }
}

class _UpButton extends StatelessWidget {
  const _UpButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.chevron_left, size: 20),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.only(right: Space.xs),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Year — twelve mini-months
// ---------------------------------------------------------------------------

class _YearView extends ConsumerWidget {
  const _YearView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(scheduleFocusedDayProvider);
    final size = WindowSize.of(context);
    final columns = size.isCompact ? 3 : (size.isMedium ? 4 : 6);

    void setYear(int year) =>
        ref.read(scheduleFocusedDayProvider.notifier).state = DateTime(
          year,
          focused.month,
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
        child: Column(
          children: [
            _StepperBar(
              label: '${focused.year}',
              onPrevious: () => setYear(focused.year - 1),
              onNext: () => setYear(focused.year + 1),
              onToday: () => _jumpToToday(ref, ScheduleView.year),
              isToday: focused.year == DateTime.now().year,
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: columns,
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  0,
                  Space.md,
                  Space.xxl,
                ),
                mainAxisSpacing: Space.md,
                crossAxisSpacing: Space.md,
                // Height from the content, not from the tile width — see
                // _MiniMonth.extentFor.
                mainAxisExtent: _MiniMonth.extentFor(context),
                children: [
                  for (var m = 1; m <= 12; m++)
                    _MiniMonth(
                      year: focused.year,
                      month: m,
                      onTap: () {
                        ref.read(scheduleFocusedDayProvider.notifier).state =
                            DateTime(focused.year, m);
                        ref.read(scheduleViewProvider.notifier).state =
                            ScheduleView.month;
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.year,
    required this.month,
    required this.onTap,
  });

  final int year;
  final int month;
  final VoidCallback onTap;

  /// A month grid needs up to six week rows; every tile is sized for six so
  /// the grid stays uniform whichever months the year happens to contain.
  static const int _maxWeekRows = 6;

  /// One day cell, at the current text scale.
  static double _cellSize(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(15);

  /// The exact height one tile needs.
  ///
  /// The year grid used to size these with `childAspectRatio: 0.86`, which ties
  /// the height to the *width*: narrow the pane — as the extended navigation
  /// rail does — and a six-row month overflows by a few pixels. Measuring the
  /// content instead makes the tile correct at any width and any text scale.
  static double extentFor(BuildContext context) {
    final label = MediaQuery.textScalerOf(context).scale(16); // labelMedium
    return Space.xs * 2 + label + Space.xxs + _cellSize(context) * _maxWeekRows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final first = DateTime(year, month);
    final lead = first.weekday - 1; // Monday-first
    final days = DateUtils.getDaysInMonth(year, month);
    final rows = ((lead + days) / 7).ceil();
    final isThisMonth = now.year == year && now.month == month;
    final cell = _cellSize(context);

    return AppCard(
      padding: const EdgeInsets.all(Space.xs),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM').format(first),
            style: theme.textTheme.labelMedium?.copyWith(
              color: isThisMonth ? scheme.primary : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Space.xxs),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _miniCell(
                      theme,
                      r * 7 + c - lead + 1,
                      days,
                      now,
                      cell,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _miniCell(
    ThemeData theme,
    int day,
    int days,
    DateTime now,
    double cell,
  ) {
    if (day < 1 || day > days) return SizedBox(height: cell);
    final isToday = now.year == year && now.month == month && now.day == day;
    return SizedBox(
      height: cell,
      child: Center(
        child: isToday
            ? Container(
                width: cell,
                height: cell,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                '$day',
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month — a six-week grid with a mark under every day that has visits
// ---------------------------------------------------------------------------

class _MonthView extends ConsumerWidget {
  const _MonthView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = ref.watch(scheduleFocusedDayProvider);
    final month = ref.watch(staffMonthProvider);
    final gridStart = monthGridStart(focused);
    final now = DateTime.now();

    void setMonth(int delta) =>
        ref.read(scheduleFocusedDayProvider.notifier).state = DateTime(
          focused.year,
          focused.month + delta,
        );

    return month.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: 'Could not load your calendar.',
        onRetry: () => ref.invalidate(staffMonthProvider),
      ),
      data: (appts) {
        // How many visits fall on each day of the visible grid.
        final counts = <DateTime, int>{};
        for (final a in appts) {
          final key = dayOf(a.slotStart);
          counts[key] = (counts[key] ?? 0) + 1;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: Column(
              children: [
                _StepperBar(
                  label: DateFormat('MMMM yyyy').format(focused),
                  onPrevious: () => setMonth(-1),
                  onNext: () => setMonth(1),
                  onToday: () => _jumpToToday(ref, ScheduleView.month),
                  isToday:
                      focused.year == now.year && focused.month == now.month,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Center(
                            child: Text(
                              DateFormat(
                                'E',
                              ).format(gridStart.add(Duration(days: i)))[0],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      0,
                      Space.md,
                      Space.md,
                    ),
                    child: Column(
                      children: [
                        for (var week = 0; week < 6; week++)
                          Expanded(
                            child: Row(
                              children: [
                                for (var d = 0; d < 7; d++)
                                  Expanded(
                                    child: _MonthCell(
                                      date: gridStart.add(
                                        Duration(days: week * 7 + d),
                                      ),
                                      inMonth:
                                          gridStart
                                              .add(Duration(days: week * 7 + d))
                                              .month ==
                                          focused.month,
                                      count:
                                          counts[gridStart.add(
                                            Duration(days: week * 7 + d),
                                          )] ??
                                          0,
                                      selected: isSameCalendarDay(
                                        gridStart.add(
                                          Duration(days: week * 7 + d),
                                        ),
                                        focused,
                                      ),
                                      onTap: () {
                                        ref
                                            .read(
                                              scheduleFocusedDayProvider
                                                  .notifier,
                                            )
                                            .state = gridStart.add(
                                          Duration(days: week * 7 + d),
                                        );
                                        ref
                                            .read(scheduleViewProvider.notifier)
                                            .state = ScheduleView
                                            .day;
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.date,
    required this.inMonth,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isToday = isSameCalendarDay(date, DateTime.now());

    final Color numberColor;
    if (isToday) {
      numberColor = scheme.onPrimary;
    } else if (!inMonth) {
      numberColor = scheme.onSurfaceVariant.withValues(alpha: 0.45);
    } else {
      numberColor = scheme.onSurface;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: Radii.chip,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday
                  ? scheme.primary
                  : selected
                  ? scheme.secondaryContainer
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected && !isToday
                    ? scheme.onSecondaryContainer
                    : numberColor,
                fontWeight: isToday || selected ? FontWeight.w700 : null,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Up to three marks, so a busy day reads as busy at a glance.
          SizedBox(
            height: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count.clamp(0, 3); i++)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: inMonth
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day — the live timeline
// ---------------------------------------------------------------------------

const double _timeGutter = 56;

class _DayView extends ConsumerStatefulWidget {
  const _DayView();

  @override
  ConsumerState<_DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<_DayView> {
  final ScrollController _scroll = ScrollController();
  Timer? _tick;
  Timer? _highlightClear;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // The "now" line only has to be minute-accurate; half a minute keeps it
    // honest without waking the tree often.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  double get _hourHeight => ref.read(scheduleHourHeightProvider);

  void _scrollToNow() {
    if (!_scroll.hasClients) return;
    final target = ((_now.hour - 1).clamp(0, 22)) * _hourHeight;
    _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
  }

  /// Brings a queue patient's card into view and glows it for a beat — driven
  /// by the "Next" button in the queue strip.
  void _focusAppointment(String appointmentId) {
    final appts = ref.read(staffFocusedDayProvider);
    Appointment? target;
    for (final a in appts) {
      if (a.id == appointmentId) {
        target = a;
        break;
      }
    }
    if (target != null && _scroll.hasClients) {
      final y = (_yFor(target.slotStart, _hourHeight) - 100).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      unawaited(
        _scroll.animateTo(y, duration: Motion.slow, curve: Motion.standard),
      );
    }
    ref.read(scheduleHighlightIdProvider.notifier).state = appointmentId;
    _highlightClear?.cancel();
    _highlightClear = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        ref.read(scheduleHighlightIdProvider.notifier).state = null;
      }
    });
  }

  void _zoom(double factor) {
    final next = (ref.read(scheduleHourHeightProvider) * factor).clamp(
      scheduleHourHeightMin,
      scheduleHourHeightMax,
    );
    ref.read(scheduleHourHeightProvider.notifier).state = next;
  }

  @override
  void dispose() {
    _tick?.cancel();
    _highlightClear?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _shiftDay(int days) {
    final focused = ref.read(scheduleFocusedDayProvider);
    ref.read(scheduleFocusedDayProvider.notifier).state = focused.add(
      Duration(days: days),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = ref.watch(scheduleFocusedDayProvider);
    final month = ref.watch(staffMonthProvider);
    final appts = ref.watch(staffFocusedDayProvider);
    final hourHeight = ref.watch(scheduleHourHeightProvider);
    final isToday = isSameCalendarDay(focused, _now);

    ref.listen(scheduleQueueCurrentIdProvider, (_, next) {
      if (next != null) _focusAppointment(next);
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
        child: Column(
          children: [
            _WeekStrip(
              focused: focused,
              onPrevious: () => _shiftDay(-1),
              onNext: () => _shiftDay(1),
            ),
            if (month.isLoading)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            if (isToday) const ScheduleQueueStrip(),
            _ZoomBar(
              onOut: () => _zoom(1 / 1.25),
              onIn: () => _zoom(1.25),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.sm,
                    Space.md,
                    Space.xxl,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final laneWidth = constraints.maxWidth - _timeGutter;
                      final compact = hourHeight < scheduleCompactBelow;
                      return SizedBox(
                        height: 24 * hourHeight,
                        child: Stack(
                          children: [
                            // Hour rules + labels.
                            for (var h = 0; h < 24; h++)
                              Positioned(
                                top: h * hourHeight,
                                left: 0,
                                right: 0,
                                child: _HourRule(hour: h),
                              ),

                            for (final slot in _layoutDay(
                              appts,
                              hourHeight,
                              compact,
                            ))
                              Positioned(
                                top: slot.top,
                                left:
                                    _timeGutter +
                                    slot.column * (laneWidth / slot.columns),
                                width: laneWidth / slot.columns - 4,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: slot.slotHeight,
                                  ),
                                  child: ScheduleAppointmentCard(
                                    key: ValueKey(slot.appointment.id),
                                    appointment: slot.appointment,
                                    compact: compact,
                                  ),
                                ),
                              ),

                            if (isToday)
                              Positioned(
                                top: _yFor(_now, hourHeight) - 9,
                                left: 0,
                                right: 0,
                                child: _NowLine(now: _now),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (appts.isEmpty && !month.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  'Nothing booked on this day.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

double _yFor(DateTime t, double hourHeight) =>
    (t.hour + t.minute / 60) * hourHeight;

double _heightFor(Appointment a, double hourHeight) {
  final minutes = a.slotEnd.difference(a.slotStart).inMinutes;
  return (minutes / 60 * hourHeight).clamp(26.0, 24 * hourHeight);
}

/// The − / + zoom control: taller rows for working a patient, shorter for a
/// whole-day overview. Mirrors pinch-zoom on the iOS Calendar day view.
class _ZoomBar extends StatelessWidget {
  const _ZoomBar({required this.onOut, required this.onIn});

  final VoidCallback onOut;
  final VoidCallback onIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.xs, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Compress the day',
            visualDensity: VisualDensity.compact,
            onPressed: onOut,
            icon: Icon(Icons.remove, color: scheme.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Expand the day',
            visualDensity: VisualDensity.compact,
            onPressed: onIn,
            icon: Icon(Icons.add, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HourRule extends StatelessWidget {
  const _HourRule({required this.hour});

  final int hour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _timeGutter,
          child: Transform.translate(
            offset: const Offset(0, -6),
            child: Text(
              DateFormat('HH:mm').format(DateTime(2000, 1, 1, hour)),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: scheme.outlineVariant)),
      ],
    );
  }
}

/// The live marker: a hairline across the grid with a dot at its start and the
/// current time in a filled pill. The pill sits opaque in the gutter so it
/// reads cleanly even when it lands on an hour label.
class _NowLine extends StatelessWidget {
  const _NowLine({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colour = scheme.error;
    return Row(
      children: [
        SizedBox(
          width: _timeGutter,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: Space.xxs),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.xs,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: Radii.pill,
                ),
                child: Text(
                  DateFormat('HH:mm').format(now),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onError,
                    fontWeight: FontWeight.w700,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        Expanded(child: Container(height: 2, color: colour)),
      ],
    );
  }
}

/// The week around the focused day: tap a date to jump to it, or step a single
/// day with the chevrons at either end.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.focused,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime focused;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weekStart = focused.subtract(Duration(days: focused.weekday - 1));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xs,
        Space.xs,
        Space.xs,
        Space.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _WeekStripDay(date: weekStart.add(Duration(days: i))),
            ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    ).withDivider(scheme.outlineVariant);
  }
}

extension on Widget {
  /// A hairline under a header strip, so the timeline scrolls under an edge.
  Widget withDivider(Color colour) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      this,
      Container(height: 1, color: colour),
    ],
  );
}

class _WeekStripDay extends ConsumerWidget {
  const _WeekStripDay({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = ref.watch(scheduleFocusedDayProvider);
    final selected = isSameCalendarDay(date, focused);
    final isToday = isSameCalendarDay(date, DateTime.now());

    return InkWell(
      onTap: () =>
          ref.read(scheduleFocusedDayProvider.notifier).state = dayOf(date),
      borderRadius: Radii.chip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xxs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('E').format(date)[0],
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? scheme.primary
                    : isToday
                    ? scheme.secondaryContainer
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? scheme.onPrimary
                      : isToday
                      ? scheme.onSecondaryContainer
                      : scheme.onSurface,
                  fontWeight: selected || isToday ? FontWeight.w700 : null,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared chrome
// ---------------------------------------------------------------------------

/// ‹ label › with a "Today" escape hatch when you have wandered off.
class _StepperBar extends StatelessWidget {
  const _StepperBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.isToday,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Next',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
          SizedBox(
            width: 64,
            child: isToday
                ? const SizedBox.shrink()
                : TextButton(onPressed: onToday, child: const Text('Today')),
          ),
        ],
      ),
    );
  }
}

void _jumpToToday(WidgetRef ref, ScheduleView keep) {
  ref.read(scheduleFocusedDayProvider.notifier).state = dayOf(DateTime.now());
  ref.read(scheduleViewProvider.notifier).state = keep;
}

// ---------------------------------------------------------------------------
// Overlap layout
// ---------------------------------------------------------------------------

class _DaySlot {
  const _DaySlot(
    this.appointment,
    this.column,
    this.columns,
    this.top,
    this.slotHeight,
  );

  final Appointment appointment;
  final int column;
  final int columns;

  /// Where the card sits on the timeline, in pixels.
  final double top;

  /// The card's minimum height — its duration on the grid. The card itself
  /// sizes to its content and grows to fill this when the slot is taller.
  final double slotHeight;
}

/// Packs overlapping appointments into side-by-side columns: appointments that
/// share any minute end up in the same cluster, and every cluster is as wide as
/// its busiest moment. Each card is then positioned and pushed down within its
/// column — by the larger of its duration and its estimated content height — so
/// a run of short back-to-back visits never draws on top of the one before it.
List<_DaySlot> _layoutDay(
  List<Appointment> appointments,
  double hourHeight,
  bool compact,
) {
  final out = <_DaySlot>[];
  final columnBottom = <int, double>{};
  var cluster = <Appointment>[];
  DateTime? clusterEnd;

  void flush() {
    if (cluster.isEmpty) return;
    final columnEnds = <DateTime>[];
    final assigned = <int>[];
    for (final a in cluster) {
      var column = -1;
      for (var i = 0; i < columnEnds.length; i++) {
        if (!columnEnds[i].isAfter(a.slotStart)) {
          column = i;
          break;
        }
      }
      if (column == -1) {
        columnEnds.add(a.slotEnd);
        column = columnEnds.length - 1;
      } else {
        columnEnds[column] = a.slotEnd;
      }
      assigned.add(column);
    }
    for (var i = 0; i < cluster.length; i++) {
      final a = cluster[i];
      final column = assigned[i];
      final slotHeight = _heightFor(a, hourHeight);
      final rendered = math.max(
        slotHeight,
        scheduleCardEstimatedHeight(a, compact: compact),
      );
      final top = math.max(
        _yFor(a.slotStart, hourHeight),
        columnBottom[column] ?? 0,
      );
      columnBottom[column] = top + rendered + 4;
      out.add(_DaySlot(a, column, columnEnds.length, top, slotHeight));
    }
    cluster = [];
    clusterEnd = null;
  }

  for (final a in appointments) {
    final end = clusterEnd;
    if (end != null && !a.slotStart.isBefore(end)) flush();
    cluster.add(a);
    final current = clusterEnd;
    if (current == null || a.slotEnd.isAfter(current)) clusterEnd = a.slotEnd;
  }
  flush();
  return out;
}
