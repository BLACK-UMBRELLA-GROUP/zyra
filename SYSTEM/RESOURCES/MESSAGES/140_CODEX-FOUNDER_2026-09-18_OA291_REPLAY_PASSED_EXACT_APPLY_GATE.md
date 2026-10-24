# 140 — CODEX → FOUNDER

**Date:** 2026-09-18  
**Subject:** OA-ZYRA-291 replay passed; exact production apply gate ready  
**Production database:** unchanged  
**Git:** not used

## 1. Outcome

OA-ZYRA-291 is ready for its separate exact production apply decision. The
client is already installed on the Founder's iPhone and fails closed while the
new RPC is absent. No further client build is required for this cutover.

## 2. Immutable target

- Project: `sxoaxonzjqkgajmlagyk` (`ZYRA-APP-LAB's Project`, EU West)
- File: `20260918094504_oa291_per_guardian_past_journey_summaries.sql`
- SHA-256:
  `2cd6dff44ca9b0038e117ec0df6a6171e76ce92c296f1a761a6d41e0fe025b23`
- Expected migration version: `20260918094504`
- No other migration is authorised by this gate.

## 3. Live preflight

Read-only production probes confirmed:

- project status `ACTIVE_HEALTHY`, PostgreSQL 17.6;
- latest applied version before this gate is `20260918075737`;
- version `20260918094504` is absent;
- `guardian_link_authority_id` and the new generic consent RPC are absent;
- 21 Guardian links exist, 20 active, with zero duplicate active
  Seeker/Guardian pairs and zero invalid `active_since` rows;
- the existing Main-only consent table contains zero rows;
- current function owners, definer flags, empty search paths and grants match
  the pre-migration contract.

The production CLI dry-run returned exactly one pending file:

`20260918094504_oa291_per_guardian_past_journey_summaries.sql`

No seed, role file, history repair or second migration was pending.

## 4. Fresh isolated replay

A disposable local Supabase PostgreSQL 17 stack replayed 212 ordered versions:

- the 209 versions in current live history through OA-ZYRA-290;
- the two previously approved, byte-pinned replay-only OA-ZYRA-198 bridges;
- OA-ZYRA-291 as the sole new product migration.

The live-history IDV placeholder was replaced only in the disposable replay by
its original applied source file, SHA-256
`78eb82c82239eb04248a716835726b15f3d2265ce36706799daebebfeead4383`.
This is required because the exported live-history file is an audit pointer,
not executable SQL. The corrected replay package inventory digest was
`66997307b47a6b380a03d96442eb906bea0a75664c803826f0572dd86c1e1eaf`.

Result: **PASS**. All 212 versions applied in order; database reset completed.
No production credentials or production data entered the disposable database.

## 5. Post-apply role matrix

New rollback-only harness:

`SOURCE/supabase/tests/zyra_oa291_per_guardian_past_summary_post_apply.sql`

SHA-256:
`efe0648e280016cb9aca4e2e04f9ebbdfe13384479e8aa54edcc23aed6e58c40`

Result: **PASS**, then `ROLLBACK`.

It directly proved:

1. Main and Additional Guardians both start OFF for pre-link summaries.
2. Current-period ended plus active summaries remain available to both.
3. Granting Main does not grant Additional, and vice versa.
4. A continuous Main/Additional switch preserves the same person's link epoch
   and permission.
5. Revoke removes old summaries immediately.
6. Removal removes all access; reactivation rotates the link epoch and starts
   OFF even if an old consent row exists.
7. An unrelated Seeker and a Guardian cannot mutate the Seeker-owned setting.
8. Null caller receives no summary and cannot read consent state.
9. `anon` has no execute grant; `authenticated` has only the intended RPC
   execute grants and no direct consent-table access.
10. The summary output remains exactly four fields: attempt id, started time,
    ended time and ended flag.

## 6. Code verification

- Focused Guardian/migration/client suite: **62/62 PASS**.
- `flutter analyze`: **PASS — no issues**.
- Migration contract suite includes the transactional harness pin.
- Approved visual baselines were not changed.

## 7. Advisor baseline

Security and performance advisors were captured immediately before apply. The
standing findings remain the existing audit bucket: private/RPC-only RLS tables
without policies, the caller-scoped participation view, intentional
authenticated definer RPC notices, leaked-password protection setting,
unindexed-FK information, unused-index information and existing multiple
permissive policy warnings. OA-ZYRA-291 creates no new table or index.

After apply, the same advisors must be rerun and compared. Only the expected
new authenticated-definer notice for
`zyra_guardian_history_consent(uuid,boolean)` is acceptable without a new
Founder decision.

## 8. Exact Founder GO required

The binding apply instruction is:

> I authorise one production apply on Supabase project
> `sxoaxonzjqkgajmlagyk` of migration
> `20260918094504_oa291_per_guardian_past_journey_summaries.sql`, SHA-256
> `2cd6dff44ca9b0038e117ec0df6a6171e76ce92c296f1a761a6d41e0fe025b23`,
> and no other migration. Apply once, stop on any drift or failure, then run
> the rollback-only OA-ZYRA-291 post-apply matrix plus catalog, grant, migration
> history and advisor verification. No retry or repair without a new exact GO.

Until that exact GO is given, production remains unchanged.

