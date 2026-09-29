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

 String get id; String get recordId; String get analyte; double get value; AbnormalFlag get abnormalFlag; String? get unit; double? get refLow; double? get refHigh;/// Where the value came from (analyser, outside lab, patient import).
 String? get source;/// Which rules judged it, and any transformation applied (Phase 4).
 String? get provenance; VerificationStatus get verificationStatus; String? get verifiedByStaffId; DateTime? get verifiedAt;
/// Create a copy of LabValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabValueCopyWith<LabValue> get copyWith => _$LabValueCopyWithImpl<LabValue>(this as LabValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabValue&&(identical(other.id, id) || other.id == id)&&(identical(other.recordId, recordId) || other.recordId == recordId)&&(identical(other.analyte, analyte) || other.analyte == analyte)&&(identical(other.value, value) || other.value == value)&&(identical(other.abnormalFlag, abnormalFlag) || other.abnormalFlag == abnormalFlag)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.refLow, refLow) || other.refLow == refLow)&&(identical(other.refHigh, refHigh) || other.refHigh == refHigh)&&(identical(other.source, source) || other.source == source)&&(identical(other.provenance, provenance) || other.provenance == provenance)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.verifiedByStaffId, verifiedByStaffId) || other.verifiedByStaffId == verifiedByStaffId)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,recordId,analyte,value,abnormalFlag,unit,refLow,refHigh,source,provenance,verificationStatus,verifiedByStaffId,verifiedAt);

@override
String toString() {
  return 'LabValue(id: $id, recordId: $recordId, analyte: $analyte, value: $value, abnormalFlag: $abnormalFlag, unit: $unit, refLow: $refLow, refHigh: $refHigh, source: $source, provenance: $provenance, verificationStatus: $verificationStatus, verifiedByStaffId: $verifiedByStaffId, verifiedAt: $verifiedAt)';
}


}

