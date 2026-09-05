/// Drift [TypeConverter]s (Phase 1).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/family_member.dart';

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

/// Stores a `List<FamilyMember>` as a JSON array in a text column
/// (`PatientProfiles.familyMembers` — redesign v2 patient dashboard: Family
/// Network). No table of its own; the whole list round-trips together.
class FamilyMemberListConverter
    extends TypeConverter<List<FamilyMember>, String> {
  const FamilyMemberListConverter();

  @override
  List<FamilyMember> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb) as List;
    return decoded
        .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  String toSql(List<FamilyMember> value) =>
      jsonEncode(value.map((m) => m.toJson()).toList());
}
