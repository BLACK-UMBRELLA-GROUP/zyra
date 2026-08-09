FEATURE NAME
Compatibility Unlock / Compatibility Unlock Plus

Group: 4 — Page Responsibilities

============================================================
STATUS
============================================================

Founder approved 2026-08-03, amended 2026-08-04. This document
supersedes the 2026-07-12 version, which was written under the
name "Profile Unlock" and carried different pricing.

Renamed, repriced and given a permanence rule in one decision
(2026-08-03). Then, on 2026-08-04, two further Founder
decisions:

  1. Green / Amber / Red MOVED from Unlock up to Plus, to widen
     the gap between the tiers.
  2. The compatibility screen rebuilt as ONE page with two
     stacked sections, replacing two swipeable tabs.

Every change below is Founder approved and implemented in the
app; nothing here is proposed.

============================================================
SUMMARY
============================================================

Purpose:
Provides deeper compatibility insight before progressing
further with a profile. Helps users make better-informed
marriage decisions without revealing private answers.

------------------------------------------------------------
Feature Name — RESOLVED
------------------------------------------------------------

The 2026-07-12 version listed three candidate names and marked
the decision pending. It is now settled:

  Compatibility Unlock
  Compatibility Unlock Plus

Rejected: "Profile Unlock", "Compatibility Preview",
"Insight Unlock".

Reasoning (Founder, 2026-08-03): the old name created an
inconsistency with the screen it opened.

  Profile Unlock        -> View Compatibility     two features?
  Compatibility Unlock  -> View Compatibility     one idea, twice

------------------------------------------------------------
Availability
------------------------------------------------------------

Seeker only (ZYRA Basic and ZYRA One).
A Guardian cannot purchase or use a Compatibility Unlock.

Ownership is NOT a subscription tier. A ZYRA Basic Seeker and a
ZYRA One Seeker can both hold unlocks — the plan changes how
many come free, not whether they can be held at all.

------------------------------------------------------------
Usage Rules
------------------------------------------------------------

• Cannot be used while swiping.
• Available from any Connections card — Considered, Saved OR
  Passed.

  CHANGED 2026-08-03, Founder approved. The 2026-07-12 version
  said "cannot be used on passed profiles" and required a
  profile to be Saved or Considered first.

  Reversed because the card already offers Consider and Save
  from a Passed state. Someone reconsidering a Pass is exactly
  who a compatibility score is useful to — offering the
  reconsideration while withholding the thing that would inform
  it was backwards, and it withheld a purchase from the moment
  a user was most likely to make one.

PERMANENCE — Founder approved 2026-08-03:

• A profile may only be Compatibility Unlocked ONCE per user,
  per tier.
• Once unlocked, that compatibility stays permanently
  accessible to that user.
• Returning to the same profile must NEVER consume another
  unlock.
• The action button changes permanently from
  "Compatibility Unlock" to "View Compatibility".
• The same behaviour applies to Compatibility Unlock Plus. The
  Plus tier affects the DEPTH of information shown, not whether
  a profile can be unlocked again.

Enforced in the database, not only in the app: a unique index
on (unlocker_id, unlocked_id, unlock_type) makes a second
charge impossible even if a client asks for one.

------------------------------------------------------------
Compatibility Unlock — the overall percentage, and nothing else
------------------------------------------------------------

CHANGED 2026-08-04, Founder approved. Green / Amber / Red
counts have MOVED OUT of this tier and up into Plus.

  Founder: "unlock should only be % — no green, yellow or red,
  so it gives unlock plus more value."

Reasoning: the two tiers were only £1 apart in substance. Unlock
gave a number and three counts; Plus added six bars. Moving the
counts up widens the gap the £2 price difference is meant to
represent, and leaves Unlock as the single cleanest thing in the
app to explain — one number.

Displays:
• Overall Compatibility %

Example:
  Overall Compatibility: 81%

Privacy protection — does NOT reveal:
• Actual onboarding answers
• Exact responses
• Private profile information
• Which specific questions caused a Green, Amber or Red

------------------------------------------------------------
Compatibility Unlock Plus
------------------------------------------------------------

Everything in Compatibility Unlock, plus the colour tallies and
a category-level breakdown.

Displays:
• Overall Compatibility %          (as per Unlock)
• Green / Amber / Red counts       (moved here 2026-08-04)
• Category-level percentages

