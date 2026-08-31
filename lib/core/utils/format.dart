/// Small formatting helpers (P2-07+).
library;

import 'package:intl/intl.dart';

final _date = DateFormat('d MMM yyyy');
final _dateTime = DateFormat('d MMM yyyy · HH:mm');
final _monthYear = DateFormat('MMMM yyyy');
final _time = DateFormat('HH:mm');

String fmtDate(DateTime d) => _date.format(d);
String fmtDateTime(DateTime d) => _dateTime.format(d);
String fmtMonthYear(DateTime d) => _monthYear.format(d);
String fmtTime(DateTime d) => _time.format(d);

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
