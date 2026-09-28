/// Builds a minimal, valid iCalendar (.ics) event for an appointment, so it
/// can be exported to the device's own calendar app.
library;

/// RFC 5545 §3.3.5 UTC date-time: `YYYYMMDDTHHMMSSZ`.
String _icsUtc(DateTime dt) {
  final u = dt.toUtc();
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${u.year}${p2(u.month)}${p2(u.day)}T'
      '${p2(u.hour)}${p2(u.minute)}${p2(u.second)}Z';
}

/// Escapes text per RFC 5545 §3.3.11 — backslash, newline, comma and
/// semicolon are the only characters that need it in an ICS value.
String _icsEscape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll('\n', r'\n')
    .replaceAll(',', r'\,')
    .replaceAll(';', r'\;');

/// One VCALENDAR containing one VEVENT. [uid] should be stable for the same
/// appointment (its own id) so re-exporting/re-importing updates rather than
/// duplicates the calendar entry in apps that respect UID.
String buildAppointmentIcs({
  required String uid,
  required String title,
  required DateTime start,
  required DateTime end,
  String? location,
  String? description,
}) {
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//MyHealth Care//Appointment Export//EN',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    'UID:$uid@myhealthcare',
    'DTSTAMP:${_icsUtc(DateTime.now())}',
    'DTSTART:${_icsUtc(start)}',
    'DTEND:${_icsUtc(end)}',
    'SUMMARY:${_icsEscape(title)}',
    if (location != null && location.isNotEmpty)
      'LOCATION:${_icsEscape(location)}',
    if (description != null && description.isNotEmpty)
      'DESCRIPTION:${_icsEscape(description)}',
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  // RFC 5545 requires CRLF line endings.
  return '${lines.join('\r\n')}\r\n';
}
