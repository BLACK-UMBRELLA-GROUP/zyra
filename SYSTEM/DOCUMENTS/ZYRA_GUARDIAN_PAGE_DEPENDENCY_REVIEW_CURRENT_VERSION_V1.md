---
id: DOC-ZYRA-0183
type: REPORT
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian Page: Six-Layer Dependency Review
links: []
owner: ZYRA chat
---

# ZYRA — Guardian Page: Six-Layer Dependency Review

**Status:** IMPLEMENTED — 2026-08-06

## Estimate vs reality

| Layer | Predicted | Actual |
|---|---|---|
| Schema | 1 column | 1 ✓ |
| RLS | **0** | **0** ✓ |
| RPCs | 1 new, 1 changed, 1 must-not-change | exactly that ✓ |
| Triggers | 0 | 0 ✓ |
| Client | 5 files, 1 new | **6 files, 2 new** — `guardian_detail_screen.dart` was counted, `link_guardian_panel.dart` was not; the label field lives there, not in `link_wali_screen` |
| Docs | 3 | 2 so far |

**First review to predict a layer at zero and be right.** Layer 2 was empty
because OA-156 already answers "may I see this", so a new feature reading
Guardian data inherited its authorisation rather than needing any.

**Verified after implementation:**

| Check | Result |
|---|---|
| `zyra_guardian_activity()` as a real Seeker | 6 rows — 5 suggestions + linked |
| Label visible to sender | ✓ "Uncle Ibrahim" |
| Label via `preview_wali_invite` as recipient | **not present** — returns `(Maryam, seeker, pending)` |
| Label via direct table read as recipient | **0 rows** |
| Static checker | clean, 96 files |

One defect found and fixed during the build: `GuardianActivity.fromRow`
parsed `occurred_at` unconditionally, so a null timestamp would have taken
the whole page down rather than dropping one line. Every branch selects a
NOT NULL column today, which is exactly why it would have gone unnoticed
until the day one of them didn't.
**Date:** 2026-08-06 · **Standard:** `SIX_LAYER_REVIEW_STANDARD_CURRENT_VERSION_V1.md`
**Follows:** `ZYRA_GUARDIAN_PAGE_REVIEW_CURRENT_VERSION_V1.md`, Founder-approved

---

## The headline: Guardian activity has a real source, and it is not the one we listed

`journey_family_review_responses (review_id, wali_id, decision, responded_at)`
is per-Guardian, timestamped, and carries the decision. That is a proper
activity feed, already modelled, already readable by the Seeker.

But checking each of your six examples against the data changes three of
them.

| Your example | Buildable | Why |
|---|---|---|
| Reviewed your latest Journey | **yes** | `responded_at` per Guardian |
| Completed Family Review | **yes** | `journey_family_reviews.resolved_at` |
| Waiting for Family Review | **yes** | open review, no response row from them |
| Accepted your Guardian invitation | **yes** | `wali_links.created_at` |
| **Became your Main Guardian** | **no** | see below |
| **Invited to Journey** | **no** | see below |

### "Became your Main Guardian" — no timestamp, and redundant anyway

`is_main` is a boolean. Nothing records *when* it became true.

Adding `is_main_since` would not help: every existing link would get a
backfilled value that is a guess, and for the first Guardian the answer is
always the same day they linked, so the entry would read:

```
Accepted your invitation · 3 March
Became your Main Guardian · 3 March
```

Two lines saying one thing. It only becomes distinct once Main can be
**reassigned**, and no reassignment path exists — `auto_designate_main_wali`
sets it on the first active link and nothing ever moves it.

**Recommend: omit. It arrives free with Main reassignment, whenever that
ships.**

### "Invited to Journey" — participation is derived, not an event

`zyra_attempt_participants()` returns `(user_id, role, is_main,
attempt_status)`. **No timestamp**, because a Guardian is a participant *by
virtue of being linked*, not by being invited. There is no invitation, so
there is no moment to report.

Changing that means making participation an event — a real modelling change
to OA-156, which was deliberately built the other way. **Not in scope, and I
would not raise it lightly.**

### The one with actual data is the one you did not list

**"Suggested Yusuf to you."** `wali_suggestions.created_at`, and it is the
only Guardian activity with real rows today:

