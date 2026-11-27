/// Whether the live AI service is usable right now — checked, not assumed.
///
/// Build settings only say a gateway is configured; this asks it (an
/// authenticated readiness call with a time limit) and reports one of
/// [GatewayReadiness]. A live request that fails because the service went
/// away updates it, and [AssistantConnection.recheck] asks again. Readiness
/// is not proof that a provider call will succeed — that is what a live
/// smoke test is for.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ai/report_ai_client.dart';

class AssistantConnection extends AsyncNotifier<GatewayReadiness> {
  @override
  Future<GatewayReadiness> build() {
    final client = ref.watch(reportAiClientProvider);
    if (!client.isConfigured) {
      return Future.value(GatewayReadiness.unconfigured);
    }
    return client.checkReadiness();
  }

  /// Asks the gateway again (shown as "checking" meanwhile).
  Future<void> recheck() async {
    final client = ref.read(reportAiClientProvider);
    if (!client.isConfigured) {
      state = const AsyncData(GatewayReadiness.unconfigured);
      return;
    }
    state = const AsyncLoading();
    state = AsyncData(await client.checkReadiness());
  }

  /// A live request failed in a way that says the service is not usable.
  void reportFailure(ReportAiFailureKind kind) {
    final next = switch (kind) {
      ReportAiFailureKind.network => GatewayReadiness.unreachable,
      ReportAiFailureKind.unauthorized => GatewayReadiness.unauthorized,
      ReportAiFailureKind.providerUnavailable =>
        GatewayReadiness.providerUnavailable,
      ReportAiFailureKind.unavailable => GatewayReadiness.unconfigured,
      _ => null,
    };
    if (next != null) state = AsyncData(next);
  }

  /// The current status, waiting for a check in progress.
  Future<GatewayReadiness> current() => future;
}

final assistantConnectionProvider =
    AsyncNotifierProvider<AssistantConnection, GatewayReadiness>(
      AssistantConnection.new,
    );

/// The status for display: [GatewayReadiness.checking] while a check runs.
final assistantReadinessProvider = Provider<GatewayReadiness>((ref) {
  final async = ref.watch(assistantConnectionProvider);
  return async.isLoading
      ? GatewayReadiness.checking
      : async.valueOrNull ?? GatewayReadiness.unreachable;
});
