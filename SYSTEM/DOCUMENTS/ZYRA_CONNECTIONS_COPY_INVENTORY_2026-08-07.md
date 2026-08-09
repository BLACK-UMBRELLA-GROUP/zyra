# ZYRA — Connections Screen: Complete UX Copy Inventory

**Purpose:** independent UX writing review. **No changes proposed here.**
**Date:** 2026-08-07 · **Source:** `lib/screens/connections/connections_screen.dart`
**Method:** extracted from source, not from screenshots — so it includes
dialogs, snackbars and empty states that only appear in specific conditions
and would be missed by capturing the screen.

**Variables** are shown as `{name}`. Every one is real and changes at runtime.

---

## 1. Page title

| Type | Wording | Where | Notes |
|---|---|---|---|
| Page title | **Connections** | Top of screen, left-aligned | Static |

---

## 2. Segment control (three tabs, swipeable)

| Type | Wording | Where | Action |
|---|---|---|---|
| Segment label | **Journeys** | Segment 1 of 3, top | Shows Journeys page |
| Segment label | **Activity** | Segment 2 of 3 | Shows Activity page |
| Segment label | **Introductions** | Segment 3 of 3 | Shows Introductions page |

Each label may carry a **white dot badge** (no text) indicating unseen items.
Accessible label only: `{count} unseen`.

---

## 3. JOURNEYS tab

### Section headings

| Wording | Where | Shown when |
|---|---|---|
| **ACTIVE JOURNEY** | 1st section | Always |
| **JOURNEY QUEUE** | 2nd section | Always |
| **PAUSED JOURNEYS** | 3rd section | Always |
| **ENDED JOURNEYS** | 4th section | Always |

### Empty states (one per section)

| Section | Wording |
|---|---|
| Active Journey | **Once you Start a Journey, it continues here.** |
| Journey Queue | **People you and another Seeker have both liked will appear here, ready for you to start a Journey.** |
| Paused Journeys | **Journeys you or the other Seeker have paused show up here.** |
| Ended Journeys | **When you or the other Seeker ends a Journey, it will appear here.** |

### Card status lines

| Wording | Where | Condition |
|---|---|---|
| **New match** | Queue card | Not yet opened |
| **Conversation open** | Active Journey card | Journey running |
| **Paused by you — conversation closed** | Paused card | You paused it |
| **Paused by them — waiting** | Paused card | They paused it |
| **Ended — cooling period** | Ended card | Within 24h of ending |
| **Ended — Restart available** | Ended card | More than 24h after ending |
| **Suggested by {guardianFirstName}** | Any card | Profile came from a Guardian |

### Buttons

| Type | Wording | Where | Action |
|---|---|---|---|
| Primary | **Start Journey** | Queue card | Opens confirmation dialog |
| Primary (busy) | **Starting…** | Replaces the above | While the request is in flight |
| Primary | **Resume** | Paused card | Lifts the pause |
| Secondary | **View Compatibility** | Journey / queue card | Opens Compatibility page |
| Secondary | **View profile** | Introduction card | Opens the profile |
| Destructive | **End Journey** | Paused card | Ends permanently |
| Icon only | flag icon (no text) | Card corner | Opens report sheet |

---

## 4. Confirmation dialog — Start Journey

| Element | Wording |
|---|---|
| **Title** | **Start Journey with {firstName}?** |
| **Body ¶1** | This begins your Active Journey. A Journey slot is used, and the Pre-Journey Ritual begins with Compatibility Reveal. |
| **Body ¶2** | From this point your linked Guardian — and {firstName}'s — can read the conversation between you. That is deliberate: ZYRA is built for a marriage process with family present, not for private one-to-one messaging. |
| **Body ¶3** | You may only have one Active Journey at a time. |
| **Confirm button** | **Start Journey** |
| **Cancel button** | **Not yet** |

---

## 5. Dialog — Paused Journey

| Element | Wording |
|---|---|
| **Title** | **Paused with {firstName}** |
| **Body** | This Journey is on hold. Resume to pick up exactly where you left off, or End it permanently. |
| **Reassurance line** | Nothing has been lost — you can resume when they finish. |
| **Buttons** | **Resume** · **End Journey** · **Close** |

---

## 6. ACTIVITY tab

### Section headings — all carry live counts

| Wording | Variable |
|---|---|
| **CONSIDERED ({count})** | number of outgoing Considers |
| **SAVED ({count})** | number saved |
| **PASSED ({count})** | number passed |
| **PASSED ({count} — showing last 10)** | shown instead when count > 10 |

### Empty states

| Section | Wording |
|---|---|
| Considered | **Profiles you've Considered but who haven't matched back yet show up here.** |
| Saved | **Profiles you've Saved to revisit later show up here.** |
| Passed | **Profiles you've Passed on show up here for this session.** |

### Card actions

| Wording | Action |
|---|---|
| **Consider** | Express interest |
| **Save** | Save for later |
| **Pass** | Decline |

Buttons shown vary by list: Considered shows Pass · Save; Saved shows Pass ·
Consider; Passed shows Save · Consider.

---

## 7. INTRODUCTIONS tab

| Type | Wording |
|---|---|
| Section heading | **INTRODUCTIONS ({count})** |
| Helper text | **Profiles your Guardian has put forward for you.** |
| Card attribution | **Suggested by {guardianFirstName}** |
| Card button | **View profile** |

---

## 8. Snackbars

| Wording | Trigger |
|---|---|
| **You already have an Active Journey. End or pause it before starting another.** | Starting a second Journey |
| **Thanks — you won't see {firstName} again.** | After reporting / passing |
| **That didn't go through. Please try again.** | Any failed action |
| **This is a demo profile — reporting works on real profiles. (dev)** | Reporting a sample profile |

---

## 9. Compatibility entry point

| Type | Wording |
|---|---|
| Button / link | **Compatibility Unlock** |
| Button | **View Compatibility** |

---

## 10. Notes for the reviewer

Things that are **deliberate** and have a reason behind them, so a critique
should knowingly agree or disagree rather than assume oversight:

1. **"Consider" is the product's word for expressing interest.** It replaced
   "Like" on 2026-07-25 (DR-ZYRA-099). "Passed" likewise replaced
   "Declined". The internal field names still say `likes` and `declined`.
2. **Section headings are ALL CAPS**; card and button text is sentence case.
3. **"Not yet"** as the cancel on Start Journey is intentional — it is not a
   refusal, and "Cancel" would frame it as one.
4. **The Guardian-visibility paragraph is long on purpose.** It is the moment
   a user learns their conversation is readable by family, and it was
   written to be unmissable rather than brief.
5. **Introductions** was renamed from "Guardian Suggestions" on 2026-08-06.
6. **Badges are dots, never numbers**, per the Badge Standard: they signal
   *unseen*, while the heading count signals *unresolved*.
7. **"Journey"** is capitalised throughout as a product noun, as are
   **Seeker**, **Guardian**, **Active Journey** and **Compatibility Unlock**.
