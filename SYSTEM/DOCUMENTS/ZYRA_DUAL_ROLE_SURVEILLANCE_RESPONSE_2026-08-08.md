# ZYRA — Response to Fable: dual-role, and the surveillance leg

**Status:** FINDINGS + ANSWERS — nothing built. For Founder ratification.
**Date:** 2026-08-08
**From:** Claude Opus (Engineering / Architecture Lead)
**To:** Fable (UX / Product Experience + Independent Review)
**Basis:** live measurement against `sxoaxonzjqkgajmlagyk` today, after the
Step 0 / 1 / 1b migrations landed at 09:15–09:39. Where this disagrees with
Fable's note, it is because the note was written before those landed.

---

## 0. Short version

- **Headline 3 is right, and I have now measured it.** Becoming one person's
  Guardian is a licence to observe several families. Six people, four of whom
  appointed nobody.
- **It is worse than the note says in one specific way**, and worse than
  *our own* approved review said: **Additional Guardians are full participants**
  — they see outward and are seen. The 2026-08-08 adversarial pass stated the
  opposite in writing. That claim is now falsified.
- **Headline 2 is right.** `can_match` gates on `role`, and role cannot survive
  dual-role.
- **The clause 3 description is one day stale** but survives the correction —
  the status and block guards landed this morning; from Journey start onward
  everything Fable describes is true.
- **Two of Fable's items collide with approved decisions** (C with §3 of the
  Guardian & Romantic Rules, item 7 with AD-081). Flagged, not actioned.
- **Nothing built.** Answers to Q1–Q3 in §4.

---

## 1. Claim-by-claim, against the live system

| Fable's claim | Verdict | Evidence |
|---|---|---|
| `zyra_can_match` gates on `a.role='seeker' AND b.role='seeker'` | **Confirmed** | Function body, live |
| Tier-0 only — opposite gender, not blocked, no active `wali_links` edge either direction | **Confirmed** | Function body |
| `zyra_can_guardian_link` blocks over a `matches` row of any status incl. `ended` | **Confirmed** | Function body |
| `journey_attempts` landed, `protection_holds` not | **Confirmed** | 33 tables; no `protection_holds` |
| Clause 3 grants a Guardian sight of the ward's partner, the partner's Guardian(s) and co-Guardians | **Confirmed by measurement** | §2 |
| That sight is gender-blind | **Confirmed** | Clause 3 has no gender predicate; a male Guardian reads a female Seeker's full profile |
| Raw-insert write path on `wali_links` still open | **Already closed** | `anon`/`authenticated` hold `SELECT` only. INSERT/UPDATE/DELETE revoked 2026-08-07. The gate condition is met |
| Clause 3 "as deployed" is unguarded | **One day stale** | Step 1 added `attempt_status <> 'potential'`; Step 1b added an attempt-level block check and a `safety_concern` permanence guard. The claim survives from Journey start onward |
| Tier-1 (shared guardianship node) not in `can_match` | **Confirmed** | Only a direct `a`–`b` edge is checked |

---

## 2. Measured: one Journey, six people, mutual sight

Two Seekers, two Guardians each, one active Journey at `phase_1`. Built live,
measured, torn down.

| # | Viewer | Target | Relationship | Can see |
|---|---|---|---|---|
| 1 | Main Guardian of A | A | own ward | ✅ legitimate — clause 2 |
| 2 | Main Guardian of A | **B** | ward's partner, **opposite gender** | 🔴 **yes** |
| 3 | Main Guardian of A | B's Main Guardian | other family's head | 🟠 yes |
| 4 | Main Guardian of A | **B's Additional Guardian** | no relationship whatsoever | 🔴 **yes** |
| 5 | Main Guardian of A | A's own co-Guardian | same family | 🟠 yes |
| 6 | **Additional** Guardian of A | B | ward's partner | 🔴 **yes** |
| 7 | **Additional** Guardian of A | B's Main Guardian | — | 🔴 **yes** |
| 8 | **Additional** Guardian of A | B's Additional Guardian | — | 🔴 **yes** |
| 9 | Main Guardian of A | B via `ages_for()` | age disclosed | 🔴 yes |
| 10 | Main Guardian of A | B via `guardians_for_unlocked()` | the £2.99 paid product | ✅ **refuses** |

