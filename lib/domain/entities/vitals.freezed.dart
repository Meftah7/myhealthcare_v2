// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vitals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Vitals {

 String get id; String get patientId; DateTime get recordedAt; int? get systolic; int? get diastolic; int? get heartRate; double? get tempC; double? get weightKg; double? get heightCm; int? get spo2; double? get glucose; String? get recordedByStaffId;
/// Create a copy of Vitals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VitalsCopyWith<Vitals> get copyWith => _$VitalsCopyWithImpl<Vitals>(this as Vitals, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vitals&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.systolic, systolic) || other.systolic == systolic)&&(identical(other.diastolic, diastolic) || other.diastolic == diastolic)&&(identical(other.heartRate, heartRate) || other.heartRate == heartRate)&&(identical(other.tempC, tempC) || other.tempC == tempC)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.spo2, spo2) || other.spo2 == spo2)&&(identical(other.glucose, glucose) || other.glucose == glucose)&&(identical(other.recordedByStaffId, recordedByStaffId) || other.recordedByStaffId == recordedByStaffId));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,recordedAt,systolic,diastolic,heartRate,tempC,weightKg,heightCm,spo2,glucose,recordedByStaffId);

@override
String toString() {
  return 'Vitals(id: $id, patientId: $patientId, recordedAt: $recordedAt, systolic: $systolic, diastolic: $diastolic, heartRate: $heartRate, tempC: $tempC, weightKg: $weightKg, heightCm: $heightCm, spo2: $spo2, glucose: $glucose, recordedByStaffId: $recordedByStaffId)';
}


}

