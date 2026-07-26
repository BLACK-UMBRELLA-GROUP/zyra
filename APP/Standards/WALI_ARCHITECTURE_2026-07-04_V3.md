FEATURE NAME
ZYRA — Platform Architecture
Document: Wali Architecture

============================================================
WALI ARCHITECTURE
============================================================

Status: CURRENT_VERSION_V3
Last Updated: 2026-06-28

Change from V2:
  — Compatibility filtering principle added: engine operates
    at Seeker level only, never at Wali level
  — Each Seeker evaluated independently for compatibility,
    hard requirements, and visibility
  — Wali Network aligned to Browse architecture: same
    engine, same rules; only initiator differs

Change from V1:
  — Family Review Period added (new Journey gate mechanic)
  — Pro Seat model clarified: discount follows the existing
    Pro Wali relationship, not the payer/billing account
  — Pricing: £9.99 per new Pro Wali (first Seat per Wali),
    £4.99 per additional Seat on same Pro Wali
  — Subscription rotation safeguards updated (30-day cooldown,
    max 4 reassignments/year, regardless of who initiates unlink)
  — Wali Network: confirmed Seeker cards shown to Walis
  — Wali Network: access requires an active Pro Seat
  — Permissions Model: Can Act updated to reflect Review Period
  — Connections sections confirmed

------------------------------------------------------------
DESIGN PRINCIPLE
------------------------------------------------------------

Support and guidance — not surveillance.

The Wali's role is to support, guide and safeguard the
marriage journey. ZYRA treats the Wali as a first-class
user with a full account, dedicated onboarding, and their
own navigation and dashboard.

The Wali experience is not a web portal or add-on.
It is a complete parallel experience within ZYRA.

Neither the Seeker nor the Wali is assumed to start first.
Both onboarding directions are fully supported and
designed as first-class paths.

------------------------------------------------------------
WHO IS A WALI
------------------------------------------------------------

The Wali is a male guardian who supports a Seeker through
their marriage journey in accordance with Islamic guidance.

Eligible Wali relationships include:
  — Father
  — Grandfather
  — Brother
  — Paternal Uncle
  — Other eligible male guardian per Islamic guidance

Exceptional cases (Seeker has no available Wali) are
governed separately under ZYRA's Islamic Governance
documentation. The core onboarding flow assumes a Wali
is available. Edge cases do not live inside onboarding.

------------------------------------------------------------
WALI ACCOUNT TYPE
------------------------------------------------------------

ZYRA has two primary account types at sign-up:
  — Seeker
  — Wali

The Wali account is entirely separate from a Seeker account.
A person cannot be both a Seeker and a Wali on the same
account.

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites a Basic Wali

  The Seeker completes onboarding and invites their Wali.
  The invitation is sent via the Wali's email or mobile.
  The invitation creates a Basic Wali relationship.

  If the Wali does not have a ZYRA account:
    → They create a Wali account and are auto-linked.

  If the Wali already has a Basic Wali account:
    → Accepting the invitation links them immediately.
    → The Wali must not already hold an active Basic link.
      If they do, they are prompted to upgrade to Pro.

PATH 2 — Seeker Purchases Wali Pro

  The Seeker purchases a Wali Pro Seat for their Wali.
  The invitation explains that a Pro Seat has already been
  purchased and is waiting for the Wali to activate.

  When the Wali signs in or creates their account:
  ZYRA detects the waiting Seat and prompts:
    "A Wali Pro licence has already been purchased for you.
     Would you like to activate it?"

  Once accepted, the Pro Seat is attached to that
  Wali–Seeker relationship.

PATH 3 — Wali Starts First

  A parent or guardian organises everything before the
  Seeker joins. This reflects how many Muslim families
  naturally operate and is a first-class path.

  1. Wali creates a Wali account.
  2. Wali purchases a Pro Seat — or remains on Basic.
  3. Wali generates an invitation for their son or daughter.
  4. Seeker joins using that invitation link.
  5. Both accounts are automatically linked.

------------------------------------------------------------
LINKING — HOW ACCOUNTS CONNECT
------------------------------------------------------------

Whether the Seeker starts or the Wali starts, the end
result is the same linked state.

Accounts are linked using secure identity verification:
  — Verified email
  — Verified mobile number
  — Internal invitation token (generated per invite)

Users never manually search for each other.
The invitation token ensures the correct accounts
are linked automatically on account creation or sign-in.

------------------------------------------------------------
WALI TIER RULES
------------------------------------------------------------

The Wali account does not itself become Pro or Premium.
Tiers are applied at the relationship level via Pro Seats.
Each active Pro Seat supports one linked Seeker.

