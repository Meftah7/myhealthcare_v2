/// Small formatting helpers (P2-07+).
library;

import 'package:intl/intl.dart';

import '../../domain/enums.dart';

final _date = DateFormat('d MMM yyyy');
final _shortDate = DateFormat('d MMM');
final _dateTime = DateFormat('d MMM yyyy · HH:mm');
final _monthYear = DateFormat('MMMM yyyy');
final _time = DateFormat('HH:mm');

String fmtDate(DateTime d) => _date.format(d);

/// Day + month, no year — for compact tiles ("14 Aug").
String fmtShortDate(DateTime d) => _shortDate.format(d);
String fmtDateTime(DateTime d) => _dateTime.format(d);
String fmtMonthYear(DateTime d) => _monthYear.format(d);
String fmtTime(DateTime d) => _time.format(d);

/// A clinician's name with the "Dr" honorific — added exactly once. Names are
/// stored plain (`users.fullName`); this is the display form. Idempotent, so
/// it's safe to call on a value that already carries the prefix.
String clinicianName(String fullName) {
  final trimmed = fullName.trim();
  return trimmed.startsWith('Dr ') ? trimmed : 'Dr $trimmed';
}

/// Human-readable label for a [VisitType] ("chronicCareReview" → "Chronic care
/// review").
String visitTypeLabel(VisitType t) => switch (t) {
  VisitType.newPatient => 'New patient',
  VisitType.followUp => 'Follow-up',
  VisitType.routineCheckup => 'Routine check-up',
  VisitType.chronicCareReview => 'Chronic care review',
  VisitType.urgentCare => 'Urgent care',
  VisitType.procedure => 'Procedure',
  VisitType.vaccination => 'Vaccination',
  VisitType.labOnly => 'Lab only',
};

/// Time-of-day greeting, e.g. "Good morning, Ali".
String greeting(String name, {DateTime? now}) {
  final h = (now ?? DateTime.now()).hour;
  final part = h < 12
      ? 'Good morning'
      : h < 18
      ? 'Good afternoon'
      : 'Good evening';
  return '$part, $name';
}

/// Compact "time ago" for feeds: "just now", "5m", "3h", "2d", then a date.
String fmtTimeAgo(DateTime d, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return _date.format(d);
}

String fmtRelativeDay(DateTime d) {
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = day.difference(today).inDays;
  return switch (diff) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ when diff > 1 && diff < 7 => DateFormat('EEEE').format(d),
    _ => _date.format(d),
  };
}
