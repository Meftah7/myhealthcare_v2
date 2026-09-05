/// Ticket tag + room number helpers (redesign v2 patient dashboard).
///
/// The facility is open 24/7, so every hour of the day maps to a letter,
/// A (00:00) through X (23:00). A ticket tag is `[hour letter]-[number]`,
/// where the number is a facility-wide, per-hour counter that resets at
/// local midnight. A room number is `[department letter]-[doctor's sequence
/// within that department]`, e.g. a department's 2nd doctor gets room
/// `C-2` if the department's name starts with C.
library;

/// The hour letter for [time]'s local hour (0 → 'A' … 23 → 'X').
String hourLetterFor(DateTime time) =>
    String.fromCharCode('A'.codeUnitAt(0) + time.hour);

/// The department letter: the first letter of [departmentName], upper-cased.
/// Falls back to '?' for a blank name.
String departmentLetterFor(String departmentName) {
  final trimmed = departmentName.trim();
  return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
}
