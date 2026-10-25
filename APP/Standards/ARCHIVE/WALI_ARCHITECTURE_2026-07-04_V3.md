FEATURE NAME
ZYRA — Platform Architecture
Document: Guardian Architecture

============================================================
GUARDIAN ARCHITECTURE
============================================================

Status: CURRENT_VERSION_V3
Last Updated: 2026-06-28

Change from V2:
  — Compatibility filtering principle added: engine operates
    at Seeker level only, never at Guardian level
  — Each Seeker evaluated independently for compatibility,
    hard requirements, and visibility
  — Guardian Network aligned to Browse architecture: same
    engine, same rules; only initiator differs

Change from V1:
  — Family Review Period added (new Journey gate mechanic)
  — Pro Seat model clarified: discount follows the existing
    Pro Guardian relationship, not the payer/billing account
  — Pricing: £9.99 per new Pro Guardian (first Seat per Guardian),
    £4.99 per additional Seat on same Pro Guardian
  — Subscription rotation safeguards updated (30-day cooldown,
    max 4 reassignments/year, regardless of who initiates unlink)
  — Guardian Network: confirmed Seeker cards shown to Guardians
  — Guardian Network: access requires an active Pro Seat
  — Permissions Model: Can Act updated to reflect Review Period
  — Connections sections confirmed

------------------------------------------------------------
DESIGN PRINCIPLE
------------------------------------------------------------

Support and guidance — not surveillance.

The Guardian's role is to support, guide and safeguard the
marriage journey. ZYRA treats the Guardian as a first-class
user with a full account, dedicated onboarding, and their
own navigation and dashboard.

The Guardian experience is not a web portal or add-on.
It is a complete parallel experience within ZYRA.

Neither the Seeker nor the Guardian is assumed to start first.
Both onboarding directions are fully supported and
designed as first-class paths.

------------------------------------------------------------
WHO IS A GUARDIAN
------------------------------------------------------------

The Guardian is a male guardian who supports a Seeker through
their marriage journey in accordance with Islamic guidance.

Eligible Guardian relationships include:
  — Father
  — Grandfather
  — Brother
  — Paternal Uncle
  — Other eligible male guardian per Islamic guidance

Exceptional cases (Seeker has no available Guardian) are
governed separately under ZYRA's Islamic Governance
documentation. The core onboarding flow assumes a Guardian
is available. Edge cases do not live inside onboarding.

------------------------------------------------------------
GUARDIAN ACCOUNT TYPE
------------------------------------------------------------

ZYRA has two primary account types at sign-up:
  — Seeker
  — Guardian

The Guardian account is entirely separate from a Seeker account.
A person cannot be both a Seeker and a Guardian on the same
account.

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites a Basic Guardian

  The Seeker completes onboarding and invites their Guardian.
  The invitation is sent via the Guardian's email or mobile.
  The invitation creates a Basic Guardian relationship.

  If the Guardian does not have a ZYRA account:
    → They create a Guardian account and are auto-linked.

  If the Guardian already has a Basic Guardian account:
    → Accepting the invitation links them immediately.
    → The Guardian must not already hold an active Basic link.
      If they do, they are prompted to upgrade to Pro.

PATH 2 — Seeker Purchases Guardian Pro

  The Seeker purchases a Guardian Pro Seat for their Guardian.
  The invitation explains that a Pro Seat has already been
  purchased and is waiting for the Guardian to activate.

  When the Guardian signs in or creates their account:
  ZYRA detects the waiting Seat and prompts:
    "A Guardian Pro licence has already been purchased for you.
     Would you like to activate it?"

  Once accepted, the Pro Seat is attached to that
  Guardian–Seeker relationship.

PATH 3 — Guardian Starts First

  A parent or guardian organises everything before the
  Seeker joins. This reflects how many Muslim families
  naturally operate and is a first-class path.

  1. Guardian creates a Guardian account.
  2. Guardian purchases a Pro Seat — or remains on Basic.
  3. Guardian generates an invitation for their son or daughter.
  4. Seeker joins using that invitation link.
  5. Both accounts are automatically linked.

------------------------------------------------------------
LINKING — HOW ACCOUNTS CONNECT
------------------------------------------------------------

Whether the Seeker starts or the Guardian starts, the end
result is the same linked state.

Accounts are linked using secure identity verification:
  — Verified email
  — Verified mobile number
  — Internal invitation token (generated per invite)

Users never manually search for each other.
The invitation token ensures the correct accounts
are linked automatically on account creation or sign-in.

------------------------------------------------------------
GUARDIAN TIER RULES
------------------------------------------------------------

The Guardian account does not itself become Pro or Premium.
Tiers are applied at the relationship level via Pro Seats.
Each active Pro Seat supports one linked Seeker.

GUARDIAN BASIC (Free)

  Every Guardian account includes one free Basic relationship.
  A Guardian account may only hold one active Basic relationship
  at any time.

  Example:
    Father
    ✓ Daughter A — Basic (free, 1 of 1 allowed)

  If the father wants to supervise a second Seeker
  simultaneously, he must purchase a Pro Seat for that
  additional relationship.

  This prevents one free Basic account from supporting
  unlimited Seekers.

