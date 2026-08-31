// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$KeyEvent {

 DateTime get date; String get title; String? get description; String? get category; String? get recordId;
/// Create a copy of KeyEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyEventCopyWith<KeyEvent> get copyWith => _$KeyEventCopyWithImpl<KeyEvent>(this as KeyEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyEvent&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.recordId, recordId) || other.recordId == recordId));
}


@override
int get hashCode => Object.hash(runtimeType,date,title,description,category,recordId);

@override
String toString() {
  return 'KeyEvent(date: $date, title: $title, description: $description, category: $category, recordId: $recordId)';
}


}

/// @nodoc
abstract mixin class $KeyEventCopyWith<$Res>  {
  factory $KeyEventCopyWith(KeyEvent value, $Res Function(KeyEvent) _then) = _$KeyEventCopyWithImpl;
@useResult
$Res call({
 DateTime date, String title, String? description, String? category, String? recordId
});




}
/// @nodoc
class _$KeyEventCopyWithImpl<$Res>
    implements $KeyEventCopyWith<$Res> {
  _$KeyEventCopyWithImpl(this._self, this._then);

  final KeyEvent _self;
  final $Res Function(KeyEvent) _then;

/// Create a copy of KeyEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? title = null,Object? description = freezed,Object? category = freezed,Object? recordId = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,recordId: freezed == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [KeyEvent].
extension KeyEventPatterns on KeyEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KeyEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KeyEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KeyEvent value)  $default,){
final _that = this;
switch (_that) {
case _KeyEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KeyEvent value)?  $default,){
final _that = this;
switch (_that) {
case _KeyEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  String title,  String? description,  String? category,  String? recordId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KeyEvent() when $default != null:
return $default(_that.date,_that.title,_that.description,_that.category,_that.recordId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  String title,  String? description,  String? category,  String? recordId)  $default,) {final _that = this;
switch (_that) {
case _KeyEvent():
return $default(_that.date,_that.title,_that.description,_that.category,_that.recordId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  String title,  String? description,  String? category,  String? recordId)?  $default,) {final _that = this;
switch (_that) {
case _KeyEvent() when $default != null:
return $default(_that.date,_that.title,_that.description,_that.category,_that.recordId);case _:
  return null;

}
}

}

/// @nodoc


class _KeyEvent implements KeyEvent {
  const _KeyEvent({required this.date, required this.title, this.description, this.category, this.recordId});
  

@override final  DateTime date;
@override final  String title;
@override final  String? description;
@override final  String? category;
@override final  String? recordId;

/// Create a copy of KeyEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KeyEventCopyWith<_KeyEvent> get copyWith => __$KeyEventCopyWithImpl<_KeyEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KeyEvent&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.recordId, recordId) || other.recordId == recordId));
}


@override
int get hashCode => Object.hash(runtimeType,date,title,description,category,recordId);

@override
String toString() {
  return 'KeyEvent(date: $date, title: $title, description: $description, category: $category, recordId: $recordId)';
}


}

