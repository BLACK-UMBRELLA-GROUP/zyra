# ZYRA Notification Specification

**Version:** V1 · **Status:** CURRENT_VERSION · **Date:** 2026-08-14
**Resolves:** OA-ZYRA-146 (parked 2026-07-28, resumed once the Active Journey / ZYRA One tiering discussion had gone deeper)
**Incorporates without altering:** OA-ZYRA-161 (approved 2026-08-06 — the Journey notification map and its two safety rules), ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md §11
**Supersedes:** the placeholder "ZYRA Notification Specification (separate document — to be specified)" named in the Journey Suspension document

**What this document is.** The single description of what ZYRA notifies, to whom, through which channel, under which consent, and what it may never say. It is a specification, not a build report — §9 marks precisely what is built today and what is not.

---

## 1 · Principles

These four govern every row in every table below. Where a later section seems to permit something a principle forbids, the principle wins.

**P1 · Visible is not the same as pushed.**
Almost everything belongs in the feed. Very little belongs on a lock screen. Collapse the two and one Journey produces ten interruptions, people disable the category, and the notifications that mattered go with it. *(OA-161, approved.)*

**P2 · A Guardian receives a digest, not a stream.**
A Guardian watching a Journey move in real time is surveillance whatever the permission model calls it. Guardians push only on endings and accepted requests; everything else reaches them in a digest. *(OA-161, approved.)*

**P3 · A notification body is a public artefact.**
It survives in a table, it renders on a lock screen, and in a shared household it is read by people who are not the recipient. Nothing goes in a body that the recipient would not want read aloud in their kitchen.

**P4 · Silence is a designed state.**
Some events must generate nothing. A protection hold is the clearest case: its existence must not be inferable from anything, including from an absence where something usually appears.

---

## 2 · Two safety rules — non-negotiable

Carried verbatim in substance from OA-ZYRA-161. These are not preferences and are not subject to the tiering discussion.

**S1 · A safety ending is worded identically to an ordinary ending, for the other party.**
If the copy differs by a single word, the protection announces itself to the person it protects against. Same title, same body, same type, same timing.

**S2 · A safety reason is disclosed to nobody automatically — including the ender's own Guardian.**
If a woman ends a Journey because she felt unsafe, that is hers to tell her family, in her words, at her timing. Routing *"she reported feeling unsafe"* to a male relative is unremarkable in most households and dangerous in a minority, and ZYRA cannot tell which one it is looking at. Her Guardian is told the Journey ended. Moderation sees the reason.

**S3 · A protection hold generates no notification to anyone, ever.** *(P4 applied.)*

**S4 · A reporter is never identified to the reported party** — not in a body, not by timing, not by a change in what the reported party can see.

**S5 · Private Ritual answers and private ratings never appear in a notification body.** The notification may say a Ritual answer arrived. It may not say what it was.

---

## 3 · Priority — two tiers, no more

The app already teaches a colour language through the traffic-light system. A notification priority scheme is not the place to introduce a second one.

| Tier | Meaning | In-app | Push | Visual |
|---|---|---|---|---|
| **Standard** | Something happened you will want to know | Feed, chronological | No | Default |
| **Time-Sensitive** | Something is waiting on *you*, and waiting has a consequence | Feed, **pinned above chronological** | Yes | Existing amber token |

Two tiers, because a third would immediately be used to mean "quite important" and every event would drift upward. If a proposed event is not clearly one of these two, it is Standard.

**Time-Sensitive requires a deadline.** If nothing expires and nothing is blocked on the recipient, it is Standard however interesting it is.

---

## 4 · Categories — the consent layer

Five, matching the CHECK constraint on `notification_preferences.category` exactly. Store the code, never the label.

| Code | Label | Default | Basis |
|---|---|---|---|
| `matches_journeys` | Matches & Journeys | **On** | Product notification — legitimate interest |
| `guardian_activity` | Guardian Activity | **On** | Product notification |
| `introductions` | Introductions | **On** | Product notification |
| `marketing_emails` | Marketing Emails | **Off** | UK GDPR / PECR — consent, a pre-ticked box is not consent |
| `product_updates` | Product Updates | **Off** | UK GDPR / PECR — consent |

