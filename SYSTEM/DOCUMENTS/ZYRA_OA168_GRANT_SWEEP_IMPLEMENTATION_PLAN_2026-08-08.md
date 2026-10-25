---
id: DOC-ZYRA-0151
type: PLAN
status: CURRENT
feature: GENERAL
purpose: OA-ZYRA-168 — Grant sweep: implementation plan
links: []
owner: ZYRA chat
---

# OA-ZYRA-168 — Grant sweep: implementation plan

**Status:** PLAN ONLY — nothing applied. For approval.
**Date:** 2026-08-08
**Scope:** write grants on `public` tables and views for `anon` and
`authenticated`
**Invariants touched:** I4 (enforce at the unskippable layer, and its grants
corollary), I7 (scope by approval)

---

## 1. What changed since OA-168 was written

OA-168 was logged as "22 tables, `authenticated` write grants without
policies." Measuring it properly found two things that change the work.

### 1.1 `anon` holds identical write grants

Not 22 tables for one role — **25 relations for two roles**, and the second
role is the unauthenticated one. `anon` has INSERT, UPDATE, DELETE and
TRUNCATE on every table `authenticated` does.

### 1.2 The grants come back by themselves

This is the finding that matters.

```
default_acl (public, tables, granted by postgres and supabase_admin)
  anon          = arwdxtm
  authenticated = arwdxtm
```

`ALTER DEFAULT PRIVILEGES` grants **INSERT, SELECT, UPDATE, DELETE, TRUNCATE,
REFERENCES, TRIGGER** to both roles on *every table created in `public`*.

So a sweep that revokes today's 121 grants fixes 25 relations and **nothing
else**. Table 26, created next week, arrives with the full set again. The
same default ACL for functions (`anon = X`) is the reason
`REVOKE EXECUTE ... FROM public` silently did nothing three times on this
project.

**Revoking the grants treats instances. Changing the default treats the
class.** I would rather do the second, and I want that decided explicitly
rather than assumed.

---

## 2. Risk today: none, and here is why I believe that

I checked rather than assumed, because "RLS will catch it" is exactly the kind
of claim that is true until one policy is written carelessly.

| Check | Result |
|---|---|
| RLS enabled on all 24 tables | Yes |
| Write policies that never reference `auth.uid()` | **2** — `journey_compatibility_insert` / `_update` |
| …do those two resolve safely for `anon`? | **Yes.** Both rest on `zyra_my_attempt_participation`, whose definition is `WHERE user_id = auth.uid()`. For `anon` that is NULL, the view returns no rows, `EXISTS` is false, write denied |
| Unfiltered base view `zyra_attempt_participant_rows` | **Not granted to `anon` or `authenticated`.** Reachable only inside owner-run views and policies. Correct |
| Client code exercising any unmatched grant | **None.** Every Dart reference to these tables is a SELECT, except `notifications.update` (matched policy, works) and `app_feedback` (written via the `zyra_submit_feedback` RPC) |

**Conclusion: every one of the 121 write grants is currently inert.** This is
hardening — removing latent capability — not a bug fix. The single live write
path this pattern did break was OA-ZYRA-167, now closed.

Worth stating plainly: the protection is currently **one layer deep**. RLS is
the only thing standing between `anon` and write access to 24 tables. A single
future policy written with a non-auth-dependent `USING` clause turns a dormant
grant into a live hole, with no second barrier. That is the I4 shape — a rule
holding at a layer nobody chose deliberately.

---

## 3. What will not break

| Concern | Why it holds |
|---|---|
| `SECURITY DEFINER` RPCs | Run as the function owner (`postgres`), not the caller. Unaffected by any revoke here. This covers every write RPC in the product |
| `SECURITY INVOKER` functions that write | Exactly one: `expire_wali_invite_if_due`, which UPDATEs `wali_invites`. That grant is **matched** (there is an UPDATE policy) and is **retained**. Verified by reading the function body, not by inference |
| `service_role` | Not touched. Server-side and admin paths keep full access |
| Table owner (`postgres`) | Not touched |
| Matched `authenticated` grants | Retained. Only grants with no corresponding policy are revoked |

---

## 4. Proposed change

Four stages. Each is independently approvable; **Stage 3 is the one with
project-wide consequences** and I have deliberately separated it.

### Stage 1 · Revoke all `anon` write privileges — 75 statements

25 relations × INSERT/UPDATE/DELETE (+TRUNCATE where held).

`anon` is the unauthenticated role. There is no flow in ZYRA where an
unauthenticated caller writes anything. This is the least contentious stage
and the highest value.

### Stage 2 · Revoke unmatched `authenticated` write privileges — 46 statements

23 relations. Only where **no policy exists for that command**. Matched grants
stay exactly as they are.