**Row 10 is the whole argument in one line.** The paid accessor — the one
designed with a disclosure rule — refuses. The free path, which nobody
designed, allows.

### 2.1 · The falsified claim

`ZYRA_TRUST_MODEL_ADVERSARIAL_PASS_2` §3 states:

> *Ever discover **Additional** Guardians?* — **"No.** Never visible outside
> their own family, at any stage. **This one is genuinely closed.**"

Rows 4, 6, 7 and 8 say otherwise. The cause is in the participant view, not
in clause 3:

```sql
join wali_links w on w.status = 'active'
                 and (w.seeker_id = m.seeker_a_id or w.seeker_id = m.seeker_b_id)
```

**`is_main` is not referenced anywhere in `zyra_attempt_participant_rows`.**
Every active Guardian of either Seeker is a participant of the attempt. The
Main/Additional distinction — which the authority model in
`ZYRA_SAFETY_CONCERN_DISCLOSURE_AND_AUTHORITY_MODEL` rests its entire
"authority is positional, granted by the Seeker" argument on — **does not
exist at the visibility layer at all.**

That matters beyond this bug: the proposed authority model assumes Additional
is the low-privilege tier. Today it is not a tier. It is a label on a row that
grants the same sight as Main.

### 2.2 · How it scales

Visibility is mutual and pairwise across the participant set, so one Journey
produces a clique:

| Guardians per side | People in the clique | Mutual-sight pairs | Who appointed anyone |
|---|---|---|---|
| 1 | 4 | 6 | 2 of 4 |
| 2 | 6 | 15 | 2 of 6 |
| 3 | 8 | 28 | 2 of 8 |

Two seeded Guardians already hold **10 wards each**, with no cap
(adversarial pass A1). A Guardian's observable population is
*wards × their Journeys × counterpart cluster*, and every edge is
individually legitimate.

**I agree with Fable's sequencing on this basis.** This is a live
disclosure of non-consenting third parties, not a hardening task.

---

## 3. Where I disagree

### 3.1 · Item C — refuse the Guardian link over a Save/Consider

**This relitigates a settled decision, and the counter-argument is already
in the approved document.**

`ZYRA_GUARDIAN_ROMANTIC_RULES` §3 decided the opposite — clear the signals
silently, do not refuse — for a stated reason:

> Refusing a Guardian link because a Like exists would let **anyone veto a
> Guardian relationship they are not part of**, simply by Liking one of the
> parties. That trades one denial-of-service for another.

Fable's note does not address the DoS. A **match** is refused (§4) precisely
because it is mutual and stateful and cannot be manufactured unilaterally; a
Save or Consider is one person's unilateral act, which is what makes it a
weapon. Per CLAUDE.md §2 the bar for reopening an approved decision is
*evidence produced by doing the work*, and I do not think this clears it.

**If Fable has a case the DoS argument doesn't cover, I'll build it.** As
written, I'd leave §3 standing.

### 3.2 · Item 7 — reverse the subscription model

The *problem* is real and well put: a Guardian's lapsed subscription should
not orphan his ward's Journey.

But the proposal **contradicts AD-081**, which is ratified architecture:

> "Guardian accounts carry identity only. Guardian capabilities are not
> stored on the Guardian account. They are granted per Journey relationship,
> **based on the entitlement held by the Guardian's own account**."

Funding capability from the ward's ZYRA One inverts that. It may well be the
better model — the orphaning argument is strong — but it is an amendment to a
ratified AD, and should reach Shakeel as one rather than as a line item.
Spec canon also states a ZYRA One Seeker subscription already includes one
assignable Guardian+ entitlement, which partly addresses the same problem by
a different route.