`notification_preferences` is **append-only** — every change INSERTs, nothing updates or deletes. Opt in, withdraw, opt in again, and all three survive. A single mutable row could only ever evidence the last one, and a withdrawal that cannot be evidenced was not honoured.

**Defaults live in the database**, not the client, so a future screen cannot quietly disagree with them.

### 4.1 · Rules

| Rule | |
|---|---|
| **R1** | Every notification type maps to exactly one category. §5 is that mapping and is exhaustive. |
| **R2** | A disabled category suppresses **creation**, not just display. A suppressed notification is never written. |
| **R3** | Security and Account notifications have **no category and no toggle** — they are not marketing and not product colour; they are the record of something happening to the account. |
| **R4** | A category toggle governs **push and feed together**. Two switches per category is the design that makes people turn everything off. |

---

## 5 · Event taxonomy

`Push` columns assume push exists; it does not yet (§9). Until it does, every row's push behaviour is deferred, not cancelled.

### 5.1 · Matches — `matches_journeys`

| Type | Trigger | To | Tier | Push |
|---|---|---|---|---|
| `new_match` | Mutual Like creates a match | both Seekers | Standard | Yes |
| — | **A Like received** | — | — | **Never. See below.** |

> **No per-Like notification, and this is a decision, not an omission.** The instant "someone liked you" ping is the mechanic mainstream dating apps use to drive compulsive re-opening, and ZYRA's own stated position is that engagement metrics are not the goal. A Like that is not reciprocated is not news; a Like that is reciprocated is a match, which already notifies. *(Recommendation from the 2026-07-28 review, carried forward.)*

### 5.2 · Journey — `matches_journeys`

**Ratified in ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md §11 and reproduced here unchanged.** If the two ever diverge, the Lifecycle document is the source of truth for this table.

| Event | Other Seeker | Own Guardian | Their Guardian |
|---|---|---|---|
| Pause | in-app, no push | digest | — |
| Resume | push | digest | — |
| End — ordinary | push, with reason | push | push |
| End — safety | push, **worded identically to ordinary** | push, **no reason** | push, no reason |
| Request New Journey | push | digest | — |
| Accept | push | push | push |
| Decline | push | — | — |
| Protection hold placed | **nothing, ever** | — | — |
| Moderator action | affected party only | — | — |
| Family Review begins | push | push | push |

Live types serving this table: `journey_ended`, `journey_request`, `journey_request_accepted`, `journey_request_declined`, `pause_nudge`, `milestone_proposed`, `milestone_confirmed`.

**One decline type covers decline, permanent decline and 14-day expiry alike** — enforced by there being no column in which the difference could leak. A requester who could distinguish an expiry from a refusal would learn the thing the rule exists to withhold. *(DR-ZYRA-121 item 8.)*

**Decline notifies rather than staying silent.** Letting the 14-day expiry deliver the news means fourteen days of hope for a question already answered. What needs protecting is *which kind* of decline, not *that* one happened.

**Time-Sensitive rows:** Family Review begins (a Review Period runs out), `milestone_proposed` (a confirmation is waiting on the recipient), `journey_request` (expires in 14 days). Everything else in this table is Standard.

### 5.3 · Guardian — `guardian_activity`

#### 5.3.1 · The invite lifecycle — every outcome notifies

An invite has **four** possible endings, not one. Today only acceptance notifies, so a Seeker who sends a code to a family member learns the outcome only if it is the good one. Silence currently means *accepted-and-nobody-told-me*, *declined*, *expired* and *still waiting* all at once, and the sender cannot tell which — so the sensible move is always to send another code, which is the worst of the four responses in three of the four cases.

