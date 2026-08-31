/// ID generation (P1-12+).
library;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A fresh unique id, optionally prefixed for readability in the DB / logs
/// (e.g. `newId('appt')` → `appt_1f9c…`).
String newId([String? prefix]) {
  final v = _uuid.v4();
  return prefix == null ? v : '${prefix}_$v';
}
