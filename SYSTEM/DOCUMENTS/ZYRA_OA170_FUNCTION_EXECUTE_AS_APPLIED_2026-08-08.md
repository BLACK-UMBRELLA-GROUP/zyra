---
id: DOC-ZYRA-0152
type: SPEC
status: CURRENT
feature: GENERAL
purpose: OA-ZYRA-170 — Function EXECUTE sweep: as applied
links: []
owner: ZYRA chat
---

# OA-ZYRA-170 — Function EXECUTE sweep: as applied

**Status:** APPLIED — **objective NOT met.** Awaiting approval to complete.
**Date:** 2026-08-08
**Migration:** `oa170_function_execute_sweep_stages_a_and_b`
**Plan:** ZYRA_OA170_FUNCTION_EXECUTE_IMPLEMENTATION_PLAN_2026-08-08.md

The migration applied exactly as written and succeeded. **The plan was
wrong.** Both stages fall short of their stated goal, and the verification is
the only reason we know.

---

## 1. Verification results

| Check | Target | Actual | |
|---|---|---|---|
| `anon` EXECUTE in `public` | 0 | **2** | ✗ |
| — of those, held via `PUBLIC` rather than `anon` | — | **2** | — |
| `anon` *explicit* grants remaining | 0 | **0** | ✓ |
| `authenticated` EXECUTE | 56, unchanged | 56 | ✓ |
| Policies, all schemas | 69, unchanged | 69 | ✓ |
| `zyra_can_match` executable by `authenticated` | true | true | ✓ |
| `zyra_can_view_profile` executable by `authenticated` | true | true | ✓ |
| `zyra_can_read_photo_object` (storage.objects) | true | true | ✓ |
| `zyra_advance_stage` executable by `authenticated` | true | true | ✓ |
| `anon` table write grants (OA-168) | 0 | 0 | ✓ |
| Function default ACL, `postgres` | no `anon=X` | no `anon=X` | ✓ |
| **New function arrives without `anon` EXECUTE** | true | **false** | ✗ |

Nothing broke. Nothing was lost. The sweep simply did not sweep.

---

## 2. Deviation — the plan was incomplete in both stages

### What happened

`revoke execute ... from anon` removed anon's **explicit** grant. It did not
remove anon's **effective** privilege, because the functions also grant
`EXECUTE` to `PUBLIC`, and `anon` is a member of `PUBLIC`.

The ACL makes it visible once you know to look. The leading `=X` — an entry
with no role name — is `PUBLIC`:

```
{=X/postgres, postgres=X/postgres, authenticated=X/postgres, service_role=X/postgres}
 ^^^^^^^^^^^ PUBLIC. anon inherits EXECUTE from here.
```

`anon=X` is correctly absent. Stage A did precisely what it said. What it said
was not enough.

### Stage B has the same hole

PostgreSQL grants `EXECUTE` to `PUBLIC` on every function at creation. That is
the language's built-in default, independent of Supabase's `pg_default_acl`
entries. Removing `anon` from the default ACL therefore changes nothing for
new functions.

**Proven, not reasoned.** The approved negative test created a throwaway
function after Stage B:

```
_oa170_probe() → anon EXECUTE = true
acl: {=X/postgres, postgres=X/postgres, authenticated=X/postgres, service_role=X/postgres}
```

Probe dropped; confirmed absent.

### Why I got it wrong

This is the **fourth** time this project has been caught by the relationship
between `PUBLIC`, `anon` and `authenticated` — and the first time in the
opposite direction.

The three previous incidents were all *"I revoked from `PUBLIC` and nothing
happened, because `anon` holds its own explicit grant."* The lesson recorded in
invariant I4's corollary is written in exactly that direction:

> Supabase's default privileges grant `anon` explicitly.

True, and it points the reader at revoking from `anon`. **It does not say that
`PUBLIC` may hold the grant too, so you must revoke from both.** I read my own
corollary, applied it in the direction it was written, and walked into the
mirror image.

The accurate statement is a union, not a list:

> A role's effective privilege is the union of its own grant, `PUBLIC`'s grant,
> and any role it inherits from. Revoking one leaves the others standing.
> **Revoke every path, then verify with `has_*_privilege()` — which reports the
> union and is the only thing that answers the real question.**

`has_function_privilege()` told the truth immediately. The catalogue ACL and
the migration's success both looked fine.

---

## 3. Completing statements — NOT applied, for approval

```sql
-- Stage A′ : remove the PUBLIC grant on the two remaining functions
revoke execute on function public.zyra_enforce_guardian_link_allowed() from public;
revoke execute on function public.zyra_normalise_profile_identity()    from public;

-- Stage B′ : stop new functions arriving with the built-in PUBLIC grant
alter default privileges for role postgres in schema public
  revoke execute on functions from public;
```

**Blast radius of Stage B′, checked before proposing it.** Revoking the
`PUBLIC` default affects only roles with no explicit grant of their own.
`authenticated`, `service_role` and `postgres` each hold explicit `=X` entries
from Supabase's default ACL, so all three are unaffected. `anon` is the only
role that loses anything — which is the objective.

Same verification as before, plus the probe repeated. I expect `anon EXECUTE`
to reach 0 and a new function to arrive anon-inexecutable. I will not claim it
has until the probe says so.

---

## 4. Rollback

Current state is one statement from the pre-migration state:

```sql
-- Reverse Stage A (anon's explicit grants; PUBLIC's grant was never removed)
grant execute on function public.zyra_enforce_guardian_link_allowed()    to anon;
grant execute on function public.zyra_normalise_profile_identity()       to anon;
grant execute on function public.expire_wali_invite_if_due(wali_invites) to anon;

-- Reverse Stage B
alter default privileges for role postgres in schema public
  grant execute on functions to anon;
```

