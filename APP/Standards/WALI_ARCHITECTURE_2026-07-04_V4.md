FEATURE NAME
ZYRA — Platform Architecture
Document: Wali Architecture

============================================================
WALI ARCHITECTURE
============================================================

Version: V4
Status: CURRENT_VERSION
Last Updated: 2026-07-04

Governing Documents:
  — ZYRA Product Specification V3 (canonical relationship lifecycle)
  — ZYRA Journey Capability Grant Rules V2 (Wali capability model)
  — AD-081 — Capability Independence Principle
  — AD-082 — State Integrity Principle

Change from V3:
  — Pro Seat model removed. Wali capabilities are now determined
    entirely by the linked Seeker's active subscription, resolved
    by AIOS per Journey relationship (AD-081; Journey Capability
    Grant Rules V1).
  — "Wali Tier Rules" section renamed to "Capability Grant Rules"
    and fully rewritten to reflect the correct model.
  — Pro Seat pricing (£9.99 / £4.99) removed from this document.
    No Wali-level subscription exists.
  — "Choose Tier: Basic / Pro" removed from Path 3 screen flow.
  — "Wali Basic" and "Wali Pro" replaced throughout with language
    aligned to Journey Capability Grant Rules V2.
  — Wali account linking limits decoupled from the removed Pro Seat
    model and flagged for formal review.
  — Permissions Model revised to a two-column format: capabilities
    when linked Seeker holds ZYRA Basic vs. ZYRA One.
  — Network access condition revised from "active Pro Seat" to
    "at least one linked Seeker holding ZYRA One."
  — Relationship lifecycle terminology aligned to Product Spec V3:
    "Match" → "Active Journey", "Active Match" → "Active Journey".

Change from V2:
  — Compatibility filtering principle added (engine operates at
    Seeker level only, never at Wali level)
  — Wali Network aligned to Browse architecture

Change from V1:
  — Family Review Period added
  — Subscription model clarified
  — Wali Network introduced

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

Wali accounts carry identity only.

A Wali account has no capability tier. Capabilities are
not stored on the Wali account or derived from it.
For each Journey relationship, AIOS resolves the Wali's
capabilities based on the linked Seeker's active subscription.

A Wali linked to multiple Seekers may simultaneously hold
different capability grants for different Journey relationships.
This is the correct and expected behaviour, not a conflict.

See: ZYRA Journey Capability Grant Rules V2
See: AD-081 — Capability Independence Principle

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites Their Wali

  The Seeker completes onboarding and invites their Wali.
  The invitation is sent via the Wali's email or mobile number.

  If the Wali does not have a ZYRA account:
    → They create a Wali account and are auto-linked.

  If the Wali already has a ZYRA account:
    → Accepting the invitation links them immediately.

  The Wali's capabilities for this Journey relationship are
  determined by the Wali's own account entitlement.

PATH 2 — Wali Holds ZYRA One Entitlement

  A Wali may independently purchase ZYRA One.
  The Wali account holds the entitlement — no Seeker action is
  required.

  When the Wali acts within a Journey relationship, AIOS grants
  the extended Wali capability set because the Wali's own
  account holds ZYRA One.

  No separate activation step is required.
  Capability resolution is automatic and continuous.
  This applies to all of the Wali's Journey relationships.

PATH 3 — Wali Starts First

  A parent or guardian organises everything before the Seeker
  joins. This reflects how many Muslim families naturally
  operate and is a first-class path.

  1. Wali creates a Wali account.
  2. Wali completes Wali onboarding.
  3. Wali generates an invitation for their Seeker.
  4. Seeker joins using that invitation link.
  5. Both accounts are automatically linked.

  The Wali's capabilities are determined by the Wali's own
  account entitlement. No tier selection occurs during
  Wali onboarding. Capability is not a property of the
  Wali account identity — it is resolved by AIOS at runtime.

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
CAPABILITY GRANT RULES
------------------------------------------------------------

A Wali's capabilities within a Journey relationship are not
a property of the Wali account. They are granted by AIOS
for each Journey relationship, based on the entitlement held
by the Wali's own account.

This section describes what capabilities apply in each case.
The authoritative specification is: ZYRA Journey Capability
Grant Rules V2.

WALI HOLDS ZYRA BASIC (default entitlement)

  AIOS grants standard Wali capabilities for all Journey
  relationships where the Wali's account holds ZYRA Basic.

  Standard Wali capabilities:
  — View Seeker's active Journey progress
  — View messages between Seeker and their match
  — View Timeline
  — Receive notifications at each Family Review Period
  — Choose Continue or Pause during the Family Review Period
  — Raise a concern or flag to ZYRA support
  — Receive safety alerts

WALI HOLDS ZYRA ONE

  AIOS grants extended Wali capabilities for all Journey
  relationships where the Wali's account holds ZYRA One,
  in addition to all standard capabilities above.

  Extended Wali capabilities (AIOS-granted):
  — Browse Seeker profile cards in the Wali Network
  — Send and receive Family Introduction Requests
  — Suggest profiles to their linked Seeker
  — View and deliver Wali AI Summary

ENTITLEMENT EXAMPLE

  Wali Ahmed holds ZYRA One on his own account.

  Ahmed is linked to:
    Daughter → AIOS grants extended capabilities (Ahmed holds One)
    Son      → AIOS grants extended capabilities (Ahmed holds One)

  Ahmed's entitlement applies to all his Journey relationships.
  Each Seeker's own entitlement determines their Seeker capabilities
  independently — Ahmed's entitlement does not affect them.

  If Ahmed downgrades to ZYRA Basic:
  AIOS revokes extended Wali capabilities across all his
  Journey relationships simultaneously.

