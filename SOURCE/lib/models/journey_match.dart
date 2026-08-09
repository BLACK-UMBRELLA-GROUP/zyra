// Real match + journey-lifecycle wrapper for the Pre-Journey Ritual
// (APP/Journey/PRE-JOURNEY RITUAL/Summary.md) and Journey Suspension
// (APP/Journey/JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md).
//
// Replaces the old UX-only Potential/Active Journey distinction in
// AppState (which held plain SeekerProfile lists with no backend
// column behind them) now that matches.status/journey_stage/
// suspended_by are real schema, per the 2026-07-25 migration. See
// ZyraJourneyService for how these are fetched.

import 'seeker_profile.dart';

class JourneyMatch {
  final String matchId;
  final SeekerProfile profile; // the OTHER party
  /// 'potential' | 'active' | 'ended'.
  ///
  /// 'paused' was removed from the CHECK constraint 2026-08-06 (OA-ZYRA-164).
  /// It had always been unreachable — suspend_journey() writes suspended_by
  /// and suspended_at and leaves the status 'active'. Pausing is a FLAG on an
  /// Active Journey, not a lifecycle state of its own (V3 §1).
  final String status;
  final String? journeyStage; // null while potential
  final String? suspendedBy; // user id of whoever suspended, or null
  final DateTime? endedAt; // set when status == 'ended'; drives the 24h cooling period (#17)
  final bool isMock; // true for demo/mock entries with no real backing row

  const JourneyMatch({
    required this.matchId,
    required this.profile,
    required this.status,
    this.journeyStage,
    this.suspendedBy,
    this.endedAt,
    this.isMock = false,
  });

  bool get isSuspended => suspendedBy != null;

  /// #17 — APP/Journey/JOURNEY AVAILABILITY/Summary.md: "24-hour
  /// cooling period begins (no actions possible)" after End Journey,
  /// "after 24 hours, journey officially disconnects" and Restart
  /// becomes available.
  bool get isInCoolingPeriod =>
      status == 'ended' && endedAt != null && DateTime.now().isBefore(endedAt!.add(const Duration(hours: 24)));

  bool get canRestart => status == 'ended' && endedAt != null && !isInCoolingPeriod;

  /// "Restart available in 4 hours".
  ///
  /// ADDED 2026-08-07 with the copy review. The Founder asked for "Restart
  /// available in 24 hours" in place of "Ended — cooling period", and the
  /// reasoning was right — users care what happens next, not what the
  /// internal state is called.
  ///
  /// But a fixed "24 hours" would be WRONG for all but the first moment of
  /// the period. A Journey ended twenty hours ago has four hours left, and
  /// telling that user twenty-four is worse than the jargon it replaced:
  /// jargon is merely unclear, an incorrect number is untrue and they will
  /// come back and find it wasn't.
  ///
  /// Rounds UP, so it never promises sooner than it can deliver.
  String get restartAvailableIn {
    if (endedAt == null) return '';
    final left = endedAt!.add(const Duration(hours: 24)).difference(DateTime.now());
    if (left.inMinutes <= 0) return 'Restart available';
    if (left.inMinutes < 60) return 'Restart available in under an hour';
    final hours = (left.inMinutes / 60).ceil();
    return 'Restart available in $hours ${hours == 1 ? "hour" : "hours"}';
  }
}
