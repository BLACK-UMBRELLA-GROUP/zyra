# ZYRA — Dual Role & Guardian Exclusion: Architectural Review

**Status:** CLOSED — all questions resolved, Founder 2026-08-07.
Implementation not begun.
**Date:** 2026-08-07

---

# ONE RESPONSIBILITY EACH

**Founder's summary, and the reason the model is now sound:**

| Concept | Sole responsibility |
|---|---|
| **Guardian relationships** | determine Guardian **capability** |
| **Application contexts** | determine which **experience** you are in |
| **Guardian links** | determine **match exclusion** |
| **Blocks** | determine **permanent personal exclusion** |

No concept does two jobs, and no job is done by two concepts. That is what
makes the earlier confusions impossible to repeat: "should a former Guardian
stay excluded" cannot be argued once exclusion belongs to the active link
and permanence belongs to blocking.

---

# THE TWO REMAINING EDGE CASES — RESOLVED

### 1. A Guardian link forming over an existing Journey → REFUSE THE LINK

**Founder:** *"Creating a Guardian link shouldn't have the side effect of
terminating an existing marriage journey. That's a much larger consequence
than the user intended when linking a Guardian."*

Right, and it follows the principle already governing this project: an
action should not silently do something larger than it says. Ending
someone's Journey as a by-product of linking a Guardian is exactly that.

So `accept_wali_invite` gains a guard, refusing with a clear explanation
rather than resolving the conflict on the user's behalf.

**Scoped to an ACTIVE Journey**, consistent with every other rule here. A
pair whose Journey has ENDED may form a Guardian link — the relationship
that would have conflicted no longer exists, and the same logic that lets a
removed Guardian become matchable lets a former match become a Guardian.

### 2. One Guardian, two Seekers → ALLOWED, with no extra exclusions

**Founder:** *"A father is Guardian for both his son and daughter… Those two
Seekers should still be able to match with other people normally. The
Guardian simply participates in both marriage processes independently. The
only restriction should remain the direct Guardian ↔ Seeker relationship
itself."*

So sharing a Guardian creates **no** exclusion between the two Seekers, and
none between either Seeker and anyone else. `zyra_can_match` tests the
DIRECT link only — never a shared third party.

Worth stating because the opposite is easy to reach for: it would have been
natural to treat a shared Guardian as a family relationship implying
mahram status. It does not. A Guardian can be an uncle to one Seeker and a
family representative to another, and those two people may be unrelated.
**Inferring kinship from a shared Guardian would invent a religious fact the
data does not contain.**

Left open only for a genuine religious or product reason to appear, not for
an engineering one.

---

---

# THE MODEL

> - One identity
> - One account
> - One Seeker profile
> - Zero or more Guardian relationships
> - **Two application contexts**

## The correction that produced it

My review concluded there should be no second "role", and the Founder
accepted that **at the data layer** while rejecting it at the experience
layer:

> *"From a database perspective I agree… But from the USER'S perspective
> there absolutely are two distinct experiences. Different navigation,
> dashboard, notifications, actions, objectives. That is a different
> application context, even if the database never stores a second role
> value."*

He is right, and I had collapsed two layers into one. "There is no second
role in the schema" and "there is no second experience" are different
claims, and only the first followed from my evidence. Guardian capability is
derived from holding links; the Guardian *experience* is a first-class
context with its own shell.

So the architecture is unchanged and the UX conclusion is stronger:
**`profiles.role` gains nothing, and the context switch becomes more
important, not less** — precisely because nothing in the data announces
which experience you are in.

---

# THE TWO RULES

### 1. Visibility and matchability are separate axes

> An active Guardian link makes two people **permanently visible to each
> other and permanently unmatchable with each other**.

Enforced by two functions, never one:

| Question | Function |
|---|---|
| May I **see** this person? | `zyra_can_view_profile` |
| May I **pursue** this person? | `zyra_can_match` — **to build** |

### 2. Exclusion follows the ACTIVE link, and ends with it

**Founder, 2026-08-07, and to be written down so nobody later assumes
otherwise:**

> *"While an active Guardian link exists, the two users are permanently
> unmatchable. The moment that link is no longer active, the exclusion
> disappears. The restriction is tied to the ACTIVE Guardian relationship,
> not to historical Guardian links."*

