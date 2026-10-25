FEATURE NAME
ZYRA — Platform Architecture
Document: Guardian Architecture

============================================================
GUARDIAN ARCHITECTURE
============================================================

Version: V4
Status: CURRENT_VERSION
Last Updated: 2026-07-04

Governing Documents:
  — ZYRA Product Specification V3 (canonical relationship lifecycle)
  — ZYRA Journey Capability Grant Rules V2 (Guardian capability model)
  — AD-081 — Capability Independence Principle
  — AD-082 — State Integrity Principle

Change from V3:
  — Pro Seat model removed. Guardian capabilities are now determined
    entirely by the linked Seeker's active subscription, resolved
    by AIOS per Journey relationship (AD-081; Journey Capability
    Grant Rules V1).
  — "Guardian Tier Rules" section renamed to "Capability Grant Rules"
    and fully rewritten to reflect the correct model.
  — Pro Seat pricing (£9.99 / £4.99) removed from this document.
    No Guardian-level subscription exists.
  — "Choose Tier: Basic / Pro" removed from Path 3 screen flow.
  — "Guardian Basic" and "Guardian Pro" replaced throughout with language
    aligned to Journey Capability Grant Rules V2.
  — Guardian account linking limits decoupled from the removed Pro Seat
    model and flagged for formal review.
  — Permissions Model revised to a two-column format: capabilities
    when linked Seeker holds ZYRA Basic vs. ZYRA One.
  — Network access condition revised from "active Pro Seat" to
    "at least one linked Seeker holding ZYRA One."
  — Relationship lifecycle terminology aligned to Product Spec V3:
    "Match" → "Active Journey", "Active Match" → "Active Journey".

Change from V2:
  — Compatibility filtering principle added (engine operates at
    Seeker level only, never at Guardian level)
  — Guardian Network aligned to Browse architecture

Change from V1:
  — Family Review Period added
  — Subscription model clarified
  — Guardian Network introduced

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

Guardian accounts carry identity only.

A Guardian account has no capability tier. Capabilities are
not stored on the Guardian account or derived from it.
For each Journey relationship, AIOS resolves the Guardian's
capabilities based on the linked Seeker's active subscription.

A Guardian linked to multiple Seekers may simultaneously hold
different capability grants for different Journey relationships.
This is the correct and expected behaviour, not a conflict.

See: ZYRA Journey Capability Grant Rules V2
See: AD-081 — Capability Independence Principle

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites Their Guardian

  The Seeker completes onboarding and invites their Guardian.
  The invitation is sent via the Guardian's email or mobile number.

  If the Guardian does not have a ZYRA account:
    → They create a Guardian account and are auto-linked.

  If the Guardian already has a ZYRA account:
    → Accepting the invitation links them immediately.

  The Guardian's capabilities for this Journey relationship are
  determined by the Guardian's own account entitlement.

PATH 2 — Guardian Holds ZYRA One Entitlement

  A Guardian may independently purchase ZYRA One.
  The Guardian account holds the entitlement — no Seeker action is
  required.

  When the Guardian acts within a Journey relationship, AIOS grants
  the extended Guardian capability set because the Guardian's own
  account holds ZYRA One.

  No separate activation step is required.
  Capability resolution is automatic and continuous.
  This applies to all of the Guardian's Journey relationships.

PATH 3 — Guardian Starts First

  A parent or guardian organises everything before the Seeker
  joins. This reflects how many Muslim families naturally
  operate and is a first-class path.

  1. Guardian creates a Guardian account.
  2. Guardian completes Guardian onboarding.
  3. Guardian generates an invitation for their Seeker.
  4. Seeker joins using that invitation link.
  5. Both accounts are automatically linked.

  The Guardian's capabilities are determined by the Guardian's own
  account entitlement. No tier selection occurs during
  Guardian onboarding. Capability is not a property of the
  Guardian account identity — it is resolved by AIOS at runtime.

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
CAPABILITY GRANT RULES
------------------------------------------------------------

A Guardian's capabilities within a Journey relationship are not
a property of the Guardian account. They are granted by AIOS
for each Journey relationship, based on the entitlement held
by the Guardian's own account.

