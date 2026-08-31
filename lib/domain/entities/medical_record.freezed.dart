// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medical_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LabValue {

 String get id; String get recordId; String get analyte; double get value; AbnormalFlag get abnormalFlag; String? get unit; double? get refLow; double? get refHigh;
/// Create a copy of LabValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabValueCopyWith<LabValue> get copyWith => _$LabValueCopyWithImpl<LabValue>(this as LabValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabValue&&(identical(other.id, id) || other.id == id)&&(identical(other.recordId, recordId) || other.recordId == recordId)&&(identical(other.analyte, analyte) || other.analyte == analyte)&&(identical(other.value, value) || other.value == value)&&(identical(other.abnormalFlag, abnormalFlag) || other.abnormalFlag == abnormalFlag)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.refLow, refLow) || other.refLow == refLow)&&(identical(other.refHigh, refHigh) || other.refHigh == refHigh));
}


@override
int get hashCode => Object.hash(runtimeType,id,recordId,analyte,value,abnormalFlag,unit,refLow,refHigh);

@override
String toString() {
  return 'LabValue(id: $id, recordId: $recordId, analyte: $analyte, value: $value, abnormalFlag: $abnormalFlag, unit: $unit, refLow: $refLow, refHigh: $refHigh)';
}


}

/// @nodoc
abstract mixin class $LabValueCopyWith<$Res>  {
  factory $LabValueCopyWith(LabValue value, $Res Function(LabValue) _then) = _$LabValueCopyWithImpl;
@useResult
$Res call({
 String id, String recordId, String analyte, double value, AbnormalFlag abnormalFlag, String? unit, double? refLow, double? refHigh
});




}
/// @nodoc
class _$LabValueCopyWithImpl<$Res>
    implements $LabValueCopyWith<$Res> {
  _$LabValueCopyWithImpl(this._self, this._then);

  final LabValue _self;
  final $Res Function(LabValue) _then;

/// Create a copy of LabValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recordId = null,Object? analyte = null,Object? value = null,Object? abnormalFlag = null,Object? unit = freezed,Object? refLow = freezed,Object? refHigh = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recordId: null == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String,analyte: null == analyte ? _self.analyte : analyte // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,abnormalFlag: null == abnormalFlag ? _self.abnormalFlag : abnormalFlag // ignore: cast_nullable_to_non_nullable
as AbnormalFlag,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,refLow: freezed == refLow ? _self.refLow : refLow // ignore: cast_nullable_to_non_nullable
as double?,refHigh: freezed == refHigh ? _self.refHigh : refHigh // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [LabValue].
extension LabValuePatterns on LabValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LabValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LabValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LabValue value)  $default,){
final _that = this;
switch (_that) {
case _LabValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LabValue value)?  $default,){
final _that = this;
switch (_that) {
case _LabValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String recordId,  String analyte,  double value,  AbnormalFlag abnormalFlag,  String? unit,  double? refLow,  double? refHigh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LabValue() when $default != null:
return $default(_that.id,_that.recordId,_that.analyte,_that.value,_that.abnormalFlag,_that.unit,_that.refLow,_that.refHigh);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String recordId,  String analyte,  double value,  AbnormalFlag abnormalFlag,  String? unit,  double? refLow,  double? refHigh)  $default,) {final _that = this;
switch (_that) {
case _LabValue():
return $default(_that.id,_that.recordId,_that.analyte,_that.value,_that.abnormalFlag,_that.unit,_that.refLow,_that.refHigh);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String recordId,  String analyte,  double value,  AbnormalFlag abnormalFlag,  String? unit,  double? refLow,  double? refHigh)?  $default,) {final _that = this;
switch (_that) {
case _LabValue() when $default != null:
return $default(_that.id,_that.recordId,_that.analyte,_that.value,_that.abnormalFlag,_that.unit,_that.refLow,_that.refHigh);case _:
  return null;

}
}

}

/// @nodoc


class _LabValue extends LabValue {
  const _LabValue({required this.id, required this.recordId, required this.analyte, required this.value, required this.abnormalFlag, this.unit, this.refLow, this.refHigh}): super._();
  

@override final  String id;
@override final  String recordId;
@override final  String analyte;
@override final  double value;
@override final  AbnormalFlag abnormalFlag;
@override final  String? unit;
@override final  double? refLow;
@override final  double? refHigh;

/// Create a copy of LabValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabValueCopyWith<_LabValue> get copyWith => __$LabValueCopyWithImpl<_LabValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabValue&&(identical(other.id, id) || other.id == id)&&(identical(other.recordId, recordId) || other.recordId == recordId)&&(identical(other.analyte, analyte) || other.analyte == analyte)&&(identical(other.value, value) || other.value == value)&&(identical(other.abnormalFlag, abnormalFlag) || other.abnormalFlag == abnormalFlag)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.refLow, refLow) || other.refLow == refLow)&&(identical(other.refHigh, refHigh) || other.refHigh == refHigh));
}