| Type | Trigger | To | Tier | Push |
|---|---|---|---|---|
| `wali_invite_received` *(proposed)* | Invite arrives | invitee | Standard | Yes |
| **`wali_request`** *(live)* | Invite **accepted**, either direction | inviter | Standard | Yes |
| `wali_invite_declined` *(proposed)* | Recipient declines | inviter | Standard | Yes |
| `wali_invite_expiring` *(proposed)* | Day 5 of 7, still pending | inviter | **Time-Sensitive** | Yes |
| `wali_invite_expired` *(proposed)* | 7-day deadline passes unredeemed | inviter | Standard | No |
| `wali_invite_revoked` *(proposed)* | Inviter withdraws it | invitee, if they had seen it | Standard | No |

**`wali_invite_expiring` is the one that saves the relationship, not the one that reports on it.** Told on day 5, the sender can chase a family member who has forgotten. Told on day 8, all they can do is start again.

**`wali_invite_expired` does not push.** Nothing is waiting on the recipient at that point and nothing is lost — it is a status correction, and a lock-screen interruption to say *"nothing happened"* is exactly what erodes trust in the category.

**Every one names who it is about**, from `wali_invites.label` where set — the private note that exists so the Pending Invitations list reads as *Dad* and *Uncle Ibrahim* rather than eight-character codes. "Your invite expired" is nearly useless to someone with three out.

#### 5.3.2 · Decline and expiry are told apart here — unlike a Journey request

`journey_request_declined` deliberately covers decline, permanent decline and expiry alike, and the requester must not be able to distinguish them (DR-ZYRA-121 item 8). **That rule does not transfer to Guardian invites, and the difference is not an oversight.**

A Journey request is a romantic approach. *"He declined"* versus *"she never opened it"* is precisely the information that protects the person who said no, and there is no action the requester should take differently in either case.

A Guardian invite is an administrative act inside a family, and the two outcomes demand **opposite** responses:

| Outcome | Right next move |
|---|---|
| Expired | Send a new code — they never got round to it |
| Declined | Do **not** send another code. This is a conversation to have in person |

Merging them produces a Seeker who repeatedly re-invites a relative who has already said no. That is a worse outcome than the candour.

> **This is a decision, not a derivation** — recorded as D6 in §10. The argument against: telling someone plainly that a family member declined to act as their Guardian is a real sensitivity, and the wording must carry no judgement. The recommendation is to distinguish them, with copy that states the fact and suggests nothing.

#### 5.3.3 · Blocker — expiry is not currently an event

**`wali_invite_expiring` and `wali_invite_expired` cannot be built until something makes expiry happen.**

`expire_wali_invite_if_due()` marks one row at a time and runs only when it is called:

- from `preview_wali_invite` — i.e. when the **recipient** opens the link, and
- inside `accept_wali_invite`, where it is a **predicate only**: the `RAISE` immediately after rolls its `UPDATE` back (corrected explicitly in migration `20260809171103`).

So **an invite nobody opens is never marked expired.** It sits at `status = 'pending'` past `expires_at` indefinitely. There is no moment at which expiry occurs, and a notification needs a moment.

The Journey side already solved this: `zyra_expire_due_journey_requests(UUID)` sweeps overdue rows, marks them, and emits the notification, called from `zyra_journey_service.dart:785`. **The Guardian side has no equivalent.** `pg_cron` is not installed, so a scheduled sweep is not currently an option either.

**Required first: `zyra_expire_due_wali_invites`,** shaped after the Journey function — sweep, mark, notify, invoked on Guardian-surface load the way the Journey one is. Raised as **OA-ZYRA-232**. Until it exists, `wali_invite_expired` has nothing to fire from.

*(Not a security hole. `accept_wali_invite` refuses an expired invite regardless, and the Pending Invitations list already computes "Expired" from the timestamp for display. The row is simply never transitioned, which is why nothing can hang off the transition.)*

#### 5.3.4 · There is also no decline path at all