/// @nodoc
abstract mixin class $LabValueCopyWith<$Res>  {
  factory $LabValueCopyWith(LabValue value, $Res Function(LabValue) _then) = _$LabValueCopyWithImpl;
@useResult
$Res call({
 String id, String recordId, String analyte, double value, AbnormalFlag abnormalFlag, String? unit, double? refLow, double? refHigh, String? source, String? provenance, VerificationStatus verificationStatus, String? verifiedByStaffId, DateTime? verifiedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recordId = null,Object? analyte = null,Object? value = null,Object? abnormalFlag = null,Object? unit = freezed,Object? refLow = freezed,Object? refHigh = freezed,Object? source = freezed,Object? provenance = freezed,Object? verificationStatus = null,Object? verifiedByStaffId = freezed,Object? verifiedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recordId: null == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String,analyte: null == analyte ? _self.analyte : analyte // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,abnormalFlag: null == abnormalFlag ? _self.abnormalFlag : abnormalFlag // ignore: cast_nullable_to_non_nullable
as AbnormalFlag,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,refLow: freezed == refLow ? _self.refLow : refLow // ignore: cast_nullable_to_non_nullable
as double?,refHigh: freezed == refHigh ? _self.refHigh : refHigh // ignore: cast_nullable_to_non_nullable
as double?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,provenance: freezed == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as String?,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,verifiedByStaffId: freezed == verifiedByStaffId ? _self.verifiedByStaffId : verifiedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String recordId,  String analyte,  double value,  AbnormalFlag abnormalFlag,  String? unit,  double? refLow,  double? refHigh,  String? source,  String? provenance,  VerificationStatus verificationStatus,  String? verifiedByStaffId,  DateTime? verifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LabValue() when $default != null:
return $default(_that.id,_that.recordId,_that.analyte,_that.value,_that.abnormalFlag,_that.unit,_that.refLow,_that.refHigh,_that.source,_that.provenance,_that.verificationStatus,_that.verifiedByStaffId,_that.verifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String recordId,  String analyte,  double value,  AbnormalFlag abnormalFlag,  String? unit,  double? refLow,  double? refHigh,  String? source,  String? provenance,  VerificationStatus verificationStatus,  String? verifiedByStaffId,  DateTime? verifiedAt)  $default,) {final _that = this;
switch (_that) {
case _LabValue():
return $default(_that.id,_that.recordId,_that.analyte,_that.value,_that.abnormalFlag,_that.unit,_that.refLow,_that.refHigh,_that.source,_that.provenance,_that.verificationStatus,_that.verifiedByStaffId,_that.verifiedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String recordId,  String analyte,  double value,  AbnormalFlag abnormalFlag,  String? unit,  double? refLow,  double? refHigh,  String? source,  String? provenance,  VerificationStatus verificationStatus,  String? verifiedByStaffId,  DateTime? verifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _LabValue() when $default != null:
return $default(_that.id,_that.recordId,_that.analyte,_that.value,_that.abnormalFlag,_that.unit,_that.refLow,_that.refHigh,_that.source,_that.provenance,_that.verificationStatus,_that.verifiedByStaffId,_that.verifiedAt);case _:
  return null;

}
}

}

/// @nodoc


class _LabValue extends LabValue {
  const _LabValue({required this.id, required this.recordId, required this.analyte, required this.value, required this.abnormalFlag, this.unit, this.refLow, this.refHigh, this.source, this.provenance, this.verificationStatus = VerificationStatus.unverified, this.verifiedByStaffId, this.verifiedAt}): super._();
  

@override final  String id;
@override final  String recordId;
@override final  String analyte;
@override final  double value;
@override final  AbnormalFlag abnormalFlag;
@override final  String? unit;
@override final  double? refLow;
@override final  double? refHigh;
/// Where the value came from (analyser, outside lab, patient import).
@override final  String? source;
/// Which rules judged it, and any transformation applied (Phase 4).
@override final  String? provenance;
@override@JsonKey() final  VerificationStatus verificationStatus;
@override final  String? verifiedByStaffId;
@override final  DateTime? verifiedAt;

/// Create a copy of LabValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabValueCopyWith<_LabValue> get copyWith => __$LabValueCopyWithImpl<_LabValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabValue&&(identical(other.id, id) || other.id == id)&&(identical(other.recordId, recordId) || other.recordId == recordId)&&(identical(other.analyte, analyte) || other.analyte == analyte)&&(identical(other.value, value) || other.value == value)&&(identical(other.abnormalFlag, abnormalFlag) || other.abnormalFlag == abnormalFlag)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.refLow, refLow) || other.refLow == refLow)&&(identical(other.refHigh, refHigh) || other.refHigh == refHigh)&&(identical(other.source, source) || other.source == source)&&(identical(other.provenance, provenance) || other.provenance == provenance)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.verifiedByStaffId, verifiedByStaffId) || other.verifiedByStaffId == verifiedByStaffId)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,recordId,analyte,value,abnormalFlag,unit,refLow,refHigh,source,provenance,verificationStatus,verifiedByStaffId,verifiedAt);

@override
String toString() {
  return 'LabValue(id: $id, recordId: $recordId, analyte: $analyte, value: $value, abnormalFlag: $abnormalFlag, unit: $unit, refLow: $refLow, refHigh: $refHigh, source: $source, provenance: $provenance, verificationStatus: $verificationStatus, verifiedByStaffId: $verifiedByStaffId, verifiedAt: $verifiedAt)';
}


}

/// @nodoc
abstract mixin class _$LabValueCopyWith<$Res> implements $LabValueCopyWith<$Res> {
  factory _$LabValueCopyWith(_LabValue value, $Res Function(_LabValue) _then) = __$LabValueCopyWithImpl;
@override @useResult
$Res call({
 String id, String recordId, String analyte, double value, AbnormalFlag abnormalFlag, String? unit, double? refLow, double? refHigh, String? source, String? provenance, VerificationStatus verificationStatus, String? verifiedByStaffId, DateTime? verifiedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recordId = null,Object? analyte = null,Object? value = null,Object? abnormalFlag = null,Object? unit = freezed,Object? refLow = freezed,Object? refHigh = freezed,Object? source = freezed,Object? provenance = freezed,Object? verificationStatus = null,Object? verifiedByStaffId = freezed,Object? verifiedAt = freezed,}) {
  return _then(_LabValue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recordId: null == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String,analyte: null == analyte ? _self.analyte : analyte // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,abnormalFlag: null == abnormalFlag ? _self.abnormalFlag : abnormalFlag // ignore: cast_nullable_to_non_nullable
as AbnormalFlag,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,refLow: freezed == refLow ? _self.refLow : refLow // ignore: cast_nullable_to_non_nullable
as double?,refHigh: freezed == refHigh ? _self.refHigh : refHigh // ignore: cast_nullable_to_non_nullable
as double?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,provenance: freezed == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as String?,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,verifiedByStaffId: freezed == verifiedByStaffId ? _self.verifiedByStaffId : verifiedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MedicalRecord {

 String get id; String get patientId; RecordType get recordType; String get title; DateTime get occurredAt; DateTime get createdAt; List<LabValue> get labValues; String? get authorStaffId; String? get appointmentId; String? get body; String? get sourceFacility; String? get attachmentPath; String? get extractedText;/// Imported by the patient — not reviewed by a clinician.
 bool get uploadedByPatient;/// The signed-in account that filed it (the patient, a proxy, or a
/// clinician).
 String? get createdByAccountId;/// Clinician review of a patient import (Phase 5).
 ImportReviewStatus get reviewStatus; String? get reviewedByStaffId; DateTime? get reviewedAt; String? get reviewNote;/// The stored original file, when there is one (Phase 5).
 SourceDocument? get sourceDocument;
/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalRecordCopyWith<MedicalRecord> get copyWith => _$MedicalRecordCopyWithImpl<MedicalRecord>(this as MedicalRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.title, title) || other.title == title)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.labValues, labValues)&&(identical(other.authorStaffId, authorStaffId) || other.authorStaffId == authorStaffId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.body, body) || other.body == body)&&(identical(other.sourceFacility, sourceFacility) || other.sourceFacility == sourceFacility)&&(identical(other.attachmentPath, attachmentPath) || other.attachmentPath == attachmentPath)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText)&&(identical(other.uploadedByPatient, uploadedByPatient) || other.uploadedByPatient == uploadedByPatient)&&(identical(other.createdByAccountId, createdByAccountId) || other.createdByAccountId == createdByAccountId)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.reviewedByStaffId, reviewedByStaffId) || other.reviewedByStaffId == reviewedByStaffId)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.sourceDocument, sourceDocument) || other.sourceDocument == sourceDocument));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,patientId,recordType,title,occurredAt,createdAt,const DeepCollectionEquality().hash(labValues),authorStaffId,appointmentId,body,sourceFacility,attachmentPath,extractedText,uploadedByPatient,createdByAccountId,reviewStatus,reviewedByStaffId,reviewedAt,reviewNote,sourceDocument]);