| Guardian | Suggestions | Linked | Reviews answered |
|---|---|---|---|
| Ibrahim | **5** | 19 Jul | 0 |
| Khadija | 0 | 25 Jul | 0 |
| Abdul | 0 | 5 Aug | 0 |
| Hassan | 0 | 5 Aug | 0 |

**Family Review has never run in this database — zero reviews, zero
responses, ever.** So the review-based entries are correct code with no
content until the flow executes. That is fine and honest under *"if there is
no activity, don't invent it"* — but it means the feature would look inert
on launch if suggestions were left out. Including them is what makes the
page alive on day one.

---

## Layer 1 — Schema · ONE new column

```sql
alter table public.wali_invites add column label text;   -- max 40, nullable
```

The sender's private note for who a code was meant for. Nothing else.

Deliberately **not** added: `is_main_since` (would be backfilled guesswork),
any verification column (dropped by decision), any activity table (every
entry derives from existing rows — outstanding action is state, CLAUDE.md
§3d, and so is history when the history already exists).

## Layer 2 — RLS · ZERO changes

Checked, not assumed:

| Policy | Already correct because |
|---|---|
| `wali_invites_select` | `inviter_id = auth.uid()` — the label is visible only to its author, by construction. No new rule needed for the privacy property you asked for |
| `journey_family_reviews_read` | scoped through `zyra_my_attempt_participation` to `role='seeker' OR is_main` — the Seeker can already read reviews on their own attempts |
| `journey_family_review_responses_read` | same shape |
| `wali_suggestions_select` | `seeker_id = me OR wali_id = me` |
| `wali_links_select` | own links only |

The OA-156 authorisation work is why this layer is empty. Participation
already answers "may I see this", so nothing new has to.

## Layer 3 — RPCs

| RPC | Change |
|---|---|
| **`zyra_guardian_activity()`** | **NEW** — one call returning the latest activity per linked Guardian. A compound read across four tables; four round trips from the client would be worse and untestable |
| **invite creation** | must accept and store `label`. Currently a direct client INSERT into `wali_invites` — moving it behind an RPC is consistent with C-3, and the INSERT policy already exists either way |
| `accept_wali_invite` | none — the label is the sender's, never the accepter's |
| `preview_wali_invite` | **must NOT return the label.** It is a private note; leaking it to the recipient would be the one real privacy defect available here |

## Layer 4 — Triggers · none

`auto_designate_main_wali` reads `is_main`. Untouched.

## Layer 5 — Client

| File | Change |
|---|---|
| `seeker_wali_tab.dart` | rebuilt — summary strip, intro, larger cards, sections, circular + |
| `guardian_detail_screen.dart` | **NEW** |
| `zyra_wali_link_service.dart` | `GuardianActivity` model, activity fetch, invite label |
| `link_wali_screen.dart` / `LinkGuardianPanel` | capture the optional label |
| `zyra_dev_scenario.dart` | fakes need activity, or the dev panel shows a feature that looks broken |

## Layer 6 — Documentation

`WALI_ARCHITECTURE_V6` (activity model), `ZYRA_DATABASE_SCHEMA` (the column),
ownership classification for `wali_invites.label` in its own migration.

---

## Dependency review

| Question | Answer |
|---|---|
| Which RPCs consume it? | 1 new, 1 changed, 1 explicitly must NOT change |
| Which client code? | 5 files, 1 of them new |
| Which docs? | 3 |
| Which policies, views, grants? | **none** — OA-156 already carries it |
| Which approved-but-unbuilt architecture? | **Remove Guardian** (second pass, your decision) and **Main reassignment** — the latter would make "Became Main Guardian" real |
| Anything else? | `preview_wali_invite` is the one place the new column could leak. Named here so it is tested, not assumed |

### Risks

1. **The label is free text and it is shown back to the sender.** Length
   capped at 40 and it is never rendered to anyone else, so the blast radius
   is one's own screen — but it is the only free-text field in this feature
   and worth stating.
2. **Family Review has never run.** The review-based activity is unverifiable
   against real data until it does. I will seed a review on test accounts to
   exercise it rather than shipping code that has never returned a row.
3. **Dev fixtures.** `fakeGuardians` will need activity, or the dev panel
   will make a working feature look broken — the same trap the relationship
   fixtures set this morning.
