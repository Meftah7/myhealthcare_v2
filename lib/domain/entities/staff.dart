/// Staff aggregate — the [User] account plus the staff profile (P1-08).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'staff.freezed.dart';

@freezed
abstract class Staff with _$Staff {
  const factory Staff({
    required User user,
    String? specialty,
    String? departmentId,
    String? licenseNo,
    String? jobTitle,
  }) = _Staff;

  const Staff._();

  String get id => user.id;
  String get fullName => user.fullName;
}