Includes revoking INSERT/UPDATE/DELETE/TRUNCATE on the view
`zyra_my_attempt_participation` from both roles — it is a `UNION ALL`-backed
view and therefore not updatable anyway, so the grants are pure noise.

### Stage 3 · Change the default privileges — the durable fix

```sql
alter default privileges in schema public
  revoke insert, update, delete, truncate on tables from anon;
alter default privileges in schema public
  revoke insert, update, delete, truncate on tables from authenticated;
-- and the same for the supabase_admin-granted default ACL
```

**What this changes:** every future table in `public` arrives with SELECT (and
REFERENCES/TRIGGER) but no write privileges. A migration that genuinely needs
a client write grant must say so explicitly.

**The trade-off, stated honestly:** a future migration that assumes the old
default will fail. I regard that as the point — it fails at migration time,
loudly, rather than shipping a table anyone can write to. But it *is* a
project-wide behaviour change and it will surprise whoever hits it first, so
it needs your decision rather than my judgement.

**If you decline Stage 3,** Stages 1–2 remain worth doing, and OA-168 should
stay open permanently as a recurring review rather than being closed — because
the condition will regrow.

### Stage 4 · Function EXECUTE for `anon` — NOT in this migration

The default ACL also grants EXECUTE on every new function to `anon`. That is
the pending broad `anon` sweep, it needs its own audit of which functions
should be callable pre-auth (invite preview, for instance, legitimately might
be), and folding it in here would be the scope creep I7 exists to prevent.

Flagged, sequenced next, not included.

---

## 5. Exact SQL

Generated from the catalogue, not written by hand — the migration will build
the statement list from the same query used to measure, so the applied set
cannot drift from the reported set.

```sql
-- Stage 1 + 2, generated form
do $$
declare r record;
begin
  -- Stage 1: all anon write privileges
  for r in
    select g.table_name, g.privilege_type
      from information_schema.role_table_grants g
     where g.table_schema = 'public' and g.grantee = 'anon'
       and g.privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE')
  loop
    execute format('revoke %s on public.%I from anon',
                   r.privilege_type, r.table_name);
  end loop;

  -- Stage 2: authenticated, ONLY where no policy covers that command
  for r in
    select g.table_name, g.privilege_type
      from information_schema.role_table_grants g
     where g.table_schema = 'public' and g.grantee = 'authenticated'
       and g.privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE')
       and not exists (
         select 1 from pg_policies p
          where p.schemaname = 'public'
            and p.tablename  = g.table_name
            and p.cmd in (g.privilege_type, 'ALL'))
  loop
    execute format('revoke %s on public.%I from authenticated',
                   r.privilege_type, r.table_name);
  end loop;
end $$;
```

Stage 3 is four literal `ALTER DEFAULT PRIVILEGES` statements, applied only if
approved separately.

**Note on the pattern:** revoking `FROM public` is *not* used anywhere above.
`anon` and `authenticated` hold their own explicit grants; a revoke from
`public` would report success and change nothing. Three prior incidents on
this project, now invariant I4's corollary.

---

## 6. Verification

Run before and after; the "after" column is the pass condition.

| Check | Before | After (required) |
|---|---|---|
| `anon` write grants in `public` | 75 | **0** |
| Unmatched `authenticated` write grants | 46 | **0** |
| Matched `authenticated` write grants | unchanged | **unchanged** |
| `service_role` privileges | unchanged | **unchanged** |
| Policy count and definitions | unchanged | **unchanged** — this migration adds no policy |
| `zyra_advance_stage` still executable by `authenticated` | yes | **yes** |
| Default ACL (Stage 3 only) | `anon=arwdxtm` | `anon=rxt` (no write bits) |

Plus a functional pass on the real write paths, all of which must still work:
like · save · pass · send message · upload photo · onboarding answer · consent
· report profile · create Wali invite · Guardian suggestion · mark
notification read · journey salam / checkpoint / phase answer / rating /
compatibility reveal · submit feedback · advance stage.

**And one deliberate negative test:** confirm an `anon`-key client is refused a
write it can currently attempt, so we have evidence the revoke did something
rather than trusting the catalogue. Per OA-167, a change that cannot be
observed failing is a change we have not verified.

---

## 7. Rollback

Every statement is a `GRANT` away from reversal, and the exact prior state is
recorded in §6's "before" column. Stage 3 reverses with the mirror-image
`ALTER DEFAULT PRIVILEGES ... GRANT`. No data is touched; no policy is
touched; nothing is dropped.

---

## 8. Decisions needed

1. **Stages 1–2** — approve as described?
2. **Stage 3 (default privileges)** — approve, or defer and keep OA-168 open
   as a recurring review?
3. **Stage 4 (function EXECUTE for `anon`)** — confirm it stays out and
   becomes the next item.

Nothing has been applied.
