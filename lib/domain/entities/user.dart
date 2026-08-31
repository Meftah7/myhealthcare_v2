/// Account entity — the identity record, role-agnostic (P1-08).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'user.freezed.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required UserRole role,
    required String fullName,
    required String email,
    required bool isActive,
    required DateTime createdAt,
    String? phone,
    DateTime? dob,
    Gender? gender,
    String? nationalId,
  }) = _User;

  const User._();

  bool get isPatient => role == UserRole.patient;
  bool get isStaff => role == UserRole.staff;
  bool get isAdmin => role == UserRole.admin;

  int? get ageYears {
    final d = dob;
    if (d == null) return null;
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }
}
