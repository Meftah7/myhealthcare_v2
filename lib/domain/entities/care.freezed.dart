// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SickLeaveCertificate {

 String get id; String get patientId; String get issuedByStaffId; String get diagnosis; DateTime get fromDate; DateTime get toDate; DateTime get issuedAt; String? get appointmentId; String? get notes;
/// Create a copy of SickLeaveCertificate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SickLeaveCertificateCopyWith<SickLeaveCertificate> get copyWith => _$SickLeaveCertificateCopyWithImpl<SickLeaveCertificate>(this as SickLeaveCertificate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SickLeaveCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.issuedByStaffId, issuedByStaffId) || other.issuedByStaffId == issuedByStaffId)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,issuedByStaffId,diagnosis,fromDate,toDate,issuedAt,appointmentId,notes);

@override
String toString() {
  return 'SickLeaveCertificate(id: $id, patientId: $patientId, issuedByStaffId: $issuedByStaffId, diagnosis: $diagnosis, fromDate: $fromDate, toDate: $toDate, issuedAt: $issuedAt, appointmentId: $appointmentId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $SickLeaveCertificateCopyWith<$Res>  {
  factory $SickLeaveCertificateCopyWith(SickLeaveCertificate value, $Res Function(SickLeaveCertificate) _then) = _$SickLeaveCertificateCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, String issuedByStaffId, String diagnosis, DateTime fromDate, DateTime toDate, DateTime issuedAt, String? appointmentId, String? notes
});




}
/// @nodoc
class _$SickLeaveCertificateCopyWithImpl<$Res>
    implements $SickLeaveCertificateCopyWith<$Res> {
  _$SickLeaveCertificateCopyWithImpl(this._self, this._then);

  final SickLeaveCertificate _self;
  final $Res Function(SickLeaveCertificate) _then;

/// Create a copy of SickLeaveCertificate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? issuedByStaffId = null,Object? diagnosis = null,Object? fromDate = null,Object? toDate = null,Object? issuedAt = null,Object? appointmentId = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,issuedByStaffId: null == issuedByStaffId ? _self.issuedByStaffId : issuedByStaffId // ignore: cast_nullable_to_non_nullable
as String,diagnosis: null == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String,fromDate: null == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as DateTime,toDate: null == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as DateTime,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SickLeaveCertificate].
extension SickLeaveCertificatePatterns on SickLeaveCertificate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SickLeaveCertificate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SickLeaveCertificate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SickLeaveCertificate value)  $default,){
final _that = this;
switch (_that) {
case _SickLeaveCertificate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SickLeaveCertificate value)?  $default,){
final _that = this;
switch (_that) {
case _SickLeaveCertificate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  String issuedByStaffId,  String diagnosis,  DateTime fromDate,  DateTime toDate,  DateTime issuedAt,  String? appointmentId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SickLeaveCertificate() when $default != null:
return $default(_that.id,_that.patientId,_that.issuedByStaffId,_that.diagnosis,_that.fromDate,_that.toDate,_that.issuedAt,_that.appointmentId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  String issuedByStaffId,  String diagnosis,  DateTime fromDate,  DateTime toDate,  DateTime issuedAt,  String? appointmentId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _SickLeaveCertificate():
return $default(_that.id,_that.patientId,_that.issuedByStaffId,_that.diagnosis,_that.fromDate,_that.toDate,_that.issuedAt,_that.appointmentId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  String issuedByStaffId,  String diagnosis,  DateTime fromDate,  DateTime toDate,  DateTime issuedAt,  String? appointmentId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _SickLeaveCertificate() when $default != null:
return $default(_that.id,_that.patientId,_that.issuedByStaffId,_that.diagnosis,_that.fromDate,_that.toDate,_that.issuedAt,_that.appointmentId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _SickLeaveCertificate extends SickLeaveCertificate {
  const _SickLeaveCertificate({required this.id, required this.patientId, required this.issuedByStaffId, required this.diagnosis, required this.fromDate, required this.toDate, required this.issuedAt, this.appointmentId, this.notes}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  String issuedByStaffId;
@override final  String diagnosis;
@override final  DateTime fromDate;
@override final  DateTime toDate;
@override final  DateTime issuedAt;
@override final  String? appointmentId;
@override final  String? notes;

/// Create a copy of SickLeaveCertificate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SickLeaveCertificateCopyWith<_SickLeaveCertificate> get copyWith => __$SickLeaveCertificateCopyWithImpl<_SickLeaveCertificate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SickLeaveCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.issuedByStaffId, issuedByStaffId) || other.issuedByStaffId == issuedByStaffId)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,issuedByStaffId,diagnosis,fromDate,toDate,issuedAt,appointmentId,notes);

@override
String toString() {
  return 'SickLeaveCertificate(id: $id, patientId: $patientId, issuedByStaffId: $issuedByStaffId, diagnosis: $diagnosis, fromDate: $fromDate, toDate: $toDate, issuedAt: $issuedAt, appointmentId: $appointmentId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SickLeaveCertificateCopyWith<$Res> implements $SickLeaveCertificateCopyWith<$Res> {
  factory _$SickLeaveCertificateCopyWith(_SickLeaveCertificate value, $Res Function(_SickLeaveCertificate) _then) = __$SickLeaveCertificateCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, String issuedByStaffId, String diagnosis, DateTime fromDate, DateTime toDate, DateTime issuedAt, String? appointmentId, String? notes
});




}
/// @nodoc
class __$SickLeaveCertificateCopyWithImpl<$Res>
    implements _$SickLeaveCertificateCopyWith<$Res> {
  __$SickLeaveCertificateCopyWithImpl(this._self, this._then);

  final _SickLeaveCertificate _self;
  final $Res Function(_SickLeaveCertificate) _then;

/// Create a copy of SickLeaveCertificate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? issuedByStaffId = null,Object? diagnosis = null,Object? fromDate = null,Object? toDate = null,Object? issuedAt = null,Object? appointmentId = freezed,Object? notes = freezed,}) {
  return _then(_SickLeaveCertificate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,issuedByStaffId: null == issuedByStaffId ? _self.issuedByStaffId : issuedByStaffId // ignore: cast_nullable_to_non_nullable
as String,diagnosis: null == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String,fromDate: null == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as DateTime,toDate: null == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as DateTime,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CareMessage {

 String get id; String get patientId; String get staffId; bool get fromStaff; String get body; DateTime get sentAt; DateTime? get readAt;
/// Create a copy of CareMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareMessageCopyWith<CareMessage> get copyWith => _$CareMessageCopyWithImpl<CareMessage>(this as CareMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.fromStaff, fromStaff) || other.fromStaff == fromStaff)&&(identical(other.body, body) || other.body == body)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,staffId,fromStaff,body,sentAt,readAt);

@override
String toString() {
  return 'CareMessage(id: $id, patientId: $patientId, staffId: $staffId, fromStaff: $fromStaff, body: $body, sentAt: $sentAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class $CareMessageCopyWith<$Res>  {
  factory $CareMessageCopyWith(CareMessage value, $Res Function(CareMessage) _then) = _$CareMessageCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, String staffId, bool fromStaff, String body, DateTime sentAt, DateTime? readAt
});




}
/// @nodoc
class _$CareMessageCopyWithImpl<$Res>
    implements $CareMessageCopyWith<$Res> {
  _$CareMessageCopyWithImpl(this._self, this._then);

  final CareMessage _self;
  final $Res Function(CareMessage) _then;

/// Create a copy of CareMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? staffId = null,Object? fromStaff = null,Object? body = null,Object? sentAt = null,Object? readAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,fromStaff: null == fromStaff ? _self.fromStaff : fromStaff // ignore: cast_nullable_to_non_nullable
as bool,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CareMessage].
extension CareMessagePatterns on CareMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareMessage value)  $default,){
final _that = this;
switch (_that) {
case _CareMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareMessage value)?  $default,){
final _that = this;
switch (_that) {
case _CareMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  String staffId,  bool fromStaff,  String body,  DateTime sentAt,  DateTime? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareMessage() when $default != null:
return $default(_that.id,_that.patientId,_that.staffId,_that.fromStaff,_that.body,_that.sentAt,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  String staffId,  bool fromStaff,  String body,  DateTime sentAt,  DateTime? readAt)  $default,) {final _that = this;
switch (_that) {
case _CareMessage():
return $default(_that.id,_that.patientId,_that.staffId,_that.fromStaff,_that.body,_that.sentAt,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  String staffId,  bool fromStaff,  String body,  DateTime sentAt,  DateTime? readAt)?  $default,) {final _that = this;
switch (_that) {
case _CareMessage() when $default != null:
return $default(_that.id,_that.patientId,_that.staffId,_that.fromStaff,_that.body,_that.sentAt,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc


class _CareMessage extends CareMessage {
  const _CareMessage({required this.id, required this.patientId, required this.staffId, required this.fromStaff, required this.body, required this.sentAt, this.readAt}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  String staffId;
@override final  bool fromStaff;
@override final  String body;
@override final  DateTime sentAt;
@override final  DateTime? readAt;

/// Create a copy of CareMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareMessageCopyWith<_CareMessage> get copyWith => __$CareMessageCopyWithImpl<_CareMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.fromStaff, fromStaff) || other.fromStaff == fromStaff)&&(identical(other.body, body) || other.body == body)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,staffId,fromStaff,body,sentAt,readAt);

@override
String toString() {
  return 'CareMessage(id: $id, patientId: $patientId, staffId: $staffId, fromStaff: $fromStaff, body: $body, sentAt: $sentAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$CareMessageCopyWith<$Res> implements $CareMessageCopyWith<$Res> {
  factory _$CareMessageCopyWith(_CareMessage value, $Res Function(_CareMessage) _then) = __$CareMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, String staffId, bool fromStaff, String body, DateTime sentAt, DateTime? readAt
});




}
/// @nodoc
class __$CareMessageCopyWithImpl<$Res>
    implements _$CareMessageCopyWith<$Res> {
  __$CareMessageCopyWithImpl(this._self, this._then);

  final _CareMessage _self;
  final $Res Function(_CareMessage) _then;

/// Create a copy of CareMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? staffId = null,Object? fromStaff = null,Object? body = null,Object? sentAt = null,Object? readAt = freezed,}) {
  return _then(_CareMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,fromStaff: null == fromStaff ? _self.fromStaff : fromStaff // ignore: cast_nullable_to_non_nullable
as bool,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$CareThread {

 String get patientId; String get staffId; String get counterpartName; CareMessage get lastMessage; int get unreadForPatient; int get unreadForStaff;
/// Create a copy of CareThread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareThreadCopyWith<CareThread> get copyWith => _$CareThreadCopyWithImpl<CareThread>(this as CareThread, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareThread&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.counterpartName, counterpartName) || other.counterpartName == counterpartName)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.unreadForPatient, unreadForPatient) || other.unreadForPatient == unreadForPatient)&&(identical(other.unreadForStaff, unreadForStaff) || other.unreadForStaff == unreadForStaff));
}


@override
int get hashCode => Object.hash(runtimeType,patientId,staffId,counterpartName,lastMessage,unreadForPatient,unreadForStaff);

@override
String toString() {
  return 'CareThread(patientId: $patientId, staffId: $staffId, counterpartName: $counterpartName, lastMessage: $lastMessage, unreadForPatient: $unreadForPatient, unreadForStaff: $unreadForStaff)';
}


}

/// @nodoc
abstract mixin class $CareThreadCopyWith<$Res>  {
  factory $CareThreadCopyWith(CareThread value, $Res Function(CareThread) _then) = _$CareThreadCopyWithImpl;
@useResult
$Res call({
 String patientId, String staffId, String counterpartName, CareMessage lastMessage, int unreadForPatient, int unreadForStaff
});


$CareMessageCopyWith<$Res> get lastMessage;

}
/// @nodoc
class _$CareThreadCopyWithImpl<$Res>
    implements $CareThreadCopyWith<$Res> {
  _$CareThreadCopyWithImpl(this._self, this._then);

  final CareThread _self;
  final $Res Function(CareThread) _then;

/// Create a copy of CareThread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? patientId = null,Object? staffId = null,Object? counterpartName = null,Object? lastMessage = null,Object? unreadForPatient = null,Object? unreadForStaff = null,}) {
  return _then(_self.copyWith(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,counterpartName: null == counterpartName ? _self.counterpartName : counterpartName // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as CareMessage,unreadForPatient: null == unreadForPatient ? _self.unreadForPatient : unreadForPatient // ignore: cast_nullable_to_non_nullable
as int,unreadForStaff: null == unreadForStaff ? _self.unreadForStaff : unreadForStaff // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CareThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareMessageCopyWith<$Res> get lastMessage {
  
  return $CareMessageCopyWith<$Res>(_self.lastMessage, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [CareThread].
extension CareThreadPatterns on CareThread {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareThread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareThread() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareThread value)  $default,){
final _that = this;
switch (_that) {
case _CareThread():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareThread value)?  $default,){
final _that = this;
switch (_that) {
case _CareThread() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String patientId,  String staffId,  String counterpartName,  CareMessage lastMessage,  int unreadForPatient,  int unreadForStaff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareThread() when $default != null:
return $default(_that.patientId,_that.staffId,_that.counterpartName,_that.lastMessage,_that.unreadForPatient,_that.unreadForStaff);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String patientId,  String staffId,  String counterpartName,  CareMessage lastMessage,  int unreadForPatient,  int unreadForStaff)  $default,) {final _that = this;
switch (_that) {
case _CareThread():
return $default(_that.patientId,_that.staffId,_that.counterpartName,_that.lastMessage,_that.unreadForPatient,_that.unreadForStaff);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String patientId,  String staffId,  String counterpartName,  CareMessage lastMessage,  int unreadForPatient,  int unreadForStaff)?  $default,) {final _that = this;
switch (_that) {
case _CareThread() when $default != null:
return $default(_that.patientId,_that.staffId,_that.counterpartName,_that.lastMessage,_that.unreadForPatient,_that.unreadForStaff);case _:
  return null;

}
}

}

/// @nodoc


class _CareThread implements CareThread {
  const _CareThread({required this.patientId, required this.staffId, required this.counterpartName, required this.lastMessage, required this.unreadForPatient, required this.unreadForStaff});
  

@override final  String patientId;
@override final  String staffId;
@override final  String counterpartName;
@override final  CareMessage lastMessage;
@override final  int unreadForPatient;
@override final  int unreadForStaff;

/// Create a copy of CareThread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareThreadCopyWith<_CareThread> get copyWith => __$CareThreadCopyWithImpl<_CareThread>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareThread&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.counterpartName, counterpartName) || other.counterpartName == counterpartName)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.unreadForPatient, unreadForPatient) || other.unreadForPatient == unreadForPatient)&&(identical(other.unreadForStaff, unreadForStaff) || other.unreadForStaff == unreadForStaff));
}


@override
int get hashCode => Object.hash(runtimeType,patientId,staffId,counterpartName,lastMessage,unreadForPatient,unreadForStaff);

@override
String toString() {
  return 'CareThread(patientId: $patientId, staffId: $staffId, counterpartName: $counterpartName, lastMessage: $lastMessage, unreadForPatient: $unreadForPatient, unreadForStaff: $unreadForStaff)';
}


}

/// @nodoc
abstract mixin class _$CareThreadCopyWith<$Res> implements $CareThreadCopyWith<$Res> {
  factory _$CareThreadCopyWith(_CareThread value, $Res Function(_CareThread) _then) = __$CareThreadCopyWithImpl;
@override @useResult
$Res call({
 String patientId, String staffId, String counterpartName, CareMessage lastMessage, int unreadForPatient, int unreadForStaff
});


@override $CareMessageCopyWith<$Res> get lastMessage;

}
/// @nodoc
class __$CareThreadCopyWithImpl<$Res>
    implements _$CareThreadCopyWith<$Res> {
  __$CareThreadCopyWithImpl(this._self, this._then);

  final _CareThread _self;
  final $Res Function(_CareThread) _then;

/// Create a copy of CareThread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? patientId = null,Object? staffId = null,Object? counterpartName = null,Object? lastMessage = null,Object? unreadForPatient = null,Object? unreadForStaff = null,}) {
  return _then(_CareThread(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,counterpartName: null == counterpartName ? _self.counterpartName : counterpartName // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as CareMessage,unreadForPatient: null == unreadForPatient ? _self.unreadForPatient : unreadForPatient // ignore: cast_nullable_to_non_nullable
as int,unreadForStaff: null == unreadForStaff ? _self.unreadForStaff : unreadForStaff // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CareThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareMessageCopyWith<$Res> get lastMessage {
  
  return $CareMessageCopyWith<$Res>(_self.lastMessage, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}

/// @nodoc
mixin _$HomeVisitRequest {

 String get id; String get patientId; String get addressText; DateTime get preferredDate; String get reasonText; HomeVisitStatus get status; DateTime get createdAt; String? get departmentId; String? get assignedStaffId; String? get decisionNote; DateTime? get decidedAt;
/// Create a copy of HomeVisitRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeVisitRequestCopyWith<HomeVisitRequest> get copyWith => _$HomeVisitRequestCopyWithImpl<HomeVisitRequest>(this as HomeVisitRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeVisitRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.preferredDate, preferredDate) || other.preferredDate == preferredDate)&&(identical(other.reasonText, reasonText) || other.reasonText == reasonText)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.assignedStaffId, assignedStaffId) || other.assignedStaffId == assignedStaffId)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,addressText,preferredDate,reasonText,status,createdAt,departmentId,assignedStaffId,decisionNote,decidedAt);

@override
String toString() {
  return 'HomeVisitRequest(id: $id, patientId: $patientId, addressText: $addressText, preferredDate: $preferredDate, reasonText: $reasonText, status: $status, createdAt: $createdAt, departmentId: $departmentId, assignedStaffId: $assignedStaffId, decisionNote: $decisionNote, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class $HomeVisitRequestCopyWith<$Res>  {
  factory $HomeVisitRequestCopyWith(HomeVisitRequest value, $Res Function(HomeVisitRequest) _then) = _$HomeVisitRequestCopyWithImpl;
@useResult
$Res call({
 String id, String patientId, String addressText, DateTime preferredDate, String reasonText, HomeVisitStatus status, DateTime createdAt, String? departmentId, String? assignedStaffId, String? decisionNote, DateTime? decidedAt
});




}
/// @nodoc
class _$HomeVisitRequestCopyWithImpl<$Res>
    implements $HomeVisitRequestCopyWith<$Res> {
  _$HomeVisitRequestCopyWithImpl(this._self, this._then);

  final HomeVisitRequest _self;
  final $Res Function(HomeVisitRequest) _then;

/// Create a copy of HomeVisitRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? addressText = null,Object? preferredDate = null,Object? reasonText = null,Object? status = null,Object? createdAt = null,Object? departmentId = freezed,Object? assignedStaffId = freezed,Object? decisionNote = freezed,Object? decidedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,preferredDate: null == preferredDate ? _self.preferredDate : preferredDate // ignore: cast_nullable_to_non_nullable
as DateTime,reasonText: null == reasonText ? _self.reasonText : reasonText // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HomeVisitStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as String?,assignedStaffId: freezed == assignedStaffId ? _self.assignedStaffId : assignedStaffId // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeVisitRequest].
extension HomeVisitRequestPatterns on HomeVisitRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeVisitRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeVisitRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeVisitRequest value)  $default,){
final _that = this;
switch (_that) {
case _HomeVisitRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeVisitRequest value)?  $default,){
final _that = this;
switch (_that) {
case _HomeVisitRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patientId,  String addressText,  DateTime preferredDate,  String reasonText,  HomeVisitStatus status,  DateTime createdAt,  String? departmentId,  String? assignedStaffId,  String? decisionNote,  DateTime? decidedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeVisitRequest() when $default != null:
return $default(_that.id,_that.patientId,_that.addressText,_that.preferredDate,_that.reasonText,_that.status,_that.createdAt,_that.departmentId,_that.assignedStaffId,_that.decisionNote,_that.decidedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patientId,  String addressText,  DateTime preferredDate,  String reasonText,  HomeVisitStatus status,  DateTime createdAt,  String? departmentId,  String? assignedStaffId,  String? decisionNote,  DateTime? decidedAt)  $default,) {final _that = this;
switch (_that) {
case _HomeVisitRequest():
return $default(_that.id,_that.patientId,_that.addressText,_that.preferredDate,_that.reasonText,_that.status,_that.createdAt,_that.departmentId,_that.assignedStaffId,_that.decisionNote,_that.decidedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patientId,  String addressText,  DateTime preferredDate,  String reasonText,  HomeVisitStatus status,  DateTime createdAt,  String? departmentId,  String? assignedStaffId,  String? decisionNote,  DateTime? decidedAt)?  $default,) {final _that = this;
switch (_that) {
case _HomeVisitRequest() when $default != null:
return $default(_that.id,_that.patientId,_that.addressText,_that.preferredDate,_that.reasonText,_that.status,_that.createdAt,_that.departmentId,_that.assignedStaffId,_that.decisionNote,_that.decidedAt);case _:
  return null;

}
}

}

/// @nodoc


class _HomeVisitRequest extends HomeVisitRequest {
  const _HomeVisitRequest({required this.id, required this.patientId, required this.addressText, required this.preferredDate, required this.reasonText, required this.status, required this.createdAt, this.departmentId, this.assignedStaffId, this.decisionNote, this.decidedAt}): super._();
  

@override final  String id;
@override final  String patientId;
@override final  String addressText;
@override final  DateTime preferredDate;
@override final  String reasonText;
@override final  HomeVisitStatus status;
@override final  DateTime createdAt;
@override final  String? departmentId;
@override final  String? assignedStaffId;
@override final  String? decisionNote;
@override final  DateTime? decidedAt;

/// Create a copy of HomeVisitRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeVisitRequestCopyWith<_HomeVisitRequest> get copyWith => __$HomeVisitRequestCopyWithImpl<_HomeVisitRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeVisitRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.preferredDate, preferredDate) || other.preferredDate == preferredDate)&&(identical(other.reasonText, reasonText) || other.reasonText == reasonText)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.assignedStaffId, assignedStaffId) || other.assignedStaffId == assignedStaffId)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,patientId,addressText,preferredDate,reasonText,status,createdAt,departmentId,assignedStaffId,decisionNote,decidedAt);

@override
String toString() {
  return 'HomeVisitRequest(id: $id, patientId: $patientId, addressText: $addressText, preferredDate: $preferredDate, reasonText: $reasonText, status: $status, createdAt: $createdAt, departmentId: $departmentId, assignedStaffId: $assignedStaffId, decisionNote: $decisionNote, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class _$HomeVisitRequestCopyWith<$Res> implements $HomeVisitRequestCopyWith<$Res> {
  factory _$HomeVisitRequestCopyWith(_HomeVisitRequest value, $Res Function(_HomeVisitRequest) _then) = __$HomeVisitRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String patientId, String addressText, DateTime preferredDate, String reasonText, HomeVisitStatus status, DateTime createdAt, String? departmentId, String? assignedStaffId, String? decisionNote, DateTime? decidedAt
});




}
/// @nodoc
class __$HomeVisitRequestCopyWithImpl<$Res>
    implements _$HomeVisitRequestCopyWith<$Res> {
  __$HomeVisitRequestCopyWithImpl(this._self, this._then);

  final _HomeVisitRequest _self;
  final $Res Function(_HomeVisitRequest) _then;

/// Create a copy of HomeVisitRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? addressText = null,Object? preferredDate = null,Object? reasonText = null,Object? status = null,Object? createdAt = null,Object? departmentId = freezed,Object? assignedStaffId = freezed,Object? decisionNote = freezed,Object? decidedAt = freezed,}) {
  return _then(_HomeVisitRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,preferredDate: null == preferredDate ? _self.preferredDate : preferredDate // ignore: cast_nullable_to_non_nullable
as DateTime,reasonText: null == reasonText ? _self.reasonText : reasonText // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HomeVisitStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as String?,assignedStaffId: freezed == assignedStaffId ? _self.assignedStaffId : assignedStaffId // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
