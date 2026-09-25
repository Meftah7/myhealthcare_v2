/// Family Network account-linking contract: request, accept/decline, unlink,
/// and read the resulting links from either side.
library;

import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

abstract interface class FamilyLinkRepository {
  /// Pending requests waiting on [ownerPatientId] to accept or decline —
  /// requests for access to *their* data.
  Future<Result<List<FamilyLink>>> incomingRequests(String ownerPatientId);

  /// Pending requests [viewerPatientId] sent, waiting on the other side.
  Future<Result<List<FamilyLink>>> outgoingRequests(String viewerPatientId);

  /// Accounts [viewerPatientId] has been granted access to (accepted).
  Future<Result<List<FamilyLink>>> linkedAccounts(String viewerPatientId);

  /// Accounts that have been granted access to [ownerPatientId]'s own data
  /// (accepted) — who can see me.
  Future<Result<List<FamilyLink>>> viewersOfMe(String ownerPatientId);

  /// The accepted link (if any) granting [viewerPatientId] access to
  /// [ownerPatientId]'s data.
  Future<Result<FamilyLink?>> activeLink({
    required String viewerPatientId,
    required String ownerPatientId,
  });

  /// [viewerPatientId] asks to access [ownerPatientId]'s data at
  /// [permission]. Fails if they're the same account, or a link (pending or
  /// accepted) already exists between them.
  Future<Result<FamilyLink>> request({
    required String ownerPatientId,
    required String viewerPatientId,
    required FamilyLinkPermission permission,
  });

  /// [actingPatientId] must be the request's owner.
  Future<Result<FamilyLink>> accept({
    required String linkId,
    required String actingPatientId,
  });

  /// Either side of a pending request can remove it — the owner declining it,
  /// or the viewer cancelling one they sent.
  Future<Result<void>> decline({
    required String linkId,
    required String actingPatientId,
  });

  /// Either side of an accepted link can remove it.
  Future<Result<void>> unlink({
    required String linkId,
    required String actingPatientId,
  });
}