@override
String toString() {
  return 'MedicalRecord(id: $id, patientId: $patientId, recordType: $recordType, title: $title, occurredAt: $occurredAt, createdAt: $createdAt, labValues: $labValues, authorStaffId: $authorStaffId, appointmentId: $appointmentId, body: $body, sourceFacility: $sourceFacility, attachmentPath: $attachmentPath, extractedText: $extractedText, uploadedByPatient: $uploadedByPatient, createdByAccountId: $createdByAccountId, reviewStatus: $reviewStatus, reviewedByStaffId: $reviewedByStaffId, reviewedAt: $reviewedAt, reviewNote: $reviewNote, sourceDocument: $sourceDocument)';
}


}

/// @nodoc
abstract mixin class $MedicalRecordCopyWith<$Res>  {
  factory $MedicalRecordCopyWith(MedicalRecord value, $Res Function(MedicalRecord) _then) = _$MedicalRecordCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, RecordType recordType, String title, DateTime occurredAt, DateTime createdAt, List<LabValue> labValues, String? authorStaffId, String? appointmentId, String? body, String? sourceFacility, String? attachmentPath, String? extractedText, bool uploadedByPatient, String? createdByAccountId, ImportReviewStatus reviewStatus, String? reviewedByStaffId, DateTime? reviewedAt, String? reviewNote, SourceDocument? sourceDocument
});


