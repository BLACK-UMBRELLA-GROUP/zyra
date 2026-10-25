---
id: DOC-ZYRA-0073
type: SPEC
status: DRAFT
feature: ARCHITECTURE AND DATA
purpose: ZYRA — Unified Authorisation Model
links: []
owner: ZYRA chat
---

# ZYRA — Unified Authorisation Model

**Status:** PROPOSED — awaiting Founder approval. Nothing built.
**Date:** 2026-08-06
**Author:** Opus (Implementation Lead)
**Responds to:** Founder instruction, 2026-08-06 — *"consolidate the
authorisation model. I do not want duplicated visibility logic long term…
Do not simply keep both because they already exist."*
**Governing architecture:** `ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md` §4
(DR-ZYRA-121, OA-ZYRA-156)

---

## 1. The two functions

| | `zyra_can_view_profile(target)` | `attempt_visible_to(attempt, user)` |
|---|---|---|
| Status | **Built** 2026-08-04 | **Approved, not built** — V3 §4 |
| Question | May the caller see this **person**? | May this user see this **attempt**? |
| Used by | `profiles_select` RLS, `ages_for()`, `score_candidates()` | 15 RLS policies after the migration |

**They are not the same function wearing two names.** One is about a person,
the other about a Journey attempt. Merging them into a single call that
takes "some uuid" and infers the object type would be worse than keeping
two — a visibility check that guesses what it is checking is exactly the
kind of thing that fails quietly.

**But the duplication is real, and it is underneath them.**

---

## 2. Where the actual overlap is

`zyra_can_view_profile` has five clauses. Three are *relationship facts*
that `attempt_visible_to` will have to re-derive:

| Clause | Also needed by `attempt_visible_to`? |
|---|---|
| 1. self | no |
| 2. Guardian ↔ Seeker, either direction | **yes** |
| 3. Guardian → their Seeker's match partner | **yes** |
| 4. own match partner | **yes** |
| 5. opposite-gender browsing | no |

Written as V3 specifies, clauses 2–4 get restated in inline SQL inside
`attempt_visible_to`. That is the drift, and it is the precise failure V3 §4
itself cites as precedent:

> The `profile-photos` storage read policy resolved visibility through an
> RLS-bound subquery on `profiles`, so photo readability silently inherited
> the gender rule of whoever *uploaded* each file… Duplicated authorisation
> logic fails quietly and expensively.

---

## 3. Proposal — one participant set, two thin policies

```
        zyra_attempt_participants(attempt_id) -> (user_id, role)
                              │
                the ONE place a role is added
                              │
          ┌───────────────────┴───────────────────┐
          │                                       │
  attempt_visible_to(attempt)         zyra_can_view_profile(target)
   "am I a participant?"               self · guardian link ·
                                       shares ANY attempt ·
                                       opposite-gender browsing
```

**`zyra_attempt_participants(attempt_id)`** returns everyone entitled to see
an attempt and why:

| user_id | role |
|---|---|
| seeker A | `seeker` |
| seeker B | `seeker` |
| A's active Guardians | `guardian` |
| B's active Guardians | `guardian` |

Both policy functions read it. Neither restates it.

### What this buys that V3's version does not

V3 §4 promises that adding a mediator or family member later is *"one
function change instead of fifteen policy rewrites."* True for the fifteen
attempt policies — but under V3 as written, that new role would still be
invisible to `zyra_can_view_profile`, so a mediator could see the attempt
and not the two people in it. **Two edits, in two places, that must agree.**

With a shared participant set it is genuinely one edit. A role added there
gains attempt visibility *and* profile visibility for the people in that
attempt, together, because both questions are answered from the same list.

---

## 4. A change I would make to the approved signature

**V3 specifies `attempt_visible_to(attempt_id, auth.uid())`.** I would drop
the second parameter and read `auth.uid()` inside the function.

Not style. A `SECURITY DEFINER` function that accepts the *subject* as an
argument can be asked about somebody else:

```sql
select attempt_visible_to('<attempt>', '<any user id>');
```

That answers "is this person party to this Journey?" for any pair a caller
cares to name — an information leak on its own, and an authorisation bypass
the moment any code path passes a value that originated with the client. The
built `zyra_can_view_profile` reads `auth.uid()` internally for this reason
and cannot be asked about a third party.

This is the same class of defect as H-2 and H-3 in the security sprint:
functions that accepted arbitrary UUIDs and answered questions about them.

**If a caller genuinely needs to ask about another user** — moderation
tooling, most likely — that should be a separate, explicitly-named function
with its own authorisation check, not a general one everybody can call.

---

## 5. Naming

Currently `zyra_can_view_profile` and `attempt_visible_to` — different
prefix, different voice, same job. Proposed, consistently:

| | |
|---|---|
| `zyra_can_view_profile(uuid)` | keep — already built and referenced |
| `zyra_can_view_attempt(uuid)` | rather than `attempt_visible_to` |
| `zyra_attempt_participants(uuid)` | new shared substrate |

Cosmetic, and cheap only before fifteen policies reference it.

---

## 6. Sequence

Fits inside OA-ZYRA-156; adds no separate phase.

| # | Step |
|---|---|
| 1 | Build `zyra_attempt_participants()` against `journey_attempts` |
| 2 | Refactor `zyra_can_view_profile` clauses 2–4 to read from it — **behaviour must not change**; the existing RLS test suite is the proof |
| 3 | Build `zyra_can_view_attempt()` on the same substrate |
| 4 | Point all 15 policies at it during the migration |

Step 2 is the one carrying risk: it touches `profiles_select`, which governs
Browse. It must be verified with the same impersonation tests used on
2026-08-04 — male seeker sees only female profiles, Guardian sees only their
own Seeker, same-gender Guardian pair still works.

---

## 7. What I need from you

1. **Approve the shared participant set** (§3), or tell me to build
   `attempt_visible_to` standalone as V3 specifies.
2. **Approve dropping the `user_id` parameter** (§4). This is a change to an
   approved design, raised with evidence rather than implemented quietly.
3. **Approve the rename** (§5), or keep V3's `attempt_visible_to`.

None of this begins until you answer. If you prefer V3 exactly as approved,
say so and I will build it as written — the drift risk in §2 is then a known,
accepted cost rather than an oversight.
