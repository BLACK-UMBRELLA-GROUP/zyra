FEATURE NAME
ZYRA TERMINOLOGY
Group: 1 — Business Rules

Status: Approved

============================================================
SUMMARY
============================================================

Purpose:
Owns official ZYRA terminology, definitions, language
standards, terminology relationships, and terminology usage
throughout the platform.

This document is the source of truth for all terminology
used across ZYRA — in features, scripts, flows, onboarding,
notifications, and all product documentation.

Owns:
• Official terminology
• Definitions
• User explanations
• Internal explanations
• Terminology relationships
• Language standards
• Terminology usage rules

Note:
• Flow Diagram — not applicable. This document defines
  terminology rather than application flows.
• Script — not applicable. Feature implementations belong
  within their respective files.

============================================================
ROLE TERMINOLOGY
============================================================

------------------------------------------------------------
TERM: Seeker
------------------------------------------------------------

Definition:
A person actively looking for marriage through ZYRA.

Purpose:
Identifies the primary marriage candidate using the platform.

User Explanation:
A Seeker is someone looking for a suitable marriage partner.

Internal Explanation:
The core marriage-candidate role throughout ZYRA. The Seeker
is the person progressing through the marriage journey and
is the primary user of marriage-search features.

Found In:
• Sign Up
• Onboarding
• Browse
• Profile Page
• Connections
• Proposal Tracker
• Subscriptions

Related Systems:
• Browse
• Potentials
• Connections
• Profile Unlocks
• Proposal Tracker
• Wali System
• Subscriptions

Notes:
• Seeker = Marriage Candidate.
• When "Seeker" is used, it always refers to the person
  seeking marriage.
• The Seeker is the person paying to find a marriage partner.

------------------------------------------------------------
TERM: Wali
------------------------------------------------------------

Definition:
A supervisor or guardian who helps oversee and support the
marriage process.

Purpose:
Provides guidance, oversight, accountability, and involvement
throughout the marriage journey.

User Explanation:
A Wali is a guardian or supervisor who helps oversee the
marriage process.

Internal Explanation:
The supervisory role within ZYRA. A Wali assists and oversees
Seekers while supporting the marriage journey.

Found In:
• Sign Up
• Onboarding
• Browse
• Wali Features
• Connections
• Proposal Tracker
• Notifications

Related Systems:
• Wali System
• Browse
• Potentials
• Connections
• Proposal Tracker
• Subscriptions

Notes:
• Wali = Supervisor / Guardian.
• When "Wali" is used, it always refers to the supervisory role.
• The Wali is not the marriage candidate.

============================================================
DISCOVERY TERMINOLOGY
============================================================

------------------------------------------------------------
TERM: Browse
------------------------------------------------------------

Definition:
The primary profile discovery area within ZYRA where users
discover potential marriage candidates.

Purpose:
Allows users to discover and assess potential marriage
candidates before viewing more detailed profile information.

User Explanation:
Browse is where you discover potential marriage candidates
and make an initial decision about whether a profile may
be suitable.

Internal Explanation:
The primary discovery system used for first-stage marriage
consideration.

Found In:
• Bottom Navigation
• Browse Page
• Discovery Journey

Related Systems:
• Decline
• Review
• Consider
• Potentials
• Notifications
• Profile Pages

Notes:
• Browse focuses on first impressions.
• Browse is appearance-first.
• Browse does not display profile bios.
• Browse does not display detailed profile information.
• Browse does not allow messaging.
• Browse is intended to support fast profile discovery.

============================================================
PROFILE DECISION TERMINOLOGY
============================================================

------------------------------------------------------------
TERM: Decline
------------------------------------------------------------

Definition:
A decision indicating that a profile is not suitable for
marriage consideration.

Purpose:
Allows users to remove unsuitable profiles from their
discovery process.

User Explanation:
Decline means "this profile is not suitable for me."

Internal Explanation:
A negative profile decision that removes the profile from
active consideration.

Found In:
• Browse
• Profile Page

Related Systems:
• Browse
• Discovery

Notes:
• Available to Seekers.
• Not available to Walis.
• Decline is a final rejection decision.

------------------------------------------------------------
TERM: Review
------------------------------------------------------------

Definition:
A decision indicating that a profile requires further review
before a marriage decision is made.

Purpose:
Allows users to revisit profiles later without placing them
under consideration.

User Explanation:
Review means "I am not ready to decide yet and would like
to look again later."

Internal Explanation:
A neutral holding decision that stores a profile for future
review.

Found In:
• Browse
• Profile Page
• Reviewed Profiles

Related Systems:
• Browse
• Reviewed Profiles

Notes:
• Available to Seekers.
• Available to Walis.
• Review is neither positive nor negative.
• Review does not create a Consideration.
• Review does not create a Match.

------------------------------------------------------------
TERM: Consider
------------------------------------------------------------

Definition:
A decision indicating that a profile may be suitable for
marriage consideration.

Purpose:
Allows users to identify profiles worth exploring further
within the marriage discovery process.

User Explanation:
Consider means "this profile may be suitable and I would
like to keep it under consideration."

Internal Explanation:
A positive profile decision that moves a profile into the
Considerations system.

Found In:
• Browse
• Profile Page
• Considerations

Related Systems:
• Browse
• Considerations
• Matching
• Connections

Notes:
• Available to Seekers.
• Not available to Walis.
• Consider does not mean Like.
• Consider does not mean Love.
• Consider does not mean Match.
• Consider means the profile may be suitable for marriage
  consideration.

============================================================
ROLE RELATIONSHIPS
============================================================

| Role   | Meaning                                          |
|--------|--------------------------------------------------|
| Seeker | Person actively looking for marriage             |
| Wali   | Supervisor / Guardian helping oversee the process|

| ZYRA Term | Equivalent Meaning       |
|-----------|--------------------------|
| Seeker    | Marriage Candidate       |
| Wali      | Supervisor / Guardian    |

Usage Rules:
• "Seeker" always refers to the person seeking marriage.
• "Wali" always refers to the supervisor or guardian.
• Seeker and Wali are separate roles with different
  responsibilities.

Decision Permissions:

Seeker:
• Decline
• Review
• Consider

Wali:
• Review

Wali Cannot:
• Decline
• Consider

============================================================
DISCOVERY RELATIONSHIPS
============================================================

Browse Available To:
• Seeker Basic
• Seeker Pro
• Seeker Premium
• Wali Pro
• Wali Premium

Primary Decisions:
• Decline
• Review
• Consider

Browse Purpose:
Browse    → Discovery
Review    → Review Later
Consider  → Potentially Suitable
Decline   → Not Suitable

Browse Philosophy:
• First impressions first.
• Decision before deeper profile information.
• Fast profile discovery.
• Appearance-first experience.

============================================================
DECISION RELATIONSHIPS
============================================================

Decision Flow:
Decline  → Not Suitable
Review   → Review Later / Undecided
Consider → Potentially Suitable

Important:
• Consider ≠ Like
• Consider ≠ Love
• Consider ≠ Match
• Consider = Suitable for Marriage Consideration

Role Access:
• Seeker → Decline, Review, Consider
• Wali   → Review Only

============================================================
APPROVED TO-DO LIST
============================================================

Terms still to be defined:
• Potential
• Consideration
• Connection
• Match
• Timeline
• Proposal Tracker
• Profile Unlock
• Network
• Saved
• Incoming Potential
• Mutual Potential
• Notifications
• Discovery
• Subscription Terminology
• AI Terminology
• Trust Score
• Verification
• Compatibility Preview
• Compatibility Preview+
• Match Confidence