$SourceDocumentCopyWith<$Res>? get sourceDocument;

}
/// @nodoc
class _$MedicalRecordCopyWithImpl<$Res>
    implements $MedicalRecordCopyWith<$Res> {
  _$MedicalRecordCopyWithImpl(this._self, this._then);

  final MedicalRecord _self;
  final $Res Function(MedicalRecord) _then;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? recordType = null,Object? title = null,Object? occurredAt = null,Object? createdAt = null,Object? labValues = null,Object? authorStaffId = freezed,Object? appointmentId = freezed,Object? body = freezed,Object? sourceFacility = freezed,Object? attachmentPath = freezed,Object? extractedText = freezed,Object? uploadedByPatient = null,Object? createdByAccountId = freezed,Object? reviewStatus = null,Object? reviewedByStaffId = freezed,Object? reviewedAt = freezed,Object? reviewNote = freezed,Object? sourceDocument = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,recordType: null == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as RecordType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,labValues: null == labValues ? _self.labValues : labValues // ignore: cast_nullable_to_non_nullable
as List<LabValue>,authorStaffId: freezed == authorStaffId ? _self.authorStaffId : authorStaffId // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,sourceFacility: freezed == sourceFacility ? _self.sourceFacility : sourceFacility // ignore: cast_nullable_to_non_nullable
as String?,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,extractedText: freezed == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String?,uploadedByPatient: null == uploadedByPatient ? _self.uploadedByPatient : uploadedByPatient // ignore: cast_nullable_to_non_nullable
as bool,createdByAccountId: freezed == createdByAccountId ? _self.createdByAccountId : createdByAccountId // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ImportReviewStatus,reviewedByStaffId: freezed == reviewedByStaffId ? _self.reviewedByStaffId : reviewedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,sourceDocument: freezed == sourceDocument ? _self.sourceDocument : sourceDocument // ignore: cast_nullable_to_non_nullable
as SourceDocument?,
  ));
}
/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SourceDocumentCopyWith<$Res>? get sourceDocument {
    if (_self.sourceDocument == null) {
    return null;
  }

  return $SourceDocumentCopyWith<$Res>(_self.sourceDocument!, (value) {
    return _then(_self.copyWith(sourceDocument: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  RecordType recordType,  String title,  DateTime occurredAt,  DateTime createdAt,  List<LabValue> labValues,  String? authorStaffId,  String? appointmentId,  String? body,  String? sourceFacility,  String? attachmentPath,  String? extractedText,  bool uploadedByPatient,  String? createdByAccountId,  ImportReviewStatus reviewStatus,  String? reviewedByStaffId,  DateTime? reviewedAt,  String? reviewNote,  SourceDocument? sourceDocument)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
return $default(_that.id,_that.patientId,_that.recordType,_that.title,_that.occurredAt,_that.createdAt,_that.labValues,_that.authorStaffId,_that.appointmentId,_that.body,_that.sourceFacility,_that.attachmentPath,_that.extractedText,_that.uploadedByPatient,_that.createdByAccountId,_that.reviewStatus,_that.reviewedByStaffId,_that.reviewedAt,_that.reviewNote,_that.sourceDocument);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  RecordType recordType,  String title,  DateTime occurredAt,  DateTime createdAt,  List<LabValue> labValues,  String? authorStaffId,  String? appointmentId,  String? body,  String? sourceFacility,  String? attachmentPath,  String? extractedText,  bool uploadedByPatient,  String? createdByAccountId,  ImportReviewStatus reviewStatus,  String? reviewedByStaffId,  DateTime? reviewedAt,  String? reviewNote,  SourceDocument? sourceDocument)  $default,) {final _that = this;
switch (_that) {
case _MedicalRecord():
return $default(_that.id,_that.patientId,_that.recordType,_that.title,_that.occurredAt,_that.createdAt,_that.labValues,_that.authorStaffId,_that.appointmentId,_that.body,_that.sourceFacility,_that.attachmentPath,_that.extractedText,_that.uploadedByPatient,_that.createdByAccountId,_that.reviewStatus,_that.reviewedByStaffId,_that.reviewedAt,_that.reviewNote,_that.sourceDocument);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  RecordType recordType,  String title,  DateTime occurredAt,  DateTime createdAt,  List<LabValue> labValues,  String? authorStaffId,  String? appointmentId,  String? body,  String? sourceFacility,  String? attachmentPath,  String? extractedText,  bool uploadedByPatient,  String? createdByAccountId,  ImportReviewStatus reviewStatus,  String? reviewedByStaffId,  DateTime? reviewedAt,  String? reviewNote,  SourceDocument? sourceDocument)?  $default,) {final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
return $default(_that.id,_that.patientId,_that.recordType,_that.title,_that.occurredAt,_that.createdAt,_that.labValues,_that.authorStaffId,_that.appointmentId,_that.body,_that.sourceFacility,_that.attachmentPath,_that.extractedText,_that.uploadedByPatient,_that.createdByAccountId,_that.reviewStatus,_that.reviewedByStaffId,_that.reviewedAt,_that.reviewNote,_that.sourceDocument);case _:
  return null;

}
}

}

