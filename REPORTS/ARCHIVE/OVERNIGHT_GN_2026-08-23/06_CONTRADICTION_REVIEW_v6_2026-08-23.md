# CONTRADICTION REVIEW — Live Guardian Network Draft v6

**Reviewer:** Fable (in-session, $0.00 API cost)
**Date:** 2026-08-23 (re-review demanded by P6/M2 of the post-run loop; replaces `03_FABLE_VERIFY.md`, which reviewed the restored ORIGINAL, not the draft — see response §F14)

## Artifact lineage (AC-13)

| Item | Value |
|---|---|
| Candidate reviewed | `02_DRAFT_v6_fable_fix.dart` — sha256 `73382e1d7af679f7…` |
| Live app file | `SOURCE/lib/screens/wali/wali_network_screen.dart` — sha256 `73382e1d7af679f7…` — **byte-identical to candidate** |
| Contract | `01_AGREED_RULES.md` (10,418 bytes, 145 lines — **truncated**: declares Rules 1–47, ends mid-Rule 22) |
| Scope of this review | Rules 1–21 + the written half of Rule 22. **Rules 23–47 are NOT ASSESSABLE — they exist only as a count in the contract's status line.** No verdict is issued on unwritten rules. |
| Gates already passed | flutter analyze rc=0 (`ANALYZE_apply.txt`); zyra_check rc=1 — 3 findings all pre-existing in other files (`ZYRA_CHECK_apply.txt`, DR-ZYRA-165) |

## Structure of the artifact

Production path (non-developer): entitlement gate → locked view (Guardian+ mock paywall, "no real payment" disclaimers ×2) or unlocked view → **empty states only** (Discover/Requests). No candidate data can render in production. Preview path (`ZyraDeveloperAccess.canUseDeveloperTools` only): full mock experience — FIRST DRAFT pill (line 499), dev scenario switcher (scenes: recommendations / loading / error / empty / capacity / suggested / passed; plans: basic / one), mock wards, 4 mock recommendation cards, staged-suggestion Requests view, profile bottom sheet.

## Rule-by-rule verdicts