If Stage A′/B′ are approved and applied, add:

```sql
grant execute on function public.zyra_enforce_guardian_link_allowed() to public;
grant execute on function public.zyra_normalise_profile_identity()    to public;
alter default privileges for role postgres in schema public
  grant execute on functions to public;
```

No function created, dropped or altered. No policy touched. No data touched.

---

## 5. New Outstanding Actions

| | |
|---|---|
| **OA-ZYRA-171** | `@zyra.test` guard depends on Supabase Auth configuration. High before real signups; zero risk today (149 accounts, all seeded, all confirmed, no real users). Recommends replacing the domain check with an allowlist rather than documenting the dependency — per I1, a guard resting on a toggleable setting is a permanent control on temporary state |
| **OA-ZYRA-172** | Audit the 62 `SECURITY DEFINER` functions executable by `authenticated`. **Not started, per your instruction.** Exists so that "every function I sampled was correctly guarded" is not quietly promoted into "all 62 are" |

---

## 6. Proposed governance change — for approval, not applied

Invariant I4's grants corollary should be rewritten from a list of three
independent grants into the union statement in §2, with this incident as its
fourth data point and the first in the reverse direction. The corollary as
written is not wrong; it is **incomplete in a way that caused this failure.**

I have not edited the invariants document. Governance changes need your
approval, and a corollary that just misled me should not be rewritten by me
unreviewed.

---

## 7. ROUND 2 — Stages A′ and B′ applied. Acceptance test half passes.

Migration `oa170_function_execute_sweep_stages_a_prime_b_prime`, approved and
applied 2026-08-08.

### A′ passed

| Check | Result |
|---|---|
| `anon` EXECUTE on all pre-existing functions | **0** ✓ |
| `zyra_enforce_guardian_link_allowed` — anon | false ✓ |
| `zyra_normalise_profile_identity` — anon | false ✓ |
| `authenticated` EXECUTE | 56, unchanged ✓ |
| All three policy-dependent functions | executable ✓ |

### B′ failed — the probe is still red

A function created *after* B′ still arrives PUBLIC-executable:

```
_oa170_probe2()  anon EXECUTE = TRUE
acl: {=X/postgres, postgres=X/postgres, authenticated=X/postgres, service_role=X/postgres}
```

Probe dropped and confirmed absent.

### Why, as far as the evidence goes

Ruled out by measurement, not assumption:

- **Wrong owner?** No — `current_user` = `postgres`, probe owner = `postgres`,
  so `FOR ROLE postgres` is the applicable default ACL.
- **An event trigger re-granting?** No — the six event triggers present are
  Supabase's pg_cron/pg_graphql/pg_net/PostgREST hooks; none grants EXECUTE on
  ordinary functions.

What the catalogue shows:

```
pg_default_acl (postgres, public, functions)
  before B′ : {postgres=X, anon=X, authenticated=X, service_role=X}
  after  B′ : {postgres=X,        authenticated=X, service_role=X}
```

The only difference is `anon`, removed back in Stage B. **My
`REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC` changed nothing** — there was no
`PUBLIC` entry in the array to remove. And the new function's ACL is exactly
that array *plus* `=X`.

The inference: PostgreSQL's built-in default of `EXECUTE TO PUBLIC` for
functions is applied **in addition to** the `pg_default_acl` entries, and
revoking an entry that is absent records nothing. Stated as an inference
because I have not yet proven it — see below.

### Proposed next step — NOT applied

Make `PUBLIC` explicit in the default ACL first, so there is something for the
revoke to remove:

```sql
alter default privileges for role postgres in schema public
  grant execute on functions to public;      -- expect '=X' to appear in defaclacl
alter default privileges for role postgres in schema public
  revoke execute on functions from public;   -- expect it to disappear
-- then re-run the probe
```

If the array can hold a `PUBLIC` entry and then drop it, the revoke sticks and
B′ is achievable. If it cannot, **there is no durable default-privileges fix
for functions**, and the fallback is:

1. Every migration creating a function ends with
   `revoke execute on function … from public;`
2. A detector query flags any `public` function carrying a PUBLIC EXECUTE
   grant — turning silent inheritance into a visible finding.

Step 2 is a new check and therefore needs approval under I7. I have not built
it.

---

## 8. OA-168 Stage 3 carries the same unverified assumption

Worth raising unprompted, because it is the identical mistake one object type
across.

I reported OA-168 Stage 3 as successful on the strength of the catalogue
reading `anon=rxtm` — **I never created a test table to confirm a new table
actually arrives without write grants.** Functions have just demonstrated that
a correct-looking `pg_default_acl` does not guarantee the resulting object.

Tables may well behave differently: the built-in default for tables grants
*nothing* to PUBLIC, so there is no equivalent hidden grant to inherit, and I
expect Stage 3 is genuinely fine. **But that is the same reasoning that made me
confident about functions an hour ago.**

Proposed: a `create table` probe under the same approval, checked and dropped,
before OA-168 is left closed.

---

## 9. Awaiting

1. Approval for the grant-then-revoke experiment (§7) to complete B′.
2. Approval for a `create table` probe to verify OA-168 Stage 3 (§8).
3. The invariant rewrite stays parked until the probe passes, per your
   instruction — one update with the final wording, not two.

**Current state is safe.** `anon` executes nothing that exists today and can
write nothing anywhere. The residual gap is future functions inheriting PUBLIC
EXECUTE at creation — which matters from the next migration onward, not now.