`zyra_revoke_wali_invite` is the **inviter** withdrawing. A recipient who opens an invite and does not want to accept has no route in the product — they close the screen, and the sender waits seven days to learn nothing.

`wali_invite_declined` therefore needs a decline **action** built beside it. Larger than a notification; recorded here so the notification is not built against a trigger that does not exist.

#### 5.3.5 · Guardian activity beyond invites

| Type | Trigger | To | Tier | Push |
|---|---|---|---|---|
| *(proposed)* `family_review_opened` | A Family Review Period begins | Guardian | **Time-Sensitive** | Yes |
| *(proposed)* `family_review_due` | Review Period nearing expiry | Guardian | **Time-Sensitive** | Yes |
| *(proposed)* `guardian_digest` | Daily or weekly rollup | Guardian | Standard | No |

**Every Guardian-facing notification names which linked Seeker it concerns.** A Guardian may have several. "A Journey ended" without a name is either useless or alarming about the wrong person.

**Guardian involvement is per attempt, not per pair** (OA-ZYRA-162). A returning Guardian keeps their own history; a *different* Guardian on a later attempt sees that a previous Journey existed and how it ended — never the previous Guardian's notes or conversations. Notification bodies must respect that boundary: nothing that would tell a brother what a father was told privately.

**Digest frequency (daily vs weekly) is OPEN** — see §10.

### 5.4 · Introductions — `introductions`

| Type | Trigger | To | Tier | Push |
|---|---|---|---|---|
| *(proposed)* `introduction_received` | A Guardian puts a profile forward | Seeker | Standard | Yes |
| *(proposed)* `introduction_answered` | Seeker passes, saves or considers | that Guardian | Standard | No |

`introduction_answered` is deliberately no-push. A Guardian receiving an instant ping the moment their Seeker declines a suggestion is P2's failure mode in its purest form.

### 5.5 · Subscription — `product_updates`

| Type | Trigger | To | Tier | Push |
|---|---|---|---|---|
| *(proposed)* `entitlement_changed` | Upgrade or downgrade takes effect | Seeker | Standard | No |
| *(proposed)* `credits_low` | Unlock credits nearly exhausted | Seeker | Standard | No |

Both are commercial prompts. They belong under the **off-by-default** consent category, not under product notifications. A credit-balance nudge is marketing wearing a utility hat.

### 5.6 · Security and Account — no category, no toggle

| Type | Trigger | To | Tier | Push |
|---|---|---|---|---|
| *(proposed)* `new_device_signin` | Sign-in from an unrecognised device | account holder | **Time-Sensitive** | Yes |
| *(proposed)* `password_changed` | Credential change | account holder | **Time-Sensitive** | Yes |
| *(proposed)* `account_action` | Suspension, restriction, reinstatement | affected party only | **Time-Sensitive** | Yes |

Not suppressible (R3). A security notice a user can accidentally disable is not a security notice.

`account_action` reaches **the affected party only** — never their Guardian, never the other party in a Journey, and it is the mechanism by which S3 and S4 stay true in practice.

---

## 6 · Delivery, read state, and navigation

### 6.1 · The feed

One chronological list with **category filter chips**, not category tabs. Tabs make the user responsible for checking several places; chips let one glance cover everything and a tap narrow it. Time-Sensitive items pin above the chronological run and leave it when resolved, not when read.

### 6.2 · Read state

| Action | Result |
|---|---|
| Tap a notification | Marks read **and navigates to what it is about** |
| Mark All as Read | Clears every unread in the current filter |
| Select All / bulk mark | Explicit selection, then one action |
| Open the section a notification points at | Marks that section's notifications read (`markSectionRead`) |

**Tap must navigate.** A notification that marks itself read and leaves the user on the list has consumed the signal and delivered nothing. This is currently the single most-felt gap (§9).

### 6.3 · The deep-link problem, and its actual cause

`notifications` carries exactly one relation column — `related_match_id`. Everything is expressed through it or through nothing.

