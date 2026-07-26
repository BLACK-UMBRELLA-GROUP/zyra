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
  final String status; // 'potential' | 'active' | 'paused' | 'ended'
  final String? journeyStage; // null while potential
  final String? suspendedBy; // user id of whoever suspended, or null
  final bool isMock; // true for demo/mock entries with no real backing row

  const JourneyMatch({
    required this.matchId,
    required this.profile,
    required this.status,
    this.journeyStage,
    this.suspendedBy,
    this.isMock = false,
  });

  bool get isSuspended => suspendedBy != null;
}
