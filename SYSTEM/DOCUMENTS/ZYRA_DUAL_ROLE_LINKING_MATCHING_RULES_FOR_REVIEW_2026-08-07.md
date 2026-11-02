---
id: DOC-ZYRA-0083
type: REPORT
status: DRAFT
feature: BROWSE AND MATCHING
purpose: ZYRA — Guardian / Seeker Dual Role, Linking & Matching: What Actually Exists
links: []
owner: ZYRA chat
---

# ZYRA — Guardian / Seeker Dual Role, Linking & Matching: What Actually Exists

**Status:** FOR REVIEW — a statement of the CURRENT system, not a proposal
**Date:** 2026-08-07 · **For:** ChatGPT review, then Founder decision

Everything below was read out of the live database and the live code today.
Nothing is from memory or from design documents. Where a rule exists only
in a design document and not in the system, that is said explicitly.

**Two live defects were found while assembling this.** Both are in §7. One
is demonstrated with a test, included. Neither is currently exposed —
every one of the 149 accounts is a seeded test account — but both must be
closed before real users exist.

---

## 1. The approved model

Founder, ratified earlier this week:

> **One identity. One account. One Seeker profile. Zero or more Guardian
> relationships. Two application contexts.**

The important consequence: **"Guardian" is not an account type, it is a
relationship.** A person does not have "a Guardian account" — they have a
row in `wali_links` where they are the `wali_id`. Nothing about the word
"account" appears anywhere in the Guardian data model.

**The system does not yet implement this.** See §6.

---

## 2. What a Guardian link IS — `wali_links`

| Column | Type | Note |
|---|---|---|
| `id` | uuid | |
| `seeker_id` | uuid NOT NULL | FK → `profiles`, ON DELETE CASCADE |
| `wali_id` | uuid NOT NULL | FK → `profiles`, ON DELETE CASCADE |
| `status` | text NOT NULL | `pending` \| `active` \| `removed` |
| `is_main` | boolean NOT NULL | exactly one Main per Seeker |
| `relationship` | text | see §3 |
| `created_at` | timestamptz | |

**Constraints actually enforced:**

| Rule | How |
|---|---|
| **You cannot be your own Guardian** | `CHECK (seeker_id <> wali_id)` — `wali_links_no_self_link` |
| **One link per pair** | `UNIQUE (seeker_id, wali_id)` |
| **At most one Main Guardian per Seeker** | Partial unique index on `seeker_id WHERE is_main AND status='active'` |
| **Status is one of three values** | CHECK |

The self-link rule is at the **table**, so it holds on every path — RPC,
direct write, admin. That one is solid.

---

## 3. The relationship values that exist

The column CHECK permits exactly seven:

```
father · brother · grandfather · uncle · legal_guardian ·
family_representative · other
```

A wider list of ~23 values was drafted and grouped for preview but is
**not live**. It is blocked behind a religious validity review of Family
Friend, Trusted Friend, Cousin and the paternal qualifiers.

**Who states the relationship:** the person creating the link states it
about *themselves*. `accept_wali_invite` takes the accepter's answer where
there is one (Guardian answering live), otherwise inherits what the
Guardian stated when sending the invite. Either way the value came from
the Guardian and never from the Seeker.

---

## 4. How a link is SUPPOSED to be created — `accept_wali_invite()`

`SECURITY DEFINER`. The rules it enforces:

1. Must be signed in.
2. Relationship must be one of the seven.
3. Invite token must exist and be `pending`.
4. **You cannot accept your own invite** — `inviter_id <> accepter`.
5. The accepter must have a profile.
6. **ROLE GATE, and this is the one that blocks dual roles:**
   - Invite from a **Seeker** → accepter's `profiles.role` must be `'wali'`,
     else *"This invite is for a Wali account"*
   - Invite from a **Wali** → accepter's role must be `'seeker'`,
     else *"This invite is for a Seeker account"*
7. Creates the link `active`, or reactivates an existing one.

**Rule 6 is why nobody can hold both roles.** `profiles.role` is a single
value (`seeker` \| `wali` \| `admin`), set once at profile creation and
never flipped — `zyra_create_profile` refuses to change it.

**Verified in data: 0 of 149 accounts are both.** Not rare — impossible.

---

## 5. Visibility — who can see whom

`zyra_can_view_profile(target)` backs the `profiles` RLS policy. It returns
true for **four** reasons, in this order:

| # | Clause | Meaning |
|---|---|---|
| 1 | `target = auth.uid()` | yourself |
| 2 | An **active** `wali_links` row joining you either way | your Guardian, or your Seeker. **Any gender. No Journey required.** |
| 3 | You and they are both in `zyra_attempt_participant_rows` for one attempt | your match partner, or your Seeker's match partner |
| 4 | Browsing: they are active, published, not blocked, and **`p.gender <> viewer.gender`**, and you are a `seeker` | the discovery rule |

**Clause 4 is the gender segregation rule, and it is the only place it
exists.** Clauses 2 and 3 do not consult gender at all — deliberately, since
a Guardian is frequently a different gender to the person they are matched
against.

### Who counts as a participant of an attempt

```sql
seeker_a  ∪  seeker_b  ∪  every wali_id with an ACTIVE link to EITHER seeker
```

So **a Guardian of either side is a participant of the attempt**, and by
clause 3 can see both Seekers.

---

## 6. What does NOT exist

