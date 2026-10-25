---
id: DOC-ZYRA-0153
type: PLAN
status: CURRENT
feature: GENERAL
purpose: OA-ZYRA-170 — Function EXECUTE sweep: implementation plan
links: []
owner: ZYRA chat
---

# OA-ZYRA-170 — Function EXECUTE sweep: implementation plan

**Status:** PLAN ONLY — nothing applied. For approval.
**Date:** 2026-08-08
**Scope:** `EXECUTE` privileges on `public` functions for `anon` and
`authenticated`, and the function default ACL
**Invariants touched:** I4 and its grants corollary, I5, I7

---

## 1. The headline: this is far smaller than OA-168, and I was wrong about why

I opened OA-170 saying function grants are "the more consequential of the two
sweeps" because a `SECURITY DEFINER` function has no RLS backstop. **The
premise is right. The exposure is not.**

Measured across all 71 functions in `public`:

| | Count |
|---|---|
| Total functions | 71 |
| `SECURITY DEFINER` | 62 |
| **`SECURITY DEFINER` executable by `anon`** | **0** |
| Executable by `anon` at all | **3** — all `SECURITY INVOKER` |

Every dangerous function is already closed to `anon`. Prior sweeps on this
project did their job. The remaining three are the residue.

---

## 2. The three

| Function | Mode | Trigger fn? | Called from client? | Assessment |
|---|---|---|---|---|
| `zyra_enforce_guardian_link_allowed()` | INVOKER | **Yes** | No | Trigger functions fire as part of the statement; PostgreSQL checks `EXECUTE` at `CREATE TRIGGER`, not at fire time. The grant does nothing. Revoke |
| `zyra_normalise_profile_identity()` | INVOKER | **Yes** | No | Same. Revoke |
| `expire_wali_invite_if_due(wali_invites)` | INVOKER | No | **No** | A PostgREST computed-column-shaped function. No Dart code references it. As `SECURITY INVOKER` it runs with the caller's privileges, and after OA-168 `anon` has no UPDATE on `wali_invites`, so it is already inert. Revoke from `anon`; **retain for `authenticated`** pending confirmation it is unused |

None is a live exposure. All three are capability nobody asked for.

---

## 3. Two assumptions of mine that measurement contradicted

Recording both, because the OA-170 entry currently states the first as fact.

### 3.1 `preview_wali_invite` does **not** need pre-auth access

I wrote that it was "the obvious candidate" for legitimate `anon`
reachability, reasoning that a Guardian follows an invite link before holding
an account.

**Wrong.** It is already `anon = false`, and the flow does not need it: the
invite is a **code the user types into `accept_wali_invite_screen`**, reached
from `link_guardian_panel` / `link_wali_screen` — both in-app, both post-sign-in.
`previewInvite()` is called at line 56 of that screen, immediately before
`acceptInvite()`, which requires auth regardless.

So the "some functions legitimately need pre-auth" caveat that justified
separating Stage 4 turns out to have **no instances**. The separation was
still right — it is how we found that out — but the reason I gave was
speculative and is now corrected.

### 3.2 The dev and mock functions are not an escalation path

Six functions looked alarming: `mock_purchase_wali_premium`,
`mock_set_wali_plan`, `zyra_debug_grant_credits`, `zyra_dev_reset_account`,
`zyra_dev_set_guardian_suggestions`, `zyra_dev_set_guardians_on_decided`. All
are `SECURITY DEFINER`, all executable by `authenticated`, and between them
they grant paid plans and unlock credits.

I was ready to report a privilege-escalation path. **Reading the bodies
stopped that.** Every one carries the same guard, added 2026-08-01:

```sql
if not exists (select 1 from auth.users u
                where u.id = caller and u.email like '%@zyra.test')
then raise exception 'mock_purchase_disabled' ...
```

Enforced inside the `SECURITY DEFINER` body — the unskippable layer for an
RPC. Exactly I4, done correctly, before I looked.

**The one thing worth your attention** is that the guard trusts an email
domain. Today that is airtight: all 149 accounts are `@zyra.test`, all
confirmed, seeded 2026-07-19 to 2026-08-05, and **zero real accounts exist**.
It stops being airtight the moment real signups open, *if* a user can register
`anything@zyra.test`. `.test` is an IANA-reserved TLD that cannot receive
mail, so this holds wherever email confirmation is enforced.

**That is a Supabase Auth configuration dependency, not a database one, and I
cannot verify it from SQL.** Flagged, not fixed, and not part of this
migration — see §6.

