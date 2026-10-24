# 131 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-288 and OA-ZYRA-289 applied, post-apply verified, and corrected iPhone build launched  
**Decision / action:** DR-ZYRA-221 / DR-ZYRA-230 / DR-ZYRA-231 / OA-ZYRA-288 / OA-ZYRA-289  
**Status:** LIVE AND POST-APPLY VERIFIED; PROFILE BUILD INSTALLED AND LAUNCHED; FOUNDER VISUAL ACCEPTANCE PENDING

## 1. Outcome

The Founder-authorised production cutover completed on Supabase project
`sxoaxonzjqkgajmlagyk` (`ZYRA-APP-LAB's Project`, EU West, PostgreSQL 17).
Exactly the two authorised migration files were applied, in order, at their
approved SHA-256 values. No other migration was applied.

The complete governed post-apply matrix passed. The already-built signed iOS
profile app was then installed under the existing bundle identifier and
launched successfully on the Founder's iPhone. Device inventory shows one
ZYRA app, not two. No TestFlight/App Store upload and no git operation
occurred.

## 2. Exact production migration record

| Order | Version / name | Approved file SHA-256 | Live history statements MD5 | Result |
|---|---|---|---|---|
| 1 | `20260917133709` / `guardian_journey_summary_for_all_active_guardians` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` | `a691f9f5d520fc87d53f29ec8e640fbf` | APPLIED ONCE |
| 2 | `20260917144606` / `oa289_permanent_personal_codes_guardian_requests` | `edeaf6086caf136ae579691235c46007abb234e1ee1f135629a8b23b5511565a` | `47b0ff0a179af818caebe9a47f9c1cec` | APPLIED ONCE |

Live migration history now contains 208 rows, contains each target version
exactly once, and ends at `20260917144606`.

## 3. OA-ZYRA-288 post-apply verification

- `zyra_attempt_summary_for_guardian` is owned by `postgres`, SQL, STABLE and
  SECURITY DEFINER with an empty stored `search_path`.
- Execute authority is limited to owner, authenticated and service role.
- The output remains exactly four data-minimised fields: `attempt_id`,
  `started_at`, `ended_at`, `ended`.
- Caller/Seeker binding, current-active-link enforcement, the positive
  current/ended allowlist, active-period boundary, Main-only consent branch,
  and link/epoch consent binding are present.
- The transaction-only live role matrix passed for Seeker, Main Guardian,
  Additional Guardian, former-Main/still-active Additional Guardian,
  removed/inactive Guardian, unrelated caller, current and paused attempts,
  ended-in-period attempts, pre-link-ended attempts and Main-consent cases.
- The matrix rolled back and retained no fixture rows.

## 4. OA-ZYRA-289 post-apply verification

- Every public RPC is owned by `postgres`, SECURITY DEFINER, has empty stored
  `search_path`, and has only the intended owner/authenticated/service-role
  execute ACL.
- Private helpers remain owner-only. New private tables are owned by
  `postgres`, have RLS enabled, expose no client policies, and retain the
  intended service-role boundary.
- The evolved `wali_invites` columns, constraints, indexes and triggers match
  the frozen migration. Direct insert is denied to PUBLIC, anon and
  authenticated.
- The canonical stock harness ran once on production inside its transaction
  and reached terminal rollback. It proved current-IDV denial, mint format,
  safe preview, request-without-link, code-owner acceptance, stale reciprocal
  active-link recheck, correct deadline warning, expired-action denial,
  self-neutral handling and the exact preview output shape.
- Focused live probes passed stable repeat mint, wrong-role denial, rotation,
  hash-only retirement, inactive old plaintext, exact 10/hour and 30/day rate
  boundaries, all nine current-IDV RPC denials, code-owner IDV recheck and
  requester IDV recheck at acceptance.
- The final transaction-only extension completed successfully. Read-only
  `pg_stat_statements` evidence records exactly one completed call containing
  its `OA-ZYRA-289 EXTENSION PASS` marker. It covered neutral invalid/self/
  same-role/blocked/romantic/already-linked cases, wrong-party acceptance,
  genuine decline/cancel, actual two-day warning and expiry, and in-window
  legacy seven-day acceptance.
- Rollback cleanliness is exact: zero test users, profiles, personal codes,
  retired hashes, attempt rows, personal-code requests, or test links remain.
  The attempt identity sequence is at 97 because PostgreSQL sequences are not
  transactional. Those skipped identifiers are the expected harmless trace
  of rollback-only rate testing and contain no member data.

## 5. Advisor review

The post-DDL security and performance advisors were run. Their findings were
the intended architecture-wide SECURITY DEFINER notices, private RLS tables
with no client policies, initially-unused new indexes, and pre-existing
project findings. The new private tables are deliberately service-role-only;
the RPCs enforce caller identity and role themselves. No new release blocker
was found.

Reference guidance:

- <https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy>
- <https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable>
- <https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index>

## 6. iPhone delivery

| Check | Result |
|---|---|
| Signed profile binary SHA-256 | `8a851853f53676b1df93c3fdb84a9206170f4dd36a4f05da3e2ec5aac2edab9f` |
| Install | PASS — `flutter install --profile` exited 0 |
| Device inventory | exactly one `ZYRA`, bundle `app.zyraconnect.zyra`, version `1.0.0`, build `2` |
| Launch | PASS — `devicectl` launched the bundle; running process confirmed |
| Second app created | NO |
| TestFlight/App Store upload | NONE |

The same bundle identifier means this governed profile build replaced the
prior installed build. The Founder can now perform the visual flow check on
the open app.

## 7. Governance reconciliation

OA-ZYRA-288 and OA-ZYRA-289 now record live/post-apply-verified/device-launched
state. The personal-code handover and documentation index carry the same
status. The two live migration files are frozen production records and must
not be edited in place.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `2682dabe44dd2cec66fc969e56d6817456840391b2b41a51381c1b1b2a4c3669` | `73e645261da483ce22606026c7fc10e44b47f600a133712ead77693c276bfad6` |
| `SYSTEM/DOCUMENTS/ZYRA_PERSONAL_CODE_AND_GUARDIAN_REQUEST_HANDOVER_CURRENT_VERSION_V1.md` | `8a944c11f1807412327e5c3ecb08796d4fcfb2e39d35937e771a698f2b3317de` | `ab23e0f4cd0a21d981c9e4ee8ab19a0e55550cde7d9554026ffbb16961b38d4f` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md` | `11df44e5a0b4709a955b9bff3498068cb8eff1fd87247fdedbedfa0b287a0f9e` | `b2e027d4eefa19064c9beeab19ceacf81833eec21bbcce53f533a477bc310b72` |

This Message 131 had no pre-state.

## 8. Remaining gate

Only the Founder's visual/device acceptance remains for these two actions.
Server cutover, post-apply verification, installation and launch are complete.

— END OF MESSAGE 131 —
