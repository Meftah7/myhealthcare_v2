// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StaffTask {

 String get id; String get staffId; String get title; TaskKind get kind; TaskStatus get status; double get ruleScore; DateTime get createdAt; String? get patientId; DateTime? get dueAt; double? get aiPriorityScore; String? get aiRationale;
/// Create a copy of StaffTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffTaskCopyWith<StaffTask> get copyWith => _$StaffTaskCopyWithImpl<StaffTask>(this as StaffTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffTask&&(identical(other.id, id) || other.id == id)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.title, title) || other.title == title)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.ruleScore, ruleScore) || other.ruleScore == ruleScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.aiPriorityScore, aiPriorityScore) || other.aiPriorityScore == aiPriorityScore)&&(identical(other.aiRationale, aiRationale) || other.aiRationale == aiRationale));
}


@override
int get hashCode => Object.hash(runtimeType,id,staffId,title,kind,status,ruleScore,createdAt,patientId,dueAt,aiPriorityScore,aiRationale);

@override
String toString() {
  return 'StaffTask(id: $id, staffId: $staffId, title: $title, kind: $kind, status: $status, ruleScore: $ruleScore, createdAt: $createdAt, patientId: $patientId, dueAt: $dueAt, aiPriorityScore: $aiPriorityScore, aiRationale: $aiRationale)';
}


}

/// @nodoc
abstract mixin class $StaffTaskCopyWith<$Res>  {
  factory $StaffTaskCopyWith(StaffTask value, $Res Function(StaffTask) _then) = _$StaffTaskCopyWithImpl;
@useResult
$Res call({
 String id, String staffId, String title, TaskKind kind, TaskStatus status, double ruleScore, DateTime createdAt, String? patientId, DateTime? dueAt, double? aiPriorityScore, String? aiRationale
});




}
/// @nodoc
class _$StaffTaskCopyWithImpl<$Res>
    implements $StaffTaskCopyWith<$Res> {
  _$StaffTaskCopyWithImpl(this._self, this._then);

  final StaffTask _self;
  final $Res Function(StaffTask) _then;

/// Create a copy of StaffTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? staffId = null,Object? title = null,Object? kind = null,Object? status = null,Object? ruleScore = null,Object? createdAt = null,Object? patientId = freezed,Object? dueAt = freezed,Object? aiPriorityScore = freezed,Object? aiRationale = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TaskKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,ruleScore: null == ruleScore ? _self.ruleScore : ruleScore // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,patientId: freezed == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,aiPriorityScore: freezed == aiPriorityScore ? _self.aiPriorityScore : aiPriorityScore // ignore: cast_nullable_to_non_nullable
as double?,aiRationale: freezed == aiRationale ? _self.aiRationale : aiRationale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffTask].
extension StaffTaskPatterns on StaffTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffTask value)  $default,){
final _that = this;
switch (_that) {
case _StaffTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffTask value)?  $default,){
final _that = this;
switch (_that) {
case _StaffTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String staffId,  String title,  TaskKind kind,  TaskStatus status,  double ruleScore,  DateTime createdAt,  String? patientId,  DateTime? dueAt,  double? aiPriorityScore,  String? aiRationale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffTask() when $default != null:
return $default(_that.id,_that.staffId,_that.title,_that.kind,_that.status,_that.ruleScore,_that.createdAt,_that.patientId,_that.dueAt,_that.aiPriorityScore,_that.aiRationale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String staffId,  String title,  TaskKind kind,  TaskStatus status,  double ruleScore,  DateTime createdAt,  String? patientId,  DateTime? dueAt,  double? aiPriorityScore,  String? aiRationale)  $default,) {final _that = this;
switch (_that) {
case _StaffTask():
return $default(_that.id,_that.staffId,_that.title,_that.kind,_that.status,_that.ruleScore,_that.createdAt,_that.patientId,_that.dueAt,_that.aiPriorityScore,_that.aiRationale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String staffId,  String title,  TaskKind kind,  TaskStatus status,  double ruleScore,  DateTime createdAt,  String? patientId,  DateTime? dueAt,  double? aiPriorityScore,  String? aiRationale)?  $default,) {final _that = this;
switch (_that) {
case _StaffTask() when $default != null:
return $default(_that.id,_that.staffId,_that.title,_that.kind,_that.status,_that.ruleScore,_that.createdAt,_that.patientId,_that.dueAt,_that.aiPriorityScore,_that.aiRationale);case _:
  return null;

}
}

}

/// @nodoc


class _StaffTask extends StaffTask {
  const _StaffTask({required this.id, required this.staffId, required this.title, required this.kind, required this.status, required this.ruleScore, required this.createdAt, this.patientId, this.dueAt, this.aiPriorityScore, this.aiRationale}): super._();
  

@override final  String id;
@override final  String staffId;
@override final  String title;
@override final  TaskKind kind;
@override final  TaskStatus status;
@override final  double ruleScore;
@override final  DateTime createdAt;
@override final  String? patientId;
@override final  DateTime? dueAt;
@override final  double? aiPriorityScore;
@override final  String? aiRationale;

/// Create a copy of StaffTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffTaskCopyWith<_StaffTask> get copyWith => __$StaffTaskCopyWithImpl<_StaffTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffTask&&(identical(other.id, id) || other.id == id)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.title, title) || other.title == title)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.ruleScore, ruleScore) || other.ruleScore == ruleScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.aiPriorityScore, aiPriorityScore) || other.aiPriorityScore == aiPriorityScore)&&(identical(other.aiRationale, aiRationale) || other.aiRationale == aiRationale));
}


@override
int get hashCode => Object.hash(runtimeType,id,staffId,title,kind,status,ruleScore,createdAt,patientId,dueAt,aiPriorityScore,aiRationale);

@override
String toString() {
  return 'StaffTask(id: $id, staffId: $staffId, title: $title, kind: $kind, status: $status, ruleScore: $ruleScore, createdAt: $createdAt, patientId: $patientId, dueAt: $dueAt, aiPriorityScore: $aiPriorityScore, aiRationale: $aiRationale)';
}


}

/// @nodoc
abstract mixin class _$StaffTaskCopyWith<$Res> implements $StaffTaskCopyWith<$Res> {
  factory _$StaffTaskCopyWith(_StaffTask value, $Res Function(_StaffTask) _then) = __$StaffTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String staffId, String title, TaskKind kind, TaskStatus status, double ruleScore, DateTime createdAt, String? patientId, DateTime? dueAt, double? aiPriorityScore, String? aiRationale
});




}
/// @nodoc
class __$StaffTaskCopyWithImpl<$Res>
    implements _$StaffTaskCopyWith<$Res> {
  __$StaffTaskCopyWithImpl(this._self, this._then);

  final _StaffTask _self;
  final $Res Function(_StaffTask) _then;

/// Create a copy of StaffTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? staffId = null,Object? title = null,Object? kind = null,Object? status = null,Object? ruleScore = null,Object? createdAt = null,Object? patientId = freezed,Object? dueAt = freezed,Object? aiPriorityScore = freezed,Object? aiRationale = freezed,}) {
  return _then(_StaffTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TaskKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,ruleScore: null == ruleScore ? _self.ruleScore : ruleScore // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,patientId: freezed == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,aiPriorityScore: freezed == aiPriorityScore ? _self.aiPriorityScore : aiPriorityScore // ignore: cast_nullable_to_non_nullable
as double?,aiRationale: freezed == aiRationale ? _self.aiRationale : aiRationale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
