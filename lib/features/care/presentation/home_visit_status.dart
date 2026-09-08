/// Shared status label + chip for home-visit requests (P10-08).
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../domain/enums.dart';

String homeVisitStatusLabel(HomeVisitStatus s) => switch (s) {
  HomeVisitStatus.requested => 'Requested',
  HomeVisitStatus.scheduled => 'Scheduled',
  HomeVisitStatus.completed => 'Completed',
  HomeVisitStatus.declined => 'Declined',
  HomeVisitStatus.cancelled => 'Cancelled',
};

class HomeVisitStatusChip extends StatelessWidget {
  const HomeVisitStatusChip({required this.status, super.key});

  final HomeVisitStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ramp = theme.clinicalStatus;
    final style = switch (status) {
      HomeVisitStatus.requested => ramp.labNormal,
      HomeVisitStatus.scheduled => ramp.riskLow,
      HomeVisitStatus.completed => ramp.riskLow,
      HomeVisitStatus.declined => ramp.riskMedium,
      HomeVisitStatus.cancelled => ramp.labNormal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: Radii.pill,
      ),
      child: Text(
        homeVisitStatusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(
          color: style.onContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
