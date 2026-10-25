---
id: DOC-ZYRA-0188
type: PLAN
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian Relationship
links: []
owner: ZYRA chat
---

# ZYRA — Guardian Relationship

**Status:** PROPOSED — for Founder review. Nothing built.
**Date:** 2026-08-06 · **Author:** Opus
**Origin:** Founder, on the Compatibility Unlock screen — *"Abdul ·
Birmingham doesn't answer that. Abdul · Father immediately tells the user
who they're likely to be communicating with if the Journey progresses."*

---

## 1. Why this is product data, not decoration

A Seeker looking at another Seeker's Guardians is not asking where they
live. They are asking **who am I going to be dealing with**, before Family
Review and Guardian interaction begin.

"Father" sets an expectation. "Birmingham" sets none.

---

## 2. Role and relationship are different questions

Founder, 2026-08-06:

| | Answers | Stored as | Values |
|---|---|---|---|
| **Role** | *Who makes Guardian decisions?* | `wali_links.is_main` — **already exists** | Main Guardian · Guardian |
| **Relationship** | *Who is this person?* | `wali_links.relationship` — **new** | Father · Brother · … |

Both are kept. Neither substitutes for the other: the Main Guardian might be
an uncle while a brother is also linked, and knowing which is which matters
in different ways.

---

## 3. The enum

```
father · brother · grandfather · uncle
legal_guardian · family_representative · other
```

Stored as lowercase snake_case codes, rendered as labels — the ratified
**store the code, never the label** rule.

**Deliberately shipped narrow (Founder's option C).** Widening an enum is an
additive migration; removing a value is a breaking one that orphans existing
rows. Starting narrow keeps the product decision open rather than encoding
one that has not been made.

`grandparent` was rejected in favour of `grandfather`: a gender-neutral
value sitting between Father and Brother is an inconsistency that invites
the question it is trying to avoid. **Either everything is gender-specific
or nothing is.** Today it is.

---

## 4. A rule the code encodes that the Founder says does not exist

**Raised, not worked around.**

`ZyraProfileService.createWaliProfile` hardcodes `gender: 'male'` for every
Guardian, with this comment:

> *"Guardian is, per WALI_ARCHITECTURE_CURRENT_VERSION_V6.md, always a male
> guardian — gender isn't asked in Guardian onboarding, so it's set directly
> rather than adding a redundant question."*

Founder, 2026-08-06: **"there is no male only rule for this app… a Guardian
can be anyone from the list we create."**

Those disagree. The enum above is male-specific by choice, and that is fine
— but the *code* is male-only by assertion, which is different:

- **Legal Guardian** and **Family Representative** are gender-neutral roles.
  A woman appointed as either is recorded by the app as male.
- Nothing asks. The Guardian never states it and cannot correct it.
- `profiles.gender` is now behind an RPC and **frozen once published**
  (C-3), so a wrongly-set value is not user-fixable.

**Not fixed here** — it is a change to Guardian onboarding and to
WALI_ARCHITECTURE, and it is a product decision rather than a technical one.
Recommendation: either ask the Guardian at onboarding, or leave `gender`
null for Guardians until it is asked. Writing a value nobody supplied is the
weakest of the three options.

---

## 5. Where it is captured

**When the Guardian accepts the invitation.** Founder's preference, and the
right one:

- The Guardian is the person who knows.
- The Seeker inviting would be guessing on someone else's behalf and
  recording it as fact.
- It arrives at the moment the link becomes real, so no row is ever created
  without it.

One screen, after the code is validated and before the link is written —
`accept_wali_invite_screen`, one question, seven options.

**Not optional.** `other` exists so nobody is forced into a wrong answer,
which means there is no case for a skip. A nullable relationship would leave
the display code handling an absence that only exists because we allowed it.

---

## 6. Schema

```sql
alter table public.wali_links
  add column relationship text
  check (relationship in ('father','brother','grandfather','uncle',
                          'legal_guardian','family_representative','other'));
```

**Nullable at first, by necessity** — two live rows already exist and their
relationship is genuinely unknown. Backfilling a guess would be inventing
data about real people. `NOT NULL` goes on once existing links have been
asked, or when the two dev rows are recreated.

Ownership, classified in the same migration per the Founder's standing rule:

```sql
comment on column public.wali_links.relationship is
  'OWNERSHIP: joint(seeker_id, wali_id) — both parties know the relationship.
   Disclosed to a Seeker who has unlocked the other party (guardians_for_unlocked).';
```

`guardians_for_unlocked` gains `relationship` to its return type. No policy
change: it is already gated on `profile_unlocks`.

---

## 7. Every surface that shows a Guardian

| Surface | Today | After |
|---|---|---|
| Compatibility Unlock — Guardian section | `Abdul · Birmingham` | `Abdul · Father`, `Main` unchanged at right |
| Guardian tab — Main card | name + relationship *(already renders it; always null in reality)* | genuinely populated |
| Guardian tab — Additional list | same | same |
| Wali journey detail | name only | name + relationship |

**One existing bug this closes.** `WaliLinkedPerson.relationship` is already
a field, already rendered on the Guardian tab, and **nothing has ever set
it**. The only place "Father" and "Brother" appear today is the dev panel's
hardcoded fakes — which is why the tab looks right in testing and would be
blank for every real user.

**City is replaced, not joined.** `Abdul · Father · Birmingham` is three
facts where the reader wanted one, and the city was never the question.

---

## 8. Sequence

| # | Step |
|---|---|
| 1 | Migration: column, CHECK, ownership comment |
| 2 | `guardians_for_unlocked` returns `relationship` |
| 3 | Reference list + `zyraRelationshipCodeFor`, mirroring `zyra_reference_data` |
| 4 | Acceptance screen: one question, seven options, required |
| 5 | `ZyraWaliLinkService` — write on accept, read on fetch |
| 6 | Display: unlock screen, Guardian tab, wali journey detail |
| 7 | Verify: RLS unchanged, unlock gating unchanged, no relationship visible without an unlock |

Steps 1–2 are behaviour-preserving. Step 4 is the only user-visible change
to an existing flow.

---

## 9. What I need from you

1. **Approve the plan.**
2. **§4 — the hardcoded `gender: 'male'`.** Ask at onboarding, leave null,
   or leave as-is for now? It is not blocking, but it is writing data nobody
   supplied.
3. **Confirm the two existing links stay null** rather than being guessed.