| Type | What it should open | What it can address today |
|---|---|---|
| `new_message` | the conversation, at the message | the match |
| `milestone_proposed` | the milestone, ready to confirm | the match |
| `journey_request` | the request, with its accept action | the match |
| `wali_request` | the Guardian's record | **nothing — `related_match_id` is NULL** |
| `introduction_received` *(proposed)* | the introduction card | nothing |

**The FK is at the wrong grain.** Journeys are now per-*attempt*; Guardian and Introduction notifications are not about a match at all. Adding more nullable FK columns for each new relation is the shape that will eventually need a sixth.

**Proposed:** a `subject_type TEXT` + `subject_id UUID` pair, plus a `deep_link TEXT` the client resolves. Keep `related_match_id` for the existing rows and the cascade it provides; new types populate the generic pair. *(Decision required — §10.)*

---

## 7 · Consent enforcement — the live gap

`create_notification()` is, in full:

```sql
INSERT INTO notifications (user_id, type, title, body, related_match_id)
VALUES (p_user_id, p_type, p_title, p_body, p_related_match_id);
```

It never reads `notification_preferences`. **Every one of the ten callers therefore writes unconditionally, and every category toggle governs nothing on the creation path.**

Today's exposure is bounded: no live type maps to `marketing_emails` or `product_updates`, so no consent-bearing message is being sent against a withdrawal. The `matches_journeys` and `guardian_activity` toggles, however, are already visible in Settings, already persisted, and already ignored — a switch that does nothing is worse than an absent one, because the user believes they have acted.

**Required, and it is R2's whole content:**

```
create_notification(p_user_id, p_type, …)
  → resolve p_type to its category via the §5 mapping
  → category has no toggle (Security/Account)  → INSERT
  → user's latest preference row for it is false → RETURN, write nothing
  → otherwise                                    → INSERT
```

Resolving in `create_notification` rather than in each caller means the ten existing callers need no change and an eleventh cannot forget.

**The mapping belongs in the database**, as a table or a function — not duplicated in Dart. A client-side copy is a second source of truth for a consent decision.

---

## 8 · Retention and content

### 8.1 · Message bodies are being copied out of `messages`

`notify_new_message` writes `left(NEW.content, 140)` into `notifications.body`. The first 140 characters of a private conversation now exist in a second table, with different lifecycle rules and no link back to the message.

Three consequences:

1. **Deletion does not follow.** `notifications` cascades from `matches`, not from `messages`. Delete or redact a message and the copy in the notification survives.
2. **Push will put it on a lock screen.** In a shared household — the norm for much of ZYRA's users — a private message preview is legible to whoever picks up the phone. This is P3's textbook case.
3. **It is more than is needed.** "A new message from *Name*" carries the entire signal.

**Proposed:** stop storing message content in `body`. Store the sender's name; render the preview from `messages` at display time, under the recipient's own RLS. *(Decision required — §10.)*

### 8.2 · Retention policy

No time-based pruning exists. The cascades are correct — delete a profile or a match and its notifications go — so there is no correctness problem, only unbounded growth.

**Proposed:** delete read notifications older than 180 days; delete unread older than 365. Time-Sensitive items are exempt while unresolved.

*Not urgent. Recorded so it is a decision rather than a discovery.*

---

## 9 · State of the build

### Built and live

| | |
|---|---|
| `notifications` table, RLS (select own · update own `read_at` · **no client INSERT at all**) | ✅ |
| `create_notification` SECURITY DEFINER, ten callers | ✅ |
| **Ten** live types in the CHECK constraint | ✅ |
| Bell icon top-right on both shells, unread badge, 20s poll | ✅ |
| Feed screen, mark-read, Mark All as Read, Select All | ✅ |
| Section dots and `markSectionRead` / `markManyRead` | ✅ |
| `notification_preferences` — append-only, five categories, DB-side defaults | ✅ |
| Client `sectionFor` handles all ten types | ✅ |

### Not built

