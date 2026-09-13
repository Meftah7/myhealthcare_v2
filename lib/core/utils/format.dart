/// Small formatting helpers (P2-07+).
///
/// Locale-aware via `Intl.getCurrentLocale()`, which [LocaleController]
/// (`app/settings/ui_prefs.dart`) keeps in sync with the app's language
/// preference on every change — so these plain top-level functions don't need
/// a `BuildContext` threaded through their ~45 call sites to pick the right
/// language. `DateFormat` is constructed fresh per call (not cached in a
/// top-level `final`) so it always picks up the *current* locale rather than
/// freezing whatever locale was active the first time a given format ran.
library;

import 'package:intl/intl.dart';

import '../../domain/enums.dart';

bool get _ar => Intl.getCurrentLocale().startsWith('ar');

String fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

/// Day + month, no year — for compact tiles ("14 Aug").
String fmtShortDate(DateTime d) => DateFormat('d MMM').format(d);
String fmtDateTime(DateTime d) => DateFormat('d MMM yyyy · HH:mm').format(d);
String fmtMonthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
String fmtTime(DateTime d) => DateFormat('HH:mm').format(d);

/// A clinician's name with the "Dr" / "د." honorific — added exactly once.
/// Names are stored plain (`users.fullName`); this is the display form.
/// Idempotent, so it's safe to call on a value that already carries either
/// prefix (e.g. once locale switches after the name was already formatted).
String clinicianName(String fullName) {
  var trimmed = fullName.trim();
  if (trimmed.startsWith('Dr ')) trimmed = trimmed.substring(3);
  if (trimmed.startsWith('د. ')) trimmed = trimmed.substring(3);
  return _ar ? 'د. $trimmed' : 'Dr $trimmed';
}

/// Human-readable label for a [VisitType] ("chronicCareReview" → "Chronic care
/// review").
String visitTypeLabel(VisitType t) => _ar
    ? switch (t) {
        VisitType.newPatient => 'مريض جديد',
        VisitType.followUp => 'متابعة',
        VisitType.routineCheckup => 'فحص روتيني',
        VisitType.chronicCareReview => 'مراجعة رعاية مرض مزمن',
        VisitType.urgentCare => 'رعاية عاجلة',
        VisitType.procedure => 'إجراء طبي',
        VisitType.vaccination => 'تطعيم',
        VisitType.labOnly => 'فحص مخبري فقط',
      }
    : switch (t) {
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
// NOTE(i18n): Arabic everyday speech doesn't have as sharp an
// afternoon/evening split as English does casually — "مساء الخير" ("good
// evening") is commonly used for both from midday on. Flag if you want a
// distinct afternoon phrase instead.
String greeting(String name, {DateTime? now}) {
  final h = (now ?? DateTime.now()).hour;
  if (_ar) {
    final part = h < 12 ? 'صباح الخير' : 'مساء الخير';
    return '$part، $name';
  }
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
  if (diff.inMinutes < 1) return _ar ? 'الآن' : 'just now';
  if (diff.inMinutes < 60) {
    return _ar ? '${diff.inMinutes} د' : '${diff.inMinutes}m';
  }
  if (diff.inHours < 24) return _ar ? '${diff.inHours} س' : '${diff.inHours}h';
  if (diff.inDays < 7) return _ar ? '${diff.inDays} ي' : '${diff.inDays}d';
  return DateFormat('d MMM yyyy').format(d);
}

String fmtRelativeDay(DateTime d) {
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = day.difference(today).inDays;
  return switch (diff) {
    0 => _ar ? 'اليوم' : 'Today',
    1 => _ar ? 'غداً' : 'Tomorrow',
    -1 => _ar ? 'أمس' : 'Yesterday',
    _ when diff > 1 && diff < 7 => DateFormat('EEEE').format(d),
    _ => DateFormat('d MMM yyyy').format(d),
  };
}