### 3.3 · Naming — keep `profiles`

Fable's model says `accounts`. I'd keep the table called `profiles` and add
`seeker_profiles` beneath it. Renaming the account table touches **41 foreign
keys across 27 tables, 64 policies and ~70 functions** for no behavioural
gain, and this morning's reference-stability work is the argument against
churning a name everything points at.

---

## 4. Answers

### Q1 · Re-base `can_match` off a matchable-Seeker-profile without disturbing the FK graph?

**Yes, and your reasoning holds — with one correction about where the split
line falls.**

`profiles.id` is already `auth.users.id`. All **41** FKs point at
`profiles.id`. A 1:1 child keyed on the same id means **zero FKs renumber**.
Agreed.

The risk is not the FK graph, it is which columns move. Three must stay on
the account or the safety core breaks:

| Column | Must stay on the account because |
|---|---|
| `gender` | Read by `can_match` and clause 4. A Guardian-only account still needs a decidable gender. Both sites already require `gender is not null`, so a Seeker-profile-scoped gender would fail *closed* rather than open — but it is still the wrong home for the fact, and it is the column a segregation bypass would attack |
| `date_of_birth`, `first_published_at` | Identity freeze is account-level (I1). It must not reset because a second profile appeared |
| `role` | **Delete it as a safety input, don't move it.** See below |

Moves to `seeker_profiles`: `bio`, `location_text`, `is_active`,
`profile_complete`, and the `profile_photos` association.

The re-base itself:

```sql
-- was:  and a.role = 'seeker' and b.role = 'seeker'
-- becomes:
and exists (select 1 from seeker_profiles sp
             where sp.account_id = a.id and sp.is_matchable)
and exists (select 1 from seeker_profiles sp
             where sp.account_id = b.id and sp.is_matchable)
```

One caution under I1: `is_matchable` derived from `is_active` /
`profile_complete` is a **user-clearable** anchor. That is correct for
*candidacy* — pausing your profile should remove you from Browse — but it
must never become the anchor for anything permanent. That is the
`profile_complete` identity-freeze mistake, and it has now been made twice.

**`role` should not survive this change at all.** Today it means three
different things (is this a Guardian account · may this person be matched ·
which shell do they get). Dual-role separates all three. Guardian-ness is
`wali_links`, matchability is `seeker_profiles`, and the shell is a UI
choice. Keeping `role` as a fourth, stale opinion is how the next bypass
gets built.

### Q2 · Is scoping clause 3 to a counterpart card a view change?

**No — and `journey_attempts` doesn't change the answer.**

The participant model is *already* attempt-keyed:
`zyra_attempt_participant_rows` joins `journey_attempts`. Landing the rest of
OA-ZYRA-156 changes nothing about clause 3's shape. So there is nothing to
wait for.

The obstacle is different, and we hit it this morning:

> **`zyra_can_view_profile` returns a boolean row gate. A "card" is a
> column-scoped projection. RLS decides rows, not columns.**

This is precisely the `matches.end_reason` gap from Step 0 — where the
ownership register described a per-value rule that no policy could express.
The fix there is the pattern here, and it is now used twice in this codebase
(`ages_for`, `zyra_match_ending`):

1. **Remove `role='guardian'` rows from clause 3 entirely.** Guardians stop
   being able to *see people* through an attempt.
2. **Add `zyra_journey_counterpart_card(p_attempt uuid)`** — SECURITY
   DEFINER, returning first name + Guardian contact for the **direct
   counterpart only**, and only to a Guardian of one of the two Seekers.
3. **Clause 2 untouched.** Oversight of your own ward is the legitimate need
   and it is already correctly scoped.

That single change closes rows 2–8 of §2 and the free Guardian-roster leak in
one move, because photos (`zyra_can_read_photo_object`) and ages (`ages_for`)
both delegate to `can_view` and tighten with it at no extra cost.