/// @nodoc


class _MedicalRecord extends MedicalRecord {
  const _MedicalRecord({required this.id, required this.patientId, required this.recordType, required this.title, required this.occurredAt, required this.createdAt, final  List<LabValue> labValues = const [], this.authorStaffId, this.appointmentId, this.body, this.sourceFacility, this.attachmentPath, this.extractedText, this.uploadedByPatient = false, this.createdByAccountId, this.reviewStatus = ImportReviewStatus.notRequired, this.reviewedByStaffId, this.reviewedAt, this.reviewNote, this.sourceDocument}): _labValues = labValues,super._();
  

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
@override final  String? appointmentId;
@override final  String? body;
@override final  String? sourceFacility;
@override final  String? attachmentPath;
@override final  String? extractedText;
/// Imported by the patient — not reviewed by a clinician.
@override@JsonKey() final  bool uploadedByPatient;
/// The signed-in account that filed it (the patient, a proxy, or a
/// clinician).
@override final  String? createdByAccountId;
/// Clinician review of a patient import (Phase 5).
@override@JsonKey() final  ImportReviewStatus reviewStatus;
@override final  String? reviewedByStaffId;
@override final  DateTime? reviewedAt;
@override final  String? reviewNote;
/// The stored original file, when there is one (Phase 5).
@override final  SourceDocument? sourceDocument;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalRecordCopyWith<_MedicalRecord> get copyWith => __$MedicalRecordCopyWithImpl<_MedicalRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.title, title) || other.title == title)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._labValues, _labValues)&&(identical(other.authorStaffId, authorStaffId) || other.authorStaffId == authorStaffId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.body, body) || other.body == body)&&(identical(other.sourceFacility, sourceFacility) || other.sourceFacility == sourceFacility)&&(identical(other.attachmentPath, attachmentPath) || other.attachmentPath == attachmentPath)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText)&&(identical(other.uploadedByPatient, uploadedByPatient) || other.uploadedByPatient == uploadedByPatient)&&(identical(other.createdByAccountId, createdByAccountId) || other.createdByAccountId == createdByAccountId)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.reviewedByStaffId, reviewedByStaffId) || other.reviewedByStaffId == reviewedByStaffId)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.sourceDocument, sourceDocument) || other.sourceDocument == sourceDocument));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,patientId,recordType,title,occurredAt,createdAt,const DeepCollectionEquality().hash(_labValues),authorStaffId,appointmentId,body,sourceFacility,attachmentPath,extractedText,uploadedByPatient,createdByAccountId,reviewStatus,reviewedByStaffId,reviewedAt,reviewNote,sourceDocument]);

