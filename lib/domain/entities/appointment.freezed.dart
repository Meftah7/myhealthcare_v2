// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Appointment {

 String get id; String get patientId; String get staffId; DateTime get slotStart; DateTime get slotEnd; VisitType get visitType; AppointmentStatus get status; DateTime get bookedAt; int get remindersSent; String? get departmentId; String? get reasonText; double? get noShowRisk; RiskBand? get riskBand; DateTime? get checkedInAt;
/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppointmentCopyWith<Appointment> get copyWith => _$AppointmentCopyWithImpl<Appointment>(this as Appointment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.slotStart, slotStart) || other.slotStart == slotStart)&&(identical(other.slotEnd, slotEnd) || other.slotEnd == slotEnd)&&(identical(other.visitType, visitType) || other.visitType == visitType)&&(identical(other.status, status) || other.status == status)&&(identical(other.bookedAt, bookedAt) || other.bookedAt == bookedAt)&&(identical(other.remindersSent, remindersSent) || other.remindersSent == remindersSent)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.reasonText, reasonText) || other.reasonText == reasonText)&&(identical(other.noShowRisk, noShowRisk) || other.noShowRisk == noShowRisk)&&(identical(other.riskBand, riskBand) || other.riskBand == riskBand)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,staffId,slotStart,slotEnd,visitType,status,bookedAt,remindersSent,departmentId,reasonText,noShowRisk,riskBand,checkedInAt);

@override
String toString() {
  return 'Appointment(id: $id, patientId: $patientId, staffId: $staffId, slotStart: $slotStart, slotEnd: $slotEnd, visitType: $visitType, status: $status, bookedAt: $bookedAt, remindersSent: $remindersSent, departmentId: $departmentId, reasonText: $reasonText, noShowRisk: $noShowRisk, riskBand: $riskBand, checkedInAt: $checkedInAt)';
}


}

/// @nodoc
abstract mixin class $AppointmentCopyWith<$Res>  {
  factory $AppointmentCopyWith(Appointment value, $Res Function(Appointment) _then) = _$AppointmentCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, String staffId, DateTime slotStart, DateTime slotEnd, VisitType visitType, AppointmentStatus status, DateTime bookedAt, int remindersSent, String? departmentId, String? reasonText, double? noShowRisk, RiskBand? riskBand, DateTime? checkedInAt
});




}
/// @nodoc
class _$AppointmentCopyWithImpl<$Res>
    implements $AppointmentCopyWith<$Res> {
  _$AppointmentCopyWithImpl(this._self, this._then);

  final Appointment _self;
  final $Res Function(Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? staffId = null,Object? slotStart = null,Object? slotEnd = null,Object? visitType = null,Object? status = null,Object? bookedAt = null,Object? remindersSent = null,Object? departmentId = freezed,Object? reasonText = freezed,Object? noShowRisk = freezed,Object? riskBand = freezed,Object? checkedInAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,slotStart: null == slotStart ? _self.slotStart : slotStart // ignore: cast_nullable_to_non_nullable
as DateTime,slotEnd: null == slotEnd ? _self.slotEnd : slotEnd // ignore: cast_nullable_to_non_nullable
as DateTime,visitType: null == visitType ? _self.visitType : visitType // ignore: cast_nullable_to_non_nullable
as VisitType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppointmentStatus,bookedAt: null == bookedAt ? _self.bookedAt : bookedAt // ignore: cast_nullable_to_non_nullable
as DateTime,remindersSent: null == remindersSent ? _self.remindersSent : remindersSent // ignore: cast_nullable_to_non_nullable
as int,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as String?,reasonText: freezed == reasonText ? _self.reasonText : reasonText // ignore: cast_nullable_to_non_nullable
as String?,noShowRisk: freezed == noShowRisk ? _self.noShowRisk : noShowRisk // ignore: cast_nullable_to_non_nullable
as double?,riskBand: freezed == riskBand ? _self.riskBand : riskBand // ignore: cast_nullable_to_non_nullable
as RiskBand?,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Appointment].
extension AppointmentPatterns on Appointment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Appointment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Appointment value)  $default,){
final _that = this;
switch (_that) {
case _Appointment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Appointment value)?  $default,){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  String staffId,  DateTime slotStart,  DateTime slotEnd,  VisitType visitType,  AppointmentStatus status,  DateTime bookedAt,  int remindersSent,  String? departmentId,  String? reasonText,  double? noShowRisk,  RiskBand? riskBand,  DateTime? checkedInAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.patientId,_that.staffId,_that.slotStart,_that.slotEnd,_that.visitType,_that.status,_that.bookedAt,_that.remindersSent,_that.departmentId,_that.reasonText,_that.noShowRisk,_that.riskBand,_that.checkedInAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  String staffId,  DateTime slotStart,  DateTime slotEnd,  VisitType visitType,  AppointmentStatus status,  DateTime bookedAt,  int remindersSent,  String? departmentId,  String? reasonText,  double? noShowRisk,  RiskBand? riskBand,  DateTime? checkedInAt)  $default,) {final _that = this;
switch (_that) {
case _Appointment():
return $default(_that.id,_that.patientId,_that.staffId,_that.slotStart,_that.slotEnd,_that.visitType,_that.status,_that.bookedAt,_that.remindersSent,_that.departmentId,_that.reasonText,_that.noShowRisk,_that.riskBand,_that.checkedInAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  String staffId,  DateTime slotStart,  DateTime slotEnd,  VisitType visitType,  AppointmentStatus status,  DateTime bookedAt,  int remindersSent,  String? departmentId,  String? reasonText,  double? noShowRisk,  RiskBand? riskBand,  DateTime? checkedInAt)?  $default,) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.patientId,_that.staffId,_that.slotStart,_that.slotEnd,_that.visitType,_that.status,_that.bookedAt,_that.remindersSent,_that.departmentId,_that.reasonText,_that.noShowRisk,_that.riskBand,_that.checkedInAt);case _:
  return null;

}
}

}

