// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_usage_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiUsageEntry {

 String get id; AiFeature get feature; DateTime get at;/// True when a live model produced the answer; false for the deterministic
/// offline fallback.
 bool get usedLiveModel; String? get userId;/// A one-line note — the prompt gist or the outcome.
 String? get summary;
/// Create a copy of AiUsageEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiUsageEntryCopyWith<AiUsageEntry> get copyWith => _$AiUsageEntryCopyWithImpl<AiUsageEntry>(this as AiUsageEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiUsageEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.feature, feature) || other.feature == feature)&&(identical(other.at, at) || other.at == at)&&(identical(other.usedLiveModel, usedLiveModel) || other.usedLiveModel == usedLiveModel)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,id,feature,at,usedLiveModel,userId,summary);

@override
String toString() {
  return 'AiUsageEntry(id: $id, feature: $feature, at: $at, usedLiveModel: $usedLiveModel, userId: $userId, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $AiUsageEntryCopyWith<$Res>  {
  factory $AiUsageEntryCopyWith(AiUsageEntry value, $Res Function(AiUsageEntry) _then) = _$AiUsageEntryCopyWithImpl;
@useResult
$Res call({
 String id, AiFeature feature, DateTime at, bool usedLiveModel, String? userId, String? summary
});




}
/// @nodoc
class _$AiUsageEntryCopyWithImpl<$Res>
    implements $AiUsageEntryCopyWith<$Res> {
  _$AiUsageEntryCopyWithImpl(this._self, this._then);

  final AiUsageEntry _self;
  final $Res Function(AiUsageEntry) _then;

/// Create a copy of AiUsageEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? feature = null,Object? at = null,Object? usedLiveModel = null,Object? userId = freezed,Object? summary = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,feature: null == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as AiFeature,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,usedLiveModel: null == usedLiveModel ? _self.usedLiveModel : usedLiveModel // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiUsageEntry].
extension AiUsageEntryPatterns on AiUsageEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiUsageEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiUsageEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiUsageEntry value)  $default,){
final _that = this;
switch (_that) {
case _AiUsageEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiUsageEntry value)?  $default,){
final _that = this;
switch (_that) {
case _AiUsageEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AiFeature feature,  DateTime at,  bool usedLiveModel,  String? userId,  String? summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiUsageEntry() when $default != null:
return $default(_that.id,_that.feature,_that.at,_that.usedLiveModel,_that.userId,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AiFeature feature,  DateTime at,  bool usedLiveModel,  String? userId,  String? summary)  $default,) {final _that = this;
switch (_that) {
case _AiUsageEntry():
return $default(_that.id,_that.feature,_that.at,_that.usedLiveModel,_that.userId,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AiFeature feature,  DateTime at,  bool usedLiveModel,  String? userId,  String? summary)?  $default,) {final _that = this;
switch (_that) {
case _AiUsageEntry() when $default != null:
return $default(_that.id,_that.feature,_that.at,_that.usedLiveModel,_that.userId,_that.summary);case _:
  return null;

}
}

}

/// @nodoc


class _AiUsageEntry implements AiUsageEntry {
  const _AiUsageEntry({required this.id, required this.feature, required this.at, required this.usedLiveModel, this.userId, this.summary});
  

@override final  String id;
@override final  AiFeature feature;
@override final  DateTime at;
/// True when a live model produced the answer; false for the deterministic
/// offline fallback.
@override final  bool usedLiveModel;
@override final  String? userId;
/// A one-line note — the prompt gist or the outcome.
@override final  String? summary;

/// Create a copy of AiUsageEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiUsageEntryCopyWith<_AiUsageEntry> get copyWith => __$AiUsageEntryCopyWithImpl<_AiUsageEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiUsageEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.feature, feature) || other.feature == feature)&&(identical(other.at, at) || other.at == at)&&(identical(other.usedLiveModel, usedLiveModel) || other.usedLiveModel == usedLiveModel)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,id,feature,at,usedLiveModel,userId,summary);

@override
String toString() {
  return 'AiUsageEntry(id: $id, feature: $feature, at: $at, usedLiveModel: $usedLiveModel, userId: $userId, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$AiUsageEntryCopyWith<$Res> implements $AiUsageEntryCopyWith<$Res> {
  factory _$AiUsageEntryCopyWith(_AiUsageEntry value, $Res Function(_AiUsageEntry) _then) = __$AiUsageEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, AiFeature feature, DateTime at, bool usedLiveModel, String? userId, String? summary
});




}
/// @nodoc
class __$AiUsageEntryCopyWithImpl<$Res>
    implements _$AiUsageEntryCopyWith<$Res> {
  __$AiUsageEntryCopyWithImpl(this._self, this._then);

  final _AiUsageEntry _self;
  final $Res Function(_AiUsageEntry) _then;

/// Create a copy of AiUsageEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? feature = null,Object? at = null,Object? usedLiveModel = null,Object? userId = freezed,Object? summary = freezed,}) {
  return _then(_AiUsageEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,feature: null == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as AiFeature,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,usedLiveModel: null == usedLiveModel ? _self.usedLiveModel : usedLiveModel // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