| Gap | Consequence |
|---|---|
| **Preferences do not gate creation** (§7) | Two visible toggles do nothing |
| **Tap does not navigate** (§6.2) | Signal consumed, nothing delivered |
| **Push** — FCM project + APNs key | Blocked on Founder credentials. Every "Push: Yes" above is deferred |
| **No Guardian digest** | P2 unimplementable; Guardians currently receive one type total |
| **No `category` / `priority` columns** | §3 and §4 have nowhere to live |
| **Icons for 7 of 10 types** | `_iconFor` handles three; the rest fall to a generic bell |
| **Family Review notifications** | A Guardian must open the Journey to discover a decision is waiting — a **Time-Sensitive** event with no notification at all |
| **Invite expiry is not an event** (§5.3.3) | No sweep exists, so an unopened invite stays `pending` forever and nothing can notify. **OA-ZYRA-232** |
| **No decline action on invites** (§5.3.4) | A recipient cannot say no; the sender waits out seven days to learn nothing |
| **3 of 4 invite outcomes are silent** (§5.3.1) | Only acceptance notifies, so silence means four different things and re-sending is always the rational move |

### Recommended order

1. **Consent enforcement** (§7) — smallest change, removes a live untruth
2. **`category` + `priority` columns** and the type→category mapping — everything else needs them
3. **Tap-to-navigate**, using `related_match_id` where it works
4. **Family Review notifications** — the highest-value missing event
5. **`zyra_expire_due_wali_invites`** (OA-ZYRA-232) — then `wali_invite_expiring` and `wali_invite_expired` have something to fire from
6. **Subject/deep-link generalisation** (§6.3) — after 3 has shown where the grain actually hurts. `wali_request` needs it: it passes `NULL` for `related_match_id`, so it can never navigate anywhere
7. **Message body change** (§8.1) — before push, not after
8. **Guardian digest** — needs §10's frequency decision
9. **Invite decline action** (§5.3.4), then `wali_invite_declined`
10. **Push** — when credentials exist

Steps 1 to 5 are independently shippable and each leaves the app whole.

---

## 10 · Open decisions

| # | Question | Why it is not decided here |
|---|---|---|
| **D1** | Guardian digest frequency — daily or weekly? | Named as open in OA-ZYRA-161. A judgement about family rhythm, not a technical one |
| **D2** | Generalise to `subject_type` + `subject_id`, or keep adding FK columns? | §6.3. Architectural, and cheaper to settle before the next type than after |
| **D3** | Stop copying message content into `body`? | §8.1. Recommended, but it changes what the feed shows today |
| **D4** | Retention: 180 days read / 365 unread? | §8.2. Numbers are a starting proposal, not a derivation |
| **D5** | Do ZYRA One and Basic differ in what they are notified about? | The tiering question this OA was parked for. **This document assumes they do not** — a notification is information about your own account, and rationing it by tier makes the paid tier better informed about their own life. If that assumption is wrong, §5 needs a tier column |
| **D6** | Guardian invites: tell decline and expiry apart, or merge them as the Journey side does? | §5.3.2. **Recommendation: tell them apart** — the two demand opposite next moves, and merging produces a Seeker who re-invites a relative who already said no. The counter-argument is that "a family member declined to be your Guardian" is a real sensitivity. Not a technical question |

**D5 is the one that matters.** Everything else in this specification survives either answer; §5 does not.

---

## 11 · Change control

- This document is the CURRENT_VERSION. Earlier drafts are archived as `ZYRA_NOTIFICATION_SPECIFICATION_<YYYY-MM-DD>_V<n>.md` and are reference-only.
- §5.2 is **reproduced** from ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md §11. That document remains the source of truth for the Journey map; if they diverge, it wins and this one is corrected.
- §2's safety rules may not be amended through this document. They originate in OA-ZYRA-161 / DR-ZYRA-121 and change only there.
- Adding a notification type requires, in one change: the CHECK constraint, the §5 row, the category mapping, an icon, and a `sectionFor` case. A type that is missing any of the five is a type that will look broken in the feed.
