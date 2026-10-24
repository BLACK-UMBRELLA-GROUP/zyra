# 141 — CODEX → FOUNDER

**Date:** 2026-09-18  
**Subject:** OA-ZYRA-291 applied, verified and live  
**State:** LIVE · POST-APPLY VERIFIED · DEVICE CLIENT ALREADY INSTALLED  
**Git / TestFlight / App Store:** untouched

## 1. Production cutover

The Founder approved the exact instruction filed in Message 140. Immediately
before apply, Codex rechecked:

- project `sxoaxonzjqkgajmlagyk` was `ACTIVE_HEALTHY` in EU West;
- migration head was `20260918075737` and target `20260918094504` was absent;
- both source and disposable push copies matched SHA-256
  `2cd6dff44ca9b0038e117ec0df6a6171e76ce92c296f1a761a6d41e0fe025b23`;
- the push workspace contained the 209 live versions plus exactly OA-ZYRA-291.

Exactly one production migration was applied through the Supabase CLI:

- version: `20260918094504`;
- name: `oa291_per_guardian_past_journey_summaries`;
- file: `20260918094504_oa291_per_guardian_past_journey_summaries.sql`;
- SHA-256:
  `2cd6dff44ca9b0038e117ec0df6a6171e76ce92c296f1a761a6d41e0fe025b23`.

No seed, role file, history repair, second migration, retry or repair ran.

## 2. Transactional production role matrix

The rollback-only OA-ZYRA-291 harness executed without error against the live
schema, then rolled back. It covered Main, Additional, unrelated Seeker,
Guardian-as-mutator and null-caller cases; per-person isolation; OFF-by-default
state; grant; immediate revoke; continuous role-switch survival;
removal/reactivation invalidation; exact grants; direct-table denial; and the
unchanged four-field summary boundary.

Post-harness verification found zero `oa291-%@zyra.test` users. No synthetic
actor, link, Journey, attempt or consent persisted.

## 3. Catalog and data verification

- migration version `20260918094504` exists once and is latest;
- all 20 active Guardian links have a non-null role-neutral active-link epoch;
- zero inactive links retain an epoch;
- zero duplicate active Seeker/Guardian pairs exist;
- the existing consent table remains empty, matching its pre-apply count;
- `wali_links_guardian_link_authority_state` exists and is validated;
- the new generic consent RPC, legacy Main wrapper, summary RPC and trigger
  function are owned by `postgres`, are `SECURITY DEFINER`, use empty
  `search_path` and expose only the intended ACLs;
- `anon` cannot execute either Guardian summary RPC;
- `authenticated` can execute the intended RPCs but has no direct consent-
  table access;
- `zyra_attempt_summary_for_guardian(uuid)` still returns exactly attempt id,
  started time, ended time and ended flag;
- trigger `wali_links_auto_main` remains enabled.

## 4. Advisor delta

Security advisor counts are unchanged except for the one expected intentional
authenticated-definer notice for
`zyra_guardian_history_consent(uuid,boolean)`:

- authenticated definer notices: 96 → 97;
- RLS-without-policy information: 16 → 16;
- security-definer view errors: 1 → 1, pre-existing;
- leaked-password protection warning: 1 → 1.

Performance advisor counts are unchanged:

- unindexed foreign keys: 14;
- no-primary-key information: 4;
- unused indexes: 22;
- multiple permissive policies: 6.

No unexpected advisor finding was introduced.

## 5. Client and verification state

- focused Guardian/migration/client suite: 62/62 PASS;
- `flutter analyze`: PASS — no issues;
- client was already built, installed and launched on the Founder iPhone in
  Message 139;
- no reinstall is required: the previously fail-closed Additional history
  control now uses the live generic RPC automatically;
- Main's legacy compatibility route remains available.

## 6. Governance

OA-ZYRA-291 is now LIVE / POST-APPLY VERIFIED / DEVICE INSTALLED. Only Founder
visual acceptance of the live controls remains. OA-ZYRA-292 stays held: this
cutover did not add Guardian Notes, message sending or reciprocal-access UI.

True pre-state for this register transition is preserved under:

`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-291_2026-09-18/post-apply-governance-prestate/`