Green / Amber / Red logic:
  Generated from the user's own onboarding preferences.
  Example — Smoking Preference:
    Green = Non-smoker
    Amber = Occasionally
    Red   = Smoker

Categories (pending final confirmation):
• Lifestyle
• Work & Education
• Family Values
• Marriage Goals
• Personality
• Deen

Example:
  Overall Compatibility: 81%
  Green:  62
  Amber:  19
  Red:     7

  Lifestyle ............ 74%
  Work & Education ..... 78%
  Family Values ........ 85%
  Marriage Goals ....... 88%
  Personality .......... 69%
  Deen ................. 92%

Same privacy protection. Only category-level percentages are
shown.

------------------------------------------------------------
WHY THE WORKED EXAMPLES CHANGED — 2026-08-04
------------------------------------------------------------

The previous version gave 81% under Unlock and 89% under Plus.
That is the same two people, so it cannot be both. The error
survived because the app showed the two tiers on separate
swipeable tabs and they were never on screen together; the
single-page rebuild put them one above the other and it was
obvious in the first mockup.

There is now ONE overall score, 81%, and the supporting figures
are derived so the arithmetic holds if anyone checks it:

  counts      (62 + 19 x 0.5) / 88  = 81.25%
  categories  (74+78+85+88+69+92)/6 = 81

ASSUMPTION, NOT A RATIFIED RULE: that arithmetic assumes
green = 1, amber = 0.5, red = 0, and equal weight per category.
The real scoring methodology is still open (see OPEN, below).
This is written down so whoever defines it knows what the
sample figures were built to satisfy — and so that changing the
methodology means changing these examples deliberately, rather
than leaving a second contradiction behind.

============================================================
PRICING — Founder approved 2026-08-03
============================================================

| Tier                      | Quantity | Price  | Saving |
|---------------------------|----------|--------|--------|
| Compatibility Unlock      | 1        | £1.99  | —      |
| Compatibility Unlock      | 5        | £7.99  | 20%    |
| Compatibility Unlock Plus | 1        | £2.99  | —      |
| Compatibility Unlock Plus | 5        | £9.99  | 33%    |

SUPERSEDES the 2026-07-12 prices (£0.99 / £2.99 and
£1.99 / £4.99). BUSINESS/ZYRA PRICING/Summary.md is updated to
match.

Savings are exact, not rounded up:
  Unlock  5 x £1.99 = £9.95 -> £7.99 saves 19.7%, shown as 20%
  Plus    5 x £2.99 = £14.95 -> £9.99 saves 33.2%, shown as 33%

Pricing strategy (Founder):
The two five-packs sit £2 apart deliberately. The intended
reader thought is "for another £2 I get the better version" —
price anchoring that makes Plus the smarter purchase while
leaving Unlock as a credible entry point.

Plus carries a BEST VALUE badge. Unlock does not. Badging both
would flatten the ladder the pricing exists to create.

------------------------------------------------------------
Included with ZYRA One
------------------------------------------------------------

A ZYRA One Seeker receives 3 free Compatibility Unlock Plus
credits (Founder approved 2026-08-03).

Shown as its own line in the balance, itemised separately from
purchased credits — "3 included with ZYRA One" and "2
purchased" are different facts, and a single total hides which.

This is NEW. The 2026-07-12 version mentioned only "Profile
Unlock Plus on Active Journey creation", which is a separate
grant and is not the same thing.

============================================================
UI BEHAVIOUR
============================================================

ON THE PROFILE CARD (Connections):
  One button, not two.
    Locked    "Compatibility Unlock"
    Unlocked  "View Compatibility"
  Either tier flips the label — both lead to the same screen
  and the same idea.

ON THE COMPATIBILITY SCREEN — REBUILT 2026-08-04:

Founder: "the compatibility unlock pages... one page instead."

SUPERSEDES the two swipeable tabs (Unlock / Unlock+) described
in the previous version. A swipe between two tabs says "these
are alternatives, pick one" — but Plus is a SUPERSET of Unlock,
so the gesture taught the wrong relationship and hid half the
offer behind a swipe the user had no reason to make.

  ONE page. ONE card. TWO stacked sections:

    OVERALL      the headline number    -> Compatibility Unlock
    THE DETAIL   what's inside it       -> Compatibility Unlock+

