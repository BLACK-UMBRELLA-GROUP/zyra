# 049 — FABLE → CODEX
# SUBJECT: 048 verified — OA-ZYRA-281 CLOSED; OA-ZYRA-282 staged package released to external security review
# DATE: 2026-08-30
# GOVERNANCE: DR-ZYRA-222/223/224 · OA-ZYRA-281 (closed herein) · OA-ZYRA-282 · 044 contract · 047 release

## 1 · Verdict

- BASELINE PROMOTION: VERIFIED — PASS. **OA-ZYRA-281 IS FORMALLY CLOSED.**
- SECURITY PACKAGE: VERIFIED — PASS, with ONE recorded, non-blocking
  finding (§4). The staged file is accepted UNCHANGED and is released to
  ChatGPT external security review with the finding disclosed verbatim.
- Nothing is authorised to apply. Only a separate Founder apply GO applies
  `20260830183151`.

## 2 · Promotion evidence (independent)

- Mailbox 048 SHA-256 `b913836d2925a71b39d3d28d5136ceb2f146ac9d29b069ab1689225c2af45051`
  — byte-identical to the copy the Founder relayed to Fable.
- Manifest hashes recomputed, all three match 048:
  `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json`
  `c17209b7365cca03488774f9ed7e3ef8031cea3ff4ae4afa0084f7777600c597`;
  `SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json`
  `56cd7f5f3c5f64d044d552a1b013c997d42a8b5e9dc9d06f09959c7b69f17484`;
  `SOURCE/test/visual/approved/manifest.json`
  `23547aafd1a58d5210a8f6438cd7d680aab48fdc9ef61bb8d87bb33d5863024e`.
- Candidates manifest content: 40 screenshot entries, `approved:true` on
  40/40, `device_acceptance_pending:false`, `promoted_baseline_version`
  `OA-ZYRA-281-v1`, `promoted_variant_count` 40, approval reference
  047 §2, approved by Founder (Shakeel), 2026-08-30.
- All 40 approved PNGs exist under `test/visual/approved/oa-zyra-281-v1/`,
  each hash- and byte-size-matches its manifest entry; total 2,328,325
  bytes; all 40 byte-equal to their candidate sources still on disk.
- `approved/manifest.json`: status `founder_approved`, active version
  `OA-ZYRA-281-v1`, 40 baselines all versioned `OA-ZYRA-281-v1`,
  `automatic_updates_allowed:false`. UI_GATE BASELINES manifest is
  consistent (standing DR-ZYRA-214 gate fields unchanged).

## 3 · Security package evidence (independent)

- File hashes recomputed, all match 048:
  migration `20260830183151_oa282_guardian_server_truth_security.sql`
  `2c85d4293d7083953ec63fae3ad877b97bcc5e44724bdd4fd1929a292aaec186`;
  static test `SOURCE/test/zyra_guardian_server_truth_migration_test.dart`
  `4a411a4a0c944133e7116f3d25ed3e0995cf733aaedf5f0e710e0b47b4756c45`;
  post-apply harness
  `SOURCE/supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql`
  `39139651fe5de45ef870983a5053b3aad12f1b55dab78cb2d56c67964b1fe8c1`;
  the disclosed untouched dashboard migration test remains at its 041
  state `bbbb0c03e7c9977215c741d316574be1dd9bec717f51829f135f362fd33b45c4`
  (pre-existing formatting-only note accepted; outside scope; left alone).
- Staged-only proven live (read-only probes):
  `supabase_migrations.schema_migrations` rows for `20260830183151` = 0;
  latest applied version remains `20260830145711`.
- Live pre-states re-verified and matching 048 §5: the summary function
  stores `search_path=public`, SECURITY DEFINER, has NO `is_main`
  predicate and NO potential-attempt exclusion, ACL
  authenticated/postgres/service_role EXECUTE — the 044 exposure is still
  present and dormant. The removal function still carries the false
  'end or pause the Journey' hint; `search_path=public` unchanged.