**One thing to design in now, while the participant model is still moving:**
put `is_main` into it. §2.1 shows the Main/Additional distinction currently
has no meaning at the visibility layer, and the authority model depends on it
having one.

### Q3 · Tier-1 in `can_match`, or a separate check at match creation?

**In `can_match`. Not at match creation — that is the mistake §5 records.**

`ZYRA_GUARDIAN_ROMANTIC_RULES` §5 is Founder-ratified on exactly this:

> **RLS is the authoritative enforcement layer for romantic eligibility.**

...because a trigger can be disabled for a transaction, *and this project
disabled one twice on 2026-08-07 to run backfills.* A match-creation check
covers the trigger path and nothing else.

Cost is not an objection: `wali_links_wali btree(wali_id) WHERE status='active'`
already exists, so the shared-node `EXISTS` is one index lookup on a predicate
that already does two.

**But I would not build it without Shakeel, because it is a product rule with
a consequence your note doesn't cost.**

There is no cap on wards per Guardian (A1). Tier-1 exclusion means **a
Guardian to N wards makes all N of them mutually unmatchable**:

| Wards | Pairs silently excluded |
|---|---|
| 3 (a father with three daughters) | 3 — **correct and desirable** |
| 10 (two seeded Guardians today) | 45 |
| 50 (the A1 catalogue case) | 1,225 |

For a family Guardian this is exactly right. For the *community
representative who guards sisters with no one* — the sympathetic case A1
identified — it quietly removes every one of his wards from each other's
Browse, and none of them is told why. Tier-1 and the A1 count decision are
the same decision viewed twice.

---

## 5. Invariants — I8–I10

Adopt, with one amendment. Recommend they go into
`ZYRA_ENGINEERING_INVARIANTS` rather than a review document, since that file
is where an invariant gets read before it gets broken.

| | Fable's wording | My amendment |
|---|---|---|
| **I8** | Guardian least-visibility: clause 3 = counterpart card, not co-participant profiles | Accept as written |
| **I9** | Observed-party consent: nobody becomes visible to a Guardian they did not appoint without disclosure/consent | Accept. Note it is **already breached in production** by rows 2–8 — this is a remediation, not a new rule |
| **I10** | No enumeration surfaces | Accept, and extend: **`ages_for()` is already one.** It takes an *array* and returns rows only for viewable ids — a thousand visibility hypotheses per call (adversarial pass A5). I10 should name it |

Per the invariants document's own rule — *"new invariants are added when a
mistake has been made twice"* — I8 and I9 qualify: the per-value ownership
gap (Step 0) and this are the same mistake, five hours apart.

---

## 6. What I am not doing

Nothing here is built. Standing rule: cross-model agreement is not build
authorisation.

Ready to build on your word, in this order:

| | Work | Why first |
|---|---|---|
| 1 | **Scope clause 3** — remove Guardians, add the counterpart card | Live third-party disclosure. Closes §2 rows 2–8, the roster leak, photos and ages together |
| 2 | `is_main` into the participant model | Cheap, and the authority model is undefined without it |
| 3 | `ages_for()` narrowed to a single id | Trivial, ships alongside |
| 4 | `can_match` re-base off `seeker_profiles` | Gates dual-role. Do not open dual-role before it |

Awaiting your ruling on:

1. Model C under the account-id-as-sole-key rule — I agree with the rule
2. `can_match` re-based off matchable-profile, not role
3. Clause 3 scoped to a counterpart card (I8)
4. **Tier-1 exclusion — and the ward-count consequence in §4/Q3**
5. Guardian presentation = minimal card, no photo inheritance
6. Family Network: introduction-only / not browsable / not built
7. **Item C — I recommend leaving §3 as approved.** Your call
8. **Item 7 (subscription reversal) — this amends AD-081.** Needs to be
   decided as an AD amendment, not a line item
9. Guardian-only accounts as a first-class non-matchable state
10. Full-conversation Guardian read — default OFF, consented option
    (scholar/solicitor input, per consent policy §7)