So `zyra_can_match` tests `status = 'active'` and nothing else. A removed
Guardian becomes matchable again, deliberately.

**Two consequences worth stating plainly, because they follow from the rule
rather than from anyone's intention:**

- **Removal is a route to matchability.** If A is B's Guardian and either
  ends the link, the pair can match. That is the correct reading of a
  relationship having genuinely ended — but it is worth knowing it exists
  before someone discovers it.
- **The exclusion is not a safety mechanism.** It expresses that a Guardian
  and their Seeker are not marriage candidates *while that is their
  relationship*. Anyone wanting a permanent bar wants **blocking**, which is
  a different feature and already exists.

---

## Applied 2026-08-07

`wali_links` now carries `CHECK (seeker_id <> wali_id)`. Founder: *"a
fundamental integrity constraint rather than business logic."*

`accept_wali_invite` already refused "cannot accept your own invite", but
that guarded one PATH. Nothing guarded the ROW, so any other writer — a dev
seeder, a future RPC, a migration — could have created one. Tested: a
self-link is now refused at the table, and zero existing rows violated it.

---

---

## The fact that reframes the whole question

**A user cannot be both today.**

```sql
profiles.role  CHECK (role = ANY (ARRAY['seeker','wali','admin']))
```

One column, one value. There is no dual-role account, no user currently
holding both, and no schema that could express one.

So this is not "review an existing model". It is **a design decision not yet
taken**, and you are right to take it before more Guardian work lands on
top. Everything below is therefore a proposal, not an audit.

---

## 1. I would challenge the framing: these are not two roles

The whole review assumes Seeker and Guardian are peers — two roles, one
switch between them. I do not think they are.

| | Seeker | Guardian |
|---|---|---|
| What it is | a **state of your account** | a **relationship you are in** |
| Where it lives | `profiles.role` | `wali_links` |
| Can exist alone | yes — a Seeker with no Guardian | **no** — you are always *someone's* Guardian |
| Plural | no | yes — father to one, uncle to another |

**Nobody is "a Guardian". They are "Amina's Guardian".** The role has no
meaning without the other person, which is exactly why `relationship` sits
on the link and not on the account — a decision already made and ratified.

Follow that through and the architecture simplifies sharply:

> **Seeker is what your account IS. Guardian is something you DO for
> somebody else.**

So the question is not "which role am I in" but "am I looking at my own
journey, or someone else's". That is a **context**, and the answer is
already in the data: you have a Guardian context if and only if
`wali_links` has an active row where `wali_id = you`.

### What this means concretely

- **Do not add a second role.** Keep `profiles.role`.
- **Guardian capability is granted by the link**, not by a role value.
  A Seeker who accepts a Guardian invitation gains a Guardian context
  automatically, and loses it when the last link ends.
- **No dual-role onboarding, no role picker, no account type migration.**
  A Seeker who becomes someone's Guardian keeps one account and one role.

**The one thing this does require:** `accept_wali_invite` currently refuses
an accepter whose `role <> 'wali'`. Under this model a **Seeker** must be
able to accept, and gain a Guardian context by holding the link. That single
check is the whole of the "dual role" work.

---

## 2. Switching — a context switch, not a mode switch

Because the Guardian side is a relationship, it should appear **only when
one exists**, and disappear when it does not. Nothing to configure and
nothing to explain.

**Recommended:** a switcher in the **Profile header**, shown only when the
user holds at least one active `wali_id` link:

```
   ( photo )  Maryam
              Seeker  ·  Guardian for Aisha        ← tap to switch
```

**Why not Settings** (your §4): Settings configures the account. Which
experience you are looking at is not configuration, it is navigation, and
burying it two taps down means people forget the other side exists.

**Why not a global toggle in the nav bar:** it costs a permanent slot for
something most users never have.

**Why the Profile header:** it is the one place already answering "who am
I", and it is where every other app puts account switching.

**Full switch, not a blend.** Founder: *"I don't want users feeling like
they're simultaneously inside both experiences."* Agreed — switching should
replace the whole shell (`WaliHomeShell` already exists), not add a tab.

---

## 3. The exclusion rule — I agree, with one important correction