This section describes what capabilities apply in each case.
The authoritative specification is: ZYRA Journey Capability
Grant Rules V2.

GUARDIAN HOLDS ZYRA BASIC (default entitlement)

  AIOS grants standard Guardian capabilities for all Journey
  relationships where the Guardian's account holds ZYRA Basic.

  Standard Guardian capabilities:
  — View Seeker's active Journey progress
  — View messages between Seeker and their match
  — View Timeline
  — Receive notifications at each Family Review Period
  — Choose Continue or Pause during the Family Review Period
  — Raise a concern or flag to ZYRA support
  — Receive safety alerts

GUARDIAN HOLDS ZYRA ONE

  AIOS grants extended Guardian capabilities for all Journey
  relationships where the Guardian's account holds ZYRA One,
  in addition to all standard capabilities above.

  Extended Guardian capabilities (AIOS-granted):
  — Browse Seeker profile cards in the Guardian Network
  — Send and receive Family Introduction Requests
  — Suggest profiles to their linked Seeker
  — View and deliver Guardian AI Summary

ENTITLEMENT EXAMPLE

  Guardian Ahmed holds ZYRA One on his own account.

  Ahmed is linked to:
    Daughter → AIOS grants extended capabilities (Ahmed holds One)
    Son      → AIOS grants extended capabilities (Ahmed holds One)

  Ahmed's entitlement applies to all his Journey relationships.
  Each Seeker's own entitlement determines their Seeker capabilities
  independently — Ahmed's entitlement does not affect them.

  If Ahmed downgrades to ZYRA Basic:
  AIOS revokes extended Guardian capabilities across all his
  Journey relationships simultaneously.

CAPABILITY CHANGES

  If the Guardian upgrades from ZYRA Basic to ZYRA One:
  → AIOS automatically grants extended Guardian capabilities
    across all the Guardian's Journey relationships.

  If the Guardian downgrades from ZYRA One to ZYRA Basic:
  → AIOS automatically revokes extended Guardian capabilities
    across all the Guardian's Journey relationships.
    Standard capabilities remain active.

  No manual action is required by either the Seeker or the Guardian.

GUARDIAN ACCOUNT LINKING LIMITS

  The previous model used a 1-Seeker cap on Guardian accounts
  to prevent abuse of the (now removed) Pro Seat model.
  That cap has been removed alongside the Pro Seat model.

  Linking limits for Guardian accounts are under review.
  A revised policy will be specified in a future update.
  Until then: no artificial cap is imposed at the account level.

------------------------------------------------------------
GUARDIAN PERMISSIONS MODEL
------------------------------------------------------------

The following table shows what each Guardian can see and do,
differentiated by the Guardian's own account entitlement.

                          | Guardian: ZYRA Basic  | Guardian: ZYRA One  |
--------------------------|-------------------|-----------------|
View Journey progress     |        ✓          |       ✓         |
View messages             |        ✓          |       ✓         |
View Timeline             |        ✓          |       ✓         |
Receive Family Review     |        ✓          |       ✓         |
  Period notifications    |                   |                 |
Continue / Pause at       |        ✓          |       ✓         |
  Family Review Period    |                   |                 |
Raise concern / flag      |        ✓          |       ✓         |
Receive safety alerts     |        ✓          |       ✓         |
Guardian Network access       |        ✗          |       ✓         |
Family Introductions      |        ✗          |       ✓         |
Suggest profiles          |        ✗          |       ✓         |
Guardian AI Summary           |        ✗          |       ✓         |

