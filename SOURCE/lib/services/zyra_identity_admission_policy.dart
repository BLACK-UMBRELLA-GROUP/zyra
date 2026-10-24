import '../models/zyra_identity_verification.dart';

/// Pure ordinary-member admission policy. Founder local previews are routed
/// separately only after the exact protected identity has been refreshed.
abstract final class ZyraIdentityAdmissionPolicy {
  static bool requiresExistingAccountGate({
    required bool productionRolloutEnabled,
  }) => productionRolloutEnabled;

  /// DR-ZYRA-221 requires server-confirmed verification while the rollout gate
  /// is active. Developer claims and local fixture data never enter this rule.
  static bool allowsExistingAccountEntry({
    required bool productionRolloutEnabled,
    required ZyraIdentityVerificationState? state,
  }) => !productionRolloutEnabled || state?.allowsApp == true;
}
