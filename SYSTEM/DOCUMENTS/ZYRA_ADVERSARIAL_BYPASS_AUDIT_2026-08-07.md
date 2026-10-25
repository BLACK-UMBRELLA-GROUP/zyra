---
id: DOC-ZYRA-0258
type: REPORT
status: CURRENT
feature: SAFETY AND PRIVACY
purpose: ZYRA — Adversarial Bypass Audit
links: []
owner: ZYRA chat
---

# ZYRA — Adversarial Bypass Audit

**Status:** FINDINGS ONLY — nothing changed, awaiting Founder authorisation
**Date:** 2026-08-07 · **Requested by:** ChatGPT, during the dual-role review

> *"Assume future developers will add new features years from now without
> remembering today's discussions. If there's anywhere the architecture can
> be bypassed — whether through direct writes, future features, admin
> tooling, edge cases, or unexpected state transitions — I'd rather discover
> and close those now than after launch."*

Every table, policy, grant, view and `SECURITY DEFINER` function in the
public schema was examined. Findings are split by whether they are
**exploitable today** or **currently harmless but structurally fragile** —
the second category is where the "years from now" risk actually lives.

---

## A. EXPLOITABLE TODAY

### A1. The romantic write path has no eligibility check — DEMONSTRATED

`likes_insert`, `saves_insert`, `passes_insert` each check only
`liker_id = auth.uid()`. Nothing about the target.

Two same-gender Seekers, run live and rolled back: A cannot **see** B
(correct), A **can Like** B, B can Like back, **a match is created and a
conversation opened**. A Seeker can also Like a Guardian.

**Severity: launch-blocking.** The product's central rule is enforced only
as a query filter, not as a property of the system.

### A2. Guardian links can be created without an invite or consent — DEMONSTRATED

`wali_links_insert` checks only `seeker_id = auth.uid()`. No invite
required, no consent from the named Guardian, `status` unconstrained — so a
client can write an `active` link directly, bypassing every rule in
`accept_wali_invite()`.

Consequences: the attacker gains `profiles` visibility of anyone they name
(defeating gender segregation and blocks); the victim acquires a Seeker they
never accepted, becomes a participant in that person's Journeys, and gets a
"Switch to Guardian" row naming a stranger.

### A3. Two functions I wrote today are callable by `anon` — MY ERROR

`zyra_reset_profile` and `zyra_submit_feedback` both return
`anon_can_run = true`. **Every other `SECURITY DEFINER` function in the
schema returns false.**

Cause: Postgres grants `EXECUTE` to `PUBLIC` by default on `CREATE
FUNCTION`. My explicit `GRANT ... TO authenticated` was redundant and did
not displace it. Someone previously established the convention of
`REVOKE EXECUTE ... FROM PUBLIC` on every function; I did not follow it.

**Actual impact: none.** Both raise `not_signed_in` when `auth.uid()` is
null. But this is precisely the "PUBLIC, `anon` and `authenticated` are
three independent grants" lesson this project learned weeks ago, and I
walked into it the same day I was auditing other people's grants.

---

## B. HARMLESS TODAY, FRAGILE BY CONSTRUCTION

This is the category ChatGPT was actually asking about. Nothing here is
exploitable. Each is safe because of an **absence** — and absences get
filled in by people who do not know why they were empty.

### B1. `journey_attempts`: RLS enabled, **zero policies**, full grants

RLS with no policy denies everything, so the table is sealed. But
`anon` and `authenticated` both hold `SELECT, INSERT, UPDATE, DELETE`.

**The day someone adds one permissive read policy to debug something, the
grants behind it are already wide open.** The table is protected by a gap,
not by a decision. Journey attempts are the spine of the entire Journey
model.

### B2. Write grants with no write policies, on four more tables

| Table | Granted | Policies |
|---|---|---|
| `matches` | INSERT, UPDATE, DELETE | SELECT only |
| `subscriptions` | INSERT, UPDATE, DELETE | SELECT only |
| `unlock_credits` | INSERT, UPDATE, DELETE | SELECT only |
| `profile_unlocks` | — *(correctly revoked)* | SELECT only |

`subscriptions` is the one to look at twice: if anyone ever adds an
`UPDATE ... USING (user_id = auth.uid())` policy — which looks entirely
reasonable in isolation — **every user can set their own `plan_type` to
`zyra_one` for free.** The only thing preventing that today is that nobody
has written the obvious policy.