CAPABILITY CHANGES

  If the Wali upgrades from ZYRA Basic to ZYRA One:
  → AIOS automatically grants extended Wali capabilities
    across all the Wali's Journey relationships.

  If the Wali downgrades from ZYRA One to ZYRA Basic:
  → AIOS automatically revokes extended Wali capabilities
    across all the Wali's Journey relationships.
    Standard capabilities remain active.

  No manual action is required by either the Seeker or the Wali.

WALI ACCOUNT LINKING LIMITS

  The previous model used a 1-Seeker cap on Wali accounts
  to prevent abuse of the (now removed) Pro Seat model.
  That cap has been removed alongside the Pro Seat model.

  Linking limits for Wali accounts are under review.
  A revised policy will be specified in a future update.
  Until then: no artificial cap is imposed at the account level.

------------------------------------------------------------
WALI PERMISSIONS MODEL
------------------------------------------------------------

The following table shows what each Wali can see and do,
differentiated by the Wali's own account entitlement.

                          | Wali: ZYRA Basic  | Wali: ZYRA One  |
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
Wali Network access       |        ✗          |       ✓         |
Family Introductions      |        ✗          |       ✓         |
Suggest profiles          |        ✗          |       ✓         |
Wali AI Summary           |        ✗          |       ✓         |

WHAT THE WALI CAN NEVER SEE (regardless of Seeker's subscription)

  — Chapter 3 (Values) answers
  — Chapter 4 (Preferences / compatibility settings)
    Compatibility settings remain private to Seeker only.
  — Match list / Browse activity

THE WALI DOES NOT:
  — See Chapter 3 or Chapter 4 answers
  — Control who the Seeker browses or expresses interest in
  — Accept on behalf of the Seeker — Seeker consent is always
    required before an Active Journey begins

------------------------------------------------------------
WALI RESPONSIBILITIES
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

PAUSE BEHAVIOUR

  If a Wali selects Pause:
  — The Journey pauses immediately.
  — The matched Seekers are notified that the Journey
    has been paused for family review.
  — ZYRA support is available to assist if the pause
    cannot be resolved between both families.

  Pause does not mean rejection.
  It means the family needs more time.

  Note: "Pause Journey" as used here refers to the Wali's
  action within the Family Review Period. This is distinct
  from the "Pause Journey" feature available to ZYRA One
  Seekers (which pauses the Active Journey entirely).
  Both use the same term in their respective contexts.

------------------------------------------------------------
WALI SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Wali:
  [ Invite Your Wali ] → ZYRA sends SMS/email
  → [ Wali Invitation Landing ] → [ Create Account ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]

Path 2 — Seeker (on ZYRA One) invites Wali:
  [ Invite Your Wali ] → ZYRA sends SMS/email
  → [ Wali Invitation Landing ] → [ Create / Sign In ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]
  (Extended capabilities are AIOS-granted automatically
   — no activation step required from the Wali)

Path 3 — Wali starts first:
  [ Wali Sign Up ] → [ Wali Onboarding ]
  → [ Wali Dashboard ] → [ Invite Seeker ]
  → Seeker receives SMS/email
  → [ Seeker Invitation Landing ] → Seeker onboarding
  → Accounts linked
  (Wali capabilities determined by Seeker's subscription
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
WALI NAVIGATION
------------------------------------------------------------

Wali accounts use a fixed 4-tab navigation:
  Dashboard · Seekers · Network · Profile

  — No Universal Toggle (Seeker-only mechanic)
  — All tabs equal size, all icons 18px
  — Floating glass pill: same design as Seeker nav

Network tab:
  — Accessible when the Wali's own account holds ZYRA One
  — A Wali without ZYRA One entitlement tapping Network
    → sees an explanation that Network access requires
      the Wali to hold ZYRA One

------------------------------------------------------------
WALI NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-07-04

WHAT THE WALI NETWORK IS

The Wali Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to Walis whose account holds ZYRA One
(capability granted by AIOS based on Wali's entitlement).

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

SEEKER CONSENT

Because the Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Wali, they agree to Terms &
Conditions explaining:
  — What their linked Wali can view
  — What information is displayed to other verified Walis
    in the Network
  — That their profile card becomes visible in the Network
    if their subscription grants Wali Network capabilities

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
   The standard ZYRA Journey begins (Potential Journey
   created; Ritual required to create Active Journey).

Key principle:
Walis agree that an introduction is worth presenting.
They do not accept on behalf of Seekers.
Seeker consent is always required before an Active
Journey begins.

INTRODUCTION LOGIC — MULTIPLE SEEKERS

When a Wali taps Introduce from a Seeker card:

  If the Wali has one eligible Seeker (gender-matched):
    → Automatically sends the introduction on their behalf.
    → No selection prompt.
    → "This introduction will be sent on behalf of [Name]."

  If the Wali has two or more eligible Seekers:
    → A selection screen appears.
    → The Wali selects which Seeker this introduction is for.
    → Maximum one per introduction request.

  Gender matching is automatic.

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

------------------------------------------------------------
PENDING ITEMS
------------------------------------------------------------

The following items require formal resolution:

  WALI ACCOUNT LINKING LIMITS
  The previous 1-Seeker cap for "Wali Basic" has been removed
  alongside the Pro Seat model it was designed to protect.
  A revised linking policy must be specified before production.
  Outstanding item: Wali Account Linking Limits V1.

  FAMILY STAGE — WALI PARTICIPATION RULES
  Detailed Wali conversation permissions during the Family
  Stage are deferred to the Family Stage specification.

  WALI ↔ WALI COMMUNICATION
  Private Wali-to-Wali communication rules depend on the
  Family Stage specification.

