---
id: DOC-ZYRA-0086
type: SPEC
status: CURRENT
feature: BROWSE AND MATCHING
purpose: ZYRA — "One identity, two profiles": an adversarial review
links: []
owner: ZYRA chat
---

# ZYRA — "One identity, two profiles": an adversarial review

**Status:** CHALLENGE — requested by the Founder, nothing built
**Date:** 2026-08-07

The brief was *"challenge this as if you were trying to break it."* So this
is written to break it. The summary up front, because the answer is not a
simple yes or no.

---

## Verdict

**The UX instinct is right and the data model is wrong.**

"I've switched to my Guardian account" is a better mental model than "my
Seeker profile is in Guardian mode." That part I would not argue with.

But the model as described achieves it by **duplicating identity**, and
identity is the exact thing this system spent today making unforgeable. It
breaks one table constraint that currently cannot be bypassed, and it
invalidates the single assumption that 50 of 64 RLS policies rest on.

**There is a third model that gives you the UX without any of that**, and I
would argue for it. It is §6.

---

## 1. The load-bearing fact the proposal walks into

```
profiles_id_fkey  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
```

**`profiles.id` IS the auth user id.** Not a reference to it — the same
value. That single equality is what the entire security model is written on:

| | count |
|---|---|
| RLS policies keyed on `auth.uid()` | **50 of 64** |
| Functions using `auth.uid()` | 41 |
| Foreign keys pointing at `profiles` | 40 |
| Columns holding a user reference | 34 |

Two profiles per identity means **`auth.uid()` no longer identifies a
profile.** Every one of those 50 policies currently says, in effect, *"the
row is mine if its user column equals me."* After the change that sentence
has no meaning until you also know which profile is active — which is
session state, and session state is not available inside an RLS policy.

The likely resolutions are all bad:

- **Pass the active profile in a JWT claim.** Now authorisation depends on a
  client-supplied value. The whole day's work was removing exactly that
  class of trust.
- **Union both profiles in every policy** — "mine if it belongs to either of
  my profiles." Correct, and it silently *merges* the two profiles for
  authorisation purposes, which is the opposite of separation.
- **Re-plumb all 50 policies** to join through an identity table. Doable,
  and it is a re-write of the security layer, not an addition to it.

This is not an argument that the model is impossible. It is an argument
about what it costs, and the cost is the security layer.

---

## 2. The constraint that breaks — and it is the good one

Today:

```sql
wali_links_no_self_link  CHECK (seeker_id <> wali_id)
```

A **table CHECK**. It cannot be bypassed by RLS, by a `SECURITY DEFINER`
function, by an admin, or by a future write path nobody has written yet. It
was verified today as one of the few genuinely unbypassable rules in the
schema.

Under two profiles, `seeker_id` points at a Seeker profile and `wali_id` at
a Guardian profile. **For the same person those are different UUIDs.** The
CHECK compares them, finds them different, and passes.

Self-guardianship becomes representable at the row level, and preventing it
moves to a trigger or a function that resolves both ids to their identities
and compares those.

**That is a straight downgrade.** Trading a constraint that cannot be
bypassed for one that can, to buy a UX improvement, is the trade this
architecture has spent all day refusing to make in the other direction.

The Founder's own rule — *"exclusion rules operate at the identity level,
not merely the profile level"* — is correct and is precisely the problem: a
CHECK constraint cannot look up an identity. It can only compare columns in
its own row.

---

## 3. New loopholes the proposal creates

Asked for directly, so here they are ranked by severity.

### 3.1 Block evasion — the serious one

```sql
profile_blocks_insert  WITH CHECK (blocker_id = auth.uid())
```

Blocks are stored between **profile ids**. Two profiles per identity means
blocking someone blocks *one of their two profiles*.

If a Seeker blocks a man, and that man also holds a Guardian profile, the
block does not cover it. He can still reach her through the Guardian surface
— which, by design, has *broader* visibility than Browse does.

On a marriage platform used by people who are nervous about being seen, **a
block that only half works is worse than no block**, because she believes
she is protected.

This is not hypothetical bookkeeping. It is the safety feature most likely
to be relied on in a moment that matters.

### 3.2 Reporting splits the same way

`profile_reports.reported_id` is a profile id. Report the Seeker profile and
the Guardian profile carries no history. A moderator reviewing an account
sees half of it, and a pattern across both roles is invisible precisely when
a pattern is the thing that matters.

### 3.3 Two profiles can disagree about the same person

Separate bio and photos means the same human being presents two accounts of
themselves. Nothing prevents them contradicting.

Model A cannot produce this. Model B produces it by construction, on a
product whose entire proposition is trust.

### 3.4 Verification becomes ambiguous

KYC is shared at identity level, which is right. But if the Guardian profile
has its own photos, **which photo set was verified?** A verified badge over
an unverified image is worse than no badge, because people act on it.

### 3.5 Deletion and erasure

`ON DELETE CASCADE` from `auth.users`. Deleting the identity removes both
profiles — fine. But *"delete my Guardian profile"* becomes a new operation
with its own consequences: the Seekers it guards lose their Guardian, and
`wali_links_one_main_per_seeker` means one of them silently loses their
**Main** Guardian. That is a whole flow that does not exist today.