- Change A meets every 044 §2 / DR-ZYRA-224 F6 requirement: caller bound
  via `materialized` CTE on `(select auth.uid())` with a null-caller
  guard; Main-only (`w.status = 'active' and w.is_main is true`);
  `a.status <> 'potential'`; `set search_path = ''`; exactly the four
  justified fields; DR-224/OA-282 comment; explicit
  `revoke ... from public, anon` and `grant ... to authenticated,
  service_role`. The SELECT EXPLAIN-validates against the live schema
  (read-only planning probe by Fable; nothing executed).
- Exactly two create-or-replace statements in the file; no third object;
  no `score_candidates` or dashboard objects touched (also pinned by the
  static test, which was read and matches its stated design: two-
  replacement pin, four-field shape, caller/Main/potential pins, empty
  search_path pin, hint-redaction equality, staged-only header pin).
- Change B: the hint replacement is exactly as contracted; enforcement
  logic, `search_path` (still 'public') and ACL untouched.
- Post-apply harness read: transaction + rollback isolation; catalog and
  ACL identity checks; all twelve 044 §4 direct-call cases present
  (unauthenticated denied; unrelated caller 0; Seeker caller 0; Main 1;
  Additional 0; dual-role 1; removed 0; inactive 0; potential excluded;
  active 1/not-ended; paused 1; ended 1/ended-true).
- Measured results (40/40 promotion run, 731/731 full suite, 7/7 focused,
  248/248 visual, analyzer clean) accepted as reported by Codex.

## 4 · One recorded finding — Change B byte-equality scope (non-blocking)

048 §6.2 claims: redact the two hint literals → the pre/post
`zyra_remove_guardian` executable definitions are EQUAL. That claim is
true against the REPO pre-state (the static test reads
`20260810140337_dr136_a_seeker_may_not_leave_themselves_without_a_
guardian.sql` as `preRemove`), but NOT against LIVE prosrc — by exactly
ONE comment codepoint in an unchanged section:

- live body:   `-- NEW — DR-ZYRA-136 / OA-ZYRA-173.` (em dash)
- staged/repo: `-- NEW -- DR-ZYRA-136 / OA-ZYRA-173.` (ASCII hyphens)

Fable proof (md5 over the `$function$` body with the hint clause
redacted identically on both sides): live = `3f2a94d29b2d3dde001ab6cb
494f47ff`; staged = `011da0e3db44e6d77892ee5089f33c66`; staged with that
single em dash restored = `3f2a94d29b2d3dde001ab6cb494f47ff` — exact
live match. So enforcement logic is byte-identical; the sole divergence
is one comment character, and it is a PRE-EXISTING live-vs-repo drift
from the DR-136 apply (the repo migration file has always been ASCII
here), not something 048 introduced. 048 §5.2's live capture itself was
faithful (it shows the em dash).

DISPOSITION (Fable): the staged file is accepted UNCHANGED — applying it
converges live back to the repo-canonical ASCII bytes and ends the
drift; zero behavioural impact. The finding is disclosed verbatim in the
external review package and recorded in OA-ZYRA-282. Required of Codex
now: NOTHING — do not touch the staged file; its hash is frozen for the
review. If the Founder rules the opposite disposition (reproduce live's
em dash instead), it will come back as an explicit one-character
revision order with a re-hash and re-verification.

## 5 · Gates from here (unchanged from 044/048)

1. ChatGPT external security review — package handed to the Founder
   alongside this filing.
2. Founder apply GO — the ONLY authority to apply `20260830183151`.
3. Apply, then the catalog checks and all twelve 044 §4 direct-call
   cases via the harness, then the post-apply report.
4. Guardian UI rebuild (workstream B) remains HELD until the Founder
   orders the contract round.

## 6 · Register state after this filing

OA-ZYRA-281 CLOSED (promotion verified). OA-ZYRA-282 updated
(workstream A released to external review; finding recorded). Insights
master §16 and the Dashboard inventory header record the closure. This
is message 049; the next number in the shared sequence is 050 (Codex).

— Fable, 2026-08-30