| Rule | Verdict | Evidence (v6 line refs) |
|---|---|---|
| 1 — No feed without active Seeker | **HELD** | wards empty → "Link a Seeker first" (552–558); multi-ward unselected → "Choose a Seeker", no feed (566–572); Requests without Seeker → empty state (1249–1258); production renders empty states only (277–296) |
| 2 — Single-Seeker context | **HELD (preview)** | Recommendations derived per selected ward (322–327); decisions keyed `'${selected.id}/${recommendation.id}'` (385, 405, 455) — no cross-context bleed |
| 3 — Selector behaviour | **HELD (UI)** | One ward → static expanded chip, no-op tap (666–674); multiple → explicit chips, no default (`_selectedSeekerId` starts null). C3-OFF exclusion from the ward list: NOT EXERCISED (mock ward composition lives in `zyra_dev_scenario.dart`) |
| 4 — Composite key | NOT EXERCISED | No persistence in draft; preview keys are (seeker, candidate) with guardian implicit — direction correct, server schema unbuilt |
| 5 — can_introduce() server gate | NOT EXERCISED | Mock only; page states "No action on this page changes live data" (642) |
| 6 — Hard filters absolute | NOT EXERCISED | Conformant by absence: no widen/override/"near-matches" control exists anywhere |
| 7 — zyra_can_match live | NOT EXERCISED | No server |
| 8 — Blocks terminal | NOT EXERCISED | No block simulation |
| 9 — Safety holds silent | NOT EXERCISED | Conformant by absence: no "unavailable" labels or grey states; empty-scene copy "keep looking without widening their choices" (593) |
| 10 — Journey availability filter-out | NOT EXERCISED | Conformant with the default: no 🔴/status indicators anywhere |
| 11 — Never weaker than Browse | NOT EXERCISED | No server |
| 12 — Approved Rung-0 field set | **VIOLATED** | Full first name on the Discover card — `'${recommendation.firstName}, ${recommendation.age}'` (960) — and on the Requests row (1314); Rule 12 approves **first-name initial** only. Avatar initials (945, 1304) are compliant. Also **INCOMPLETE**: verified-Guardian badge, 🟢 availability indicator, and compatibility band are uniformly absent from the card. Displayed fields otherwise clean: age ✓, region only (965) ✓, relationship/family label (979) ✓ |
| 13 — No free text | **HELD** | No input controls anywhere; every string is system/mock-controlled |
| 14 — Reason chips taxonomy | NOT VERIFIABLE HERE | Chips render from `recommendation.reasons` (1006–1027); the strings live in `guardian_network_preview.dart` (outside this file); page disclaims fields as provisional (642) |
| 15 — Ladder never inverted | **HELD** | Region only; no city string anywhere in card or sheet |
| 16 — Uniform field set | **HELD** | One card widget for all profiles; no per-profile conditional omission (the Rule-12 gaps are uniform — a completeness issue, not a sparseness leak) |
| 17 — v1 action set | **INCOMPLETE** | Card actions are View · Pass · Suggest (1034–1068). **Save is missing.** FIR absent with explicitly deferring copy — "…once the final consent flow is approved" (1266) — acceptable pending D-items. No extra actions; no messaging (Part G respected) |
| 18 — View is silent | **HELD (preview)** | View opens a local sheet only; nothing simulates or implies notification |
| 19 — Save/Pass private, Pass reversible | **HELD for Pass; Save absent** | Pass dims the card (912), confirmation "Removed from this recommendation list" + Undo (1070–1076, 1191–1232); silent; reversible ✓ |
| 20 — Suggestion is not consent | **HELD (copy)** | "Suggestion staged for the Seeker." (1210); "Suggested to X · awaiting their choice" (1319); "No request has been sent to another family." (1277). Routing to the real `wali_suggestions` pipe: NOT EXERCISED (mock) |
| 21 — Decline reasons never disclosed | NOT EXERCISED | No decline state in mock scenes; nothing discloses a reason |
| 22 (written half) — FIR chain | NOT EXERCISED | FIR not built; consistent with a rule that is half-written. Capacity scene (622–627) disables Suggest at capacity — instinct toward unwritten Rule 38, unverifiable against a truncated contract |
| 23–47 | **NOT ASSESSABLE** | Not present in the written contract (F13) |

## New defects found in the live artifact

1. **Empty profile sheet (functional stub).** `_GuardianNetworkProfileSheet` (1341–1371) renders a styled sheet containing an empty `Column`. Tapping View on any card opens a blank sheet. ORIGINAL's sheet had content (including its line-1413 name site); the regeneration lost it and brace-closing repair made the loss analyze-clean. Readiness-gate lesson (AC-11): a widget test asserting sheet content would have caught this; flutter analyze cannot.
2. **Pricing copy in the locked view** — "Included free with a linked Seeker's ZYRA One subscription, or available on its own for £9.99/month" (181) and "Guardian's own Guardian+ entitlement may still provide access" (824). The Guardian+ gate itself is Founder-ratified; the £9.99/month figure and the standalone-purchase claim must be verified against the current PRICING documentation before any non-preview build. Flagged, not judged here.

## Invented-product-rules check

Beyond the flagged pricing copy: none found. Preview disclaimers are present and honest ("Preview fields and recommendation reasons are provisional. No action on this page changes live data.", "FIRST DRAFT" pill, "no real payment is taken"). D1–D13 remain pending and nothing in the artifact forecloses them.

## Verdict

**NOT READY as a finished first draft; SAFE and USEFUL to open on device.** The production path can leak nothing (empty states only). The preview path is a faithful skeleton of the agreed rules with three known gaps: the Rule-12 name display (two sites, deterministic fix available), three approved card fields uniformly missing, and the empty profile sheet. Founder phone-testing the preview now is reasonable **provided these gaps are read as known-issues, not as the intended design** — this document is that known-issues list. Full readiness additionally requires the completed contract (rules 22–47, AGREED_RULES v1.1) so the remaining 25 rules can be assessed at all.

— Fable · re-review of the exact live artifact, hash-verified