WALI BASIC (Free)

  Every Wali account includes one free Basic relationship.
  A Wali account may only hold one active Basic relationship
  at any time.

  Example:
    Father
    ✓ Daughter A — Basic (free, 1 of 1 allowed)

  If the father wants to supervise a second Seeker
  simultaneously, he must purchase a Pro Seat for that
  additional relationship.

  This prevents one free Basic account from supporting
  unlimited Seekers.

WALI PRO SEAT (per linked Seeker)

  A Pro Seat is purchased per Seeker relationship.
  A Wali may purchase as many Pro Seats as required.
  Each Seat is independent and supports one Seeker.

  PRICING RULE:
    The discount follows the existing Pro Wali relationship,
    not the billing account or who is paying.

    First Pro Seat for a given Wali:        £9.99 / month
    Additional Seats for the SAME Wali:     £4.99 / month each

    A brand-new Pro Wali always costs £9.99.
    The £4.99 rate is ONLY available when adding another
    Seeker to a Wali who already holds an active Pro Seat.

  This prevents a loophole where a user creates multiple
  new Pro Walis at the discounted rate. The discount
  rewards expanding an existing Pro Wali relationship,
  not creating new ones.

  EXAMPLES:

  Dad (existing Pro Wali):
    Son       → £9.99/month  (first Pro Seat for Dad)
    Daughter  → £4.99/month  (additional Seat — Dad is already Pro)
    Daughter  → £4.99/month  (additional Seat — Dad is already Pro)

  Mum (separate Wali):
    First Pro Seat → £9.99/month  (Mum is a new Pro Wali)

  Total (Dad 3 Seekers + Mum 1 Seeker):
    Dad:  £9.99 + £4.99 + £4.99 = £19.97/month
    Mum:  £9.99/month
    Combined: £29.96/month

  SEEKER'S VIEW — MY WALI PAGE:

  Dad
  ✓ Wali Pro
  [Manage]
  Add another Pro Seat for Dad — £4.99/month
  (Discounted because Dad already has an active Pro Seat)

  Mum
  ✓ Wali Basic
  Upgrade to Wali Pro — £9.99/month
  (Full price because Mum has no existing Pro Seat)

WHO PAYS FOR PRO

  Either the Seeker or the Wali can pay for a Pro Seat.
  The Seat is attached to the Wali–Seeker relationship
  regardless of who purchased it.
  The pricing tier (£9.99 or £4.99) is determined by the
  Wali's existing Pro status, not by who pays.

------------------------------------------------------------
WALI PERMISSIONS MODEL
------------------------------------------------------------

Can See:
  — Seeker's public profile (as it appears to others)
  — Messages between Seeker and their match (from start)
  — Journey stage and progression status
  — Milestone events (Introduction accepted, Stage 2, etc.)
  — Safety alerts and notifications
  — Family introduction messages (when invited)

Cannot See:
  — Chapter 3 (Values) answers
  — Chapter 4 (Preferences / compatibility settings)
    Compatibility settings remain private to Seeker only.
  — Match list / Browse activity

Can Act:
  — Continue or Pause Journey during the Family Review Period
  — Accept or decline Family Introduction Requests (Pro only)
  — Send messages within family introduction context
  — Raise a concern or flag to ZYRA support

------------------------------------------------------------
WALI RESPONSIBILITIES
------------------------------------------------------------

  ✓ Viewing the progress of each Journey
  ✓ Viewing messages between Seeker and their match
  ✓ Receiving notifications at each Family Review Period
  ✓ Choosing to Continue or Pause during the Review Period
  ✓ Participating in family introductions (Pro)
  ✓ Joining conversations when appropriate
  ✓ Receiving safety notifications when necessary
  ✓ Helping ensure the process remains respectful
    and family-oriented

The Wali does not:
  — See Chapter 3 (Values) or Chapter 4 (Preferences) answers
  — Control who the Seeker browses or expresses interest in
  — Accept on behalf of the Seeker

------------------------------------------------------------
FAMILY REVIEW PERIOD
------------------------------------------------------------

After both Seekers complete a Journey stage, the next stage
does not unlock immediately.

Instead, the Journey enters a 48-hour Family Review Period.

WHAT HAPPENS DURING THE REVIEW PERIOD

  1. Both Walis receive a notification to review the
     completed stage.

  2. Each Wali may:
       ✅ Continue  — explicitly confirms readiness
       ❌ Pause     — halts progression until resolved

  3. If neither Wali raises a concern within 48 hours:
       → The Journey automatically continues.