> **An active Guardian–Seeker relationship excludes both users from each
> other's marriage journey while that link exists.**

Ratify it. But the wording needs one change, because as drafted it would
break the product:

### Exclusion is about CONNECTION, not VISIBILITY

Your draft says Person B *"should never appear"* and you *"should never see
me"*. Taken literally that removes the Guardian page — a Seeker must be able
to see their Guardian, and a Guardian must be able to see their Seeker.
`zyra_can_view_profile` **explicitly grants** that today, in either
direction, for exactly this reason.

**The precise rule:**

> An active Guardian link makes two people **permanently visible to each
> other and permanently unmatchable with each other**, for as long as the
> link exists.

Visibility and matchability are different axes. The Guardian link sets them
in *opposite* directions, which is why one rule must not be written as
though it governs both.

### Where it must be enforced — and the honest state of each

| Surface | Enforced today? |
|---|---|
| Browse / discovery | **NO** — `zyra_can_view_profile`'s browsing clause checks active, complete, block, gender. No `wali_links` check |
| Consider / Save / Pass | **NO** |
| Match creation | **NO** — `create_match_on_mutual_like` is a trigger with no link check |
| Journey creation | **NO** |
| Compatibility Unlock | **NO** — `zyra_unlock_profile` gates on `zyra_can_view_profile`, which permits it |
| Guardian Introductions | **NO** — a Guardian could introduce their own Seeker to themselves |
| Scoring | **NO** |

**None of it is enforced, and that is fine — because it cannot be reached
today.** A single-role account means a Guardian has no Browse. The hole is
theoretical right now and becomes real **the moment dual context ships**,
which is precisely why this must land first.

### One place, not seven

Founder: *"I'd much rather have one central architectural rule than several
independent checks that can drift."* Strongly agreed, and there is an
obvious home.

**`zyra_can_view_profile` is already the choke point** — Browse, Unlock and
the RLS policies all route through it. But it must NOT simply return false,
because that would also hide the Guardian page.

**Recommend a second function beside it:**

```sql
zyra_can_match(p_target uuid) returns boolean
  -- false if an active wali_links row exists between the pair, either way
```

Then:

| Question | Function |
|---|---|
| May I *see* this person? | `zyra_can_view_profile` |
| May I *pursue* this person? | `zyra_can_match` |

Every matching surface calls the second. One definition, one place to
change, and the two axes stay separate by construction rather than by
everyone remembering.

---

## 4. Edge cases you have not listed

1. **Guardian for yourself.** `wali_links` has **no CHECK preventing
   `seeker_id = wali_id`**. `accept_wali_invite` blocks accepting your own
   invite, but nothing stops the row existing. **Add the constraint** — it
   is one line and it is the cheapest guarantee here.
2. **The link ends mid-Journey.** If exclusion is enforced only at creation,
   an existing Journey survives a new Guardian link forming over it. Decide:
   does a new Guardian link **end** an existing Journey between the pair, or
   is the link refused? I would **refuse the link** — ending someone's
   Journey as a side effect of an unrelated action is too violent.
3. **Guardian of both parties.** A man is Guardian to Aisha and to Yusuf.
   They match each other. Is that permitted? Nothing in the rule as drafted
   forbids it, and arguably it is the *ideal* case — a family member who
   knows both. **Flagging rather than deciding.**
4. **Indirect links.** My Guardian is also my match's Guardian. Same
   question as 3, one step removed.
5. **Removed links.** Exclusion is scoped to `status = 'active'`, so a
   removed Guardian becomes matchable again. Correct, but worth stating —
   it means removal is a route to matchability.
6. **Gender.** Guardians are male by current implementation and Browse is
   gender-segregated, so most Guardian–Seeker pairs are already unmatchable
   by gender. **That is a coincidence, not a safeguard**, and it disappears
   the moment the Guardian gender review changes anything.

---

## What I need from you

1. **Agree the reframing** — Guardian is a relationship, not a second role?
2. **Ratify the corrected rule** — permanently visible, permanently
   unmatchable?
3. **`zyra_can_match` as the single enforcement point?**
4. **Edge case 2** — refuse the link, or end the Journey?
5. **Edge case 3** — may one Guardian's two Seekers match each other?
