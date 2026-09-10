// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'referral_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReferralRequest {

 String get id; String get patientId; String get requestedByStaffId; String get reason; ReferralRequestStatus get status; DateTime get createdAt; String? get appointmentId; String? get decidedByAdminId; String? get decisionNote; DateTime? get decidedAt;
/// Create a copy of ReferralRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferralRequestCopyWith<ReferralRequest> get copyWith => _$ReferralRequestCopyWithImpl<ReferralRequest>(this as ReferralRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferralRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.requestedByStaffId, requestedByStaffId) || other.requestedByStaffId == requestedByStaffId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.decidedByAdminId, decidedByAdminId) || other.decidedByAdminId == decidedByAdminId)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,requestedByStaffId,reason,status,createdAt,appointmentId,decidedByAdminId,decisionNote,decidedAt);

@override
String toString() {
  return 'ReferralRequest(id: $id, patientId: $patientId, requestedByStaffId: $requestedByStaffId, reason: $reason, status: $status, createdAt: $createdAt, appointmentId: $appointmentId, decidedByAdminId: $decidedByAdminId, decisionNote: $decisionNote, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class $ReferralRequestCopyWith<$Res>  {
  factory $ReferralRequestCopyWith(ReferralRequest value, $Res Function(ReferralRequest) _then) = _$ReferralRequestCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, String requestedByStaffId, String reason, ReferralRequestStatus status, DateTime createdAt, String? appointmentId, String? decidedByAdminId, String? decisionNote, DateTime? decidedAt
});




}
/// @nodoc
class _$ReferralRequestCopyWithImpl<$Res>
    implements $ReferralRequestCopyWith<$Res> {
  _$ReferralRequestCopyWithImpl(this._self, this._then);

  final ReferralRequest _self;
  final $Res Function(ReferralRequest) _then;

/// Create a copy of ReferralRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? requestedByStaffId = null,Object? reason = null,Object? status = null,Object? createdAt = null,Object? appointmentId = freezed,Object? decidedByAdminId = freezed,Object? decisionNote = freezed,Object? decidedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,requestedByStaffId: null == requestedByStaffId ? _self.requestedByStaffId : requestedByStaffId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReferralRequestStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,decidedByAdminId: freezed == decidedByAdminId ? _self.decidedByAdminId : decidedByAdminId // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReferralRequest].
extension ReferralRequestPatterns on ReferralRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReferralRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReferralRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReferralRequest value)  $default,){
final _that = this;
switch (_that) {
case _ReferralRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReferralRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ReferralRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  String requestedByStaffId,  String reason,  ReferralRequestStatus status,  DateTime createdAt,  String? appointmentId,  String? decidedByAdminId,  String? decisionNote,  DateTime? decidedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReferralRequest() when $default != null:
return $default(_that.id,_that.patientId,_that.requestedByStaffId,_that.reason,_that.status,_that.createdAt,_that.appointmentId,_that.decidedByAdminId,_that.decisionNote,_that.decidedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  String requestedByStaffId,  String reason,  ReferralRequestStatus status,  DateTime createdAt,  String? appointmentId,  String? decidedByAdminId,  String? decisionNote,  DateTime? decidedAt)  $default,) {final _that = this;
switch (_that) {
case _ReferralRequest():
return $default(_that.id,_that.patientId,_that.requestedByStaffId,_that.reason,_that.status,_that.createdAt,_that.appointmentId,_that.decidedByAdminId,_that.decisionNote,_that.decidedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  String requestedByStaffId,  String reason,  ReferralRequestStatus status,  DateTime createdAt,  String? appointmentId,  String? decidedByAdminId,  String? decisionNote,  DateTime? decidedAt)?  $default,) {final _that = this;
switch (_that) {
case _ReferralRequest() when $default != null:
return $default(_that.id,_that.patientId,_that.requestedByStaffId,_that.reason,_that.status,_that.createdAt,_that.appointmentId,_that.decidedByAdminId,_that.decisionNote,_that.decidedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ReferralRequest extends ReferralRequest {
  const _ReferralRequest({required this.id, required this.patientId, required this.requestedByStaffId, required this.reason, required this.status, required this.createdAt, this.appointmentId, this.decidedByAdminId, this.decisionNote, this.decidedAt}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  String requestedByStaffId;
@override final  String reason;
@override final  ReferralRequestStatus status;
@override final  DateTime createdAt;
@override final  String? appointmentId;
@override final  String? decidedByAdminId;
@override final  String? decisionNote;
@override final  DateTime? decidedAt;

/// Create a copy of ReferralRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferralRequestCopyWith<_ReferralRequest> get copyWith => __$ReferralRequestCopyWithImpl<_ReferralRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReferralRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.requestedByStaffId, requestedByStaffId) || other.requestedByStaffId == requestedByStaffId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.decidedByAdminId, decidedByAdminId) || other.decidedByAdminId == decidedByAdminId)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,requestedByStaffId,reason,status,createdAt,appointmentId,decidedByAdminId,decisionNote,decidedAt);

@override
String toString() {
  return 'ReferralRequest(id: $id, patientId: $patientId, requestedByStaffId: $requestedByStaffId, reason: $reason, status: $status, createdAt: $createdAt, appointmentId: $appointmentId, decidedByAdminId: $decidedByAdminId, decisionNote: $decisionNote, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class _$ReferralRequestCopyWith<$Res> implements $ReferralRequestCopyWith<$Res> {
  factory _$ReferralRequestCopyWith(_ReferralRequest value, $Res Function(_ReferralRequest) _then) = __$ReferralRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, String requestedByStaffId, String reason, ReferralRequestStatus status, DateTime createdAt, String? appointmentId, String? decidedByAdminId, String? decisionNote, DateTime? decidedAt
});




}
/// @nodoc
class __$ReferralRequestCopyWithImpl<$Res>
    implements _$ReferralRequestCopyWith<$Res> {
  __$ReferralRequestCopyWithImpl(this._self, this._then);

  final _ReferralRequest _self;
  final $Res Function(_ReferralRequest) _then;

/// Create a copy of ReferralRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? requestedByStaffId = null,Object? reason = null,Object? status = null,Object? createdAt = null,Object? appointmentId = freezed,Object? decidedByAdminId = freezed,Object? decisionNote = freezed,Object? decidedAt = freezed,}) {
  return _then(_ReferralRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,requestedByStaffId: null == requestedByStaffId ? _self.requestedByStaffId : requestedByStaffId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReferralRequestStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,decidedByAdminId: freezed == decidedByAdminId ? _self.decidedByAdminId : decidedByAdminId // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
