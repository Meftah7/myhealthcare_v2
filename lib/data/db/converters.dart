/// Drift [TypeConverter]s (Phase 1).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a `List<String>` as a JSON array in a text column. Used for
/// allergies, chronic conditions, etc.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb);
    return (decoded as List).cast<String>();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