PURPOSE

  The Family Review Period is not a permission gate.
  It is a deliberate pause that:

  — Encourages family awareness at each stage
  — Gives Walis meaningful involvement without veto power
    over every micro-decision
  — Prevents a Journey from moving too fast

  Silence is treated as:
  "The family had the opportunity to review this stage."
  It is not an explicit approval.

  This respects the Wali's role while preventing inactive
  accounts from blocking progress indefinitely.

PAUSE BEHAVIOUR

  If a Wali selects Pause:
  — The Journey pauses immediately.
  — The matched Seekers are notified that the Journey
    has been paused for family review.
  — ZYRA support is available to assist if the pause
    cannot be resolved between both families.

  Pause does not mean rejection.
  It means the family needs more time.

------------------------------------------------------------
SUBSCRIPTION MODEL
------------------------------------------------------------

WALI BASIC
  Cost:      Free
  Limit:     1 active Seeker relationship (hard cap)

WALI PRO SEAT
  Cost:      £9.99/month — first Pro Seat for a given Wali
             £4.99/month — each additional Seat, same Wali
  Limit:     None — purchase as many Seats as needed
  Who pays:  Either the Seeker or the Wali
  Discount:  Follows the Wali relationship, not the payer

PRO SEAT REASSIGNMENT SAFEGUARDS

  To prevent a Pro Seat rotating between Seekers:

  1. Trigger — regardless of who initiates the unlink
     The safeguards apply whenever a Pro Seat becomes
     unassigned, regardless of who initiated the removal.
     This covers:
       — Wali removes Seeker
       — Seeker removes Wali
       — Seeker changes Wali
       — Mutual unlink

  2. Cooldown on reassignment
     A 30-day cooldown applies when a Pro Seat becomes
     unassigned. The Seat cannot be reassigned until
     the cooldown elapses.

  3. Reassignment frequency cap
     A Pro Seat may only be reassigned a maximum of
     4 times per calendar year.

  4. Active Journey block
     Reassignment is blocked if the current linked Seeker
     is in an Active Journey. Reassignment only becomes
     available once that Journey has ended or been
     formally closed.

  These safeguards allow genuine family transitions
  (one child's journey ends, another begins) while
  preventing a single Pro Seat from supporting
  multiple active Seekers in rotation.

  Basic links: The 1-Seeker cap is strictly enforced.
  Basic cannot rotate or be reassigned without the same
  cooldown and frequency safeguards.

SEEKER SUBSCRIPTION SPONSORSHIP

  A Wali may optionally pay for the linked Seeker's
  Seeker subscription. This is separate from the Wali Seat.

  Example: A father holds a Pro Seat AND pays for his
  daughter's Seeker Premium subscription.

  Two independent billing concepts:
    1. Wali Pro Seat (£9.99 first / £4.99 additional per month)
    2. Seeker subscription — paid by Seeker or by Wali

------------------------------------------------------------
WALI SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Wali (Basic):
  [ Invite Your Wali ] → ZYRA sends SMS/email (Basic)
  → [ Wali Invitation Landing ] → [ Create Account ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]

Path 2 — Seeker purchases Wali Pro:
  [ Invite Your Wali ] → Seeker pays → ZYRA sends SMS/email (Pro)
  → [ Wali Invitation Landing ] → [ Create / Sign In ]
  → Prompt: "A Pro Seat is waiting — activate it?"
  → [ Wali Onboarding ] → [ Wali Dashboard ]

Path 3 — Wali starts first:
  [ Wali Sign Up ] → [ Choose Tier: Basic / Pro ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]
  → [ Invite Seeker ] → Seeker receives SMS/email
  → [ Seeker Invitation Landing ] → Seeker onboarding
  → Accounts linked

------------------------------------------------------------
CONNECTIONS SECTIONS
------------------------------------------------------------

The Connections area is structured as follows:

  — Declined
  — Review
  — Family Introductions
  — Likes
  — Matches

Family Introductions is a dedicated section.
It is not merged into Review.
Consolidation can be considered once the full app
is designed and usage patterns are understood.

------------------------------------------------------------
WALI NAVIGATION
------------------------------------------------------------

Wali accounts use a fixed 4-tab navigation:
  Dashboard · Seekers · Network · Profile

  — No Universal Toggle (Seeker-only mechanic)
  — All tabs equal size, all icons 18px
  — Floating glass pill: same design as Seeker nav

Network tab:
  — Only accessible with at least one active Pro Seat
  — Basic Wali tapping Network → upgrade screen

------------------------------------------------------------
WALI NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-06-28

WHAT THE WALI NETWORK IS

The Wali Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to verified Walis with an active Pro Seat.

WHAT IS DISPLAYED

The cards shown in the Network are Seeker profile cards.
The Wali is browsing on behalf of their linked Seeker.

The Wali cannot edit or customise what is shown.
Cards are 100% system-controlled.

No free-text introductions.
No biographies.
No manually added information.

Reason:
Free text creates a privacy loophole. A Wali could
reveal information that ZYRA intentionally hides
through progressive disclosure, including:
  — Occupation
  — Education
  — Religious practice
  — Previous marriage history
  — Compatibility answers

Only ZYRA determines what is displayed on each card.

CARD CONTENTS (system-controlled)

  — Seeker initial (e.g. K.)
  — Age
  — City
  — Wali relationship ("Guided by his father")
  — Verified Wali badge

No Wali tier shown on cards.
Access to Network already requires a Pro Seat.

SEEKER CONSENT

Because the Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Wali, they agree to Terms &
Conditions explaining:
  — What their linked Wali can view
  — What information is displayed to other verified Walis
    in the Network
  — That their profile card becomes visible in the Network
    once a Wali is linked

Consent is collected during the Wali linking flow.

WALI NETWORK FLOW

1. Wali A discovers Seeker B's system-controlled card
   in the Network Discover feed.

2. Wali A sends a Family Introduction Request to Wali B.

3. Wali B reviews Seeker A's system-controlled card.

4. Wali B accepts or declines.

5. If both Walis agree:
   The introduction is presented to both Seekers
   independently.

6. Each Seeker independently accepts or declines.

7. If both Seekers accept:
   The standard ZYRA Journey begins.

Key principle:
Walis agree that an introduction is worth presenting.
They do not accept on behalf of Seekers.
Seeker consent is always required before a Journey begins.

INTRODUCTION LOGIC — MULTIPLE SEEKERS

When a Wali taps Introduce from a Seeker card:

  If the Wali has one eligible Seeker (gender-matched):
    → Automatically sends the introduction on their behalf.
    → No selection prompt.
    → "This introduction will be sent on behalf of [Name]."

  If the Wali has two or more eligible Seekers:
    → A selection screen appears.
    → The Wali selects which daughter (or son) this
      introduction is for.
    → Maximum one per introduction request.

  Gender matching is automatic.
  A Wali with both a son and a daughter browsing male
  Seeker cards will only see the introduction sent
  on behalf of the daughter.

NETWORK TABS

  Discover  — Wali browses system-controlled Seeker cards
  Requests  — Incoming Family Introduction Requests

------------------------------------------------------------
WALI NETWORK — COMPATIBILITY FILTERING PRINCIPLE
------------------------------------------------------------

RULE: The compatibility engine operates at the Seeker level.
It never operates at the Wali level.

Each Seeker linked to a Wali is evaluated independently
for compatibility, hard requirements, and visibility.
A Seeker's profile never affects another Seeker's visibility
simply because they share the same Wali.

EXAMPLE

  Wali Ahmed is linked to:
    Son A — smokes
    Son B — does not smoke

  Another Seeker has a Hard Requirement:
    🚫 Never show anyone who smokes.

  Incorrect (Wali-level filtering):
    Wali Ahmed disappears from the Network entirely
    because Son A does not satisfy the requirement.

  Correct (Seeker-level filtering):
    Son A → ❌ Fails Hard Requirement → Not shown.
    Son B → ✅ Passes Hard Requirement → Shown.
    Wali Ahmed remains visible in the Network,
    showing only Son B's card.

CONSEQUENCES

  — A Wali with multiple Seekers may have different numbers
    of Seeker rows visible to different Network viewers.

  — A Wali card may show 2 Seekers to one viewer and
    1 Seeker to another, depending on compatibility.

  — If none of a Wali's linked Seekers pass compatibility,
    the Wali card does not appear at all for that viewer.

  — Each Seeker card in the Network has independent:
      · Compatibility filtering
      · Hard Requirement filtering
      · Visibility
      · Family Introduction requests

ALIGNMENT WITH BROWSE

  The Wali Network uses the same compatibility engine,
  hard requirement rules, and visibility logic as Browse.

  The only architectural difference between Browse and
  the Wali Network is who initiates the introduction:

    Browse:        Seeker initiates.
    Wali Network:  Wali initiates on behalf of their Seeker.

  The underlying engine is identical.

------------------------------------------------------------
EXCEPTIONAL CASES (DEFERRED)
------------------------------------------------------------

The following scenarios are not handled in core onboarding.
Deferred to ZYRA's Islamic Governance document:

  — Seeker has no living male guardian
  — Seeker is a revert with no Muslim male family member
  — Dispute over who has Wali authority
  — Wali becomes unavailable mid-journey
  — Female guardian acting in Wali capacity in exceptional
    circumstances