@override
String toString() {
  return 'MedicalRecord(id: $id, patientId: $patientId, recordType: $recordType, title: $title, occurredAt: $occurredAt, createdAt: $createdAt, labValues: $labValues, authorStaffId: $authorStaffId, appointmentId: $appointmentId, body: $body, sourceFacility: $sourceFacility, attachmentPath: $attachmentPath, extractedText: $extractedText, uploadedByPatient: $uploadedByPatient, createdByAccountId: $createdByAccountId, reviewStatus: $reviewStatus, reviewedByStaffId: $reviewedByStaffId, reviewedAt: $reviewedAt, reviewNote: $reviewNote, sourceDocument: $sourceDocument)';
}


}

/// @nodoc
abstract mixin class _$MedicalRecordCopyWith<$Res> implements $MedicalRecordCopyWith<$Res> {
  factory _$MedicalRecordCopyWith(_MedicalRecord value, $Res Function(_MedicalRecord) _then) = __$MedicalRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, RecordType recordType, String title, DateTime occurredAt, DateTime createdAt, List<LabValue> labValues, String? authorStaffId, String? appointmentId, String? body, String? sourceFacility, String? attachmentPath, String? extractedText, bool uploadedByPatient, String? createdByAccountId, ImportReviewStatus reviewStatus, String? reviewedByStaffId, DateTime? reviewedAt, String? reviewNote, SourceDocument? sourceDocument
});


@override $SourceDocumentCopyWith<$Res>? get sourceDocument;

}
/// @nodoc
class __$MedicalRecordCopyWithImpl<$Res>
    implements _$MedicalRecordCopyWith<$Res> {
  __$MedicalRecordCopyWithImpl(this._self, this._then);

  final _MedicalRecord _self;
  final $Res Function(_MedicalRecord) _then;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? recordType = null,Object? title = null,Object? occurredAt = null,Object? createdAt = null,Object? labValues = null,Object? authorStaffId = freezed,Object? appointmentId = freezed,Object? body = freezed,Object? sourceFacility = freezed,Object? attachmentPath = freezed,Object? extractedText = freezed,Object? uploadedByPatient = null,Object? createdByAccountId = freezed,Object? reviewStatus = null,Object? reviewedByStaffId = freezed,Object? reviewedAt = freezed,Object? reviewNote = freezed,Object? sourceDocument = freezed,}) {
  return _then(_MedicalRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,recordType: null == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as RecordType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,labValues: null == labValues ? _self._labValues : labValues // ignore: cast_nullable_to_non_nullable
as List<LabValue>,authorStaffId: freezed == authorStaffId ? _self.authorStaffId : authorStaffId // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,sourceFacility: freezed == sourceFacility ? _self.sourceFacility : sourceFacility // ignore: cast_nullable_to_non_nullable
as String?,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,extractedText: freezed == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String?,uploadedByPatient: null == uploadedByPatient ? _self.uploadedByPatient : uploadedByPatient // ignore: cast_nullable_to_non_nullable
as bool,createdByAccountId: freezed == createdByAccountId ? _self.createdByAccountId : createdByAccountId // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ImportReviewStatus,reviewedByStaffId: freezed == reviewedByStaffId ? _self.reviewedByStaffId : reviewedByStaffId // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,sourceDocument: freezed == sourceDocument ? _self.sourceDocument : sourceDocument // ignore: cast_nullable_to_non_nullable
as SourceDocument?,
  ));
}

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SourceDocumentCopyWith<$Res>? get sourceDocument {
    if (_self.sourceDocument == null) {
    return null;
  }

  return $SourceDocumentCopyWith<$Res>(_self.sourceDocument!, (value) {
    return _then(_self.copyWith(sourceDocument: value));
  });
}
}