@override
int get hashCode => Object.hash(runtimeType,id,recordId,analyte,value,abnormalFlag,unit,refLow,refHigh);

@override
String toString() {
  return 'LabValue(id: $id, recordId: $recordId, analyte: $analyte, value: $value, abnormalFlag: $abnormalFlag, unit: $unit, refLow: $refLow, refHigh: $refHigh)';
}


}

/// @nodoc
abstract mixin class _$LabValueCopyWith<$Res> implements $LabValueCopyWith<$Res> {
  factory _$LabValueCopyWith(_LabValue value, $Res Function(_LabValue) _then) = __$LabValueCopyWithImpl;
@override @useResult
$Res call({
 String id, String recordId, String analyte, double value, AbnormalFlag abnormalFlag, String? unit, double? refLow, double? refHigh
});




}
/// @nodoc
class __$LabValueCopyWithImpl<$Res>
    implements _$LabValueCopyWith<$Res> {
  __$LabValueCopyWithImpl(this._self, this._then);

  final _LabValue _self;
  final $Res Function(_LabValue) _then;

/// Create a copy of LabValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recordId = null,Object? analyte = null,Object? value = null,Object? abnormalFlag = null,Object? unit = freezed,Object? refLow = freezed,Object? refHigh = freezed,}) {
  return _then(_LabValue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recordId: null == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String,analyte: null == analyte ? _self.analyte : analyte // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,abnormalFlag: null == abnormalFlag ? _self.abnormalFlag : abnormalFlag // ignore: cast_nullable_to_non_nullable
as AbnormalFlag,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,refLow: freezed == refLow ? _self.refLow : refLow // ignore: cast_nullable_to_non_nullable
as double?,refHigh: freezed == refHigh ? _self.refHigh : refHigh // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$MedicalRecord {

 String get id; String get patientId; RecordType get recordType; String get title; DateTime get occurredAt; DateTime get createdAt; List<LabValue> get labValues; String? get authorStaffId; String? get body; String? get sourceFacility; String? get attachmentPath; String? get extractedText;
/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalRecordCopyWith<MedicalRecord> get copyWith => _$MedicalRecordCopyWithImpl<MedicalRecord>(this as MedicalRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.title, title) || other.title == title)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.labValues, labValues)&&(identical(other.authorStaffId, authorStaffId) || other.authorStaffId == authorStaffId)&&(identical(other.body, body) || other.body == body)&&(identical(other.sourceFacility, sourceFacility) || other.sourceFacility == sourceFacility)&&(identical(other.attachmentPath, attachmentPath) || other.attachmentPath == attachmentPath)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,recordType,title,occurredAt,createdAt,const DeepCollectionEquality().hash(labValues),authorStaffId,body,sourceFacility,attachmentPath,extractedText);

@override
String toString() {
  return 'MedicalRecord(id: $id, patientId: $patientId, recordType: $recordType, title: $title, occurredAt: $occurredAt, createdAt: $createdAt, labValues: $labValues, authorStaffId: $authorStaffId, body: $body, sourceFacility: $sourceFacility, attachmentPath: $attachmentPath, extractedText: $extractedText)';
}


}

/// @nodoc
abstract mixin class $MedicalRecordCopyWith<$Res>  {
  factory $MedicalRecordCopyWith(MedicalRecord value, $Res Function(MedicalRecord) _then) = _$MedicalRecordCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, RecordType recordType, String title, DateTime occurredAt, DateTime createdAt, List<LabValue> labValues, String? authorStaffId, String? body, String? sourceFacility, String? attachmentPath, String? extractedText
});




}
/// @nodoc
class _$MedicalRecordCopyWithImpl<$Res>
    implements $MedicalRecordCopyWith<$Res> {
  _$MedicalRecordCopyWithImpl(this._self, this._then);

  final MedicalRecord _self;
  final $Res Function(MedicalRecord) _then;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? recordType = null,Object? title = null,Object? occurredAt = null,Object? createdAt = null,Object? labValues = null,Object? authorStaffId = freezed,Object? body = freezed,Object? sourceFacility = freezed,Object? attachmentPath = freezed,Object? extractedText = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,recordType: null == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as RecordType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,labValues: null == labValues ? _self.labValues : labValues // ignore: cast_nullable_to_non_nullable
as List<LabValue>,authorStaffId: freezed == authorStaffId ? _self.authorStaffId : authorStaffId // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,sourceFacility: freezed == sourceFacility ? _self.sourceFacility : sourceFacility // ignore: cast_nullable_to_non_nullable
as String?,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,extractedText: freezed == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicalRecord].
extension MedicalRecordPatterns on MedicalRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicalRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicalRecord value)  $default,){
final _that = this;
switch (_that) {
case _MedicalRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicalRecord value)?  $default,){
final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  RecordType recordType,  String title,  DateTime occurredAt,  DateTime createdAt,  List<LabValue> labValues,  String? authorStaffId,  String? body,  String? sourceFacility,  String? attachmentPath,  String? extractedText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
return $default(_that.id,_that.patientId,_that.recordType,_that.title,_that.occurredAt,_that.createdAt,_that.labValues,_that.authorStaffId,_that.body,_that.sourceFacility,_that.attachmentPath,_that.extractedText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  RecordType recordType,  String title,  DateTime occurredAt,  DateTime createdAt,  List<LabValue> labValues,  String? authorStaffId,  String? body,  String? sourceFacility,  String? attachmentPath,  String? extractedText)  $default,) {final _that = this;
switch (_that) {
case _MedicalRecord():
return $default(_that.id,_that.patientId,_that.recordType,_that.title,_that.occurredAt,_that.createdAt,_that.labValues,_that.authorStaffId,_that.body,_that.sourceFacility,_that.attachmentPath,_that.extractedText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  RecordType recordType,  String title,  DateTime occurredAt,  DateTime createdAt,  List<LabValue> labValues,  String? authorStaffId,  String? body,  String? sourceFacility,  String? attachmentPath,  String? extractedText)?  $default,) {final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
return $default(_that.id,_that.patientId,_that.recordType,_that.title,_that.occurredAt,_that.createdAt,_that.labValues,_that.authorStaffId,_that.body,_that.sourceFacility,_that.attachmentPath,_that.extractedText);case _:
  return null;

}
}

}

