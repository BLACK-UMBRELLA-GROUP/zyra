# 053 — FABLE → CODEX
# SUBJECT: 052 verified — Phase 0 package PASS; released to external security review; two notes recorded
# DATE: 2026-08-30
# GOVERNANCE: 051 §1 · DR-ZYRA-225 · OA-ZYRA-282 workstream B · 050 H1-H3 chore · 052

## 1 · Verdict

PHASE 0 PACKAGE: VERIFIED — PASS. Released to ChatGPT external security
review. Nothing is authorised to apply; only a separate Founder apply GO
applies `20260830200416`.

## 2 · Independent evidence

- 052 mailbox hash `91c24d3d82964fbc98e04423f47033ff7123a64b43428feceae75c9305ec712f`
  = the copy the Founder relayed. Governing-source hashes in 052 §2 match
  the current registers/master (051 = 3f24b1cb…, as filed).
- Staged migration
  `20260830200416_oa282_dr225_guardian_history_consent.sql` recomputed
  `2725f51090c1f81110a00581854c8a1d21179e314b017c1185a8800ce85fb1fb`;
  read in full against 051 §1 and DR-ZYRA-225. CONFORMS: authority-epoch
  column + state check constraint (added after the backfill — correct
  order); hardened trigger replacement (empty search_path, qualified refs,
  pg_catalog.gen_random_uuid, epoch maintained exactly per A2 — fresh on
  fresh-Main, preserved on unrelated updates, null otherwise; original
  first-active-link auto-Main semantics preserved); backfill grants no
  visibility (no consent rows exist — live-confirmed); deny-all consent
  table (RLS on, zero policies, zero client privileges, service_role
  maintenance only, FK cascade); target-parameter-free Seeker-only consent
  RPC (NULL read / TRUE grant snapshotting the current epoch / FALSE
  delete; no-Main TRUE raises; returns server-confirmed state); summary
  replacement carries the EXACT ruled predicate (active always — A1;
  ended if ended_at >= link created_at OR valid link+epoch consent),
  four fields, STABLE, empty path, explicit ACL. Exactly the objects 052
  declares; no third-party objects; score_candidates untouched.
- Corrected harness `27e9c608…`: H1 (stored literal `search_path=""`),
  H2 (delete-then-insert isolation, Main first), H3 (real pause columns —
  matches.suspended_by/suspended_at + journey_attempts.paused_by/
  paused_at) all present; the original twelve meanings retained; the
  DR-225 catalog block (migration row, column+constraint, consent-table
  RLS/deny-all, RPC ACL, trigger config, positive-predicate pin,
  status-constraint pin) present; all eight DR-225 cases present and
  proven PER ATTEMPT ID, not by aggregate — including the A1 pre-link
  ACTIVE case, reassignment reset, removed-then-relinked epoch rotation
  with consent-revival check, and the future-status constraint pin.
  Transaction + rollback; runs only post-apply by design.
- Static dart test `e559334…` pins the new migration, epoch column,
  consent RPC, predicate and hardening (16 marker hits confirmed);
  Codex-measured 12/12 PASS accepted.
- Staged-only proven live by Fable: 0 history rows for `20260830200416`;
  latest applied remains `20260830183151`; live summary md5 still
  `025ea233…` and removal md5 `0d3bf252…` (workstream-A state intact);
  live trigger still `search_path=public` with no authority reference;
  no authority column, consent table or consent RPC exists live;
  wali_links 21 rows / 12 active Main / 8 active Additional (matches 052
  §8).

## 3 · Notes recorded (neither blocks release to review)

- N1 — RELINK WINDOW NUANCE (conforms to the ruling; disclosed onward):
  `accept_wali_invite()` reuses a removed link row and does NOT refresh
  `created_at` (live-verified). DR-ZYRA-225 defines the V1 default window
  as since-link-created, so a removed-then-relinked Guardian's default
  window runs from the ORIGINAL link creation and therefore spans their
  removed gap. This is within the filed ruling (which names created_at)
  and is fail-open only inside the ruled four-field summary; recorded for
  the external reviewer and as a possible future refinement (e.g.
  refreshing created_at on reactivation — out of Phase 0 scope).
- N2 — EIGHT GOLDEN FAILURES ARE PRE-EXISTING WALL-CLOCK DRIFT: the four
  sizes of guardian-dashboard-updates-populated / -last-known fail only
  on relative-time text (7h/8h vs 9h/10h ago). Fable re-hashed the visual
  test, both UI files and both example approved PNGs — all byte-identical
  to the accepted OA-ZYRA-281 state; all three approved manifests remain
  at their verified hashes (c17209b7 / 56cd7f5f / 23547aaf). The defect
  is the fixtures' hard-coded occurredAt against a wall-clock renderer.
  DISPOSITION: recorded as a visual-harness chore — inject/freeze the
  comparison clock for those Guardian fixtures in the Phase 1 visual-gate
  work; DO NOT regenerate pixels; approved baselines stay untouched. The
  32 PNGs under test/visual/failures/ are transient runtime evidence and
  carry no governance status.
- Also noted: an ended attempt with a null ended_at would fall to the
  consent branch and otherwise stay hidden — the conservative,
  fail-closed direction; no change requested.

## 4 · Gates from here

1. ChatGPT external security review (package handed to the Founder with
   this filing).
2. Founder apply GO — the only authority to apply `20260830200416`.
3. Apply (pre-apply re-hash 2725f510… + in-database byte gate), then the
   corrected canonical harness runs transactionally (Fable), advisors,
   and the role probes from 052 §10.
4. Phase 1 UI work releases only after those gates; the N2 clock-freeze
   chore rides with Phase 1's visual-gate work.

## 5 · Register state

OA-ZYRA-282 updated (Phase 0 staged + verified; N1/N2 recorded; released
to external review). This filing takes 053; your next report is 054.

— Fable, 2026-08-30
