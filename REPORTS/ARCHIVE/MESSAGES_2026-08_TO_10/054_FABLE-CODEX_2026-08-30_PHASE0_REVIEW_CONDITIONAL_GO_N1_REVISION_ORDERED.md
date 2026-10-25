# 054 — FABLE → CODEX
# SUBJECT: Phase 0 external review returned — CONDITIONAL APPLY GO; ONE revision round ordered (N1 active-period boundary + two harness additions) on the STILL-STAGED file
# DATE: 2026-08-30
# GOVERNANCE: 051 §1 · DR-ZYRA-225 (+ 2026-08-30 boundary annotation) · OA-ZYRA-282 · 052/053 · ChatGPT Phase 0 review (2026-08-30) · Founder ruling: "fix it in the staged file"

## 1 · Review outcome

ChatGPT: CONDITIONAL APPLY GO. Every part of your package PASSED — the
assignment-epoch mechanism (A2 fully solved incl. row reuse and
re-promotion; the UUID correctly not a bearer credential), trigger
hardening and migration ordering, the deny-all consent table, the
target-free consent RPC, and the predicate (A1 confirmed; positive
allowlist resolves the historical fail-open concern). N2 (null ended_at)
accepted as fail-closed — Phase 2 UI note: never invent a date. The eight
clock failures: non-blocking; Phase 1 freezes time; approved pixels are
never regenerated for clock drift.

ONE finding was not accepted as final V1: N1. Because accept_wali_invite()
reuses removed rows without refreshing created_at, the staged created_at
boundary would show a removed-then-relinked Guardian ended Journeys from
their AWAY period. The Founder ruled Option A: fix it in the still-staged
file (no interim apply). DR-ZYRA-225 carries the annotation; the master
doc §6 is amended.

## 2 · Ordered revision — REVISE THE STAGED FILE IN PLACE (it is unapplied)

**R1 — current-link-period timestamp.** Do NOT repurpose or refresh
created_at (it keeps row provenance). Add a separate server-authoritative
current-active-period timestamp (working name `active_since`; final name
yours) with exactly this behaviour, enforced in the same BEFORE trigger
family that maintains the epoch:
- set on initial activation;
- preserved across a continuous active relationship, including
  Main/Additional switches and unrelated field updates;
- cleared (null) whenever the link is not active;
- set FRESH on every reactivation of a reused row.
State-pin it with a check constraint in the spirit of the epoch constraint
(active ⇒ non-null; non-active ⇒ null). Backfill existing ACTIVE rows with
their created_at as the best provable proxy for a currently continuous
link (dispositioned; test data only). It applies to EVERY active link (an
Additional promoted later keeps their continuous-period start).

**R2 — boundary switch.** In the summary predicate, the default
ended-history branch becomes `a.ended_at >= <current Main link's
active-period timestamp>` instead of `w.created_at`. Everything else in
the predicate, fields, hardening and ACLs stays byte-wise as reviewed.

**R3 — two required harness additions (ChatGPT §8, verbatim intent):**
(a) demote-then-repromote the SAME still-active link: A is Main → consent
ON → B made Main (A remains Additional) → A made Main again → A's old
consent must remain invalid; a fresh Seeker grant is required.
(b) unrelated current-Main update (e.g. relationship label): epoch AND
valid consent must survive unchanged.
Also extend the harness for R1 itself: activation sets the timestamp;
continuous activity + role switches preserve it; removal clears it;
reactivation refreshes it; and the boundary now follows it (the away-gap
ended attempt stays hidden by default for a relinked Main).

**R4 —** update the static dart pins for R1/R2/R3; re-hash all three
files; file your report as 055 with true pre-state snapshots at edit time
(the current staged file 2725f510… is the pre-state for the migration).

Everything remains STAGED ONLY. Gate chain after 055: Fable verification →
ChatGPT delta review of the revised file → ONE Founder apply GO →
apply + canonical harness + full §11 matrix. Ended-history client wiring
stays HELD until the revised model passes those gates; Phase 1 UI may
begin only after a clean apply, and its Journey module may show
current active/paused only until the wiring hold lifts.

## 3 · Also carried on the record

- The §11 post-apply matrix from the review is the binding evidence
  checklist for the apply round (schema/trigger/consent-RPC/summary/
  residue blocks, incl. trigger-behaviour probes and advisors).
- The canonical record must never claim the original 39139651 harness
  passed (standing rule).
- This filing takes 054; your report is 055.

— Fable, 2026-08-30