`profile_unlocks` shows the correct pattern: the grants themselves were
revoked. The others should match it.

### B3. Blanket `anon` grants on 28 of 32 tables

Most tables grant all six privileges to `anon`. RLS blocks it because every
policy compares against `auth.uid()`, which is null for `anon`.

Defence therefore rests on **every policy, forever, remembering to check
`auth.uid()`**. Thirteen policies currently do not reference it directly —
all thirteen route through `zyra_my_attempt_participation` instead, which
does filter correctly. That is fine. It is also thirteen places where the
protection is one indirection away from where you would look for it.

### B4. `create_match_on_mutual_like` is an INSERT trigger, and triggers get disabled

Matches are created by a trigger on `likes`. Two ways that becomes wrong:

- **A backfill with triggers enabled** mass-creates matches and conversations
  as a side effect of a data migration.
- **A backfill with triggers disabled** — I disabled `profiles_updated_at`
  twice today for exactly this reason — silently skips match creation, and
  the data ends up in a state the application believes is impossible.

Putting `can_match()` in the trigger is necessary but does not fix this:
a disabled trigger enforces nothing. **The predicate also needs to be in the
RLS `WITH CHECK` on `likes`**, which cannot be disabled per-transaction.

### B5. `zyra_reset_profile` interacts with future exclusion rules

Reset deletes all likes, saves and passes in both directions but
deliberately keeps `matches` (they are joint data). Once Guardian exclusion
exists, that asymmetry deserves a second look: a match that predates a rule
survives a reset that clears everything which produced it.

Not wrong today. Worth re-checking the moment exclusions land.

### B6. There is no admin, and that is currently a feature

`profiles.role` permits `'admin'`; `zyra_create_profile` refuses to grant
it; no policy references it; no tooling reads it.

When admin tooling is eventually built, the tempting shape is a blanket
`USING (is_admin())` bypass on every table. That would silently defeat every
rule in this document. It should be built as **explicit per-table admin
policies**, and the Identity Correction process (§4 of the Settings
document) is the first thing that will ask for it.

### B7. No table uses `FORCE ROW LEVEL SECURITY`

The owner (`postgres`) bypasses RLS on every table. That is required for the
`SECURITY DEFINER` functions to work and is normal for Supabase. Recorded
so nobody later mistakes RLS for a boundary against server-side code — **it
is not, and was never meant to be.**

---

## C. VERIFIED SOUND

Worth stating, so a future reader knows these were checked rather than
missed.

- **`zyra_attempt_participant_rows`** — the unfiltered participant union —
  has **no grants to `anon` or `authenticated`.** Only the auth-filtered
  `zyra_my_attempt_participation` is exposed. Had that been reversed, every
  match pairing on the platform would be readable by any user. Correctly
  built.
- **Every `SECURITY DEFINER` function sets `search_path`.** All 56.
- **`mock_purchase_wali_premium` / `mock_set_wali_plan`** are gated to
  `%@zyra.test` accounts server-side, not just hidden in the UI.
- **Entitlement tables are read-only to clients** — `subscriptions`,
  `unlock_credits`, `profile_unlocks` all SELECT-only by policy.
- **`wali_links_no_self_link`** is a table CHECK and cannot be bypassed by
  any path, including `SECURITY DEFINER`.
- **One Main Guardian per Seeker** is a partial unique index, so it holds
  under concurrency rather than relying on a read-then-write.

---

## D. What this changes about the plan

The agreed sequence still stands. Two amendments:

1. **Step 0 grows.** "Close the write paths" was scoped to `wali_links`,
   `likes`, `saves`, `passes`. It should also revoke the write grants
   behind `matches`, `subscriptions`, `unlock_credits` and
   `journey_attempts` — following the `profile_unlocks` pattern that is
   already correct — so those tables are protected by decision rather than
   by omission. Same migration, small addition.

2. **`can_match()` goes in the RLS `WITH CHECK`, not only the trigger**
   (B4). A trigger is disableable; a policy is not.

And one correction to make regardless of what is authorised: **A3 is mine
and should be revoked from PUBLIC** whether or not the rest proceeds.

---

## E. Still awaiting

Nothing in this document has been changed. Three AI reviews agree on the
plan; the standing rule is that cross-model agreement is not build
authorisation, so all of it waits on the Founder.

**No live exposure in the meantime** — all 149 accounts are seeded test
accounts and no real user data exists.
