// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'risk_flag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RiskFlag {

 String get id; String get patientId; RiskFlagKind get kind; Severity get severity; String get rationale; DateTime get detectedAt; FlagSource get source; String get dedupeKey; String? get acknowledgedBy; DateTime? get acknowledgedAt;
/// Create a copy of RiskFlag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskFlagCopyWith<RiskFlag> get copyWith => _$RiskFlagCopyWithImpl<RiskFlag>(this as RiskFlag, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskFlag&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.detectedAt, detectedAt) || other.detectedAt == detectedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.dedupeKey, dedupeKey) || other.dedupeKey == dedupeKey)&&(identical(other.acknowledgedBy, acknowledgedBy) || other.acknowledgedBy == acknowledgedBy)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,kind,severity,rationale,detectedAt,source,dedupeKey,acknowledgedBy,acknowledgedAt);

@override
String toString() {
  return 'RiskFlag(id: $id, patientId: $patientId, kind: $kind, severity: $severity, rationale: $rationale, detectedAt: $detectedAt, source: $source, dedupeKey: $dedupeKey, acknowledgedBy: $acknowledgedBy, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class $RiskFlagCopyWith<$Res>  {
  factory $RiskFlagCopyWith(RiskFlag value, $Res Function(RiskFlag) _then) = _$RiskFlagCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, RiskFlagKind kind, Severity severity, String rationale, DateTime detectedAt, FlagSource source, String dedupeKey, String? acknowledgedBy, DateTime? acknowledgedAt
});




}
/// @nodoc
class _$RiskFlagCopyWithImpl<$Res>
    implements $RiskFlagCopyWith<$Res> {
  _$RiskFlagCopyWithImpl(this._self, this._then);

  final RiskFlag _self;
  final $Res Function(RiskFlag) _then;

/// Create a copy of RiskFlag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? kind = null,Object? severity = null,Object? rationale = null,Object? detectedAt = null,Object? source = null,Object? dedupeKey = null,Object? acknowledgedBy = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RiskFlagKind,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,detectedAt: null == detectedAt ? _self.detectedAt : detectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as FlagSource,dedupeKey: null == dedupeKey ? _self.dedupeKey : dedupeKey // ignore: cast_nullable_to_non_nullable
as String,acknowledgedBy: freezed == acknowledgedBy ? _self.acknowledgedBy : acknowledgedBy // ignore: cast_nullable_to_non_nullable
as String?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RiskFlag].
extension RiskFlagPatterns on RiskFlag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiskFlag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiskFlag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiskFlag value)  $default,){
final _that = this;
switch (_that) {
case _RiskFlag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiskFlag value)?  $default,){
final _that = this;
switch (_that) {
case _RiskFlag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  RiskFlagKind kind,  Severity severity,  String rationale,  DateTime detectedAt,  FlagSource source,  String dedupeKey,  String? acknowledgedBy,  DateTime? acknowledgedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiskFlag() when $default != null:
return $default(_that.id,_that.patientId,_that.kind,_that.severity,_that.rationale,_that.detectedAt,_that.source,_that.dedupeKey,_that.acknowledgedBy,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  RiskFlagKind kind,  Severity severity,  String rationale,  DateTime detectedAt,  FlagSource source,  String dedupeKey,  String? acknowledgedBy,  DateTime? acknowledgedAt)  $default,) {final _that = this;
switch (_that) {
case _RiskFlag():
return $default(_that.id,_that.patientId,_that.kind,_that.severity,_that.rationale,_that.detectedAt,_that.source,_that.dedupeKey,_that.acknowledgedBy,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  RiskFlagKind kind,  Severity severity,  String rationale,  DateTime detectedAt,  FlagSource source,  String dedupeKey,  String? acknowledgedBy,  DateTime? acknowledgedAt)?  $default,) {final _that = this;
switch (_that) {
case _RiskFlag() when $default != null:
return $default(_that.id,_that.patientId,_that.kind,_that.severity,_that.rationale,_that.detectedAt,_that.source,_that.dedupeKey,_that.acknowledgedBy,_that.acknowledgedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RiskFlag extends RiskFlag {
  const _RiskFlag({required this.id, required this.patientId, required this.kind, required this.severity, required this.rationale, required this.detectedAt, required this.source, required this.dedupeKey, this.acknowledgedBy, this.acknowledgedAt}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  RiskFlagKind kind;
@override final  Severity severity;
@override final  String rationale;
@override final  DateTime detectedAt;
@override final  FlagSource source;
@override final  String dedupeKey;
@override final  String? acknowledgedBy;
@override final  DateTime? acknowledgedAt;

/// Create a copy of RiskFlag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiskFlagCopyWith<_RiskFlag> get copyWith => __$RiskFlagCopyWithImpl<_RiskFlag>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiskFlag&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.detectedAt, detectedAt) || other.detectedAt == detectedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.dedupeKey, dedupeKey) || other.dedupeKey == dedupeKey)&&(identical(other.acknowledgedBy, acknowledgedBy) || other.acknowledgedBy == acknowledgedBy)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,kind,severity,rationale,detectedAt,source,dedupeKey,acknowledgedBy,acknowledgedAt);

@override
String toString() {
  return 'RiskFlag(id: $id, patientId: $patientId, kind: $kind, severity: $severity, rationale: $rationale, detectedAt: $detectedAt, source: $source, dedupeKey: $dedupeKey, acknowledgedBy: $acknowledgedBy, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class _$RiskFlagCopyWith<$Res> implements $RiskFlagCopyWith<$Res> {
  factory _$RiskFlagCopyWith(_RiskFlag value, $Res Function(_RiskFlag) _then) = __$RiskFlagCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, RiskFlagKind kind, Severity severity, String rationale, DateTime detectedAt, FlagSource source, String dedupeKey, String? acknowledgedBy, DateTime? acknowledgedAt
});




}
/// @nodoc
class __$RiskFlagCopyWithImpl<$Res>
    implements _$RiskFlagCopyWith<$Res> {
  __$RiskFlagCopyWithImpl(this._self, this._then);

  final _RiskFlag _self;
  final $Res Function(_RiskFlag) _then;

/// Create a copy of RiskFlag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? kind = null,Object? severity = null,Object? rationale = null,Object? detectedAt = null,Object? source = null,Object? dedupeKey = null,Object? acknowledgedBy = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_RiskFlag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RiskFlagKind,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,detectedAt: null == detectedAt ? _self.detectedAt : detectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as FlagSource,dedupeKey: null == dedupeKey ? _self.dedupeKey : dedupeKey // ignore: cast_nullable_to_non_nullable
as String,acknowledgedBy: freezed == acknowledgedBy ? _self.acknowledgedBy : acknowledgedBy // ignore: cast_nullable_to_non_nullable
as String?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
