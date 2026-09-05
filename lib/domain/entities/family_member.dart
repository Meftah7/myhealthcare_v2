/// A linked family member on a patient's account (redesign v2 patient
/// dashboard: Family Network).
///
/// Hand-written rather than `@freezed` — a small immutable value type that's
/// JSON-serialized into [PatientProfiles.familyMembers] via
/// `FamilyMemberListConverter` (converters.dart), so it needs no table of
/// its own.
library;

import '../enums.dart';

enum FamilyRelationship { spouse, child, parent, sibling, guardian, other }

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.relationship,
    required this.firstName,
    required this.lastName,
    this.cpr,
    this.dob,
    this.gender,
    this.bloodType,
  });

  final String id;
  final FamilyRelationship relationship;
  final String firstName;
  final String lastName;

  /// The 9-digit national ID, if provided.
  final String? cpr;
  final DateTime? dob;
  final Gender? gender;
  final String? bloodType;

  String get fullName => '$firstName $lastName'.trim();

  static const _unset = Object();

  FamilyMember copyWith({
    FamilyRelationship? relationship,
    String? firstName,
    String? lastName,
    Object? cpr = _unset,
    Object? dob = _unset,
    Object? gender = _unset,
    Object? bloodType = _unset,
  }) => FamilyMember(
    id: id,
    relationship: relationship ?? this.relationship,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    cpr: identical(cpr, _unset) ? this.cpr : cpr as String?,
    dob: identical(dob, _unset) ? this.dob : dob as DateTime?,
    gender: identical(gender, _unset) ? this.gender : gender as Gender?,
    bloodType: identical(bloodType, _unset)
        ? this.bloodType
        : bloodType as String?,
  );

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    relationship: FamilyRelationship.values.byName(
      json['relationship'] as String,
    ),
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    cpr: json['cpr'] as String?,
    dob: json['dob'] == null ? null : DateTime.parse(json['dob'] as String),
    gender: json['gender'] == null
        ? null
        : Gender.values.byName(json['gender'] as String),
    bloodType: json['bloodType'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'relationship': relationship.name,
    'firstName': firstName,
    'lastName': lastName,
    'cpr': cpr,
    'dob': dob?.toIso8601String(),
    'gender': gender?.name,
    'bloodType': bloodType,
  };

  @override
  bool operator ==(Object other) =>
      other is FamilyMember &&
      other.id == id &&
      other.relationship == relationship &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.cpr == cpr &&
      other.dob == dob &&
      other.gender == gender &&
      other.bloodType == bloodType;

  @override
  int get hashCode => Object.hash(
    id,
    relationship,
    firstName,
    lastName,
    cpr,
    dob,
    gender,
    bloodType,
  );
}

String familyRelationshipLabel(FamilyRelationship r) => switch (r) {
  FamilyRelationship.spouse => 'Spouse',
  FamilyRelationship.child => 'Child',
  FamilyRelationship.parent => 'Parent',
  FamilyRelationship.sibling => 'Sibling',
  FamilyRelationship.guardian => 'Guardian',
  FamilyRelationship.other => 'Other',
};
