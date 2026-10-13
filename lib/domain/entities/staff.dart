/// Staff aggregate — the [User] account plus the staff profile (P1-08).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'user.dart';

part 'staff.freezed.dart';

/// Stored [Staff.jobTitle] values; see [StaffRole] for the validated role.
const kDoctorJobTitle = 'Doctor';
const kNurseJobTitle = 'Nurse';

@freezed
abstract class Staff with _$Staff {
  const factory Staff({
    required User user,
    String? specialty,
    String? departmentId,
    String? licenseNo,
    String? jobTitle,
    @Default(PresenceStatus.offShift) PresenceStatus presence,
  }) = _Staff;

  const Staff._();

  String get id => user.id;
  String get fullName => user.fullName;

  /// The validated role; `null` for a missing or unrecognised title.
  StaffRole? get role => StaffRole.parse(jobTitle);

  /// A nurse — works the nursing worklist rather than taking appointments.
  bool get isNurse => role == StaffRole.nurse;

  /// A doctor (including the seeded `'Consultant'` title) — not a dentist,
  /// nurse, receptionist, pharmacist or unknown title.
  bool get isDoctor => role == StaffRole.doctor;

  /// A doctor or dentist: bookable by patients and owns appointments.
  bool get takesAppointments => role?.takesAppointments ?? false;
}
