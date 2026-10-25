# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — 041 migration revision VERIFIED PASSED; proceeding to the narrow external second pass

## 1 · Verification performed (independent, 2026-08-30)

- **Hashes:** 041 matched the relay (`c2e72c69…` recomputed); revised
  migration matches §1 (`4f11c53b…`); revised test file present (253 lines).
- **Full SQL read (380 lines) against 039 R1–R7 + 040 A1–A5 — all satisfied:**
  `caller_participation` retains attempt/match/role/is_main/attempt_status
  with no early collapse; every domain branch carries an explicit per-role
  audience predicate via EXISTS against the specific participation row
  (Additional Guardians excluded everywhere; dual-role resolved by specific
  participation); notification branch splits `direct_recipient` vs
  `seeker_match` audiences with related-match Seeker participation required;
  the six domain-canonical notification classes (`new_match`,
  `journey_request_accepted`, `journey_paused`, `journey_continued`,
  `journey_ended`, `milestone_confirmed`) are REMOVED from the allowlist and
  the match-level `NOT EXISTS` heuristic is deleted; `journey_decision_*`
  excluded; domain rows return `null::boolean` (three-state contract in the
  catalog comment, with the ruled not-an-inbox wording); reviews index is
  attempt-led with the partial predicate; guardian-suggestion index removed;
  every projected timestamp NOT-NULL-guarded plus live nullability evidence;
  attempt+match double-key equality on timeline/review branches; hardening
  unchanged (empty search_path, auth.uid()-only, clamp, all-or-none cursor
  22023, keyset, no writes, revoke public/anon).
- **Evidence spot-checks:** the `new_match`↔`match_created` single-writer
  claim verified in `20260812001249…` lines 41–68 (milestone inserts +
  `create_notification('new_match')` in one writer); guardian-suggestion
  Seeker-only audience verified in `zyra_guardian_suggestion_service.dart`
  ("Pending suggestions for the signed-in Seeker"; Guardian creation UI
  unbuilt); static test pins verified (view predicate + columns, suggestion
  non-widening, banned-class list, banned heuristic, 4× domain NULL,
  response index, no guardian-suggestion index).
- **Live probes (mine, read-only):** RPC absent; 0 `%dashboard_updates%`
  indexes; migration history still ends `20260829183507`; and
  `journey_decision_needed` confirmed ABSENT from the live notifications
  type constraint — your exclusion rationale independently verified.
- **Measured results** (10/10 focused, 696/696 full, clean analyzer, 0
  static findings, five seed EXPLAIN probes) — accepted as the measured
  record. 038 discipline observed: true pre-snapshots taken; canonical
  hashes clean.

**VERDICT: 041 VERIFIED PASSED.** The audience-evidence and canonical-source
tables are exactly the right shape — visibility now has provenance, and the
semantic-pair collapse (accept/start, match/match-created) is cleaner than
anything the earlier design had.

## 2 · Next gates

1. Narrow external second pass (audience authority, canonical semantics, SQL
   correctness, indexing, definer hardening) — the Founder is routing the
   package to ChatGPT now.
2. Founder apply GO (after the second pass).
3. Post-apply verification per your §7 ten-point matrix (including the
   index re-plan and role-case probes), then client wiring authorisation.

Hold until those return. Nothing further needed from you this round.

— Fable, 2026-08-30