WHAT THE GUARDIAN CAN NEVER SEE (regardless of Seeker's subscription)

  — Chapter 3 (Values) answers
  — Chapter 4 (Preferences / compatibility settings)
    Compatibility settings remain private to Seeker only.
  — Match list / Browse activity

THE GUARDIAN DOES NOT:
  — See Chapter 3 or Chapter 4 answers
  — Control who the Seeker browses or expresses interest in
  — Accept on behalf of the Seeker — Seeker consent is always
    required before an Active Journey begins

------------------------------------------------------------
GUARDIAN RESPONSIBILITIES
------------------------------------------------------------

  ✓ Viewing the progress of each Journey
  ✓ Viewing messages between Seeker and their match
  ✓ Receiving notifications at each Family Review Period
  ✓ Choosing to Continue or Pause during the Review Period
  ✓ Participating in family introductions (when Seeker holds
    ZYRA One — AIOS-granted capability)
  ✓ Joining conversations when appropriate
  ✓ Receiving safety notifications when necessary
  ✓ Helping ensure the process remains respectful
    and family-oriented

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

PAUSE BEHAVIOUR

  If a Guardian selects Pause:
  — The Journey pauses immediately.
  — The matched Seekers are notified that the Journey
    has been paused for family review.
  — ZYRA support is available to assist if the pause
    cannot be resolved between both families.

  Pause does not mean rejection.
  It means the family needs more time.

  Note: "Pause Journey" as used here refers to the Guardian's
  action within the Family Review Period. This is distinct
  from the "Pause Journey" feature available to ZYRA One
  Seekers (which pauses the Active Journey entirely).
  Both use the same term in their respective contexts.

------------------------------------------------------------
GUARDIAN SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Guardian:
  [ Invite Your Guardian ] → ZYRA sends SMS/email
  → [ Guardian Invitation Landing ] → [ Create Account ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]

Path 2 — Seeker (on ZYRA One) invites Guardian:
  [ Invite Your Guardian ] → ZYRA sends SMS/email
  → [ Guardian Invitation Landing ] → [ Create / Sign In ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]
  (Extended capabilities are AIOS-granted automatically
   — no activation step required from the Guardian)

Path 3 — Guardian starts first:
  [ Guardian Sign Up ] → [ Guardian Onboarding ]
  → [ Guardian Dashboard ] → [ Invite Seeker ]
  → Seeker receives SMS/email
  → [ Seeker Invitation Landing ] → Seeker onboarding
  → Accounts linked
  (Guardian capabilities determined by Seeker's subscription
   — resolved automatically by AIOS on link)

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
  — Accessible when the Guardian's own account holds ZYRA One
  — A Guardian without ZYRA One entitlement tapping Network
    → sees an explanation that Network access requires
      the Guardian to hold ZYRA One

------------------------------------------------------------
GUARDIAN NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-07-04

WHAT THE GUARDIAN NETWORK IS

The Guardian Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to Guardians whose account holds ZYRA One
(capability granted by AIOS based on Guardian's entitlement).

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

SEEKER CONSENT

Because the Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Guardian, they agree to Terms &
Conditions explaining:
  — What their linked Guardian can view
  — What information is displayed to other verified Guardians
    in the Network
  — That their profile card becomes visible in the Network
    if their subscription grants Guardian Network capabilities

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
   The standard ZYRA Journey begins (Potential Journey
   created; Ritual required to create Active Journey).

Key principle:
Guardians agree that an introduction is worth presenting.
They do not accept on behalf of Seekers.
Seeker consent is always required before an Active
Journey begins.

INTRODUCTION LOGIC — MULTIPLE SEEKERS

When a Guardian taps Introduce from a Seeker card:

  If the Guardian has one eligible Seeker (gender-matched):
    → Automatically sends the introduction on their behalf.
    → No selection prompt.
    → "This introduction will be sent on behalf of [Name]."

  If the Guardian has two or more eligible Seekers:
    → A selection screen appears.
    → The Guardian selects which Seeker this introduction is for.
    → Maximum one per introduction request.

  Gender matching is automatic.

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

------------------------------------------------------------
PENDING ITEMS
------------------------------------------------------------

The following items require formal resolution:

  GUARDIAN ACCOUNT LINKING LIMITS
  The previous 1-Seeker cap for "Guardian Basic" has been removed
  alongside the Pro Seat model it was designed to protect.
  A revised linking policy must be specified before production.
  Outstanding item: Guardian Account Linking Limits V1.

  FAMILY STAGE — GUARDIAN PARTICIPATION RULES
  Detailed Guardian conversation permissions during the Family
  Stage are deferred to the Family Stage specification.

  GUARDIAN ↔ GUARDIAN COMMUNICATION
  Private Guardian-to-Guardian communication rules depend on the
  Family Stage specification.

