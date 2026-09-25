/// A link between two real patient accounts: the [viewerPatientId] account
/// gets [permission] over the [ownerPatientId] account's data, once the
/// owner accepts.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'family_link.freezed.dart';

@freezed
abstract class FamilyLink with _$FamilyLink {
  const factory FamilyLink({
    required String id,

    /// The account whose data is being shared.
    required String ownerPatientId,

    /// The account being granted access.
    required String viewerPatientId,
    required FamilyLinkPermission permission,
    required FamilyLinkStatus status,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) = _FamilyLink;

  const FamilyLink._();

  bool get isAccepted => status == FamilyLinkStatus.accepted;
  bool get canManage =>
      isAccepted && permission == FamilyLinkPermission.manage;
}
