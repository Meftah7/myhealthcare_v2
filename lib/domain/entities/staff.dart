/// Staff aggregate — the [User] account plus the staff profile (P1-08).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'user.dart';

part 'staff.freezed.dart';

/// The two staff kinds the app distinguishes, stored in [Staff.jobTitle].
///
/// Only `Nurse` carries behaviour (it routes to the nursing worklist); every
/// other title — including the seeded `'Consultant'` — reads as a doctor.
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

  /// A nurse — works the nursing worklist rather than taking appointments.
  bool get isNurse => jobTitle == kNurseJobTitle;

  /// Every clinician who isn't a nurse (the seeded `'Consultant'` staff
  /// included).
  bool get isDoctor => !isNurse;
}