/// @nodoc
mixin _$SourceDocument {

 String get id; String get fileName; String get mimeType; int get sizeBytes;/// Hex SHA-256 of the stored bytes.
 String get sha256; DateTime get storedAt;
/// Create a copy of SourceDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceDocumentCopyWith<SourceDocument> get copyWith => _$SourceDocumentCopyWithImpl<SourceDocument>(this as SourceDocument, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.storedAt, storedAt) || other.storedAt == storedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,fileName,mimeType,sizeBytes,sha256,storedAt);

@override
String toString() {
  return 'SourceDocument(id: $id, fileName: $fileName, mimeType: $mimeType, sizeBytes: $sizeBytes, sha256: $sha256, storedAt: $storedAt)';
}


}

/// @nodoc
abstract mixin class $SourceDocumentCopyWith<$Res>  {
  factory $SourceDocumentCopyWith(SourceDocument value, $Res Function(SourceDocument) _then) = _$SourceDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, String mimeType, int sizeBytes, String sha256, DateTime storedAt
});




}
/// @nodoc
class _$SourceDocumentCopyWithImpl<$Res>
    implements $SourceDocumentCopyWith<$Res> {
  _$SourceDocumentCopyWithImpl(this._self, this._then);

  final SourceDocument _self;
  final $Res Function(SourceDocument) _then;

/// Create a copy of SourceDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? mimeType = null,Object? sizeBytes = null,Object? sha256 = null,Object? storedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,storedAt: null == storedAt ? _self.storedAt : storedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceDocument].
extension SourceDocumentPatterns on SourceDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceDocument value)  $default,){
final _that = this;
switch (_that) {
case _SourceDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceDocument value)?  $default,){
final _that = this;
switch (_that) {
case _SourceDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  String mimeType,  int sizeBytes,  String sha256,  DateTime storedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceDocument() when $default != null:
return $default(_that.id,_that.fileName,_that.mimeType,_that.sizeBytes,_that.sha256,_that.storedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  String mimeType,  int sizeBytes,  String sha256,  DateTime storedAt)  $default,) {final _that = this;
switch (_that) {
case _SourceDocument():
return $default(_that.id,_that.fileName,_that.mimeType,_that.sizeBytes,_that.sha256,_that.storedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  String mimeType,  int sizeBytes,  String sha256,  DateTime storedAt)?  $default,) {final _that = this;
switch (_that) {
case _SourceDocument() when $default != null:
return $default(_that.id,_that.fileName,_that.mimeType,_that.sizeBytes,_that.sha256,_that.storedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SourceDocument implements SourceDocument {
  const _SourceDocument({required this.id, required this.fileName, required this.mimeType, required this.sizeBytes, required this.sha256, required this.storedAt});
  

@override final  String id;
@override final  String fileName;
@override final  String mimeType;
@override final  int sizeBytes;
/// Hex SHA-256 of the stored bytes.
@override final  String sha256;
@override final  DateTime storedAt;

/// Create a copy of SourceDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceDocumentCopyWith<_SourceDocument> get copyWith => __$SourceDocumentCopyWithImpl<_SourceDocument>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.storedAt, storedAt) || other.storedAt == storedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,fileName,mimeType,sizeBytes,sha256,storedAt);

@override
String toString() {
  return 'SourceDocument(id: $id, fileName: $fileName, mimeType: $mimeType, sizeBytes: $sizeBytes, sha256: $sha256, storedAt: $storedAt)';
}


}

/// @nodoc
abstract mixin class _$SourceDocumentCopyWith<$Res> implements $SourceDocumentCopyWith<$Res> {
  factory _$SourceDocumentCopyWith(_SourceDocument value, $Res Function(_SourceDocument) _then) = __$SourceDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, String mimeType, int sizeBytes, String sha256, DateTime storedAt
});




}
/// @nodoc
class __$SourceDocumentCopyWithImpl<$Res>
    implements _$SourceDocumentCopyWith<$Res> {
  __$SourceDocumentCopyWithImpl(this._self, this._then);

  final _SourceDocument _self;
  final $Res Function(_SourceDocument) _then;

/// Create a copy of SourceDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? mimeType = null,Object? sizeBytes = null,Object? sha256 = null,Object? storedAt = null,}) {
  return _then(_SourceDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,storedAt: null == storedAt ? _self.storedAt : storedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
