// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'password_reset_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PasswordResetRequest {

 String get id; String get userId; String get identifierEntered; DateTime get requestedAt; bool get resolved; String? get resolvedByStaffId; DateTime? get resolvedAt;
/// Create a copy of PasswordResetRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PasswordResetRequestCopyWith<PasswordResetRequest> get copyWith => _$PasswordResetRequestCopyWithImpl<PasswordResetRequest>(this as PasswordResetRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PasswordResetRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.identifierEntered, identifierEntered) || other.identifierEntered == identifierEntered)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.resolved, resolved) || other.resolved == resolved)&&(identical(other.resolvedByStaffId, resolvedByStaffId) || other.resolvedByStaffId == resolvedByStaffId)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,identifierEntered,requestedAt,resolved,resolvedByStaffId,resolvedAt);

@override
String toString() {
  return 'PasswordResetRequest(id: $id, userId: $userId, identifierEntered: $identifierEntered, requestedAt: $requestedAt, resolved: $resolved, resolvedByStaffId: $resolvedByStaffId, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class $PasswordResetRequestCopyWith<$Res>  {
  factory $PasswordResetRequestCopyWith(PasswordResetRequest value, $Res Function(PasswordResetRequest) _then) = _$PasswordResetRequestCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String identifierEntered, DateTime requestedAt, bool resolved, String? resolvedByStaffId, DateTime? resolvedAt
});




}
/// @nodoc
class _$PasswordResetRequestCopyWithImpl<$Res>
    implements $PasswordResetRequestCopyWith<$Res> {
  _$PasswordResetRequestCopyWithImpl(this._self, this._then);

  final PasswordResetRequest _self;
  final $Res Function(PasswordResetRequest) _then;

/// Create a copy of PasswordResetRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? identifierEntered = null,Object? requestedAt = null,Object? resolved = null,Object? resolvedByStaffId = freezed,Object? resolvedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,identifierEntered: null == identifierEntered ? _self.identifierEntered : identifierEntered // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolved: null == resolved ? _self.resolved : resolved // ignore: cast_nullable_to_non_nullable
as bool,resolvedByStaffId: freezed == resolvedByStaffId ? _self.resolvedByStaffId : resolvedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PasswordResetRequest].
extension PasswordResetRequestPatterns on PasswordResetRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PasswordResetRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PasswordResetRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PasswordResetRequest value)  $default,){
final _that = this;
switch (_that) {
case _PasswordResetRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PasswordResetRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PasswordResetRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String identifierEntered,  DateTime requestedAt,  bool resolved,  String? resolvedByStaffId,  DateTime? resolvedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PasswordResetRequest() when $default != null:
return $default(_that.id,_that.userId,_that.identifierEntered,_that.requestedAt,_that.resolved,_that.resolvedByStaffId,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String identifierEntered,  DateTime requestedAt,  bool resolved,  String? resolvedByStaffId,  DateTime? resolvedAt)  $default,) {final _that = this;
switch (_that) {
case _PasswordResetRequest():
return $default(_that.id,_that.userId,_that.identifierEntered,_that.requestedAt,_that.resolved,_that.resolvedByStaffId,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String identifierEntered,  DateTime requestedAt,  bool resolved,  String? resolvedByStaffId,  DateTime? resolvedAt)?  $default,) {final _that = this;
switch (_that) {
case _PasswordResetRequest() when $default != null:
return $default(_that.id,_that.userId,_that.identifierEntered,_that.requestedAt,_that.resolved,_that.resolvedByStaffId,_that.resolvedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PasswordResetRequest implements PasswordResetRequest {
  const _PasswordResetRequest({required this.id, required this.userId, required this.identifierEntered, required this.requestedAt, required this.resolved, this.resolvedByStaffId, this.resolvedAt});
  

@override final  String id;
@override final  String userId;
@override final  String identifierEntered;
@override final  DateTime requestedAt;
@override final  bool resolved;
@override final  String? resolvedByStaffId;
@override final  DateTime? resolvedAt;

/// Create a copy of PasswordResetRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PasswordResetRequestCopyWith<_PasswordResetRequest> get copyWith => __$PasswordResetRequestCopyWithImpl<_PasswordResetRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PasswordResetRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.identifierEntered, identifierEntered) || other.identifierEntered == identifierEntered)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.resolved, resolved) || other.resolved == resolved)&&(identical(other.resolvedByStaffId, resolvedByStaffId) || other.resolvedByStaffId == resolvedByStaffId)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,identifierEntered,requestedAt,resolved,resolvedByStaffId,resolvedAt);

@override
String toString() {
  return 'PasswordResetRequest(id: $id, userId: $userId, identifierEntered: $identifierEntered, requestedAt: $requestedAt, resolved: $resolved, resolvedByStaffId: $resolvedByStaffId, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class _$PasswordResetRequestCopyWith<$Res> implements $PasswordResetRequestCopyWith<$Res> {
  factory _$PasswordResetRequestCopyWith(_PasswordResetRequest value, $Res Function(_PasswordResetRequest) _then) = __$PasswordResetRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String identifierEntered, DateTime requestedAt, bool resolved, String? resolvedByStaffId, DateTime? resolvedAt
});




}
/// @nodoc
class __$PasswordResetRequestCopyWithImpl<$Res>
    implements _$PasswordResetRequestCopyWith<$Res> {
  __$PasswordResetRequestCopyWithImpl(this._self, this._then);

  final _PasswordResetRequest _self;
  final $Res Function(_PasswordResetRequest) _then;

/// Create a copy of PasswordResetRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? identifierEntered = null,Object? requestedAt = null,Object? resolved = null,Object? resolvedByStaffId = freezed,Object? resolvedAt = freezed,}) {
  return _then(_PasswordResetRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,identifierEntered: null == identifierEntered ? _self.identifierEntered : identifierEntered // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolved: null == resolved ? _self.resolved : resolved // ignore: cast_nullable_to_non_nullable
as bool,resolvedByStaffId: freezed == resolvedByStaffId ? _self.resolvedByStaffId : resolvedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
