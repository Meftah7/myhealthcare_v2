import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';

/// Natural-height cards: larger text expands the card instead of clipping it.
class UpcomingAppointmentCarousel extends StatefulWidget {
  const UpcomingAppointmentCarousel({
    required this.appointments,
    this.doctorNames = const {},
    super.key,
  }) : assert(appointments.length > 0);

  final List<Appointment> appointments;
  final Map<String, String> doctorNames;

  @override
  State<UpcomingAppointmentCarousel> createState() =>
      _UpcomingAppointmentCarouselState();
}

class _UpcomingAppointmentCarouselState
    extends State<UpcomingAppointmentCarousel>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _index = 0;
  bool _foreground = true;
  double _direction = 1;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restartTimer();
  }

  @override
  void didUpdateWidget(UpcomingAppointmentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedId = oldWidget.appointments[_index].id;
    final newIndex = widget.appointments.indexWhere((a) => a.id == selectedId);
    _index = newIndex < 0 ? 0 : newIndex;
    if (oldWidget.appointments.length != widget.appointments.length) {
      _restartTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_foreground || widget.appointments.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      if (MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)) {
        return;
      }
      _move(1, restart: false);
    });
  }

  void _move(int delta, {bool restart = true}) {
    if (widget.appointments.length < 2) return;
    setState(() {
      _direction = delta > 0 ? 1 : -1;
      _index = (_index + delta) % widget.appointments.length;
    });
    if (restart) _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appointment = widget.appointments[_index];
    final cardKey = ValueKey(appointment.id);
    final staticMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onHorizontalDragStart: (_) {
            _dragDistance = 0;
            _timer?.cancel();
          },
          onHorizontalDragUpdate: (details) {
            _dragDistance += details.primaryDelta ?? 0;
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() > 100 || _dragDistance.abs() > 40) {
              final movement = velocity.abs() > 100 ? velocity : _dragDistance;
              _move(movement < 0 ? 1 : -1);
            } else {
              _restartTimer();
            }
          },
          onHorizontalDragCancel: _restartTimer,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: staticMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(
                    child.key == cardKey ? _direction : -_direction,
                    0,
                  ),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _AppointmentCard(
                key: cardKey,
                appointment: appointment,
                doctorName: widget.doctorNames[appointment.staffId],
              ),
            ),
          ),
        ),
        if (widget.appointments.length > 1) ...[
          const SizedBox(height: Space.xs),
          ReadableLabel(
            t.carouselPosition(_index + 1, widget.appointments.length),
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: t.previousAppointment,
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: t.nextAppointment,
                onPressed: () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
        const SizedBox(height: Space.sm),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.doctorName,
    super.key,
  });

  final Appointment appointment;
  final String? doctorName;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detail = AppRoutes.patientAppointmentDetail(appointment.id);
    return AppCard(
      color: theme.brightness == Brightness.light
          ? AppColors.seed
          : AppColors.brandBlue,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadableLabel(
            t.ticketOverline,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          if (appointment.ticketTag != null)
            ReadableLabel(
              appointment.ticketTag!,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
          const SizedBox(height: Space.xs),
          ReadableLabel(
            doctorName ?? visitTypeLabel(appointment.visitType),
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: Space.sm),
          ReadableLabel(
            '${fmtRelativeDay(appointment.slotStart)} · ${fmtTime(appointment.slotStart)} · ${t.roomNumber(appointment.roomNumber ?? t.none)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          if (appointment.bookedForName != null) ...[
            const SizedBox(height: Space.xs),
            ReadableLabel(
              t.bookedForName(appointment.bookedForName!),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
          const SizedBox(height: Space.md),
          OutlinedButton(
            onPressed: () => context.push(detail),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 18),
                const SizedBox(width: Space.xs),
                Expanded(child: ReadableLabel(t.ticketOverline)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.patientAppointments),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: SizedBox(
              width: double.infinity,
              child: ReadableLabel(
                t.appointmentsTitle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
