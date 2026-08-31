// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PatientContext {

 String get patientId; String get contextText; String get hash; int get approxTokens;
/// Create a copy of PatientContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientContextCopyWith<PatientContext> get copyWith => _$PatientContextCopyWithImpl<PatientContext>(this as PatientContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientContext&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.contextText, contextText) || other.contextText == contextText)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.approxTokens, approxTokens) || other.approxTokens == approxTokens));
}


@override
int get hashCode => Object.hash(runtimeType,patientId,contextText,hash,approxTokens);

@override
String toString() {
  return 'PatientContext(patientId: $patientId, contextText: $contextText, hash: $hash, approxTokens: $approxTokens)';
}


}

/// @nodoc
abstract mixin class $PatientContextCopyWith<$Res>  {
  factory $PatientContextCopyWith(PatientContext value, $Res Function(PatientContext) _then) = _$PatientContextCopyWithImpl;
@useResult
$Res call({
 String patientId, String contextText, String hash, int approxTokens
});




}
/// @nodoc
class _$PatientContextCopyWithImpl<$Res>
    implements $PatientContextCopyWith<$Res> {
  _$PatientContextCopyWithImpl(this._self, this._then);

  final PatientContext _self;
  final $Res Function(PatientContext) _then;

/// Create a copy of PatientContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? patientId = null,Object? contextText = null,Object? hash = null,Object? approxTokens = null,}) {
  return _then(_self.copyWith(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,contextText: null == contextText ? _self.contextText : contextText // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,approxTokens: null == approxTokens ? _self.approxTokens : approxTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientContext].
extension PatientContextPatterns on PatientContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientContext value)  $default,){
final _that = this;
switch (_that) {
case _PatientContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientContext value)?  $default,){
final _that = this;
switch (_that) {
case _PatientContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String patientId,  String contextText,  String hash,  int approxTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientContext() when $default != null:
return $default(_that.patientId,_that.contextText,_that.hash,_that.approxTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String patientId,  String contextText,  String hash,  int approxTokens)  $default,) {final _that = this;
switch (_that) {
case _PatientContext():
return $default(_that.patientId,_that.contextText,_that.hash,_that.approxTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String patientId,  String contextText,  String hash,  int approxTokens)?  $default,) {final _that = this;
switch (_that) {
case _PatientContext() when $default != null:
return $default(_that.patientId,_that.contextText,_that.hash,_that.approxTokens);case _:
  return null;

}
}

}

/// @nodoc


class _PatientContext implements PatientContext {
  const _PatientContext({required this.patientId, required this.contextText, required this.hash, required this.approxTokens});
  

@override final  String patientId;
@override final  String contextText;
@override final  String hash;
@override final  int approxTokens;

/// Create a copy of PatientContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientContextCopyWith<_PatientContext> get copyWith => __$PatientContextCopyWithImpl<_PatientContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientContext&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.contextText, contextText) || other.contextText == contextText)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.approxTokens, approxTokens) || other.approxTokens == approxTokens));
}


@override
int get hashCode => Object.hash(runtimeType,patientId,contextText,hash,approxTokens);

@override
String toString() {
  return 'PatientContext(patientId: $patientId, contextText: $contextText, hash: $hash, approxTokens: $approxTokens)';
}


}

/// @nodoc
abstract mixin class _$PatientContextCopyWith<$Res> implements $PatientContextCopyWith<$Res> {
  factory _$PatientContextCopyWith(_PatientContext value, $Res Function(_PatientContext) _then) = __$PatientContextCopyWithImpl;
@override @useResult
$Res call({
 String patientId, String contextText, String hash, int approxTokens
});




}
/// @nodoc
class __$PatientContextCopyWithImpl<$Res>
    implements _$PatientContextCopyWith<$Res> {
  __$PatientContextCopyWithImpl(this._self, this._then);

  final _PatientContext _self;
  final $Res Function(_PatientContext) _then;

/// Create a copy of PatientContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? patientId = null,Object? contextText = null,Object? hash = null,Object? approxTokens = null,}) {
  return _then(_PatientContext(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,contextText: null == contextText ? _self.contextText : contextText // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,approxTokens: null == approxTokens ? _self.approxTokens : approxTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$HealthSummary {

 String get summaryMarkdown; String get modelId; String get promptVersion; List<KeyEvent> get keyEvents; List<Trend> get trends; List<RedFlag> get redFlags;
/// Create a copy of HealthSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthSummaryCopyWith<HealthSummary> get copyWith => _$HealthSummaryCopyWithImpl<HealthSummary>(this as HealthSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthSummary&&(identical(other.summaryMarkdown, summaryMarkdown) || other.summaryMarkdown == summaryMarkdown)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&const DeepCollectionEquality().equals(other.keyEvents, keyEvents)&&const DeepCollectionEquality().equals(other.trends, trends)&&const DeepCollectionEquality().equals(other.redFlags, redFlags));
}


@override
int get hashCode => Object.hash(runtimeType,summaryMarkdown,modelId,promptVersion,const DeepCollectionEquality().hash(keyEvents),const DeepCollectionEquality().hash(trends),const DeepCollectionEquality().hash(redFlags));

@override
String toString() {
  return 'HealthSummary(summaryMarkdown: $summaryMarkdown, modelId: $modelId, promptVersion: $promptVersion, keyEvents: $keyEvents, trends: $trends, redFlags: $redFlags)';
}


}

/// @nodoc
abstract mixin class $HealthSummaryCopyWith<$Res>  {
  factory $HealthSummaryCopyWith(HealthSummary value, $Res Function(HealthSummary) _then) = _$HealthSummaryCopyWithImpl;
@useResult
$Res call({
 String summaryMarkdown, String modelId, String promptVersion, List<KeyEvent> keyEvents, List<Trend> trends, List<RedFlag> redFlags
});




}
/// @nodoc
class _$HealthSummaryCopyWithImpl<$Res>
    implements $HealthSummaryCopyWith<$Res> {
  _$HealthSummaryCopyWithImpl(this._self, this._then);

  final HealthSummary _self;
  final $Res Function(HealthSummary) _then;

/// Create a copy of HealthSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summaryMarkdown = null,Object? modelId = null,Object? promptVersion = null,Object? keyEvents = null,Object? trends = null,Object? redFlags = null,}) {
  return _then(_self.copyWith(
summaryMarkdown: null == summaryMarkdown ? _self.summaryMarkdown : summaryMarkdown // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,promptVersion: null == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String,keyEvents: null == keyEvents ? _self.keyEvents : keyEvents // ignore: cast_nullable_to_non_nullable
as List<KeyEvent>,trends: null == trends ? _self.trends : trends // ignore: cast_nullable_to_non_nullable
as List<Trend>,redFlags: null == redFlags ? _self.redFlags : redFlags // ignore: cast_nullable_to_non_nullable
as List<RedFlag>,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthSummary].
extension HealthSummaryPatterns on HealthSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthSummary value)  $default,){
final _that = this;
switch (_that) {
case _HealthSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthSummary value)?  $default,){
final _that = this;
switch (_that) {
case _HealthSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summaryMarkdown,  String modelId,  String promptVersion,  List<KeyEvent> keyEvents,  List<Trend> trends,  List<RedFlag> redFlags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthSummary() when $default != null:
return $default(_that.summaryMarkdown,_that.modelId,_that.promptVersion,_that.keyEvents,_that.trends,_that.redFlags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summaryMarkdown,  String modelId,  String promptVersion,  List<KeyEvent> keyEvents,  List<Trend> trends,  List<RedFlag> redFlags)  $default,) {final _that = this;
switch (_that) {
case _HealthSummary():
return $default(_that.summaryMarkdown,_that.modelId,_that.promptVersion,_that.keyEvents,_that.trends,_that.redFlags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summaryMarkdown,  String modelId,  String promptVersion,  List<KeyEvent> keyEvents,  List<Trend> trends,  List<RedFlag> redFlags)?  $default,) {final _that = this;
switch (_that) {
case _HealthSummary() when $default != null:
return $default(_that.summaryMarkdown,_that.modelId,_that.promptVersion,_that.keyEvents,_that.trends,_that.redFlags);case _:
  return null;

}
}

}

/// @nodoc


class _HealthSummary implements HealthSummary {
  const _HealthSummary({required this.summaryMarkdown, required this.modelId, required this.promptVersion, final  List<KeyEvent> keyEvents = const [], final  List<Trend> trends = const [], final  List<RedFlag> redFlags = const []}): _keyEvents = keyEvents,_trends = trends,_redFlags = redFlags;
  

@override final  String summaryMarkdown;
@override final  String modelId;
@override final  String promptVersion;
 final  List<KeyEvent> _keyEvents;
@override@JsonKey() List<KeyEvent> get keyEvents {
  if (_keyEvents is EqualUnmodifiableListView) return _keyEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyEvents);
}

 final  List<Trend> _trends;
@override@JsonKey() List<Trend> get trends {
  if (_trends is EqualUnmodifiableListView) return _trends;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trends);
}

 final  List<RedFlag> _redFlags;
@override@JsonKey() List<RedFlag> get redFlags {
  if (_redFlags is EqualUnmodifiableListView) return _redFlags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redFlags);
}


/// Create a copy of HealthSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthSummaryCopyWith<_HealthSummary> get copyWith => __$HealthSummaryCopyWithImpl<_HealthSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthSummary&&(identical(other.summaryMarkdown, summaryMarkdown) || other.summaryMarkdown == summaryMarkdown)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&const DeepCollectionEquality().equals(other._keyEvents, _keyEvents)&&const DeepCollectionEquality().equals(other._trends, _trends)&&const DeepCollectionEquality().equals(other._redFlags, _redFlags));
}