Layout rules, each Founder-chosen from mockups:

| Element        | Decision                                    |
|----------------|---------------------------------------------|
| Balance        | Plain words, top-right of each section       |
|                | header: "5 left" / "none left". No balance   |
|                | card, no subheading.                         |
| The plus       | An ICON, or welded to the word — never the   |
|                | word "Plus". Button reads                    |
|                | "Unlock Compatibility+" with NO space, so    |
|                | the glyph cannot break to its own line.      |
| Locked detail  | A padlock on EVERY ROW. The buyer sees the   |
|                | six named categories and the three colour    |
|                | tallies, with every value withheld.          |
| Unlocked state | Open padlock + the word "Unlocked". Nothing  |
|                | else.                                        |
| Zero balance   | Button disabled, not relabelled. The corner  |
|                | says why; the foot link says what to do.     |
| Buy            | "Buy more unlocks" as a TEXT LINK at the     |
|                | foot. "Buy unlocks" if they have never held  |
|                | any. Not a third button.                     |
| BEST VALUE     | NOT on this page. Prices are not either.     |
|                | Both belong on the buy page, where there is  |
|                | something to compare them against.           |

Plus unlocks Overall too. The spec defines Plus as "everything
in Compatibility Unlock, plus...", so buying Plus must never
leave the overall number still locked — charging again for a
part already bought would break the permanence rule the unique
index exists to enforce.

REMOVED 2026-08-04: "Unlocked — revisit any time, free".
Founder: "I don't like the text 'you can revisit anytime
free' — remove that." Consistent with the permanence line
rejected the day before, and for the same reason: the app was
explaining its own generosity.

Rejected 2026-08-03: a permanence line beside the price.
Founder: "the user will know each unlock is permanent."

FREE-CREDIT ITEMISATION MOVED. The previous version required
ZYRA One's 3 free credits to be shown as their own line,
separate from purchased ones. This screen now folds them into
one plain count, because the Founder replaced the balance card
with a corner count. Where a credit came from is a
purchase-page question, not a should-I-spend-one question — the
itemisation requirement now belongs to the buy page.

============================================================
NOT YET REAL
============================================================

Recorded so nobody mistakes the screen for a working feature:

• THE SCORE. Compatibility is computed from onboarding_answers,
  which has zero rows for real users, and the Green/Amber/Red
  scoring method is still undefined. Every figure currently on
  screen is transcribed from this document's worked examples.

  ** NOTHING ON SCREEN NOW SAYS SO. ** The gold SAMPLE banner
  was removed 2026-08-04 at the Founder's instruction ("remove
  the yellow sample logo"). The buy link still refuses honestly
  — "Payments are not built yet, nothing has been charged" —
  but a screenshot of "81% overall" no longer carries a warning
  with it. Flagged, not overridden: this is a Founder decision
  about his own build. It becomes a real risk the first time
  this screen is shown to anyone outside it, and should be
  revisited before any demo, investor deck or TestFlight.
• THE PAYMENT. There is no payment SDK in the project — no
  in_app_purchase, no StoreKit, no RevenueCat, no Stripe.
  Unlocking costs nothing today.
• THE UNLOCK RECORD IS REAL. profile_unlocks rows are written
  and read, RLS-scoped to the caller, with the once-only rule
  enforced by a unique index. When payments land, the purchase
  gates the insert — the insert itself does not change.

============================================================
OPEN
============================================================

• Define the complete Green / Amber / Red scoring methodology.
  When it is defined, update the worked examples above — they
  currently assume green=1, amber=0.5, red=0 and equal category
  weighting purely so the sample arithmetic is self-consistent.
• Confirm the final Plus category set.
• Build the BUY page. It now owns the prices, the BEST VALUE
  badge, and the free-vs-purchased credit itemisation — three
  things this document requires and no screen currently shows.
• Restore some on-screen marker that the figures are not real,
  in a form the Founder accepts (the gold banner was rejected).
• Decide whether unused purchased unlocks expire or carry
  forward indefinitely.
• Persist Chapter 2/3/4 onboarding answers, without which no
  score can be computed at all
  (see ZYRA_ONBOARDING_PERSISTENCE_AUDIT_CURRENT_VERSION_V1).

CLOSED by this version: the feature name, the pricing, the
permanence rule, and the "what does Saved/Considered mean for
eligibility" question.
