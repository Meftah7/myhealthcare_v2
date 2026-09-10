// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_in_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkInTicket {

 String get id; String get patientId; String get departmentId; String get ticketTag; WalkInStatus get status; String get createdByStaffId; DateTime get createdAt; String? get reason; String? get sourceAppointmentId; String? get claimedByStaffId; String? get resultAppointmentId; DateTime? get resolvedAt;
/// Create a copy of WalkInTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkInTicketCopyWith<WalkInTicket> get copyWith => _$WalkInTicketCopyWithImpl<WalkInTicket>(this as WalkInTicket, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkInTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.ticketTag, ticketTag) || other.ticketTag == ticketTag)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdByStaffId, createdByStaffId) || other.createdByStaffId == createdByStaffId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sourceAppointmentId, sourceAppointmentId) || other.sourceAppointmentId == sourceAppointmentId)&&(identical(other.claimedByStaffId, claimedByStaffId) || other.claimedByStaffId == claimedByStaffId)&&(identical(other.resultAppointmentId, resultAppointmentId) || other.resultAppointmentId == resultAppointmentId)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,departmentId,ticketTag,status,createdByStaffId,createdAt,reason,sourceAppointmentId,claimedByStaffId,resultAppointmentId,resolvedAt);

@override
String toString() {
  return 'WalkInTicket(id: $id, patientId: $patientId, departmentId: $departmentId, ticketTag: $ticketTag, status: $status, createdByStaffId: $createdByStaffId, createdAt: $createdAt, reason: $reason, sourceAppointmentId: $sourceAppointmentId, claimedByStaffId: $claimedByStaffId, resultAppointmentId: $resultAppointmentId, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class $WalkInTicketCopyWith<$Res>  {
  factory $WalkInTicketCopyWith(WalkInTicket value, $Res Function(WalkInTicket) _then) = _$WalkInTicketCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, String departmentId, String ticketTag, WalkInStatus status, String createdByStaffId, DateTime createdAt, String? reason, String? sourceAppointmentId, String? claimedByStaffId, String? resultAppointmentId, DateTime? resolvedAt
});




}
/// @nodoc
class _$WalkInTicketCopyWithImpl<$Res>
    implements $WalkInTicketCopyWith<$Res> {
  _$WalkInTicketCopyWithImpl(this._self, this._then);

  final WalkInTicket _self;
  final $Res Function(WalkInTicket) _then;

/// Create a copy of WalkInTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? departmentId = null,Object? ticketTag = null,Object? status = null,Object? createdByStaffId = null,Object? createdAt = null,Object? reason = freezed,Object? sourceAppointmentId = freezed,Object? claimedByStaffId = freezed,Object? resultAppointmentId = freezed,Object? resolvedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as String,ticketTag: null == ticketTag ? _self.ticketTag : ticketTag // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WalkInStatus,createdByStaffId: null == createdByStaffId ? _self.createdByStaffId : createdByStaffId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,sourceAppointmentId: freezed == sourceAppointmentId ? _self.sourceAppointmentId : sourceAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,claimedByStaffId: freezed == claimedByStaffId ? _self.claimedByStaffId : claimedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,resultAppointmentId: freezed == resultAppointmentId ? _self.resultAppointmentId : resultAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkInTicket].
extension WalkInTicketPatterns on WalkInTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalkInTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalkInTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalkInTicket value)  $default,){
final _that = this;
switch (_that) {
case _WalkInTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalkInTicket value)?  $default,){
final _that = this;
switch (_that) {
case _WalkInTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  String departmentId,  String ticketTag,  WalkInStatus status,  String createdByStaffId,  DateTime createdAt,  String? reason,  String? sourceAppointmentId,  String? claimedByStaffId,  String? resultAppointmentId,  DateTime? resolvedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalkInTicket() when $default != null:
return $default(_that.id,_that.patientId,_that.departmentId,_that.ticketTag,_that.status,_that.createdByStaffId,_that.createdAt,_that.reason,_that.sourceAppointmentId,_that.claimedByStaffId,_that.resultAppointmentId,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  String departmentId,  String ticketTag,  WalkInStatus status,  String createdByStaffId,  DateTime createdAt,  String? reason,  String? sourceAppointmentId,  String? claimedByStaffId,  String? resultAppointmentId,  DateTime? resolvedAt)  $default,) {final _that = this;
switch (_that) {
case _WalkInTicket():
return $default(_that.id,_that.patientId,_that.departmentId,_that.ticketTag,_that.status,_that.createdByStaffId,_that.createdAt,_that.reason,_that.sourceAppointmentId,_that.claimedByStaffId,_that.resultAppointmentId,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  String departmentId,  String ticketTag,  WalkInStatus status,  String createdByStaffId,  DateTime createdAt,  String? reason,  String? sourceAppointmentId,  String? claimedByStaffId,  String? resultAppointmentId,  DateTime? resolvedAt)?  $default,) {final _that = this;
switch (_that) {
case _WalkInTicket() when $default != null:
return $default(_that.id,_that.patientId,_that.departmentId,_that.ticketTag,_that.status,_that.createdByStaffId,_that.createdAt,_that.reason,_that.sourceAppointmentId,_that.claimedByStaffId,_that.resultAppointmentId,_that.resolvedAt);case _:
  return null;

}
}

}

/// @nodoc


class _WalkInTicket extends WalkInTicket {
  const _WalkInTicket({required this.id, required this.patientId, required this.departmentId, required this.ticketTag, required this.status, required this.createdByStaffId, required this.createdAt, this.reason, this.sourceAppointmentId, this.claimedByStaffId, this.resultAppointmentId, this.resolvedAt}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  String departmentId;
@override final  String ticketTag;
@override final  WalkInStatus status;
@override final  String createdByStaffId;
@override final  DateTime createdAt;
@override final  String? reason;
@override final  String? sourceAppointmentId;
@override final  String? claimedByStaffId;
@override final  String? resultAppointmentId;
@override final  DateTime? resolvedAt;

/// Create a copy of WalkInTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalkInTicketCopyWith<_WalkInTicket> get copyWith => __$WalkInTicketCopyWithImpl<_WalkInTicket>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalkInTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.ticketTag, ticketTag) || other.ticketTag == ticketTag)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdByStaffId, createdByStaffId) || other.createdByStaffId == createdByStaffId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sourceAppointmentId, sourceAppointmentId) || other.sourceAppointmentId == sourceAppointmentId)&&(identical(other.claimedByStaffId, claimedByStaffId) || other.claimedByStaffId == claimedByStaffId)&&(identical(other.resultAppointmentId, resultAppointmentId) || other.resultAppointmentId == resultAppointmentId)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,departmentId,ticketTag,status,createdByStaffId,createdAt,reason,sourceAppointmentId,claimedByStaffId,resultAppointmentId,resolvedAt);

@override
String toString() {
  return 'WalkInTicket(id: $id, patientId: $patientId, departmentId: $departmentId, ticketTag: $ticketTag, status: $status, createdByStaffId: $createdByStaffId, createdAt: $createdAt, reason: $reason, sourceAppointmentId: $sourceAppointmentId, claimedByStaffId: $claimedByStaffId, resultAppointmentId: $resultAppointmentId, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class _$WalkInTicketCopyWith<$Res> implements $WalkInTicketCopyWith<$Res> {
  factory _$WalkInTicketCopyWith(_WalkInTicket value, $Res Function(_WalkInTicket) _then) = __$WalkInTicketCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, String departmentId, String ticketTag, WalkInStatus status, String createdByStaffId, DateTime createdAt, String? reason, String? sourceAppointmentId, String? claimedByStaffId, String? resultAppointmentId, DateTime? resolvedAt
});




}
/// @nodoc
class __$WalkInTicketCopyWithImpl<$Res>
    implements _$WalkInTicketCopyWith<$Res> {
  __$WalkInTicketCopyWithImpl(this._self, this._then);

  final _WalkInTicket _self;
  final $Res Function(_WalkInTicket) _then;

/// Create a copy of WalkInTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? departmentId = null,Object? ticketTag = null,Object? status = null,Object? createdByStaffId = null,Object? createdAt = null,Object? reason = freezed,Object? sourceAppointmentId = freezed,Object? claimedByStaffId = freezed,Object? resultAppointmentId = freezed,Object? resolvedAt = freezed,}) {
  return _then(_WalkInTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as String,ticketTag: null == ticketTag ? _self.ticketTag : ticketTag // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WalkInStatus,createdByStaffId: null == createdByStaffId ? _self.createdByStaffId : createdByStaffId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,sourceAppointmentId: freezed == sourceAppointmentId ? _self.sourceAppointmentId : sourceAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,claimedByStaffId: freezed == claimedByStaffId ? _self.claimedByStaffId : claimedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,resultAppointmentId: freezed == resultAppointmentId ? _self.resultAppointmentId : resultAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
