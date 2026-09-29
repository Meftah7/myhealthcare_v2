enum CapabilityMode { disabled, offline, mock, live }

enum CapabilityReviewState { notRequired, unvalidated, validated }

class CapabilityDefinition {
  const CapabilityDefinition({
    required this.id,
    required this.label,
    required this.owner,
    required this.mode,
    required this.reviewState,
    required this.fallback,
  });

  final String id;
  final String label;
  final String owner;
  final CapabilityMode mode;
  final CapabilityReviewState reviewState;
  final String fallback;

  bool get mayShip =>
      mode != CapabilityMode.disabled &&
      owner.trim().isNotEmpty &&
      reviewState != CapabilityReviewState.unvalidated;
}

const phase8Capabilities = <CapabilityDefinition>[
  CapabilityDefinition(
    id: 'live-clinical-ai',
    label: 'Live clinical AI drafts',
    owner: 'Unassigned clinical safety owner',
    mode: CapabilityMode.disabled,
    reviewState: CapabilityReviewState.unvalidated,
    fallback: 'Use an explicitly labelled mock/offline draft in demo mode.',
  ),
  CapabilityDefinition(
    id: 'nutrition-estimate',
    label: 'Calorie and macro estimate',
    owner: 'Patient product owner',
    mode: CapabilityMode.offline,
    reviewState: CapabilityReviewState.notRequired,
    fallback: 'The calculator remains available offline.',
  ),
  CapabilityDefinition(
    id: 'operations-demand',
    label: 'Historical appointment demand',
    owner: 'Clinic operations administrator',
    mode: CapabilityMode.offline,
    reviewState: CapabilityReviewState.notRequired,
    fallback: 'Show deterministic history without AI narration.',
  ),
  CapabilityDefinition(
    id: 'no-show-risk',
    label: 'No-show operational estimate',
    owner: 'Unassigned qualified model owner',
    mode: CapabilityMode.disabled,
    reviewState: CapabilityReviewState.unvalidated,
    fallback: 'Do not display or use the score for care decisions.',
  ),
];

bool phase8CapabilityEnabled(String id) =>
    phase8Capabilities.singleWhere((capability) => capability.id == id).mayShip;