---

## 4. Proposed change

### Stage A · Revoke `anon` EXECUTE on the three functions

```sql
revoke execute on function public.zyra_enforce_guardian_link_allowed()  from anon;
revoke execute on function public.zyra_normalise_profile_identity()     from anon;
revoke execute on function public.expire_wali_invite_if_due(wali_invites) from anon;
```

After this, `anon` can execute **nothing** in `public`.

### Stage B · Change the function default ACL — the durable fix

```sql
alter default privileges for role postgres in schema public
  revoke execute on functions from anon;
```

Currently `{postgres=X, anon=X, authenticated=X, service_role=X}`. Every new
function arrives `anon`-executable; Stage A cleans three and the next function
written re-opens the hole. This is the OA-168 Stage 3 argument applied to
functions, and it is the part of this plan that actually matters.

**`authenticated` retains the default EXECUTE.** Removing it would mean every
new RPC needs an explicit grant or it fails — defensible, and the mirror of
what we did for tables, but it would break the current development rhythm on
every single RPC rather than only on tables that need write policies. I am
**not** proposing it here. Raise it separately if you want the symmetry.

### Stage C · NOT proposed — `authenticated` EXECUTE audit

62 `SECURITY DEFINER` functions are `authenticated`-executable. Each one I
sampled enforces its own caller checks (`auth.uid()` null-check, party checks,
`@zyra.test` guards, `zyra_can_view_profile` visibility checks). A full
line-by-line audit of all 62 is a genuinely useful exercise and a different
piece of work. Not folded in — I7.

---

## 5. What must not break

| Must retain | Why |
|---|---|
| `zyra_can_match` — `authenticated` EXECUTE | Called inside the INSERT policies on `likes`, `passes`, `saves`. Policy expressions execute as the querying role. Revoking it silently breaks liking, passing and saving |
| `zyra_can_view_profile` — `authenticated` EXECUTE | Called inside the `profiles` SELECT policy |
| `zyra_can_read_photo_object` — `authenticated` EXECUTE | Called inside a **`storage.objects`** policy |
| All 62 DEFINER RPCs — `authenticated` EXECUTE | The entire app runs through them |

**A correction to my own method here.** My first cross-reference searched only
`pg_policies where schemaname = 'public'` and returned two functions. That
filter would have missed `zyra_can_read_photo_object` entirely — a function
whose removal would have broken every photo in the app, found only because I
re-ran the query without the schema filter. The lesson from I5 again: the
query was correct, its scope was an assumption.

---

## 6. Flagged, not in scope

| Item | Why deferred |
|---|---|
| `@zyra.test` guard depends on Auth config | Supabase Auth setting, not SQL. Must be confirmed before real signups open. Suggest its own OA |
| `expire_wali_invite_if_due` retained for `authenticated` | Appears unused by the client. Removing an apparently-unused function is how you discover it was used. Confirm first |
| Full `authenticated` EXECUTE audit of 62 DEFINER functions | Stage C above |
| `authenticated` default EXECUTE | Deliberately unchanged |
| `supabase_admin` function default ACL | Same known gap as OA-168 §3; `postgres` cannot alter it |

---

## 7. Verification

| Check | Required after |
|---|---|
| `anon` EXECUTE count in `public` | **0** |
| `authenticated` EXECUTE count | **unchanged** |
| `zyra_can_match` / `zyra_can_view_profile` / `zyra_can_read_photo_object` executable by `authenticated` | **true** |
| Function default ACL, `postgres` | `anon` has **no** `X` |
| Policy count, all schemas | unchanged |

**Negative test:** create a throwaway function after Stage B and confirm it
arrives without `anon` EXECUTE, then drop it. Proves the default actually
changed rather than the catalogue merely reading as though it did.

**Functional pass:** like · save · pass · view a profile · **load a profile
photo** (the `storage.objects` path) · type and accept an invite code.

---

## 8. Rollback

Three `GRANT EXECUTE` statements and one `ALTER DEFAULT PRIVILEGES ... GRANT`.
No function is created, dropped or altered. No data touched.

---

## 9. Decisions needed

1. **Stage A** — revoke `anon` EXECUTE on the three. Approve?
2. **Stage B** — change the function default ACL for `anon`. Approve?
3. **Stage C** — confirm the 62-function `authenticated` audit stays out and
   becomes its own OA.
4. **The `@zyra.test` Auth dependency** — open as its own OA now, or fold into
   pre-launch checks?

Nothing has been applied.