/// @nodoc
abstract mixin class $VitalsCopyWith<$Res>  {
  factory $VitalsCopyWith(Vitals value, $Res Function(Vitals) _then) = _$VitalsCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, DateTime recordedAt, int? systolic, int? diastolic, int? heartRate, double? tempC, double? weightKg, double? heightCm, int? spo2, double? glucose, String? recordedByStaffId
});




}
/// @nodoc
class _$VitalsCopyWithImpl<$Res>
    implements $VitalsCopyWith<$Res> {
  _$VitalsCopyWithImpl(this._self, this._then);

  final Vitals _self;
  final $Res Function(Vitals) _then;

/// Create a copy of Vitals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? recordedAt = null,Object? systolic = freezed,Object? diastolic = freezed,Object? heartRate = freezed,Object? tempC = freezed,Object? weightKg = freezed,Object? heightCm = freezed,Object? spo2 = freezed,Object? glucose = freezed,Object? recordedByStaffId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,systolic: freezed == systolic ? _self.systolic : systolic // ignore: cast_nullable_to_non_nullable
as int?,diastolic: freezed == diastolic ? _self.diastolic : diastolic // ignore: cast_nullable_to_non_nullable
as int?,heartRate: freezed == heartRate ? _self.heartRate : heartRate // ignore: cast_nullable_to_non_nullable
as int?,tempC: freezed == tempC ? _self.tempC : tempC // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,spo2: freezed == spo2 ? _self.spo2 : spo2 // ignore: cast_nullable_to_non_nullable
as int?,glucose: freezed == glucose ? _self.glucose : glucose // ignore: cast_nullable_to_non_nullable
as double?,recordedByStaffId: freezed == recordedByStaffId ? _self.recordedByStaffId : recordedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Vitals].
extension VitalsPatterns on Vitals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vitals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vitals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vitals value)  $default,){
final _that = this;
switch (_that) {
case _Vitals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vitals value)?  $default,){
final _that = this;
switch (_that) {
case _Vitals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  DateTime recordedAt,  int? systolic,  int? diastolic,  int? heartRate,  double? tempC,  double? weightKg,  double? heightCm,  int? spo2,  double? glucose,  String? recordedByStaffId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vitals() when $default != null:
return $default(_that.id,_that.patientId,_that.recordedAt,_that.systolic,_that.diastolic,_that.heartRate,_that.tempC,_that.weightKg,_that.heightCm,_that.spo2,_that.glucose,_that.recordedByStaffId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  DateTime recordedAt,  int? systolic,  int? diastolic,  int? heartRate,  double? tempC,  double? weightKg,  double? heightCm,  int? spo2,  double? glucose,  String? recordedByStaffId)  $default,) {final _that = this;
switch (_that) {
case _Vitals():
return $default(_that.id,_that.patientId,_that.recordedAt,_that.systolic,_that.diastolic,_that.heartRate,_that.tempC,_that.weightKg,_that.heightCm,_that.spo2,_that.glucose,_that.recordedByStaffId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  DateTime recordedAt,  int? systolic,  int? diastolic,  int? heartRate,  double? tempC,  double? weightKg,  double? heightCm,  int? spo2,  double? glucose,  String? recordedByStaffId)?  $default,) {final _that = this;
switch (_that) {
case _Vitals() when $default != null:
return $default(_that.id,_that.patientId,_that.recordedAt,_that.systolic,_that.diastolic,_that.heartRate,_that.tempC,_that.weightKg,_that.heightCm,_that.spo2,_that.glucose,_that.recordedByStaffId);case _:
  return null;

}
}

}

/// @nodoc


class _Vitals extends Vitals {
  const _Vitals({required this.id, required this.patientId, required this.recordedAt, this.systolic, this.diastolic, this.heartRate, this.tempC, this.weightKg, this.heightCm, this.spo2, this.glucose, this.recordedByStaffId}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  DateTime recordedAt;
@override final  int? systolic;
@override final  int? diastolic;
@override final  int? heartRate;
@override final  double? tempC;
@override final  double? weightKg;
@override final  double? heightCm;
@override final  int? spo2;
@override final  double? glucose;
@override final  String? recordedByStaffId;

/// Create a copy of Vitals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VitalsCopyWith<_Vitals> get copyWith => __$VitalsCopyWithImpl<_Vitals>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vitals&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.systolic, systolic) || other.systolic == systolic)&&(identical(other.diastolic, diastolic) || other.diastolic == diastolic)&&(identical(other.heartRate, heartRate) || other.heartRate == heartRate)&&(identical(other.tempC, tempC) || other.tempC == tempC)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.spo2, spo2) || other.spo2 == spo2)&&(identical(other.glucose, glucose) || other.glucose == glucose)&&(identical(other.recordedByStaffId, recordedByStaffId) || other.recordedByStaffId == recordedByStaffId));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,recordedAt,systolic,diastolic,heartRate,tempC,weightKg,heightCm,spo2,glucose,recordedByStaffId);

@override
String toString() {
  return 'Vitals(id: $id, patientId: $patientId, recordedAt: $recordedAt, systolic: $systolic, diastolic: $diastolic, heartRate: $heartRate, tempC: $tempC, weightKg: $weightKg, heightCm: $heightCm, spo2: $spo2, glucose: $glucose, recordedByStaffId: $recordedByStaffId)';
}


}

/// @nodoc
abstract mixin class _$VitalsCopyWith<$Res> implements $VitalsCopyWith<$Res> {
  factory _$VitalsCopyWith(_Vitals value, $Res Function(_Vitals) _then) = __$VitalsCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, DateTime recordedAt, int? systolic, int? diastolic, int? heartRate, double? tempC, double? weightKg, double? heightCm, int? spo2, double? glucose, String? recordedByStaffId
});




}
/// @nodoc
class __$VitalsCopyWithImpl<$Res>
    implements _$VitalsCopyWith<$Res> {
  __$VitalsCopyWithImpl(this._self, this._then);

  final _Vitals _self;
  final $Res Function(_Vitals) _then;

/// Create a copy of Vitals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? recordedAt = null,Object? systolic = freezed,Object? diastolic = freezed,Object? heartRate = freezed,Object? tempC = freezed,Object? weightKg = freezed,Object? heightCm = freezed,Object? spo2 = freezed,Object? glucose = freezed,Object? recordedByStaffId = freezed,}) {
  return _then(_Vitals(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,systolic: freezed == systolic ? _self.systolic : systolic // ignore: cast_nullable_to_non_nullable
as int?,diastolic: freezed == diastolic ? _self.diastolic : diastolic // ignore: cast_nullable_to_non_nullable
as int?,heartRate: freezed == heartRate ? _self.heartRate : heartRate // ignore: cast_nullable_to_non_nullable
as int?,tempC: freezed == tempC ? _self.tempC : tempC // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,spo2: freezed == spo2 ? _self.spo2 : spo2 // ignore: cast_nullable_to_non_nullable
as int?,glucose: freezed == glucose ? _self.glucose : glucose // ignore: cast_nullable_to_non_nullable
as double?,recordedByStaffId: freezed == recordedByStaffId ? _self.recordedByStaffId : recordedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