| Missing | Consequence |
|---|---|
| **`zyra_can_match()`** — the Guardian↔Seeker match exclusion rule | Nothing prevents someone being matched with a person they are also a Guardian to. The rule was agreed; no function, constraint or policy implements it. |
| **Dual-role acceptance** | `accept_wali_invite` rule 6 refuses it outright. |
| **A role/context switcher with anything behind it** | The UI row is built and gated on real data, so it renders nothing. Correct — the state cannot exist. |
| **Guardian gender governance** | `createWaliProfile` hardcodes `gender: 'male'`; V6 defines a Wali as a male guardian. **Under the current model a female Seeker cannot become a Guardian at all.** Review ordered 2026-08-06, still outstanding. |

---

## 7. ⚠️ TWO LIVE DEFECTS

### 7.1 A user can create a Guardian link with no invite and no consent — DEMONSTRATED

`wali_links` grants `INSERT` directly to `authenticated`, and the RLS
policy is:

```sql
wali_links_insert  WITH CHECK (seeker_id = auth.uid())
```

That checks *who the seeker is* and **nothing else**. It does not require an
invite, does not require the named Guardian to have agreed, and does not
constrain `status` — so a client can insert a row that is `active`
immediately, bypassing `accept_wali_invite()` and every rule in §4.

**Test run against the live database, then rolled back.** Two Seekers of
the SAME gender, who by clause 4 must never see each other:

| Step | Result |
|---|---|
| 1. Can A view B before? | **false** — correct, gender rule blocks it |
| 2. A inserts `(seeker_id=A, wali_id=B, status='active')` | **ACCEPTED** |
| 3. Row exists | 1 |
| 4. Can A view B now? | **true** |
| 5. Can A read B's `seeker_details`? | 0 rows — still protected |

**What it gets an attacker:** `profiles` visibility of any user they name —
first name, surname, gender, location, bio, active and published flags —
defeating the gender segregation rule *and* the block rule in one write.
`seeker_details` holds, because that policy requires the attacker to be the
`wali_id` and the INSERT policy forces them to be the `seeker_id`.

**What it does to the victim:** they acquire a Seeker they never accepted.
They become a participant in that person's Journey attempts (§5), and the
new "Switch to Guardian" row appears in their own Profile naming a stranger.

**Bounded, but not by design.** The attacker can only ever be the
`seeker_id` in rows they create, which is the only reason this is not worse.

**Fix:** revoke `INSERT` on `wali_links` from `authenticated` and `anon`
entirely and let `accept_wali_invite()` — already `SECURITY DEFINER` — be
the sole write path. Same shape as `app_feedback`, where the table has no
INSERT grant and the RPC does the validating.

### 7.2 Grants that no policy backs

`wali_links` grants `INSERT`, `SELECT` and `DELETE` to **`anon`** as well as
`authenticated`, and grants `DELETE` to both with **no DELETE policy at
all**. RLS currently denies all of it — `anon` fails `seeker_id = auth.uid()`
because `auth.uid()` is null, and a missing policy denies by default.

Harmless today. It is defence resting on two separate accidents lining up,
and the same pattern is on `likes`, `saves`, `passes` and `matches`
(`matches` grants INSERT/UPDATE/DELETE to both roles with only a SELECT
policy). Worth a sweep of its own — this is the same class as the TRUNCATE
hardening done earlier this week.

---

## 8. The open questions

These are for review. **None is decided.**

1. **Should a Seeker be able to become a Guardian at all?** The approved
   model says yes; the code says no; the gender review may say only men.
   Those three have to be reconciled before anything is built.

2. **`zyra_can_match()` must land first.** If dual roles are opened without
   it, someone can be Guardian to a person they can also be matched with —
   the exact hole the rule exists to close. **They ship together or neither
   ships.**

3. **What does "Guardian to two Seekers" mean when one is themselves a
   Seeker?** Agreed as allowed. But a Guardian sees both Seekers' Journeys
   (§5), so a Guardian who is also browsing gains sight of people through a
   route that has no gender rule on it.

4. **Refusing a Guardian link over an existing Journey.** Agreed in
   principle, unimplemented. Today nothing stops the two people in an
   Active Journey creating a Guardian link with each other — and §7.1 means
   one of them can do it unilaterally.

5. **Payment.** The current model is that **Guardians do not pay**: ZYRA
   One at £34.99/month states *"One Guardian+ entitlement included"*, and
   the seeded data confirms a Guardian resolves as Guardian+ free via the
   Seeker's subscription. Any proposal to charge for a Guardian context is
   a reversal of that, and worth stress-testing: a father who must pay to
   act as his daughter's Guardian is a father who does not sign up, and her
   entire experience depends on him being there.

6. **Does a login-time profile chooser make sense?** Under "one account,
   two contexts" the answer is probably no — contexts get switched, not
   chosen at the door — but a one-time prompt when a second context first
   appears is a different question.

---

## 9. Summary for the reviewer

**What is solid:** the self-link ban is at the table and cannot be
bypassed. The one-Main-per-Seeker rule is a partial unique index and holds
under concurrency. Visibility is one function with four clearly separated
clauses.

**What is intended but not enforced:** everything about who may become a
Guardian. Those rules live in `accept_wali_invite()`, and §7.1 shows the
table can be written without going through it.

**The question worth putting first:** should the dual-role model be opened
up at all before `zyra_can_match()` and the gender review exist — or is the
correct answer for now that one person is one thing, and the switcher waits?
