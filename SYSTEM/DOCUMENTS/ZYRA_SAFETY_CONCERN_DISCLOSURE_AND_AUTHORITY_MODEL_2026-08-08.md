---
id: DOC-ZYRA-0261
type: SPEC
status: CURRENT
feature: SAFETY AND PRIVACY
purpose: ZYRA — Safety-concern disclosure, and the authority model
links: []
owner: ZYRA chat
---

# ZYRA — Safety-concern disclosure, and the authority model

**Status:** ONE URGENT FINDING + a design response. Nothing built.
**Date:** 2026-08-08

---

# Part 1 · 🔴 `safety_concern` is disclosed to the person it was raised about

**This is the most serious finding of the review, and it is not a Guardian
problem. It is a column-level rule with no column-level enforcement.**

## The rule, already written down

`zyra_data_ownership` records for `matches.end_reason`:

> *"OWNERSHIP: per-value. joint for the five stated reasons… **safety_concern
> is row-scoped(ended_by) and MUST NEVER reach the other party by export or
> any indirect route** — otherwise the export becomes the disclosure channel
> V3 §3 and §11 exist to close."*

Somebody thought about this carefully and wrote the rule down.

## What actually happens

Tested live and rolled back. Seeker A ends a Journey with Seeker B, citing
`safety_concern` about B.

| Reader | Sees |
|---|---|
| **B — the person it was raised about** | **`safety_concern`** |
| **B's Guardian** | **`safety_concern`** |
| B's Guardian also sees `ended_by` | **the other Seeker** — so, who raised it |

`matches_select` returns the **whole row**. There is no column-level grant
restriction on `matches`, so every column comes with it — `end_reason`,
`ended_by`, `end_note`.

## Why this is worse than a privacy bug

A woman ends a Journey because a man made her feel unsafe. The system
currently tells **him**, and tells **his family**, with her name attached.

The likely real-world consequences of that on this product need no
elaboration. And the second-order effect is just as damaging: once anyone
learns it works this way, nobody uses `safety_concern` again, and the safety
signal disappears from the data entirely.

## The gap in kind

The register describes **per-value** ownership — the same column is joint
for five reasons and private for one. RLS cannot express that: a policy
decides whether you get a row, not which columns or which values.

`profiles` already solved the column half of this by **revoking the SELECT
grant** on `date_of_birth` and exposing age through `ages_for()`. `matches`
has no such treatment.

## The fix

Not attempted. The shape:

1. **Revoke SELECT on `end_reason`, `end_note`, `ended_by` from
   `authenticated`** — the `profiles.date_of_birth` pattern.
2. **A `SECURITY DEFINER` accessor** that returns the ending as each viewer
   is entitled to see it: the true reason for `ended_by`, and for everyone
   else — the other Seeker, both families' Guardians — the five joint
   reasons pass through while `safety_concern` returns
   `prefer_not_to_say`.
3. **`safety_concern` must be indistinguishable from `prefer_not_to_say`**
   downstream. If the substitution is detectable — a different UI string, a
   missing note, a distinct code path — the substitution is the disclosure.
4. **Check the same value elsewhere.** It flows into notifications and any
   future export; `messages.content` is already flagged `pending-legal` for
   related reasons.

## Also found, lower severity

- **`journey_family_review_responses`** lets a Main Guardian read the *other
  family's* Main Guardian's individual continue/pause decision. The joint
  outcome is arguably shared; who voted which way is a different thing.
  Worth deciding rather than inheriting.
- **`matches_select` already gates Guardians on `status <> 'potential'`** —
  so the *match row* is correctly hidden pre-Journey while
  `zyra_can_view_profile` clause 3 leaks the *profile*. Confirms the fix for
  clause 3 is a one-line adoption of a pattern already used two tables away.

---

# Part 2 · The authority model

**The instinct is right. The axis is wrong.**

Proposed: relationship determines authority — `father` full, `community
representative` restricted unless promoted.

## Three objections

### 2.1 · Relationship is self-declared and unverified — this one is fatal

Established earlier in this project: *"the person creating the link provides
the relationship information about themselves."* Nothing checks it. There is
no document, no corroboration, not even the Seeker confirming it.

**A catalogue-builder declares `father`.** Authority derived from an
unverifiable claim restricts only the people who tell the truth, and hands
the highest tier to anyone willing not to.

### 2.2 · It penalises exactly the people with the fewest options

A woman with no father, brother or uncle — the person who most needs the
product to work — has a `family_representative` or `legal_guardian` as her
**only** Guardian. Restricting that tier leaves her with a Guardian who
cannot do the job, and the alternative on offer is no Guardian at all.

The tier that sounds least trustworthy in the abstract is the one held by
the users in the weakest position.

### 2.3 · It does not close A1

A catalogue-builder self-selects for whatever position carries visibility.
Restrict `family_representative` and they declare `uncle` and seek to be
Main. The tiering moves the target; it does not remove it.

## What the right axis is

> **Authority is granted by the Seeker. It is never inferred from a label
> the Guardian wrote about themselves.**

| | |
|---|---|
| **Position** — Main vs Additional | Structural, chosen by the Seeker, enforced by `wali_links_one_main_per_seeker` |
| **Default** | Main → full · Additional → oversight of their own Seeker only |
| **Adjustable** | The Seeker may restrict a Guardian below the default. Never above it |

This survives every objection above. It cannot be gamed by a false
declaration, because the Seeker chooses. It does not penalise the woman with
no male relatives, because she makes her representative Main and they get
what the role needs. And it puts the decision with the person whose data it
is, which is the same principle as the rest of the model.

**Relationship stays exactly what it is today: a label, shown for context,
carrying no power.** Its job is to help a family understand who they are
looking at — which is also the job of the Guardian count.

## Where the idea does pay off

Credit where it is due, because this is real and I missed it in pass 2.

`wali_links_one_main_per_seeker` means **one Main per Seeker**. So the
high-visibility position cannot be accumulated quietly — a catalogue-builder
must be **chosen as primary by fourteen separate people**, each of whom
displaced whoever else they might have picked.

That is a far higher bar than being Additional to fifty. **Authority tiering
does not close A1, but it raises its cost substantially** — and combined
with surfacing the count, a person who is Main for fourteen Seekers is both
hard to become and impossible to hide.

That is probably as close to solved as this gets without refusing something
legitimate.

---

# Part 3 · The philosophy, as ratified

> **A Guardian only learns what they genuinely need to perform their role,
> only after the appropriate level of consent has been reached, and only
> about families their own Seeker is genuinely progressing with.**

Adopted. It should be the opening line of the trust model document, because
it is the sentence every future feature gets tested against.

---

# Part 4 · Sequence, revised once more

| | | |
|---|---|---|
| **0** | **`safety_concern` disclosure — Part 1** | **New. Ahead of everything: it is a safety failure, not a privacy one, and the rule already exists and is simply unenforced** |
| 1 | Status guard on clause 3 | one line, standalone |
| 2 | Invite hardening | |
| 3 | Notification content rules | |
| 4 | Agree the matrix — incl. removed-Guardian revocation, and Seeker-granted authority | |
| 5 | Read-side predicate | |
| 6 | `can_introduce()` with both conditions | |
| 7 | Family Network | last |

**Still open and not yet challenged by anyone:** whether a Guardian should
see the other family's Main Guardian's individual review decision, and
whether `messages.read_at` — the other Seeker's behaviour — should be
visible to Guardians at all. Both are small; both are the kind of thing this
review keeps finding by looking one table further.
