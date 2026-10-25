---
id: DOC-ZYRA-0150
type: SPEC
status: CURRENT
feature: GENERAL
purpose: OA-ZYRA-168 — grant sweep: as applied
links: []
owner: ZYRA chat
---

# OA-ZYRA-168 — grant sweep: as applied

**Status:** APPLIED and VERIFIED — 2026-08-08
**Approved by:** Founder, Stages 1–3 together; Stage 4 excluded
**Migration:** `oa168_grant_sweep_stages_1_to_3`
**Plan:** ZYRA_OA168_GRANT_SWEEP_IMPLEMENTATION_PLAN_2026-08-08.md

Applied exactly as planned. No deviations. No data touched, no policy touched,
nothing dropped.

---

## 1. Result

| Check | Before | After | Required |
|---|---|---|---|
| `anon` write grants in `public` | 75 | **0** | 0 ✓ |
| Unmatched `authenticated` write grants | 46 | **0** | 0 ✓ |
| Matched `authenticated` write grants | 29 | **29** | unchanged ✓ |
| `service_role` write grants | 148 | **148** | unchanged ✓ |
| Policies in `public` | 65 | **65** | unchanged ✓ |
| `zyra_advance_stage` executable by `authenticated` | true | **true** | true ✓ |
| Default ACL, `postgres`/tables | `anon=arwdxtm` | **`anon=rxtm`** | no write bits ✓ |
| Default ACL, `supabase_admin`/tables | `arwdDxtm` | `arwdDxtm` | **not changed — see §3** |

Spot-checked individually and confirmed still granted: `likes` INSERT,
`messages` INSERT, `profile_photos` UPDATE, `wali_invites` UPDATE,
`notifications` UPDATE, `onboarding_answers` INSERT, `seeker_details` UPDATE.

**One correction to my own verification.** I labelled the expected matched-grant
count "22" in the check query. The correct figure is 29 (75 total − 46
unmatched). The label was a guess written into an assertion; the measurement
was right and nothing matched was revoked. Flagging it because an expectation
stated as a number, then not met, is the kind of thing that gets waved through.

---

## 2. The negative test

The check that matters, because a change I cannot observe failing is not one I
have verified.

```
as role anon:  insert into public.likes(liker_id, liked_id) values (...)
result:        ERROR 42501 — permission denied for table likes
```

**Refused at the grant layer, before RLS is consulted.** Before this migration
`anon` held the INSERT grant, so the same statement would have reached the
policy layer and been refused there — a single barrier. There are now two.

Run inside a `DO` block terminated by `RAISE`, so the transaction could not
commit even had the write been wrongly permitted.

---

## 3. Known gap — `supabase_admin` default ACL

Stage 3b attempted to change the `supabase_admin` default ACL and was refused;
`postgres` lacks the privilege. The migration caught the exception and
continued, by design.

**Consequence:** a table created in `public` *by supabase_admin* would still
inherit `arwdDxtm` for `anon` and `authenticated`. ZYRA migrations run as
`postgres`, so Stage 3a covers the normal path. This is a real edge, not a
theoretical one, and it is recorded rather than glossed: the class is fixed for
our workflow, not for every possible workflow.

---

## 4. Rollback

121 `GRANT` statements restore the prior state exactly. Nothing else needs
reversing — no policy, schema or data change was made.

```sql
-- Stage 1 + 2 reversal (abbreviated; the pattern is uniform)
grant DELETE, INSERT, UPDATE on public.app_feedback   to anon, authenticated;
grant DELETE, INSERT, UPDATE on public.conversations  to anon, authenticated;
-- ... 25 relations, INSERT/UPDATE/DELETE/TRUNCATE as originally held.
-- The full 121-statement list was generated from the live catalogue
-- immediately before the migration and is reproducible with:
--
--   select format('grant %s on public.%I to %s;', privilege_type, table_name, grantee)
--     from information_schema.role_table_grants
--    where table_schema='public' and grantee in ('anon','authenticated')
--      and privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE');
--
-- (run against a restore point, since the current catalogue no longer holds them)

-- Stage 3 reversal
alter default privileges for role postgres in schema public
  grant insert, update, delete, truncate on tables to anon;
alter default privileges for role postgres in schema public
  grant insert, update, delete, truncate on tables to authenticated;
```

---

## 5. Governance recorded

| Where | What |
|---|---|
| OA-ZYRA-168 | Actioned 2026-08-08, with outcome, negative test and the `supabase_admin` gap |
| OA-ZYRA-170 | Opened for Stage 4 — function EXECUTE for `anon` |
| ZYRA_ENGINEERING_INVARIANTS V3 | I4 corollary: **explicit grants after explicit policy** — create table, add policies, grant only what the policies need |

**Why Stage 4 is the more consequential half, despite being smaller.** A table
grant to `anon` still had RLS behind it — which is exactly why all 75 were
inert. A *function* grant has no such backstop: a `SECURITY DEFINER` function
executable by `anon` runs as its owner with no policy layer in the way. That
sweep also cannot be indiscriminate, because some functions legitimately need
pre-auth reachability (`preview_wali_invite()` being the obvious case).

Nothing further applied. OA-ZYRA-170 awaits its own plan and approval.
