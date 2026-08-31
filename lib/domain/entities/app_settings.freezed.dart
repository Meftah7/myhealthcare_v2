// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 bool get aiEnabled; bool get mockMode; String get modelId; double get aiTaskWeight; int get seedVersion; DateTime get updatedAt;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.aiEnabled, aiEnabled) || other.aiEnabled == aiEnabled)&&(identical(other.mockMode, mockMode) || other.mockMode == mockMode)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.aiTaskWeight, aiTaskWeight) || other.aiTaskWeight == aiTaskWeight)&&(identical(other.seedVersion, seedVersion) || other.seedVersion == seedVersion)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,aiEnabled,mockMode,modelId,aiTaskWeight,seedVersion,updatedAt);

@override
String toString() {
  return 'AppSettings(aiEnabled: $aiEnabled, mockMode: $mockMode, modelId: $modelId, aiTaskWeight: $aiTaskWeight, seedVersion: $seedVersion, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 bool aiEnabled, bool mockMode, String modelId, double aiTaskWeight, int seedVersion, DateTime updatedAt
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aiEnabled = null,Object? mockMode = null,Object? modelId = null,Object? aiTaskWeight = null,Object? seedVersion = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
aiEnabled: null == aiEnabled ? _self.aiEnabled : aiEnabled // ignore: cast_nullable_to_non_nullable
as bool,mockMode: null == mockMode ? _self.mockMode : mockMode // ignore: cast_nullable_to_non_nullable
as bool,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,aiTaskWeight: null == aiTaskWeight ? _self.aiTaskWeight : aiTaskWeight // ignore: cast_nullable_to_non_nullable
as double,seedVersion: null == seedVersion ? _self.seedVersion : seedVersion // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool aiEnabled,  bool mockMode,  String modelId,  double aiTaskWeight,  int seedVersion,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.aiEnabled,_that.mockMode,_that.modelId,_that.aiTaskWeight,_that.seedVersion,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool aiEnabled,  bool mockMode,  String modelId,  double aiTaskWeight,  int seedVersion,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.aiEnabled,_that.mockMode,_that.modelId,_that.aiTaskWeight,_that.seedVersion,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool aiEnabled,  bool mockMode,  String modelId,  double aiTaskWeight,  int seedVersion,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.aiEnabled,_that.mockMode,_that.modelId,_that.aiTaskWeight,_that.seedVersion,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings extends AppSettings {
  const _AppSettings({required this.aiEnabled, required this.mockMode, required this.modelId, required this.aiTaskWeight, required this.seedVersion, required this.updatedAt}): super._();
  

@override final  bool aiEnabled;
@override final  bool mockMode;
@override final  String modelId;
@override final  double aiTaskWeight;
@override final  int seedVersion;
@override final  DateTime updatedAt;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.aiEnabled, aiEnabled) || other.aiEnabled == aiEnabled)&&(identical(other.mockMode, mockMode) || other.mockMode == mockMode)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.aiTaskWeight, aiTaskWeight) || other.aiTaskWeight == aiTaskWeight)&&(identical(other.seedVersion, seedVersion) || other.seedVersion == seedVersion)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,aiEnabled,mockMode,modelId,aiTaskWeight,seedVersion,updatedAt);

@override
String toString() {
  return 'AppSettings(aiEnabled: $aiEnabled, mockMode: $mockMode, modelId: $modelId, aiTaskWeight: $aiTaskWeight, seedVersion: $seedVersion, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool aiEnabled, bool mockMode, String modelId, double aiTaskWeight, int seedVersion, DateTime updatedAt
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aiEnabled = null,Object? mockMode = null,Object? modelId = null,Object? aiTaskWeight = null,Object? seedVersion = null,Object? updatedAt = null,}) {
  return _then(_AppSettings(
aiEnabled: null == aiEnabled ? _self.aiEnabled : aiEnabled // ignore: cast_nullable_to_non_nullable
as bool,mockMode: null == mockMode ? _self.mockMode : mockMode // ignore: cast_nullable_to_non_nullable
as bool,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,aiTaskWeight: null == aiTaskWeight ? _self.aiTaskWeight : aiTaskWeight // ignore: cast_nullable_to_non_nullable
as double,seedVersion: null == seedVersion ? _self.seedVersion : seedVersion // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
