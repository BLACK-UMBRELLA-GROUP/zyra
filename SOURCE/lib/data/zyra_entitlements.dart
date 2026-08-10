// THE CANONICAL JOURNEY LIMITS — one definition, every surface.
//
// Founder-approved 2026-08-09. Supersedes every scattered number that
// described how many Journeys a plan may hold.
//
// ═══════════════════════════════════════════════════════════════════════
// THE MATRIX
// ═══════════════════════════════════════════════════════════════════════
//
//                    ZYRA Basic        ZYRA One
//   Active               1                 3
//   Potential           25             unlimited
//   Paused               5                10
//   Ended                5                10
//
// ── WHY A FILE AND NOT FOUR CONSTANTS. This project has paid three times
// today for the same mistake: four copies of an age fetch, two copies of
// a comet animation, three copies of a Journey stage switch. Limits are
// worse than labels, because a limit that disagrees with the server does
// not look wrong — it looks like the app refusing you for no reason.
//
// So: add a FIELD to [ZyraJourneyLimits], never a second table of numbers
// somewhere else. If a plan gains a fifth countable thing, it goes here.
//
// ── POTENTIAL IS NULLABLE, AND null MEANS UNLIMITED — not zero, and not
// "unknown". ZYRA One has no ceiling on Potential Journeys. Anything
// comparing against this must handle null explicitly; [isWithin] exists
// so that nobody writes `count < limit` against a null and gets it wrong.
//
// ═══════════════════════════════════════════════════════════════════════
// 🔴 WHAT THIS FILE IS *NOT*, AS OF 2026-08-09
// ═══════════════════════════════════════════════════════════════════════
//
// IT IS NOT ENFORCED BY THE DATABASE. These are the agreed numbers, and
// today they are honoured by the client and by the dev panel only. The
// server still enforces exactly one rule, and it is a different one:
//
//   zyra_enforce_one_active_match() refuses a SECOND row with
//   status='active' for either party — and a PAUSED Journey is an active
//   row with suspended_by set, so today a paused Journey still occupies
//   the single active slot. Unique partial indexes
//   matches_seeker_a_active / matches_seeker_b_active enforce the same
//   thing at the storage layer.
//
// Which means the database physically cannot hold "1 active + 5 paused",
// let alone "3 active + 10 paused". Making these numbers real requires a
// migration that (a) excludes suspended rows from the active count and
// (b) makes the limit plan-aware. There is also no server-side seeker
// entitlement function yet — only wali_has_wali_one() — so the server
// currently cannot tell which plan a Seeker is on.
//
// That work is raised, not silently assumed. Until it lands, treat this
// file as the specification and the dev panel as the only place the
// numbers are visible.

import '../state/app_state.dart' show ZyraPlan;

/// How many Journeys of each kind a plan may hold.
///
/// [potential] is null when unlimited. Every other field is a real cap.
class ZyraJourneyLimits {
  /// Running Journeys — not paused. The headline entitlement.
  final int active;

  /// Mutual matches nobody has opened yet. Null means unlimited.
  ///
  /// On a capped plan, reaching this number does NOT block new matches.
  /// The agreed behaviour is a CHOICE at the moment of matching: end one
  /// of the existing Potential Journeys, or discard the new one. That
  /// flow is not built yet — see the header.
  final int? potential;

  /// Journeys held with suspended_by set. Independent of [active] by
  /// decision (Founder, 2026-08-09) — a paused Journey does not consume
  /// an active slot. The database does not yet agree; see the header.
  final int paused;

  /// Ended Journeys retained and shown in the Ended section.
  ///
  /// What happens AT the cap is deliberately not encoded here, because it
  /// has not been decided. Ending a Journey cannot be refused, so the cap
  /// must mean something else — oldest drops off the list, or oldest is
  /// deleted. Those differ materially under data-protection rules.
  final int ended;

  const ZyraJourneyLimits({
    required this.active,
    required this.potential,
    required this.paused,
    required this.ended,
  });
}

class ZyraEntitlements {
  ZyraEntitlements._();

  static const ZyraJourneyLimits basic = ZyraJourneyLimits(
    active: 1,
    potential: 25,
    paused: 5,
    ended: 5,
  );

  static const ZyraJourneyLimits one = ZyraJourneyLimits(
    active: 3,
    potential: null, // unlimited
    paused: 10,
    ended: 10,
  );

  static ZyraJourneyLimits of(ZyraPlan plan) =>
      plan == ZyraPlan.one ? one : basic;

  /// True when [count] is within [limit], treating null as unlimited.
  ///
  /// Exists so that no call site writes `count < limit` against a
  /// nullable and either crashes or silently treats unlimited as zero.
  static bool isWithin(int count, int? limit) => limit == null || count < limit;

  // ── DEV PANEL ONLY ────────────────────────────────────────────────────

  /// The most segments the dev panel will draw for one control.
  ///
  /// Founder, 2026-08-09: "ZYRA One Potential is unlimited but show max 10
  /// in toggle." Applied to every control, because a 26-wide segmented row
  /// for Basic's 25 Potential Journeys is not usable on a phone either.
  ///
  /// 🔴 CONSEQUENCE, stated rather than buried: the panel cannot stage
  /// Basic sitting AT its Potential cap of 25, which is exactly the state
  /// the "choose one to end" flow needs for testing. When that flow is
  /// built it needs its own control, not a longer row.
  static const int devSegmentCeiling = 10;

  /// Highest value the dev panel offers for a control whose real cap is
  /// [realCap]. Null (unlimited) and anything above the ceiling both come
  /// back as [devSegmentCeiling].
  static int devMaxFor(int? realCap) {
    if (realCap == null || realCap > devSegmentCeiling) return devSegmentCeiling;
    return realCap;
  }

  /// Segment labels '0'..devMaxFor(realCap), inclusive. Always starts at
  /// '0' — Founder, 2026-08-09: "make sure each option have option for 0
  /// also."
  static List<String> devOptions(int? realCap) =>
      [for (var i = 0; i <= devMaxFor(realCap); i++) '$i'];

  /// Clamps a stored dev value to what the CURRENT plan allows.
  ///
  /// Needed because the dev panel keeps its counts across a plan switch:
  /// set Paused to 8 on ZYRA One, drop to Basic, and 8 is now above
  /// Basic's 5. Used by both the panel (so the row shows a real value) and
  /// the fake-journey generator (so the list matches the row), which is
  /// the whole point of putting it here rather than in either of them.
  static int devClamp(int value, int? realCap) {
    final max = devMaxFor(realCap);
    if (value < 0) return 0;
    return value > max ? max : value;
  }
}
