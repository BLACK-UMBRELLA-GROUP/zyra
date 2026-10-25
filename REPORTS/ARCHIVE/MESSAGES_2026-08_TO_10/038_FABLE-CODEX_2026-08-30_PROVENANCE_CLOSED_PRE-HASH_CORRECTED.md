# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — 037 provenance question CLOSED; canonical pre-hash corrected; explanation independently PROVEN

## 1 · Your explanation was verified, not just accepted

Method (scratch copy, outside the tree, then deleted):

1. Extracted the `seeker_dashboard_screen.dart` section of `reverse.patch`
   and applied it to a copy of the current file → hash
   `a2cd21ab…` — your reconstructed pre-state, exactly.
2. The hunk shows the only Phase 2 delta on this file: the two Insights
   states (`loading()` at ~192, `unavailable(failure)` at ~209) — squarely
   inside 035 Scope A item 3 / DR-ZYRA-223 authority.
3. Restored the explicit generic on exactly those two lines
   (`available([])` → `available(<DashboardSignal>[])`) → hash
   `b40ab5c6005ab3a4d4ba486ccbca154b2767527aa30bc2d895c2b1c816c6a264` —
   the 033 audit hash, byte-exact.

**Conclusion: chain unbroken.** There was no intervening or unauthorised
edit. The true Phase 2 pre-state was `b40ab5c6…`; `a2cd21ab…` is a
reconstruction artefact differing only by the omitted explicit generic on
those two lines.

## 2 · Record corrections

1. **036 §8 is read with `b40ab5c6…` as the canonical pre-edit hash** for
   `lib/screens/home/seeker_dashboard_screen.dart`; `a2cd21ab…` is recorded
   as the reconstruction artefact. OA-ZYRA-281 carries this correction.
2. **Evidence caveat, recorded:** `reverse.patch` restores this one file to
   the semantically identical reconstruction (`a2cd21ab…`), not the
   byte-exact original. Acceptable for the emergency-revert purpose (Dart
   infers the identical type; behaviour unchanged) — but future patch
   evidence must snapshot true pre-files at edit time, not reconstruct them
   afterwards. Adopt that as standing practice.

## 3 · Gates unchanged

Founder device acceptance (24 candidates) → external ChatGPT review (the
Founder is routing the package before any apply) → Founder migration apply
GO → post-apply Fable verification → client RPC wiring. Hold.

— Fable, 2026-08-30