GUARDIAN PRO SEAT (per linked Seeker)

  A Pro Seat is purchased per Seeker relationship.
  A Guardian may purchase as many Pro Seats as required.
  Each Seat is independent and supports one Seeker.

  PRICING RULE:
    The discount follows the existing Pro Guardian relationship,
    not the billing account or who is paying.

    First Pro Seat for a given Guardian:        £9.99 / month
    Additional Seats for the SAME Guardian:     £4.99 / month each

    A brand-new Pro Guardian always costs £9.99.
    The £4.99 rate is ONLY available when adding another
    Seeker to a Guardian who already holds an active Pro Seat.

  This prevents a loophole where a user creates multiple
  new Pro Guardians at the discounted rate. The discount
  rewards expanding an existing Pro Guardian relationship,
  not creating new ones.

  EXAMPLES:

  Dad (existing Pro Guardian):
    Son       → £9.99/month  (first Pro Seat for Dad)
    Daughter  → £4.99/month  (additional Seat — Dad is already Pro)
    Daughter  → £4.99/month  (additional Seat — Dad is already Pro)

  Mum (separate Guardian):
    First Pro Seat → £9.99/month  (Mum is a new Pro Guardian)

  Total (Dad 3 Seekers + Mum 1 Seeker):
    Dad:  £9.99 + £4.99 + £4.99 = £19.97/month
    Mum:  £9.99/month
    Combined: £29.96/month

  SEEKER'S VIEW — MY GUARDIAN PAGE:

  Dad
  ✓ Guardian Pro
  [Manage]
  Add another Pro Seat for Dad — £4.99/month
  (Discounted because Dad already has an active Pro Seat)

  Mum
  ✓ Guardian Basic
  Upgrade to Guardian Pro — £9.99/month
  (Full price because Mum has no existing Pro Seat)

WHO PAYS FOR PRO

  Either the Seeker or the Guardian can pay for a Pro Seat.
  The Seat is attached to the Guardian–Seeker relationship
  regardless of who purchased it.
  The pricing tier (£9.99 or £4.99) is determined by the
  Guardian's existing Pro status, not by who pays.

------------------------------------------------------------
GUARDIAN PERMISSIONS MODEL
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
GUARDIAN RESPONSIBILITIES
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

The Guardian does not:
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

  1. Both Guardians receive a notification to review the
     completed stage.

  2. Each Guardian may:
       ✅ Continue  — explicitly confirms readiness
       ❌ Pause     — halts progression until resolved

  3. If neither Guardian raises a concern within 48 hours:
       → The Journey automatically continues.

PURPOSE

  The Family Review Period is not a permission gate.
  It is a deliberate pause that:

  — Encourages family awareness at each stage
  — Gives Guardians meaningful involvement without veto power
    over every micro-decision
  — Prevents a Journey from moving too fast

  Silence is treated as:
  "The family had the opportunity to review this stage."
  It is not an explicit approval.

  This respects the Guardian's role while preventing inactive
  accounts from blocking progress indefinitely.

PAUSE BEHAVIOUR

  If a Guardian selects Pause:
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

GUARDIAN BASIC
  Cost:      Free
  Limit:     1 active Seeker relationship (hard cap)

GUARDIAN PRO SEAT
  Cost:      £9.99/month — first Pro Seat for a given Guardian
             £4.99/month — each additional Seat, same Guardian
  Limit:     None — purchase as many Seats as needed
  Who pays:  Either the Seeker or the Guardian
  Discount:  Follows the Guardian relationship, not the payer

PRO SEAT REASSIGNMENT SAFEGUARDS

  To prevent a Pro Seat rotating between Seekers:

  1. Trigger — regardless of who initiates the unlink
     The safeguards apply whenever a Pro Seat becomes
     unassigned, regardless of who initiated the removal.
     This covers:
       — Guardian removes Seeker
       — Seeker removes Guardian
       — Seeker changes Guardian
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

  A Guardian may optionally pay for the linked Seeker's
  Seeker subscription. This is separate from the Guardian Seat.

  Example: A father holds a Pro Seat AND pays for his
  daughter's Seeker Premium subscription.

  Two independent billing concepts:
    1. Guardian Pro Seat (£9.99 first / £4.99 additional per month)
    2. Seeker subscription — paid by Seeker or by Guardian

------------------------------------------------------------
GUARDIAN SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Guardian (Basic):
  [ Invite Your Guardian ] → ZYRA sends SMS/email (Basic)
  → [ Guardian Invitation Landing ] → [ Create Account ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]

Path 2 — Seeker purchases Guardian Pro:
  [ Invite Your Guardian ] → Seeker pays → ZYRA sends SMS/email (Pro)
  → [ Guardian Invitation Landing ] → [ Create / Sign In ]
  → Prompt: "A Pro Seat is waiting — activate it?"
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]

Path 3 — Guardian starts first:
  [ Guardian Sign Up ] → [ Choose Tier: Basic / Pro ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]
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
GUARDIAN NAVIGATION
------------------------------------------------------------

