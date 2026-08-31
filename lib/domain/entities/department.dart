/// Clinical department (P1-08).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'department.freezed.dart';

@freezed
abstract class Department with _$Department {
  const factory Department({
    required String id,
    required String name,
    String? description,
  }) = _Department;
}
