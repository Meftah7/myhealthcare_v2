/// Patient aggregate — the [User] account plus the patient profile (P1-08).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'patient.freezed.dart';

@freezed
abstract class Patient with _$Patient {
  const factory Patient({
    required User user,
    String? bloodType,
    @Default([]) List<String> allergies,
    @Default([]) List<String> chronicConditions,
    String? emergencyContact,
  }) = _Patient;

  const Patient._();

  String get id => user.id;
  String get fullName => user.fullName;
  bool get hasChronicCondition => chronicConditions.isNotEmpty;
}
