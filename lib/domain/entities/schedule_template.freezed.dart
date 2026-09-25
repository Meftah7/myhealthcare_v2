// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScheduleTemplate {

 String get id; String get staffId;/// 1 = Monday … 7 = Sunday (`DateTime.weekday`).
 int get weekday;/// Minutes from midnight, local clinic time.
 int get startMinutes; int get endMinutes; int get slotMinutes;
/// Create a copy of ScheduleTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleTemplateCopyWith<ScheduleTemplate> get copyWith => _$ScheduleTemplateCopyWithImpl<ScheduleTemplate>(this as ScheduleTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.startMinutes, startMinutes) || other.startMinutes == startMinutes)&&(identical(other.endMinutes, endMinutes) || other.endMinutes == endMinutes)&&(identical(other.slotMinutes, slotMinutes) || other.slotMinutes == slotMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,id,staffId,weekday,startMinutes,endMinutes,slotMinutes);

@override
String toString() {
  return 'ScheduleTemplate(id: $id, staffId: $staffId, weekday: $weekday, startMinutes: $startMinutes, endMinutes: $endMinutes, slotMinutes: $slotMinutes)';
}


}

/// @nodoc
abstract mixin class $ScheduleTemplateCopyWith<$Res>  {
  factory $ScheduleTemplateCopyWith(ScheduleTemplate value, $Res Function(ScheduleTemplate) _then) = _$ScheduleTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String staffId, int weekday, int startMinutes, int endMinutes, int slotMinutes
});




}
/// @nodoc
class _$ScheduleTemplateCopyWithImpl<$Res>
    implements $ScheduleTemplateCopyWith<$Res> {
  _$ScheduleTemplateCopyWithImpl(this._self, this._then);

  final ScheduleTemplate _self;
  final $Res Function(ScheduleTemplate) _then;

/// Create a copy of ScheduleTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? staffId = null,Object? weekday = null,Object? startMinutes = null,Object? endMinutes = null,Object? slotMinutes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,startMinutes: null == startMinutes ? _self.startMinutes : startMinutes // ignore: cast_nullable_to_non_nullable
as int,endMinutes: null == endMinutes ? _self.endMinutes : endMinutes // ignore: cast_nullable_to_non_nullable
as int,slotMinutes: null == slotMinutes ? _self.slotMinutes : slotMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleTemplate].
extension ScheduleTemplatePatterns on ScheduleTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleTemplate value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String staffId,  int weekday,  int startMinutes,  int endMinutes,  int slotMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleTemplate() when $default != null:
return $default(_that.id,_that.staffId,_that.weekday,_that.startMinutes,_that.endMinutes,_that.slotMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String staffId,  int weekday,  int startMinutes,  int endMinutes,  int slotMinutes)  $default,) {final _that = this;
switch (_that) {
case _ScheduleTemplate():
return $default(_that.id,_that.staffId,_that.weekday,_that.startMinutes,_that.endMinutes,_that.slotMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String staffId,  int weekday,  int startMinutes,  int endMinutes,  int slotMinutes)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleTemplate() when $default != null:
return $default(_that.id,_that.staffId,_that.weekday,_that.startMinutes,_that.endMinutes,_that.slotMinutes);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduleTemplate implements ScheduleTemplate {
  const _ScheduleTemplate({required this.id, required this.staffId, required this.weekday, required this.startMinutes, required this.endMinutes, required this.slotMinutes});
  

@override final  String id;
@override final  String staffId;
/// 1 = Monday … 7 = Sunday (`DateTime.weekday`).
@override final  int weekday;
/// Minutes from midnight, local clinic time.
@override final  int startMinutes;
@override final  int endMinutes;
@override final  int slotMinutes;

/// Create a copy of ScheduleTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleTemplateCopyWith<_ScheduleTemplate> get copyWith => __$ScheduleTemplateCopyWithImpl<_ScheduleTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.startMinutes, startMinutes) || other.startMinutes == startMinutes)&&(identical(other.endMinutes, endMinutes) || other.endMinutes == endMinutes)&&(identical(other.slotMinutes, slotMinutes) || other.slotMinutes == slotMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,id,staffId,weekday,startMinutes,endMinutes,slotMinutes);

@override
String toString() {
  return 'ScheduleTemplate(id: $id, staffId: $staffId, weekday: $weekday, startMinutes: $startMinutes, endMinutes: $endMinutes, slotMinutes: $slotMinutes)';
}


}

/// @nodoc
abstract mixin class _$ScheduleTemplateCopyWith<$Res> implements $ScheduleTemplateCopyWith<$Res> {
  factory _$ScheduleTemplateCopyWith(_ScheduleTemplate value, $Res Function(_ScheduleTemplate) _then) = __$ScheduleTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String staffId, int weekday, int startMinutes, int endMinutes, int slotMinutes
});




}
/// @nodoc
class __$ScheduleTemplateCopyWithImpl<$Res>
    implements _$ScheduleTemplateCopyWith<$Res> {
  __$ScheduleTemplateCopyWithImpl(this._self, this._then);

  final _ScheduleTemplate _self;
  final $Res Function(_ScheduleTemplate) _then;

/// Create a copy of ScheduleTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? staffId = null,Object? weekday = null,Object? startMinutes = null,Object? endMinutes = null,Object? slotMinutes = null,}) {
  return _then(_ScheduleTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,startMinutes: null == startMinutes ? _self.startMinutes : startMinutes // ignore: cast_nullable_to_non_nullable
as int,endMinutes: null == endMinutes ? _self.endMinutes : endMinutes // ignore: cast_nullable_to_non_nullable
as int,slotMinutes: null == slotMinutes ? _self.slotMinutes : slotMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