Guardian accounts use a fixed 4-tab navigation:
  Dashboard · Seekers · Network · Profile

  — No Universal Toggle (Seeker-only mechanic)
  — All tabs equal size, all icons 18px
  — Floating glass pill: same design as Seeker nav

Network tab:
  — Only accessible with at least one active Pro Seat
  — Basic Guardian tapping Network → upgrade screen

------------------------------------------------------------
GUARDIAN NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-06-28

WHAT THE GUARDIAN NETWORK IS

The Guardian Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to verified Guardians with an active Pro Seat.

WHAT IS DISPLAYED

The cards shown in the Network are Seeker profile cards.
The Guardian is browsing on behalf of their linked Seeker.

The Guardian cannot edit or customise what is shown.
Cards are 100% system-controlled.

No free-text introductions.
No biographies.
No manually added information.

Reason:
Free text creates a privacy loophole. A Guardian could
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
  — Guardian relationship ("Guided by his father")
  — Verified Guardian badge

No Guardian tier shown on cards.
Access to Network already requires a Pro Seat.

SEEKER CONSENT

Because the Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Guardian, they agree to Terms &
Conditions explaining:
  — What their linked Guardian can view
  — What information is displayed to other verified Guardians
    in the Network
  — That their profile card becomes visible in the Network
    once a Guardian is linked

Consent is collected during the Guardian linking flow.

GUARDIAN NETWORK FLOW

1. Guardian A discovers Seeker B's system-controlled card
   in the Network Discover feed.

2. Guardian A sends a Family Introduction Request to Guardian B.

3. Guardian B reviews Seeker A's system-controlled card.

4. Guardian B accepts or declines.

5. If both Guardians agree:
   The introduction is presented to both Seekers
   independently.

6. Each Seeker independently accepts or declines.

7. If both Seekers accept:
   The standard ZYRA Journey begins.

Key principle:
Guardians agree that an introduction is worth presenting.
They do not accept on behalf of Seekers.
Seeker consent is always required before a Journey begins.

INTRODUCTION LOGIC — MULTIPLE SEEKERS

When a Guardian taps Introduce from a Seeker card:

  If the Guardian has one eligible Seeker (gender-matched):
    → Automatically sends the introduction on their behalf.
    → No selection prompt.
    → "This introduction will be sent on behalf of [Name]."

  If the Guardian has two or more eligible Seekers:
    → A selection screen appears.
    → The Guardian selects which daughter (or son) this
      introduction is for.
    → Maximum one per introduction request.

  Gender matching is automatic.
  A Guardian with both a son and a daughter browsing male
  Seeker cards will only see the introduction sent
  on behalf of the daughter.

NETWORK TABS

  Discover  — Guardian browses system-controlled Seeker cards
  Requests  — Incoming Family Introduction Requests

------------------------------------------------------------
GUARDIAN NETWORK — COMPATIBILITY FILTERING PRINCIPLE
------------------------------------------------------------

RULE: The compatibility engine operates at the Seeker level.
It never operates at the Guardian level.

Each Seeker linked to a Guardian is evaluated independently
for compatibility, hard requirements, and visibility.
A Seeker's profile never affects another Seeker's visibility
simply because they share the same Guardian.

EXAMPLE

  Guardian Ahmed is linked to:
    Son A — smokes
    Son B — does not smoke

  Another Seeker has a Hard Requirement:
    🚫 Never show anyone who smokes.

  Incorrect (Guardian-level filtering):
    Guardian Ahmed disappears from the Network entirely
    because Son A does not satisfy the requirement.

  Correct (Seeker-level filtering):
    Son A → ❌ Fails Hard Requirement → Not shown.
    Son B → ✅ Passes Hard Requirement → Shown.
    Guardian Ahmed remains visible in the Network,
    showing only Son B's card.

CONSEQUENCES

  — A Guardian with multiple Seekers may have different numbers
    of Seeker rows visible to different Network viewers.

  — A Guardian card may show 2 Seekers to one viewer and
    1 Seeker to another, depending on compatibility.

  — If none of a Guardian's linked Seekers pass compatibility,
    the Guardian card does not appear at all for that viewer.

  — Each Seeker card in the Network has independent:
      · Compatibility filtering
      · Hard Requirement filtering
      · Visibility
      · Family Introduction requests

ALIGNMENT WITH BROWSE

  The Guardian Network uses the same compatibility engine,
  hard requirement rules, and visibility logic as Browse.

  The only architectural difference between Browse and
  the Guardian Network is who initiates the introduction:

    Browse:        Seeker initiates.
    Guardian Network:  Guardian initiates on behalf of their Seeker.

  The underlying engine is identical.

------------------------------------------------------------
EXCEPTIONAL CASES (DEFERRED)
------------------------------------------------------------

The following scenarios are not handled in core onboarding.
Deferred to ZYRA's Islamic Governance document:

  — Seeker has no living male guardian
  — Seeker is a revert with no Muslim male family member
  — Dispute over who has Guardian authority
  — Guardian becomes unavailable mid-journey
  — Female guardian acting in Guardian capacity in exceptional
    circumstances
