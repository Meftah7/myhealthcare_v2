// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FamilyLink {

 String get id;/// The account whose data is being shared.
 String get ownerPatientId;/// The account being granted access.
 String get viewerPatientId; FamilyLinkPermission get permission; FamilyLinkStatus get status; DateTime get createdAt; DateTime? get respondedAt;
/// Create a copy of FamilyLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyLinkCopyWith<FamilyLink> get copyWith => _$FamilyLinkCopyWithImpl<FamilyLink>(this as FamilyLink, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyLink&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerPatientId, ownerPatientId) || other.ownerPatientId == ownerPatientId)&&(identical(other.viewerPatientId, viewerPatientId) || other.viewerPatientId == viewerPatientId)&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,ownerPatientId,viewerPatientId,permission,status,createdAt,respondedAt);

@override
String toString() {
  return 'FamilyLink(id: $id, ownerPatientId: $ownerPatientId, viewerPatientId: $viewerPatientId, permission: $permission, status: $status, createdAt: $createdAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class $FamilyLinkCopyWith<$Res>  {
  factory $FamilyLinkCopyWith(FamilyLink value, $Res Function(FamilyLink) _then) = _$FamilyLinkCopyWithImpl;
@useResult
$Res call({
 String id, String ownerPatientId, String viewerPatientId, FamilyLinkPermission permission, FamilyLinkStatus status, DateTime createdAt, DateTime? respondedAt
});




}
/// @nodoc
class _$FamilyLinkCopyWithImpl<$Res>
    implements $FamilyLinkCopyWith<$Res> {
  _$FamilyLinkCopyWithImpl(this._self, this._then);

  final FamilyLink _self;
  final $Res Function(FamilyLink) _then;

/// Create a copy of FamilyLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerPatientId = null,Object? viewerPatientId = null,Object? permission = null,Object? status = null,Object? createdAt = null,Object? respondedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerPatientId: null == ownerPatientId ? _self.ownerPatientId : ownerPatientId // ignore: cast_nullable_to_non_nullable
as String,viewerPatientId: null == viewerPatientId ? _self.viewerPatientId : viewerPatientId // ignore: cast_nullable_to_non_nullable
as String,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as FamilyLinkPermission,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FamilyLinkStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyLink].
extension FamilyLinkPatterns on FamilyLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyLink value)  $default,){
final _that = this;
switch (_that) {
case _FamilyLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyLink value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerPatientId,  String viewerPatientId,  FamilyLinkPermission permission,  FamilyLinkStatus status,  DateTime createdAt,  DateTime? respondedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyLink() when $default != null:
return $default(_that.id,_that.ownerPatientId,_that.viewerPatientId,_that.permission,_that.status,_that.createdAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerPatientId,  String viewerPatientId,  FamilyLinkPermission permission,  FamilyLinkStatus status,  DateTime createdAt,  DateTime? respondedAt)  $default,) {final _that = this;
switch (_that) {
case _FamilyLink():
return $default(_that.id,_that.ownerPatientId,_that.viewerPatientId,_that.permission,_that.status,_that.createdAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerPatientId,  String viewerPatientId,  FamilyLinkPermission permission,  FamilyLinkStatus status,  DateTime createdAt,  DateTime? respondedAt)?  $default,) {final _that = this;
switch (_that) {
case _FamilyLink() when $default != null:
return $default(_that.id,_that.ownerPatientId,_that.viewerPatientId,_that.permission,_that.status,_that.createdAt,_that.respondedAt);case _:
  return null;

}
}

}

/// @nodoc


class _FamilyLink extends FamilyLink {
  const _FamilyLink({required this.id, required this.ownerPatientId, required this.viewerPatientId, required this.permission, required this.status, required this.createdAt, this.respondedAt}): super._();
  

@override final  String id;
/// The account whose data is being shared.
@override final  String ownerPatientId;
/// The account being granted access.
@override final  String viewerPatientId;
@override final  FamilyLinkPermission permission;
@override final  FamilyLinkStatus status;
@override final  DateTime createdAt;
@override final  DateTime? respondedAt;

/// Create a copy of FamilyLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyLinkCopyWith<_FamilyLink> get copyWith => __$FamilyLinkCopyWithImpl<_FamilyLink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyLink&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerPatientId, ownerPatientId) || other.ownerPatientId == ownerPatientId)&&(identical(other.viewerPatientId, viewerPatientId) || other.viewerPatientId == viewerPatientId)&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,ownerPatientId,viewerPatientId,permission,status,createdAt,respondedAt);

@override
String toString() {
  return 'FamilyLink(id: $id, ownerPatientId: $ownerPatientId, viewerPatientId: $viewerPatientId, permission: $permission, status: $status, createdAt: $createdAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class _$FamilyLinkCopyWith<$Res> implements $FamilyLinkCopyWith<$Res> {
  factory _$FamilyLinkCopyWith(_FamilyLink value, $Res Function(_FamilyLink) _then) = __$FamilyLinkCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerPatientId, String viewerPatientId, FamilyLinkPermission permission, FamilyLinkStatus status, DateTime createdAt, DateTime? respondedAt
});




}
/// @nodoc
class __$FamilyLinkCopyWithImpl<$Res>
    implements _$FamilyLinkCopyWith<$Res> {
  __$FamilyLinkCopyWithImpl(this._self, this._then);

  final _FamilyLink _self;
  final $Res Function(_FamilyLink) _then;

/// Create a copy of FamilyLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerPatientId = null,Object? viewerPatientId = null,Object? permission = null,Object? status = null,Object? createdAt = null,Object? respondedAt = freezed,}) {
  return _then(_FamilyLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerPatientId: null == ownerPatientId ? _self.ownerPatientId : ownerPatientId // ignore: cast_nullable_to_non_nullable
as String,viewerPatientId: null == viewerPatientId ? _self.viewerPatientId : viewerPatientId // ignore: cast_nullable_to_non_nullable
as String,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as FamilyLinkPermission,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FamilyLinkStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