/// @nodoc
abstract mixin class _$KeyEventCopyWith<$Res> implements $KeyEventCopyWith<$Res> {
  factory _$KeyEventCopyWith(_KeyEvent value, $Res Function(_KeyEvent) _then) = __$KeyEventCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String title, String? description, String? category, String? recordId
});




}
/// @nodoc
class __$KeyEventCopyWithImpl<$Res>
    implements _$KeyEventCopyWith<$Res> {
  __$KeyEventCopyWithImpl(this._self, this._then);

  final _KeyEvent _self;
  final $Res Function(_KeyEvent) _then;

/// Create a copy of KeyEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? title = null,Object? description = freezed,Object? category = freezed,Object? recordId = freezed,}) {
  return _then(_KeyEvent(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,recordId: freezed == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Trend {

 String get metric; String get direction; String get summary;
/// Create a copy of Trend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendCopyWith<Trend> get copyWith => _$TrendCopyWithImpl<Trend>(this as Trend, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trend&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,metric,direction,summary);

@override
String toString() {
  return 'Trend(metric: $metric, direction: $direction, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $TrendCopyWith<$Res>  {
  factory $TrendCopyWith(Trend value, $Res Function(Trend) _then) = _$TrendCopyWithImpl;
@useResult
$Res call({
 String metric, String direction, String summary
});




}
/// @nodoc
class _$TrendCopyWithImpl<$Res>
    implements $TrendCopyWith<$Res> {
  _$TrendCopyWithImpl(this._self, this._then);

  final Trend _self;
  final $Res Function(Trend) _then;

/// Create a copy of Trend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metric = null,Object? direction = null,Object? summary = null,}) {
  return _then(_self.copyWith(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Trend].
extension TrendPatterns on Trend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trend value)  $default,){
final _that = this;
switch (_that) {
case _Trend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trend value)?  $default,){
final _that = this;
switch (_that) {
case _Trend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String metric,  String direction,  String summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trend() when $default != null:
return $default(_that.metric,_that.direction,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String metric,  String direction,  String summary)  $default,) {final _that = this;
switch (_that) {
case _Trend():
return $default(_that.metric,_that.direction,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String metric,  String direction,  String summary)?  $default,) {final _that = this;
switch (_that) {
case _Trend() when $default != null:
return $default(_that.metric,_that.direction,_that.summary);case _:
  return null;

}
}

}

/// @nodoc


class _Trend implements Trend {
  const _Trend({required this.metric, required this.direction, required this.summary});
  

@override final  String metric;
@override final  String direction;
@override final  String summary;

/// Create a copy of Trend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendCopyWith<_Trend> get copyWith => __$TrendCopyWithImpl<_Trend>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trend&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,metric,direction,summary);

@override
String toString() {
  return 'Trend(metric: $metric, direction: $direction, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$TrendCopyWith<$Res> implements $TrendCopyWith<$Res> {
  factory _$TrendCopyWith(_Trend value, $Res Function(_Trend) _then) = __$TrendCopyWithImpl;
@override @useResult
$Res call({
 String metric, String direction, String summary
});




}
/// @nodoc
class __$TrendCopyWithImpl<$Res>
    implements _$TrendCopyWith<$Res> {
  __$TrendCopyWithImpl(this._self, this._then);

  final _Trend _self;
  final $Res Function(_Trend) _then;

/// Create a copy of Trend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metric = null,Object? direction = null,Object? summary = null,}) {
  return _then(_Trend(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RedFlag {

 Severity get severity; String get description;
/// Create a copy of RedFlag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RedFlagCopyWith<RedFlag> get copyWith => _$RedFlagCopyWithImpl<RedFlag>(this as RedFlag, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RedFlag&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,severity,description);

@override
String toString() {
  return 'RedFlag(severity: $severity, description: $description)';
}


}

/// @nodoc
abstract mixin class $RedFlagCopyWith<$Res>  {
  factory $RedFlagCopyWith(RedFlag value, $Res Function(RedFlag) _then) = _$RedFlagCopyWithImpl;
@useResult
$Res call({
 Severity severity, String description
});




}
/// @nodoc
class _$RedFlagCopyWithImpl<$Res>
    implements $RedFlagCopyWith<$Res> {
  _$RedFlagCopyWithImpl(this._self, this._then);

  final RedFlag _self;
  final $Res Function(RedFlag) _then;

/// Create a copy of RedFlag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? severity = null,Object? description = null,}) {
  return _then(_self.copyWith(
severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RedFlag].
extension RedFlagPatterns on RedFlag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RedFlag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RedFlag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RedFlag value)  $default,){
final _that = this;
switch (_that) {
case _RedFlag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RedFlag value)?  $default,){
final _that = this;
switch (_that) {
case _RedFlag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Severity severity,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RedFlag() when $default != null:
return $default(_that.severity,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Severity severity,  String description)  $default,) {final _that = this;
switch (_that) {
case _RedFlag():
return $default(_that.severity,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Severity severity,  String description)?  $default,) {final _that = this;
switch (_that) {
case _RedFlag() when $default != null:
return $default(_that.severity,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _RedFlag implements RedFlag {
  const _RedFlag({required this.severity, required this.description});
  

@override final  Severity severity;
@override final  String description;

/// Create a copy of RedFlag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RedFlagCopyWith<_RedFlag> get copyWith => __$RedFlagCopyWithImpl<_RedFlag>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RedFlag&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,severity,description);

@override
String toString() {
  return 'RedFlag(severity: $severity, description: $description)';
}


}

/// @nodoc
abstract mixin class _$RedFlagCopyWith<$Res> implements $RedFlagCopyWith<$Res> {
  factory _$RedFlagCopyWith(_RedFlag value, $Res Function(_RedFlag) _then) = __$RedFlagCopyWithImpl;
@override @useResult
$Res call({
 Severity severity, String description
});




}
/// @nodoc
class __$RedFlagCopyWithImpl<$Res>
    implements _$RedFlagCopyWith<$Res> {
  __$RedFlagCopyWithImpl(this._self, this._then);

  final _RedFlag _self;
  final $Res Function(_RedFlag) _then;

/// Create a copy of RedFlag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? severity = null,Object? description = null,}) {
  return _then(_RedFlag(
severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as Severity,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AiSummary {

 String get id; String get patientId; DateTime get generatedAt; String get modelId; String get promptVersion; String get summaryMarkdown; String get inputHash; List<KeyEvent> get keyEvents; List<Trend> get trends; List<RedFlag> get redFlags;
/// Create a copy of AiSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiSummaryCopyWith<AiSummary> get copyWith => _$AiSummaryCopyWithImpl<AiSummary>(this as AiSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&(identical(other.summaryMarkdown, summaryMarkdown) || other.summaryMarkdown == summaryMarkdown)&&(identical(other.inputHash, inputHash) || other.inputHash == inputHash)&&const DeepCollectionEquality().equals(other.keyEvents, keyEvents)&&const DeepCollectionEquality().equals(other.trends, trends)&&const DeepCollectionEquality().equals(other.redFlags, redFlags));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,generatedAt,modelId,promptVersion,summaryMarkdown,inputHash,const DeepCollectionEquality().hash(keyEvents),const DeepCollectionEquality().hash(trends),const DeepCollectionEquality().hash(redFlags));

@override
String toString() {
  return 'AiSummary(id: $id, patientId: $patientId, generatedAt: $generatedAt, modelId: $modelId, promptVersion: $promptVersion, summaryMarkdown: $summaryMarkdown, inputHash: $inputHash, keyEvents: $keyEvents, trends: $trends, redFlags: $redFlags)';
}


}

/// @nodoc
abstract mixin class $AiSummaryCopyWith<$Res>  {
  factory $AiSummaryCopyWith(AiSummary value, $Res Function(AiSummary) _then) = _$AiSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, DateTime generatedAt, String modelId, String promptVersion, String summaryMarkdown, String inputHash, List<KeyEvent> keyEvents, List<Trend> trends, List<RedFlag> redFlags
});




}
/// @nodoc
class _$AiSummaryCopyWithImpl<$Res>
    implements $AiSummaryCopyWith<$Res> {
  _$AiSummaryCopyWithImpl(this._self, this._then);

  final AiSummary _self;
  final $Res Function(AiSummary) _then;

/// Create a copy of AiSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? generatedAt = null,Object? modelId = null,Object? promptVersion = null,Object? summaryMarkdown = null,Object? inputHash = null,Object? keyEvents = null,Object? trends = null,Object? redFlags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,promptVersion: null == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String,summaryMarkdown: null == summaryMarkdown ? _self.summaryMarkdown : summaryMarkdown // ignore: cast_nullable_to_non_nullable
as String,inputHash: null == inputHash ? _self.inputHash : inputHash // ignore: cast_nullable_to_non_nullable
as String,keyEvents: null == keyEvents ? _self.keyEvents : keyEvents // ignore: cast_nullable_to_non_nullable
as List<KeyEvent>,trends: null == trends ? _self.trends : trends // ignore: cast_nullable_to_non_nullable
as List<Trend>,redFlags: null == redFlags ? _self.redFlags : redFlags // ignore: cast_nullable_to_non_nullable
as List<RedFlag>,
  ));
}

}


/// Adds pattern-matching-related methods to [AiSummary].
extension AiSummaryPatterns on AiSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiSummary value)  $default,){
final _that = this;
switch (_that) {
case _AiSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AiSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  DateTime generatedAt,  String modelId,  String promptVersion,  String summaryMarkdown,  String inputHash,  List<KeyEvent> keyEvents,  List<Trend> trends,  List<RedFlag> redFlags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiSummary() when $default != null:
return $default(_that.id,_that.patientId,_that.generatedAt,_that.modelId,_that.promptVersion,_that.summaryMarkdown,_that.inputHash,_that.keyEvents,_that.trends,_that.redFlags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  DateTime generatedAt,  String modelId,  String promptVersion,  String summaryMarkdown,  String inputHash,  List<KeyEvent> keyEvents,  List<Trend> trends,  List<RedFlag> redFlags)  $default,) {final _that = this;
switch (_that) {
case _AiSummary():
return $default(_that.id,_that.patientId,_that.generatedAt,_that.modelId,_that.promptVersion,_that.summaryMarkdown,_that.inputHash,_that.keyEvents,_that.trends,_that.redFlags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  DateTime generatedAt,  String modelId,  String promptVersion,  String summaryMarkdown,  String inputHash,  List<KeyEvent> keyEvents,  List<Trend> trends,  List<RedFlag> redFlags)?  $default,) {final _that = this;
switch (_that) {
case _AiSummary() when $default != null:
return $default(_that.id,_that.patientId,_that.generatedAt,_that.modelId,_that.promptVersion,_that.summaryMarkdown,_that.inputHash,_that.keyEvents,_that.trends,_that.redFlags);case _:
  return null;

}
}

}

/// @nodoc


class _AiSummary implements AiSummary {
  const _AiSummary({required this.id, required this.patientId, required this.generatedAt, required this.modelId, required this.promptVersion, required this.summaryMarkdown, required this.inputHash, final  List<KeyEvent> keyEvents = const [], final  List<Trend> trends = const [], final  List<RedFlag> redFlags = const []}): _keyEvents = keyEvents,_trends = trends,_redFlags = redFlags;
  

@override final  String id;
@override final  String patientId;
@override final  DateTime generatedAt;
@override final  String modelId;
@override final  String promptVersion;
@override final  String summaryMarkdown;
@override final  String inputHash;
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


/// Create a copy of AiSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiSummaryCopyWith<_AiSummary> get copyWith => __$AiSummaryCopyWithImpl<_AiSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&(identical(other.summaryMarkdown, summaryMarkdown) || other.summaryMarkdown == summaryMarkdown)&&(identical(other.inputHash, inputHash) || other.inputHash == inputHash)&&const DeepCollectionEquality().equals(other._keyEvents, _keyEvents)&&const DeepCollectionEquality().equals(other._trends, _trends)&&const DeepCollectionEquality().equals(other._redFlags, _redFlags));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,generatedAt,modelId,promptVersion,summaryMarkdown,inputHash,const DeepCollectionEquality().hash(_keyEvents),const DeepCollectionEquality().hash(_trends),const DeepCollectionEquality().hash(_redFlags));

@override
String toString() {
  return 'AiSummary(id: $id, patientId: $patientId, generatedAt: $generatedAt, modelId: $modelId, promptVersion: $promptVersion, summaryMarkdown: $summaryMarkdown, inputHash: $inputHash, keyEvents: $keyEvents, trends: $trends, redFlags: $redFlags)';
}


}

/// @nodoc
abstract mixin class _$AiSummaryCopyWith<$Res> implements $AiSummaryCopyWith<$Res> {
  factory _$AiSummaryCopyWith(_AiSummary value, $Res Function(_AiSummary) _then) = __$AiSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, DateTime generatedAt, String modelId, String promptVersion, String summaryMarkdown, String inputHash, List<KeyEvent> keyEvents, List<Trend> trends, List<RedFlag> redFlags
});




}
/// @nodoc
class __$AiSummaryCopyWithImpl<$Res>
    implements _$AiSummaryCopyWith<$Res> {
  __$AiSummaryCopyWithImpl(this._self, this._then);

  final _AiSummary _self;
  final $Res Function(_AiSummary) _then;

/// Create a copy of AiSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? generatedAt = null,Object? modelId = null,Object? promptVersion = null,Object? summaryMarkdown = null,Object? inputHash = null,Object? keyEvents = null,Object? trends = null,Object? redFlags = null,}) {
  return _then(_AiSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,promptVersion: null == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String,summaryMarkdown: null == summaryMarkdown ? _self.summaryMarkdown : summaryMarkdown // ignore: cast_nullable_to_non_nullable
as String,inputHash: null == inputHash ? _self.inputHash : inputHash // ignore: cast_nullable_to_non_nullable
as String,keyEvents: null == keyEvents ? _self._keyEvents : keyEvents // ignore: cast_nullable_to_non_nullable
as List<KeyEvent>,trends: null == trends ? _self._trends : trends // ignore: cast_nullable_to_non_nullable
as List<Trend>,redFlags: null == redFlags ? _self._redFlags : redFlags // ignore: cast_nullable_to_non_nullable
as List<RedFlag>,
  ));
}


}

// dart format on
