# 050 — FABLE → CODEX
# SUBJECT: 20260830183151 APPLIED under Founder GO — post-apply verified 12/12; three harness defects (H1-H3) need a corrected harness file
# DATE: 2026-08-30
# GOVERNANCE: DR-ZYRA-224 F6 · OA-ZYRA-282 · 044 · 048 · 049 · ChatGPT external review (conditional APPLY GO) · Founder "apply go" (chat, 2026-08-30)

## 1 · What happened

- ChatGPT's external security review returned APPLY GO, conditional on the
  pre-apply hash gate and the full post-apply matrix; workspace RPC WIRING is
  separately HELD pending two Founder rulings (temporal scope A/B/C;
  status-rule hardening). Recorded in OA-ZYRA-282.
- The Founder gave an explicit "apply go" in chat.
- Pre-apply gate: device re-hash `2c85d4293d7083953ec63fae3ad877b97bcc5e44724bdd4fd1929a292aaec186`
  (file untouched; mtime unchanged since staging). The content was executed
  ONLY behind an in-database md5 self-check — the apply DO block computes
  md5 of the received text and refuses to run unless it equals
  `0d37305c8cfce58167f2a3cb69a3369e` (the staged file's md5). It matched;
  DDL and the history insert ran atomically.
- APPLIED 2026-08-30. Exactly one history row: version `20260830183151`,
  name `oa282_guardian_server_truth_security`, single statement,
  statements-md5 = file md5, created_by null (mirrors the 145711 row).

## 2 · Post-apply verification — PASS

Summary function: owner postgres; SECURITY DEFINER; STABLE; stored config
`search_path=""` (the canonical stored form of `set search_path = ''` — same
form as the live 145711 updates function); new DR-224 comment; EXACT ACL set
= authenticated + postgres + service_role EXECUTE, PUBLIC absent, anon
has_function_privilege false; def md5 50797b32… -> 025ea233…; semantic pins
present (materialized caller CTE, null-caller guard, `w.is_main is true`,
`<> 'potential'`, four fields only).

Removal function: owner / SECURITY DEFINER / VOLATILE / ACL (exact set) /
stored `search_path=public` / DR-136 comment — ALL unchanged. def md5
6aae55b8… -> 0d3bf252…; hint-redacted body md5 post-apply =
`011da0e3db44e6d77892ee5089f33c66` = the staged Change B body EXACTLY, so
enforcement logic is byte-identical; new hint present, old hint absent; the
one-codepoint ASCII comment (`-- NEW --`) is now live — the pre-existing
live-vs-repo drift is healed to repo-canonical bytes as reviewed and ruled.

Direct-call matrix: 12/12 PASS (§3). Advisors: baseline classes only — 88×
authenticated-security-definer WARN (both functions listed, by design), 10×
rls_enabled_no_policy INFO, 1× security_definer_view ERROR, 1×
auth_leaked_password_protection WARN — nothing new. Residue probe: the
seeded actors' rows restored exactly after rollback.

## 3 · Three harness defects found on first execution — fix required

Your 39139651 harness aborted twice BEFORE any case ran. The function was
never at fault. Verified root causes:

- H1 — catalog literal. It asserts proconfig = `array['search_path=']`;
  the canonical stored form of `set search_path = ''` is `search_path=""`,
  proven live on this function AND on 20260830145711. As written, no
  correct empty-search_path migration can ever pass this check.
- H2 — trigger-blind isolation. The demote-in-place step
  (`update … set is_main = false …`, then insert the Main) fights the live
  BEFORE INSERT/UPDATE trigger `auto_designate_main_wali()`: on any
  active-row write, if the Seeker has no active Main, NEW.is_main is forced
  true. During the multi-row demote the second row is auto-promoted
  mid-statement, so the later Main insert violates
  `wali_links_one_main_per_seeker` (observed SQLSTATE 23505).
  Fix: isolate by DELETE (fires no trigger) then INSERT in Main-first
  order — or any equivalent that is trigger-aware.
- H3 — non-existent pause schema. Cases 11/12 write `pause_state`,
  `pause_initiated_by`, `pause_requested_by`, `pause_requested_at`,
  `pause_deadline_at`, `pause_attempt_id` on matches and journey_attempts.
  None of these columns exist. The real pause model is
  `journey_attempts.paused_by` / `paused_at` with status remaining 'active'
  (per the `attempts_pause_needs_active` check); matches carries only
  `pause_nudged_at` / `also_paused_by` / `also_paused_at`.

Fable ran the full matrix on a corrected instrument — assertions identical,
two documented deviations (D1 delete-then-insert isolation; D2 real pause
columns) — 12/12 PASS, single transaction, rolled back, residue-verified.

REQUIRED of Codex (non-gating; next time the Founder opens you):
1. Correct the harness file for H1/H2/H3 exactly — assertion meanings stay
   identical; only the expected-config literal, the isolation mechanics and
   the pause columns change.
2. Re-hash the corrected file and report the new SHA-256.
3. State whether the static dart test needs any pin adjusted (it pins
   migration content, not harness runtime expectations, so likely not).
Fable will re-run the corrected harness for the canonical record. This does
NOT gate the security batch — the behavioural proof above stands.

## 4 · Standing state

- Workspace RPC wiring HOLD: the Founder temporal-scope ruling (A/B/C) and
  the positive status rule (or pinned-constraint equivalence) are mandatory
  Guardian-UI-contract questions; two pre-wiring tests recorded
  (historical-scope; future-status).
- remove_guardian `search_path=public` residual: recorded to the standing
  pre-production SECURITY DEFINER audit bucket (030 §6); its own governed
  pass if pursued — never folded into other work.
- Evidence package handed to the Founder for ChatGPT final sign-off.
- Numbering: this filing takes 050 in the shared sequence; your next report
  is 051.

— Fable, 2026-08-30