/// @nodoc


class _Appointment extends Appointment {
  const _Appointment({required this.id, required this.patientId, required this.staffId, required this.slotStart, required this.slotEnd, required this.visitType, required this.status, required this.bookedAt, required this.remindersSent, this.departmentId, this.reasonText, this.noShowRisk, this.riskBand, this.checkedInAt}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  String staffId;
@override final  DateTime slotStart;
@override final  DateTime slotEnd;
@override final  VisitType visitType;
@override final  AppointmentStatus status;
@override final  DateTime bookedAt;
@override final  int remindersSent;
@override final  String? departmentId;
@override final  String? reasonText;
@override final  double? noShowRisk;
@override final  RiskBand? riskBand;
@override final  DateTime? checkedInAt;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppointmentCopyWith<_Appointment> get copyWith => __$AppointmentCopyWithImpl<_Appointment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.slotStart, slotStart) || other.slotStart == slotStart)&&(identical(other.slotEnd, slotEnd) || other.slotEnd == slotEnd)&&(identical(other.visitType, visitType) || other.visitType == visitType)&&(identical(other.status, status) || other.status == status)&&(identical(other.bookedAt, bookedAt) || other.bookedAt == bookedAt)&&(identical(other.remindersSent, remindersSent) || other.remindersSent == remindersSent)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.reasonText, reasonText) || other.reasonText == reasonText)&&(identical(other.noShowRisk, noShowRisk) || other.noShowRisk == noShowRisk)&&(identical(other.riskBand, riskBand) || other.riskBand == riskBand)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,staffId,slotStart,slotEnd,visitType,status,bookedAt,remindersSent,departmentId,reasonText,noShowRisk,riskBand,checkedInAt);

@override
String toString() {
  return 'Appointment(id: $id, patientId: $patientId, staffId: $staffId, slotStart: $slotStart, slotEnd: $slotEnd, visitType: $visitType, status: $status, bookedAt: $bookedAt, remindersSent: $remindersSent, departmentId: $departmentId, reasonText: $reasonText, noShowRisk: $noShowRisk, riskBand: $riskBand, checkedInAt: $checkedInAt)';
}


}

/// @nodoc
abstract mixin class _$AppointmentCopyWith<$Res> implements $AppointmentCopyWith<$Res> {
  factory _$AppointmentCopyWith(_Appointment value, $Res Function(_Appointment) _then) = __$AppointmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, String staffId, DateTime slotStart, DateTime slotEnd, VisitType visitType, AppointmentStatus status, DateTime bookedAt, int remindersSent, String? departmentId, String? reasonText, double? noShowRisk, RiskBand? riskBand, DateTime? checkedInAt
});




}
/// @nodoc
class __$AppointmentCopyWithImpl<$Res>
    implements _$AppointmentCopyWith<$Res> {
  __$AppointmentCopyWithImpl(this._self, this._then);

  final _Appointment _self;
  final $Res Function(_Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? staffId = null,Object? slotStart = null,Object? slotEnd = null,Object? visitType = null,Object? status = null,Object? bookedAt = null,Object? remindersSent = null,Object? departmentId = freezed,Object? reasonText = freezed,Object? noShowRisk = freezed,Object? riskBand = freezed,Object? checkedInAt = freezed,}) {
  return _then(_Appointment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,slotStart: null == slotStart ? _self.slotStart : slotStart // ignore: cast_nullable_to_non_nullable
as DateTime,slotEnd: null == slotEnd ? _self.slotEnd : slotEnd // ignore: cast_nullable_to_non_nullable
as DateTime,visitType: null == visitType ? _self.visitType : visitType // ignore: cast_nullable_to_non_nullable
as VisitType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppointmentStatus,bookedAt: null == bookedAt ? _self.bookedAt : bookedAt // ignore: cast_nullable_to_non_nullable
as DateTime,remindersSent: null == remindersSent ? _self.remindersSent : remindersSent // ignore: cast_nullable_to_non_nullable
as int,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as String?,reasonText: freezed == reasonText ? _self.reasonText : reasonText // ignore: cast_nullable_to_non_nullable
as String?,noShowRisk: freezed == noShowRisk ? _self.noShowRisk : noShowRisk // ignore: cast_nullable_to_non_nullable
as double?,riskBand: freezed == riskBand ? _self.riskBand : riskBand // ignore: cast_nullable_to_non_nullable
as RiskBand?,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