/// @nodoc


class _MedicalRecord extends MedicalRecord {
  const _MedicalRecord({required this.id, required this.patientId, required this.recordType, required this.title, required this.occurredAt, required this.createdAt, final  List<LabValue> labValues = const [], this.authorStaffId, this.body, this.sourceFacility, this.attachmentPath, this.extractedText}): _labValues = labValues,super._();
  

@override final  String id;
@override final  String patientId;
@override final  RecordType recordType;
@override final  String title;
@override final  DateTime occurredAt;
@override final  DateTime createdAt;
 final  List<LabValue> _labValues;
@override@JsonKey() List<LabValue> get labValues {
  if (_labValues is EqualUnmodifiableListView) return _labValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labValues);
}

@override final  String? authorStaffId;
@override final  String? body;
@override final  String? sourceFacility;
@override final  String? attachmentPath;
@override final  String? extractedText;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalRecordCopyWith<_MedicalRecord> get copyWith => __$MedicalRecordCopyWithImpl<_MedicalRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.title, title) || other.title == title)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._labValues, _labValues)&&(identical(other.authorStaffId, authorStaffId) || other.authorStaffId == authorStaffId)&&(identical(other.body, body) || other.body == body)&&(identical(other.sourceFacility, sourceFacility) || other.sourceFacility == sourceFacility)&&(identical(other.attachmentPath, attachmentPath) || other.attachmentPath == attachmentPath)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,recordType,title,occurredAt,createdAt,const DeepCollectionEquality().hash(_labValues),authorStaffId,body,sourceFacility,attachmentPath,extractedText);

@override
String toString() {
  return 'MedicalRecord(id: $id, patientId: $patientId, recordType: $recordType, title: $title, occurredAt: $occurredAt, createdAt: $createdAt, labValues: $labValues, authorStaffId: $authorStaffId, body: $body, sourceFacility: $sourceFacility, attachmentPath: $attachmentPath, extractedText: $extractedText)';
}


}

/// @nodoc
abstract mixin class _$MedicalRecordCopyWith<$Res> implements $MedicalRecordCopyWith<$Res> {
  factory _$MedicalRecordCopyWith(_MedicalRecord value, $Res Function(_MedicalRecord) _then) = __$MedicalRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, RecordType recordType, String title, DateTime occurredAt, DateTime createdAt, List<LabValue> labValues, String? authorStaffId, String? body, String? sourceFacility, String? attachmentPath, String? extractedText
});




}
/// @nodoc
class __$MedicalRecordCopyWithImpl<$Res>
    implements _$MedicalRecordCopyWith<$Res> {
  __$MedicalRecordCopyWithImpl(this._self, this._then);

  final _MedicalRecord _self;
  final $Res Function(_MedicalRecord) _then;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? recordType = null,Object? title = null,Object? occurredAt = null,Object? createdAt = null,Object? labValues = null,Object? authorStaffId = freezed,Object? body = freezed,Object? sourceFacility = freezed,Object? attachmentPath = freezed,Object? extractedText = freezed,}) {
  return _then(_MedicalRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,recordType: null == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as RecordType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,labValues: null == labValues ? _self._labValues : labValues // ignore: cast_nullable_to_non_nullable
as List<LabValue>,authorStaffId: freezed == authorStaffId ? _self.authorStaffId : authorStaffId // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,sourceFacility: freezed == sourceFacility ? _self.sourceFacility : sourceFacility // ignore: cast_nullable_to_non_nullable
as String?,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,extractedText: freezed == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
