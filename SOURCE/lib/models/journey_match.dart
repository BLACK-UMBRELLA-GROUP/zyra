// Real match + journey-lifecycle wrapper for the Pre-Journey Ritual
// (APP/Journey/PRE-JOURNEY RITUAL/Summary.md) and Journey Suspension
// (APP/Journey/JOURNEY SUSPENSION/JOURNEY_SUSPENSION (CURRENT_VERSION)).
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
  final String? suspendedBy; // user id of the PRIMARY hold, or null

  /// The SECOND hold — DR-ZYRA-170 (2026-08-15, shared pause holds).
  /// A pause is a personal hold: either party may hold, the Journey
  /// rests while any hold exists, and each lifts only their own. When
  /// the primary hand lifts first, the server PROMOTES this id into
  /// suspendedBy — so this is only ever the second of two live hands,
  /// never a survivor of one.
  final String? alsoPausedBy;

  /// When the current pause episode began. Drives the time-honesty line
  /// ("Paused · 3 months") on the Journeys rows — DR-ZYRA-142's answer to
  /// "how long may a pause last": forever (the system never ends what
  /// people haven't — DR-ZYRA-121 item 12), but honestly.
  final DateTime? suspendedAt;

  /// When the waiting person sent their one "I'm ready" nudge this pause
  /// episode, or null if they still have it. Set by nudge_paused_journey,
  /// cleared by suspend/resume (a new pause is a new episode). Only
  /// meaningful to the NON-pauser: it decides whether their row shows the
  /// nudge button or "You let them know".
  final DateTime? pauseNudgedAt;

  /// Set when status == 'ended'; drives the 24-hour cooling period and the
  /// Founder's 60-day direct New Journey request window.
  final DateTime? endedAt;

  /// The OTHER person is currently in an Active Journey with someone else,
  /// so beginning (or restarting) with them would be refused right now —
  /// the server's one_active_journey_limit / other_party guards are the
  /// truth behind this flag. Real rows receive the server-computed signal
  /// from zyra_journey_busy_flags; dev stand-ins use the same field so the
  /// busy card can still be exercised without remote data.
  final bool inAnotherJourney;
  final bool isMock; // true for demo/mock entries with no real backing row

  const JourneyMatch({
    required this.matchId,
    required this.profile,
    required this.status,
    this.journeyStage,
    this.suspendedBy,
    this.alsoPausedBy,
    this.suspendedAt,
    this.pauseNudgedAt,
    this.endedAt,
    this.inAnotherJourney = false,
    this.isMock = false,
  });

  bool get isSuspended => suspendedBy != null;

  /// Both hands holding (DR-ZYRA-170) — the card reads "Paused by both
  /// of you" and each Resume lifts only the caller's own hold.
  bool get pausedByBoth => suspendedBy != null && alsoPausedBy != null;

  /// Whether [userId] currently holds a pause on this Journey, either
  /// hand. Decides Resume-vs-respond on the paused card.
  bool heldBy(String? userId) =>
      userId != null && (suspendedBy == userId || alsoPausedBy == userId);

  /// "3 months" / "6 weeks" / "12 days" — empty under 30 days, because a
  /// young pause needs no commentary. Time-honesty is a mirror, not a
  /// deadline: informative, never manipulative (DR-ZYRA-142).
  String get pausedFor {
    if (suspendedAt == null) return '';
    final days = DateTime.now().difference(suspendedAt!).inDays;
    if (days < 30) return '';
    if (days < 61) return '${(days / 7).floor()} weeks';
    final months = (days / 30).floor();
    return '$months month${months == 1 ? '' : 's'}';
  }

  /// #17 — APP/Journey/JOURNEY AVAILABILITY/Summary.md: "24-hour
  /// cooling period begins (no actions possible)" after End Journey,
  /// "after 24 hours, journey officially disconnects" and Restart
  /// becomes available.
  bool get isInCoolingPeriod =>
      status == 'ended' &&
      endedAt != null &&
      DateTime.now().isBefore(endedAt!.add(const Duration(hours: 24)));

  /// Founder, 2026-08-18: a direct New Journey request remains visible for
  /// 60 days after End. This client boundary prevents the app offering the
  /// action outside the approved window; OA-ZYRA-242 owns matching server and
  /// Browse enforcement before the rule is production-complete.
  bool get isWithinNewJourneyRequestWindow =>
      status == 'ended' &&
      endedAt != null &&
      DateTime.now().isBefore(endedAt!.add(const Duration(days: 60)));

  bool get canRestart => isWithinNewJourneyRequestWindow && !isInCoolingPeriod;

  /// "You can ask again in 4 hours".
  ///
  /// ADDED 2026-08-07 with the copy review. The Founder asked for "Restart
  /// available in 24 hours" in place of "Ended — cooling period", and the
  /// reasoning was right — users care what happens next, not what the
  /// internal state is called.
  ///
  /// REWORDED 2026-08-10, OA-ZYRA-159. The word "Restart" had to go: it names
  /// a capability that has refused since 2026-08-06 and promises something
  /// unilateral. What actually becomes available is the right to ASK, which
  /// the other person may decline. The getter name stays `restartAvailableIn`
  /// for now — renaming it touches call sites for no behavioural gain, and
  /// OA-ZYRA-156 step 7 will be through this file anyway.
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
    if (!isWithinNewJourneyRequestWindow) {
      return 'the 60-day request window has ended';
    }
    final left = endedAt!
        .add(const Duration(hours: 24))
        .difference(DateTime.now());
    if (left.inMinutes <= 0) return 'you can ask again';
    if (left.inMinutes < 60) return 'you can ask again in under an hour';
    final hours = (left.inMinutes / 60).ceil();
    return 'you can ask again in $hours ${hours == 1 ? "hour" : "hours"}';
  }
}
