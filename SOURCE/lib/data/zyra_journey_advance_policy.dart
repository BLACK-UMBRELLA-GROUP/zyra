/// Client-side policy for re-asking an already chosen two-person threshold.
///
/// A retry is allowed only after this member made an explicit choice and the
/// server said it is waiting for the other person. Guardian Gate is excluded:
/// retrying it automatically can complete Stage 3 before it is ever rendered.
class ZyraJourneyAdvancePolicy {
  ZyraJourneyAdvancePolicy._();

  static bool shouldRetryStalled({
    required String? stage,
    required String? reason,
  }) {
    if (reason == null) return false;
    return stage == 'salam_exchange' || stage == 'compatibility_reveal';
  }
}