### 3.6 Subscription and credits

Shared at identity level, as stated. Then a Guardian context can spend the
Seeker's unlock credits, and an audit trail keyed on profile id shows the
spend against the wrong half. Solvable, but it is another place where
"shared" and "separate" have to be adjudicated field by field.

---

## 4. Does it simplify the predicates? No — it adds an indirection to each

Direct answer to question 3.

**Today:**

```sql
zyra_can_match(a, b)          -- a, b are profile ids = auth user ids
zyra_can_guardian_link(a, b)  -- same
```

Both are single-join predicates over columns that are already the thing
being compared.

**Under two profiles**, every clause has to resolve profile → identity
first, because the Founder's rule places exclusions at identity level:

```sql
-- not self               ->  identity_of(a) <> identity_of(b)
-- no Guardian edge       ->  no wali_links between ANY profile of
--                            identity_of(a) and ANY profile of identity_of(b)
-- no block               ->  no block between ANY pair of their profiles
-- genders differ         ->  read from the identity, not the profile
```

Every predicate gains a lookup, and the two-sided ones gain a cross product.
Inside an RLS `WITH CHECK` that runs on every Like, that is not free.

More importantly: **the rules stop being expressible in terms of the rows
they guard.** That is the property that currently makes them checkable.

---

## 5. What is genuinely right in the proposal

Being fair to it, because the instinct is sound and should survive.

1. **The user's mental model.** People do not think in contexts. They think
   in accounts. "Switch to my Guardian account" is the correct sentence.
2. **Photos genuinely differ.** A Guardian's picture, shown to another
   family during a Journey, is not a Browse photo. One photo set serving
   both is wrong, and today's schema has no answer — Guardian onboarding
   never asks for a photo, which is an open question, not a decision.
3. **Bio genuinely differs.** "About me as someone seeking marriage" and
   "about me as the person looking after my daughter" are different texts.
4. **Onboarding genuinely differs.** Already true, already two flows.
5. **Dashboards genuinely differ.** Already true, already two shells.

Note what that list contains and what it does not. **Every item is
presentation or activity. Not one of them is identity.**

---

## 6. The model I would argue for instead

**One identity row. One presentation row per role. Relationships unchanged.**

```
profiles                 ← unchanged. id = auth.uid(). THE identity.
                           first_name, surname_line, dob, gender,
                           first_published_at, verification
guardian_presentation    ← NEW. user_id → profiles.id, one row
                           photo, bio, guardian-specific answers
wali_links               ← unchanged. still keyed on profiles.id
```

**What the user experiences:** exactly what was asked for. Switch to your
Guardian account and you get a different photo, a different bio, a different
dashboard, different activity, a different everything you can see. It is
your Guardian account.

**What the system keeps:**

| | |
|---|---|
| `auth.uid() = profiles.id` | intact — **zero policy changes** |
| `wali_links_no_self_link` | intact — still a table CHECK, still unbypassable |
| `zyra_can_match` / `zyra_can_guardian_link` | **unchanged, not one line** |
| Blocks, reports | remain identity-level automatically, because there is one profile id per person |
| Identity freeze, correction process, verification | untouched |
| Every exclusion rule agreed today | holds without restatement |

**The honest cost:** name, date of birth and gender are shared across both
roles.

And that is a feature, not a compromise. **A Guardian presenting under a
different name from their Seeker profile is a safety hole, not a
convenience.** The same is true of date of birth. The only identity field
with an argument for differing is gender, and that is the outstanding
governance review, which will most likely conclude that Guardians are male —
in which case a Seeker's gender and their Guardian gender being the same
person's is precisely the fact the review needs to reason about.

So the "two separate accounts" feeling is delivered by everything the user
sees, and quietly declined for the three facts that must not vary.

---

## 7. If full Model B is still wanted

Then these must be decided first, and none is small:

1. **Where identity lives.** A new `identities` table with `profiles`
   pointing at it — a migration touching 40 foreign keys and 50 policies.
2. **How RLS learns the active profile**, without trusting a client-supplied
   claim.
3. **A replacement for `wali_links_no_self_link`** that survives being a
   trigger rather than a constraint.
4. **Identity-level blocks and reports**, or block evasion ships with it.
5. **Whether the two profiles may disagree**, and what enforces it if not.
6. **Which photo set verification attaches to.**

My estimate, and estimates from schema alone have been wrong in a consistent
direction on this project: this is **larger than everything built today
combined**, and it lands on the security layer rather than beside it.

---

## 8. Recommendation

Adopt **§6**. It delivers the mental model that prompted the question, costs
one new table, and changes no rule that was agreed today.

Revisit full Model B only if a concrete requirement appears that §6 cannot
serve — a Guardian who must be *anonymous* to their Seeker's counterpart
would be one, and it is worth asking whether that requirement exists,
because it is the only thing I can construct that genuinely needs two
identities.

**The question I would put back:** is there anything a Guardian needs to
show, hide or be, that differs from their Seeker profile in a way that is
not photo, bio, dashboard or activity? If the answer is no, §6 is the whole
of it.