@override
int get hashCode => Object.hash(runtimeType,summaryMarkdown,modelId,promptVersion,const DeepCollectionEquality().hash(_keyEvents),const DeepCollectionEquality().hash(_trends),const DeepCollectionEquality().hash(_redFlags));

@override
String toString() {
  return 'HealthSummary(summaryMarkdown: $summaryMarkdown, modelId: $modelId, promptVersion: $promptVersion, keyEvents: $keyEvents, trends: $trends, redFlags: $redFlags)';
}


}

/// @nodoc
abstract mixin class _$HealthSummaryCopyWith<$Res> implements $HealthSummaryCopyWith<$Res> {
  factory _$HealthSummaryCopyWith(_HealthSummary value, $Res Function(_HealthSummary) _then) = __$HealthSummaryCopyWithImpl;
@override @useResult
$Res call({
 String summaryMarkdown, String modelId, String promptVersion, List<KeyEvent> keyEvents, List<Trend> trends, List<RedFlag> redFlags
});




}
/// @nodoc
class __$HealthSummaryCopyWithImpl<$Res>
    implements _$HealthSummaryCopyWith<$Res> {
  __$HealthSummaryCopyWithImpl(this._self, this._then);

  final _HealthSummary _self;
  final $Res Function(_HealthSummary) _then;

/// Create a copy of HealthSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summaryMarkdown = null,Object? modelId = null,Object? promptVersion = null,Object? keyEvents = null,Object? trends = null,Object? redFlags = null,}) {
  return _then(_HealthSummary(
summaryMarkdown: null == summaryMarkdown ? _self.summaryMarkdown : summaryMarkdown // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,promptVersion: null == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String,keyEvents: null == keyEvents ? _self._keyEvents : keyEvents // ignore: cast_nullable_to_non_nullable
as List<KeyEvent>,trends: null == trends ? _self._trends : trends // ignore: cast_nullable_to_non_nullable
as List<Trend>,redFlags: null == redFlags ? _self._redFlags : redFlags // ignore: cast_nullable_to_non_nullable
as List<RedFlag>,
  ));
}


}

// dart format on
